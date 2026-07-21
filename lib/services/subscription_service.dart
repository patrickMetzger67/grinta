import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:grinta/services/subscription_entitlement_cache.dart';
import 'package:grinta/services/userService.dart' show UserDocumentFields, UserService;
import 'package:grinta/services/user_root_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat-backed subscription state, exposed app-wide via [ChangeNotifier].
///
/// Entitlements are always tied to the **Firebase Auth UID** (via
/// [PurchasesConfiguration.appUserID] / [Purchases.logIn]), never to device
/// or selected player/profile. Call [ensureInitialized] at startup; prefers
/// configuring RC with the restored Firebase UID so a new device does not
/// mint a throwaway anonymous ID. Mobile uses App Store / Play Billing; web
/// uses RevenueCat Web Billing (Stripe checkout hosted by RevenueCat).
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
    _attachLifecycleHandler();
  }

  static final SubscriptionService instance = SubscriptionService._();

  SubscriptionState _state = SubscriptionState.initial();
  Offerings? _offerings;
  bool _sdkConfigured = false;
  String? _loggedInUid;
  Future<void>? _initFuture;
  Future<void>? _logInFuture;
  String? _logInFutureUid;
  Future<void>? _refreshForActiveSessionFuture;
  DateTime? _lastOfferingsRefreshAt;
  _SubscriptionLifecycleObserver? _lifecycleObserver;

  static const Duration _offeringsRefreshMinInterval = Duration(seconds: 60);

  bool _notifyListenersScheduled = false;

  /// Defers listener notifications while a frame is building to avoid
  /// "setState/markNeedsBuild called during build" on web shells and paywalls.
  @override
  void notifyListeners() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      if (_notifyListenersScheduled) return;
      _notifyListenersScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notifyListenersScheduled = false;
        if (hasListeners) super.notifyListeners();
      });
      return;
    }
    super.notifyListeners();
  }

  SubscriptionState get state => _state;
  Offerings? get offerings => _offerings;

  /// True when RevenueCat reports at least one non-expired paid entitlement.
  bool get isSubscribed => _state.isSubscribed;

  /// Active paid entitlement (RevenueCat / durable cache), or platform admin.
  ///
  /// [UserRootService.isRoot] always grants full paid access so admins are never
  /// locked out by a RevenueCat identity glitch.
  bool get hasActivePaidSubscription =>
      UserRootService.instance.isRoot || _state.activeEntitlements.isNotEmpty;

  CoachTier? get coachTier =>
      UserRootService.instance.isRoot ? CoachTier.pro : _state.coachTier;
  bool get hasPlayerSubscription =>
      UserRootService.instance.isRoot || _state.hasPlayerSubscription;
  String? get activeProductId => _state.activeProductId;
  SubscriptionBillingPeriod? get billingPeriod => _state.billingPeriod;
  DateTime? get subscriptionExpiresAt => _state.subscriptionExpiresAt;
  DateTime? get renewalDate => _state.subscriptionExpiresAt;
  Set<String> get activeEntitlements => _state.activeEntitlements;

  bool hasEntitlement(String entitlementId) =>
      _state.hasEntitlement(entitlementId);

  /// Active subscription environment (sandbox in debug, production in release).
  SubscriptionEnvironment get environment => SubscriptionEnvironment.current;

  /// Whether App Store / Play Billing is available (iOS/Android with valid API key).
  bool get isNativeStoreAvailable {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return isRevenueCatIosApiKeyConfigured;
      case TargetPlatform.android:
        return isRevenueCatAndroidApiKeyConfigured;
      default:
        return false;
    }
  }

  /// Whether RevenueCat Web Billing is configured (web + valid `rcb_*` API key).
  bool get isWebBillingAvailable => kIsWeb && isRevenueCatWebApiKeyConfigured;

  /// Whether purchases can be initiated on this platform.
  bool get isPurchaseAvailable =>
      isNativeStoreAvailable || isWebBillingAvailable;

  String get _apiKeyForPlatform {
    if (kIsWeb) return revenueCatWebApiKey;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return revenueCatIosApiKey;
      case TargetPlatform.android:
        return revenueCatAndroidApiKey;
      default:
        return '';
    }
  }

  Future<void> ensureInitialized() async {
    _initFuture ??= _initialize();
    await _initFuture;
  }

  /// Ensures RevenueCat is identified as the current Firebase UID.
  ///
  /// Safe to call after auth changes; no-op when purchases are unavailable or
  /// the user is signed out. Prefer this before reading entitlements / opening
  /// the paywall so access follows the user across devices.
  Future<void> ensureUserLinked() async {
    await ensureInitialized();
    if (!_sdkConfigured) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _logInRevenueCat(uid);
  }

  Future<void> _initialize() async {
    // Restore last-known access before talking to RevenueCat so paywalls do not
    // flash (and so isRoot / promo / prior purchase still work if RC fails).
    final uidBeforeSdk = FirebaseAuth.instance.currentUser?.uid;
    if (uidBeforeSdk != null) {
      await _hydrateFromDurableSources(uidBeforeSdk);
    }

    if (!isPurchaseAvailable) {
      if (_state.activeEntitlements.isEmpty) {
        _state = SubscriptionState.unavailable(error: _unavailableReason());
      } else {
        _state = _state.copyWith(isLoading: false, isInitialized: true);
      }
      notifyListeners();
      return;
    }

    final apiKey = _apiKeyForPlatform;

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

      // Prefer Firebase UID at configure time so a restored session on a new
      // device loads that user's CustomerInfo instead of a fresh anonymous ID.
      final uidAtConfigure = FirebaseAuth.instance.currentUser?.uid;

      if (kDebugMode) {
        final prefix = apiKey.length >= 7 ? apiKey.substring(0, 7) : apiKey;
        debugPrint(
          'SubscriptionService: configuring RevenueCat '
          '(${kIsWeb ? 'web' : defaultTargetPlatform.name}, key=$prefix…, '
          'appUserID=${uidAtConfigure ?? '(anonymous until login)'})',
        );
      }

      final config = PurchasesConfiguration(apiKey)
        ..appUserID = uidAtConfigure;
      await Purchases.configure(config);
      _sdkConfigured = true;

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      await refreshOfferings();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // logIn is idempotent when already identified; also covers auth that
        // arrived after configure started, and refreshes CustomerInfo.
        await _logInRevenueCat(uid);
      } else {
        _state = _state.copyWith(isLoading: false, isInitialized: true);
        notifyListeners();
      }
    } catch (e, st) {
      final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
      final prefix = apiKey.length >= 7 ? apiKey.substring(0, 7) : apiKey;
      debugPrint(
        'SubscriptionService: Purchases.configure FAILED '
        '($platform, key=$prefix…): $e\n$st',
      );
      // Keep durable entitlements when RC configure fails — never lock payers out.
      if (_state.activeEntitlements.isEmpty) {
        _state = SubscriptionState.unavailable(
          error: 'RevenueCat configure failed ($platform): $e. '
              'Verify ${_apiKeyEnvHint()} in dart_defines.json and run with '
              '--dart-define-from-file=dart_defines.json.',
        );
      } else {
        _state = _state.copyWith(
          isLoading: false,
          isInitialized: true,
          lastError: 'RevenueCat configure failed ($platform): $e',
        );
      }
      notifyListeners();
    }
  }

  String _unavailableReason() {
    if (kIsWeb) {
      final raw = revenueCatWebApiKey;
      if (raw.isEmpty) {
        return 'Web Billing non configuré. Ajoutez REVENUECAT_WEB_API_KEY_* '
            'dans dart_defines.json (clés rcb_sb_ / rcb_ depuis RevenueCat).';
      }
      return 'Clé Web Billing RevenueCat invalide (placeholder ou mauvais préfixe). '
          'Utilisez rcb_sb_* (sandbox) ou rcb_* (prod) depuis le dashboard RevenueCat.';
    }

    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final rawKey = _apiKeyForPlatform;
    final envHint = _apiKeyEnvHint();

    if (rawKey.isEmpty) {
      return 'RevenueCat API key missing. Run with '
          '--dart-define-from-file=dart_defines.json and set $envHint '
          '(RevenueCat → Project → ${isAndroid ? 'Android' : 'iOS'} app → API keys). '
          'Cross-platform web subscriptions require a configured mobile SDK.';
    }

    return 'Invalid RevenueCat ${isAndroid ? 'Android' : 'iOS'} API key '
        '(placeholder or wrong prefix). Replace goog_xxx / appl_xxx in '
        'dart_defines.json with the public key from RevenueCat dashboard.';
  }

  String _apiKeyEnvHint() {
    if (kIsWeb) return 'REVENUECAT_WEB_API_KEY_SANDBOX / _PROD';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'REVENUECAT_ANDROID_API_KEY_SANDBOX / _PROD';
    }
    return 'REVENUECAT_IOS_API_KEY_SANDBOX / _PROD';
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (!_sdkConfigured && isPurchaseAvailable) {
      await ensureInitialized();
    }

    final String? uid = user?.uid;
    if (uid == _loggedInUid) {
      // Recover cross-platform entitlements (e.g. web Stripe) if a prior fetch failed.
      if (_sdkConfigured && _state.activeEntitlements.isEmpty) {
        unawaited(refreshForActiveSession());
      }
      return;
    }

    if (uid == null) {
      await _logOutRevenueCat();
      return;
    }

    // Restore durable access for this Firebase user before RC round-trips.
    await _hydrateFromDurableSources(uid);

    if (_sdkConfigured) {
      await _logInRevenueCat(uid);
    }
  }

  /// Links RevenueCat to the signed-in Firebase user before entitlement reads.
  Future<void> _ensureRevenueCatUserLinked() async {
    if (!_sdkConfigured) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (uid != _loggedInUid) {
      await _logInRevenueCat(uid);
      return;
    }

    // Already linked but empty: recover (web Stripe / promo / prior glitch).
    if (_state.activeEntitlements.isEmpty) {
      await _fetchCustomerInfo();
      if (_state.activeEntitlements.isEmpty) {
        await _hydrateFromDurableSources(uid);
      }
    }
  }

  static bool _isAnonymousRevenueCatUser(String appUserId) =>
      appUserId.startsWith(r'$RCAnonymousID');

  Future<void> _logInRevenueCat(String uid) async {
    if (!_sdkConfigured) return;
    if (uid == _loggedInUid) return;

    if (_logInFuture != null && _logInFutureUid == uid) {
      await _logInFuture;
      return;
    }

    final inFlight = _logInFuture;
    if (inFlight != null) {
      await inFlight;
      if (uid == _loggedInUid) return;
      if (_logInFuture != null && _logInFutureUid == uid) {
        await _logInFuture;
        return;
      }
    }

    final future = _performLogInRevenueCat(uid);
    _logInFuture = future;
    _logInFutureUid = uid;
    try {
      await future;
    } finally {
      if (identical(_logInFuture, future)) {
        _logInFuture = null;
        _logInFutureUid = null;
      }
    }
  }

  bool _isConcurrentLoginError(Object e) {
    if (e is PlatformException) {
      final details = '${e.message} ${e.details}';
      if (details.contains('429') ||
          details.contains('7638') ||
          details.contains('another request in flight')) {
        return true;
      }
    }
    final text = e.toString();
    return text.contains('429') ||
        text.contains('7638') ||
        text.contains('another request in flight');
  }

  bool _isInvalidCredentialsError(Object e) {
    if (e is PlatformException) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.invalidCredentialsError) {
        return true;
      }
    }
    final text = e.toString().toLowerCase();
    return text.contains('invalid api key') ||
        text.contains('invalid_credentials');
  }

  void _markRevenueCatLoggedIn(String uid, CustomerInfo info) {
    // originalAppUserId can remain the first anonymous RC id even after
    // Purchases.logIn(firebaseUid); identity is Purchases.appUserID / logIn.
    _loggedInUid = uid;
    if (kDebugMode) {
      final activeKeys = info.entitlements.active.keys.toList();
      debugPrint(
        'SubscriptionService: RevenueCat linked firebaseUid=$uid '
        'rcOriginalAppUserId=${info.originalAppUserId} '
        'activeEntitlements=${activeKeys.isEmpty ? '(none)' : activeKeys.join(', ')}',
      );
    }
  }

  Future<void> _performLogInRevenueCat(String uid) async {
    try {
      _setLoading(true);

      LogInResult? result;

      const maxAttempts = kIsWeb ? 4 : 2;
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          result = await Purchases.logIn(uid);
          // Prefer current appUserID (not originalAppUserId): RC keeps the
          // first-seen anonymous id in originalAppUserId even after identify.
          final currentAppUserId = await Purchases.appUserID;
          if (_isAnonymousRevenueCatUser(currentAppUserId) &&
              attempt < maxAttempts - 1) {
            if (kDebugMode) {
              debugPrint(
                'SubscriptionService: logIn still anonymous '
                '(firebaseUid=$uid, appUserID=$currentAppUserId), '
                'retrying (${attempt + 1}/$maxAttempts)',
              );
            }
            await Future<void>.delayed(
              Duration(milliseconds: 400 * (attempt + 1)),
            );
            continue;
          }
          break;
        } catch (e) {
          if (attempt < maxAttempts - 1 && _isConcurrentLoginError(e)) {
            if (kDebugMode) {
              debugPrint(
                'SubscriptionService: Purchases.logIn concurrent request '
                '(firebaseUid=$uid), retrying in 500ms',
              );
            }
            await Future<void>.delayed(const Duration(milliseconds: 500));
            continue;
          }
          rethrow;
        }
      }

      if (result == null) {
        throw StateError('Purchases.logIn returned no result');
      }

      final linkedAppUserId = await Purchases.appUserID;
      if (linkedAppUserId != uid && kDebugMode) {
        debugPrint(
          'SubscriptionService: WARNING appUserID=$linkedAppUserId '
          'expected firebaseUid=$uid after Purchases.logIn',
        );
      }

      _markRevenueCatLoggedIn(uid, result.customerInfo);
      _applyCustomerInfo(result.customerInfo);
      await _fetchCustomerInfo();
      await refreshOfferings();
      _lastOfferingsRefreshAt = DateTime.now();

      if (kDebugMode) {
        final info = result.customerInfo;
        final activeKeys = info.entitlements.active.keys.toList();
        debugPrint(
          'SubscriptionService: logIn firebaseUid=$uid '
          'rcAppUserID=$linkedAppUserId '
          'rcOriginalAppUserId=${info.originalAppUserId} '
          'activeEntitlements=${activeKeys.isEmpty ? '(none)' : activeKeys.join(', ')}',
        );
        if (!kIsWeb && activeKeys.isNotEmpty) {
          debugPrint(
            'SubscriptionService: cross-platform entitlements synced after logIn '
            '(e.g. web Stripe purchase): ${activeKeys.join(', ')}',
          );
        }
      }
    } catch (e, st) {
      if (_isInvalidCredentialsError(e)) {
        if (kDebugMode) {
          debugPrint(
            'SubscriptionService: Purchases.logIn skipped (invalid RevenueCat API key). '
            'Check REVENUECAT_* dart_defines for this build.',
          );
        }
      } else {
        debugPrint(
          'SubscriptionService: Purchases.logIn FAILED (firebaseUid=$uid): $e\n$st',
        );
        _state = _state.copyWith(lastError: e.toString());
      }
      _state = _state.copyWith(isLoading: false, isInitialized: true);
      notifyListeners();
    }
  }

  Future<void> _logOutRevenueCat() async {
    _loggedInUid = null;
    _offerings = null;

    if (_sdkConfigured) {
      try {
        await Purchases.logOut();
      } catch (e, st) {
        debugPrint('SubscriptionService logOut failed: $e\n$st');
      }
    }

    _state = SubscriptionState.unavailable();
    notifyListeners();
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _applyCustomerInfo(info);
  }

  void _applyCustomerInfo(CustomerInfo info) {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    // Drop stale anonymous snapshots before Purchases.logIn(firebaseUid) completes.
    // After logIn, apply CustomerInfo even when originalAppUserId is still the
    // first-seen anonymous id (RevenueCat keeps that field on identified users).
    if (firebaseUid != null &&
        _loggedInUid != firebaseUid &&
        _isAnonymousRevenueCatUser(info.originalAppUserId)) {
      if (kDebugMode) {
        debugPrint(
          'SubscriptionService: ignoring anonymous CustomerInfo '
          '(rcOriginalAppUserId=${info.originalAppUserId}) while Firebase uid=$firebaseUid '
          'is not yet linked to RevenueCat',
        );
      }
      return;
    }

    final active = _extractActiveEntitlements(info);

    // Empty RC must not wipe a durable grant (promo / prior purchase cache).
    if (active.isEmpty) {
      if (firebaseUid != null) {
        unawaited(_handleEmptyRevenueCatEntitlements(firebaseUid));
        return;
      }
      _state = SubscriptionState(
        isLoading: false,
        isInitialized: true,
        managementUrl: info.managementURL,
      );
      notifyListeners();
      return;
    }

    final coachTier = _resolveCoachTier(active);
    final hasPlayer = active.contains(SubscriptionEntitlementIds.player);
    final primaryEntitlement = _primaryEntitlement(info, active);
    final productId = primaryEntitlement?.productIdentifier;
    final billingPeriod = _resolveBillingPeriod(productId);
    final expiresAt = _resolveRenewalDate(
      primaryEntitlement,
      info,
      billingPeriod,
    );

    _state = SubscriptionState(
      isLoading: false,
      isInitialized: true,
      activeEntitlements: active,
      coachTier: coachTier,
      hasPlayerSubscription: hasPlayer,
      activeProductId: productId,
      billingPeriod: billingPeriod,
      subscriptionExpiresAt: expiresAt,
      managementUrl: info.managementURL,
    );

    if (firebaseUid != null && active.isNotEmpty) {
      unawaited(
        SubscriptionEntitlementCache.saveForUid(
          uid: firebaseUid,
          entitlements: active,
          productId: productId,
          expiresAt: expiresAt,
        ),
      );
    }

    if (kDebugMode) {
      final rcActive = info.entitlements.active.keys.toList();
      debugPrint(
        'SubscriptionService: applied CustomerInfo '
        'rcOriginalAppUserId=${info.originalAppUserId} '
        'rcActiveKeys=${rcActive.isEmpty ? '(none)' : rcActive.join(', ')} '
        'recognized=${active.isEmpty ? '(none)' : active.join(', ')} '
        'hasActivePaidSubscription=${active.isNotEmpty}',
      );
    }

    notifyListeners();
  }

  /// Restores access from device cache then Firestore `subscriptionAccess`.
  Future<void> _hydrateFromDurableSources(String uid) async {
    if (_state.activeEntitlements.isNotEmpty) return;

    final cached = await SubscriptionEntitlementCache.loadForUid(uid);
    if (cached != null && !cached.isExpired) {
      _applyDurableEntitlements(cached, source: 'local-cache');
      return;
    }

    final fromFirestore = await _loadFirestoreSubscriptionAccess(uid);
    if (fromFirestore != null && !fromFirestore.isExpired) {
      _applyDurableEntitlements(fromFirestore, source: 'firestore');
      await SubscriptionEntitlementCache.saveForUid(
        uid: uid,
        entitlements: fromFirestore.entitlements,
        productId: fromFirestore.activeProductId,
        expiresAt: fromFirestore.expiresAt,
      );
    }
  }

  Future<void> _handleEmptyRevenueCatEntitlements(String uid) async {
    // A flaky empty RC response must never revoke a non-expired local grant.
    final cached = await SubscriptionEntitlementCache.loadForUid(uid);
    if (cached != null && !cached.isExpired) {
      _applyDurableEntitlements(cached, source: 'local-cache-on-empty-rc');
      return;
    }

    final expiresAt = _state.subscriptionExpiresAt;
    if (_state.activeEntitlements.isNotEmpty &&
        (expiresAt == null || expiresAt.isAfter(DateTime.now()))) {
      _state = _state.copyWith(isLoading: false, isInitialized: true);
      notifyListeners();
      return;
    }

    final fromFirestore = await _loadFirestoreSubscriptionAccess(uid);
    if (fromFirestore != null && !fromFirestore.isExpired) {
      _applyDurableEntitlements(fromFirestore, source: 'firestore-after-empty-rc');
      await SubscriptionEntitlementCache.saveForUid(
        uid: uid,
        entitlements: fromFirestore.entitlements,
        productId: fromFirestore.activeProductId,
        expiresAt: fromFirestore.expiresAt,
      );
      return;
    }

    await SubscriptionEntitlementCache.saveForUid(
      uid: uid,
      entitlements: const <String>{},
    );
    _state = const SubscriptionState(isLoading: false, isInitialized: true);
    notifyListeners();
  }

  void _applyDurableEntitlements(
    CachedSubscriptionEntitlements cached, {
    required String source,
  }) {
    _state = SubscriptionState(
      isLoading: false,
      isInitialized: true,
      activeEntitlements: cached.entitlements,
      coachTier: cached.coachTier,
      hasPlayerSubscription: cached.hasPlayerSubscription,
      activeProductId: cached.activeProductId,
      subscriptionExpiresAt: cached.expiresAt,
    );
    if (kDebugMode) {
      debugPrint(
        'SubscriptionService: hydrated entitlements from $source '
        'uid=${cached.uid} '
        'active=${cached.entitlements.join(', ')}',
      );
    }
    notifyListeners();
  }

  Future<CachedSubscriptionEntitlements?> _loadFirestoreSubscriptionAccess(
    String uid,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(UserService.collectionName)
          .doc(uid)
          .get();
      final raw = doc.data()?[UserDocumentFields.subscriptionAccess];
      if (raw is! Map) return null;

      final entitlements = <String>{};
      final list = raw['entitlements'];
      if (list is List) {
        for (final entry in list) {
          final id = entry?.toString().trim() ?? '';
          if (id.isNotEmpty) entitlements.add(id);
        }
      }
      if (entitlements.isEmpty) return null;

      DateTime? expiresAt;
      final expiresRaw = raw['expiresAt'];
      if (expiresRaw is Timestamp) {
        expiresAt = expiresRaw.toDate();
      } else if (expiresRaw is DateTime) {
        expiresAt = expiresRaw;
      } else if (expiresRaw is String) {
        expiresAt = DateTime.tryParse(expiresRaw);
      }
      if (expiresAt != null && !expiresAt.isAfter(DateTime.now())) {
        return null;
      }

      CoachTier? coachTier;
      for (final id in SubscriptionEntitlementIds.coachTiersOrdered) {
        if (entitlements.contains(id)) {
          coachTier = CoachTier.fromEntitlementId(id);
          break;
        }
      }

      return CachedSubscriptionEntitlements(
        uid: uid,
        entitlements: entitlements,
        coachTier: coachTier,
        hasPlayerSubscription:
            entitlements.contains(SubscriptionEntitlementIds.player),
        activeProductId: raw['productId']?.toString(),
        expiresAt: expiresAt,
      );
    } catch (e, st) {
      debugPrint(
        'SubscriptionService: Firestore subscriptionAccess read failed: $e\n$st',
      );
      return null;
    }
  }

  Set<String> _extractActiveEntitlements(CustomerInfo info) {
    final Set<String> active = <String>{};
    const knownIds = <String>[
      ...SubscriptionEntitlementIds.coachTiersOrdered,
      SubscriptionEntitlementIds.player,
    ];

    for (final id in knownIds) {
      if (_addEntitlementIfValid(active, id, info.entitlements.active[id])) {
        continue;
      }
      // Promotional grants can appear in `all` before `active` syncs locally.
      _addEntitlementIfValid(active, id, info.entitlements.all[id]);
    }
    return active;
  }

  bool _addEntitlementIfValid(
    Set<String> active,
    String id,
    EntitlementInfo? entitlement,
  ) {
    if (entitlement == null || !_isEntitlementCurrentlyValid(entitlement)) {
      return false;
    }
    active.add(id);
    return true;
  }

  /// RevenueCat normally omits expired entitlements from [active]; this guards
  /// stale sandbox payloads so expired subscribers can re-subscribe.
  bool _isEntitlementCurrentlyValid(EntitlementInfo entitlement) {
    if (!entitlement.isActive) return false;
    final expiration = _parseRevenueCatDate(entitlement.expirationDate);
    if (expiration == null) return true;
    return expiration.isAfter(DateTime.now());
  }

  CoachTier? _resolveCoachTier(Set<String> active) {
    for (final id in SubscriptionEntitlementIds.coachTiersOrdered) {
      if (active.contains(id)) {
        return CoachTier.fromEntitlementId(id);
      }
    }
    return null;
  }

  EntitlementInfo? _primaryEntitlement(
    CustomerInfo info,
    Set<String> active,
  ) {
    for (final id in SubscriptionEntitlementIds.coachTiersOrdered) {
      if (active.contains(id)) {
        return info.entitlements.active[id];
      }
    }
    if (active.contains(SubscriptionEntitlementIds.player)) {
      return info.entitlements.active[SubscriptionEntitlementIds.player];
    }
    return null;
  }

  /// Parses RevenueCat ISO-8601 date strings (`expirationDate`, purchase dates).
  DateTime? _parseRevenueCatDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool _isSameLocalDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  /// Next renewal / expiration for the active entitlement.
  ///
  /// Uses [EntitlementInfo.expirationDate] first, then
  /// [CustomerInfo.allExpirationDates] for the active product. Never uses
  /// [EntitlementInfo.latestPurchaseDate] (purchase date, not renewal).
  DateTime? _resolveRenewalDate(
    EntitlementInfo? entitlement,
    CustomerInfo info,
    SubscriptionBillingPeriod? billingPeriod,
  ) {
    if (entitlement == null) return null;

    final productId = entitlement.productIdentifier;
    final purchase = _parseRevenueCatDate(entitlement.latestPurchaseDate);
    final rawExpiration = entitlement.expirationDate;
    final rawFromMap = info.allExpirationDates[productId];

    DateTime? preferred;
    String? preferredSource;

    for (final entry in <String, String?>{
      'expirationDate': rawExpiration,
      'allExpirationDates': rawFromMap,
    }.entries) {
      final parsed = _parseRevenueCatDate(entry.value);
      if (parsed == null) continue;

      // Annual plans should renew ~1 year out; skip values that match the
      // purchase day (wrong field or stale RC payload).
      if (billingPeriod == SubscriptionBillingPeriod.yearly &&
          purchase != null &&
          _isSameLocalDay(parsed, purchase)) {
        continue;
      }

      if (preferred == null || parsed.isAfter(preferred)) {
        preferred = parsed;
        preferredSource = entry.key;
      }
    }

    if (preferred == null) {
      preferred = _parseRevenueCatDate(rawExpiration) ??
          _parseRevenueCatDate(rawFromMap);
      preferredSource = 'fallback';
    }

    if (kDebugMode) {
      debugPrint(
        'SubscriptionService: renewal date '
        'entitlement=${entitlement.identifier} '
        'productId=$productId '
        'periodType=${entitlement.periodType.name} '
        'willRenew=${entitlement.willRenew} '
        'billingPeriod=${billingPeriod?.name ?? 'unknown'} '
        'rawExpirationDate=$rawExpiration '
        'rawLatestPurchaseDate=${entitlement.latestPurchaseDate} '
        'rawAllExpirationDates=$rawFromMap '
        'resolved=${preferred?.toUtc().toIso8601String()} '
        'source=$preferredSource',
      );
    }

    return preferred;
  }

  SubscriptionBillingPeriod? _resolveBillingPeriod(String? productId) {
    if (productId == null || productId.isEmpty) return null;

    if (SubscriptionProductLookup.isYearlyProduct(productId)) {
      return SubscriptionBillingPeriod.yearly;
    }
    if (SubscriptionProductLookup.isMonthlyProduct(productId)) {
      return SubscriptionBillingPeriod.monthly;
    }

    final package = packageForProduct(productId);
    if (package != null) {
      switch (package.packageType) {
        case PackageType.annual:
          return SubscriptionBillingPeriod.yearly;
        case PackageType.monthly:
          return SubscriptionBillingPeriod.monthly;
        default:
          break;
      }
    }

    return null;
  }

  Future<void> refreshCustomerInfo() async {
    if (!_sdkConfigured) return;
    await _ensureRevenueCatUserLinked();
    await _fetchCustomerInfo();
  }

  Future<void> _fetchCustomerInfo() async {
    if (!_sdkConfigured) return;
    try {
      final info = await Purchases.getCustomerInfo();
      _applyCustomerInfo(info);
      if (kDebugMode) {
        debugPrint(
          'SubscriptionService: getCustomerInfo '
          'appUserId=${info.originalAppUserId} '
          'active=${info.entitlements.active.keys.join(', ')}',
        );
      }
    } catch (e, st) {
      debugPrint(
        'SubscriptionService: getCustomerInfo FAILED '
        '(${kIsWeb ? 'web' : defaultTargetPlatform.name}): $e\n$st',
      );
    }
  }

  /// Refreshes access after a promotional grant.
  ///
  /// Returns true when [expectedEntitlement] is active locally. Prefers
  /// RevenueCat when configured; on web/desktop without store keys, falls back
  /// to the Firestore `subscriptionAccess` mirror written by `redeemPromoCode`
  /// (demo-critical: IAP unavailable must not block a successful promo).
  Future<bool> refreshAfterPromoRedeem({
    required String expectedEntitlement,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    if (isPurchaseAvailable) {
      await ensureInitialized();
      if (_sdkConfigured) {
        // Promo grants target the Firebase UID; re-alias from any anonymous RC user.
        _loggedInUid = null;
        _lastOfferingsRefreshAt = null;

        const maxAttempts = 6;
        const retryDelay = Duration(milliseconds: 800);
        for (var attempt = 0; attempt < maxAttempts; attempt++) {
          if (attempt == 0) {
            try {
              await Purchases.invalidateCustomerInfoCache();
            } catch (e, st) {
              debugPrint(
                'SubscriptionService: invalidateCustomerInfoCache failed: $e\n$st',
              );
            }
          }

          await _logInRevenueCat(uid);
          await _fetchCustomerInfo();

          if (hasEntitlement(expectedEntitlement)) {
            if (kDebugMode) {
              debugPrint(
                'SubscriptionService: promo entitlement verified via RC '
                '($expectedEntitlement, attempt=${attempt + 1})',
              );
            }
            return true;
          }

          if (attempt < maxAttempts - 1) {
            await Future<void>.delayed(retryDelay);
          }
        }
      }
    } else if (kDebugMode) {
      debugPrint(
        'SubscriptionService: refreshAfterPromoRedeem — RevenueCat not '
        'configured; verifying via Firestore subscriptionAccess mirror.',
      );
    }

    final mirrored = await _verifyPromoViaDurableMirror(expectedEntitlement);
    if (!mirrored && kDebugMode) {
      debugPrint(
        'SubscriptionService: promo entitlement NOT visible after refresh '
        '(expected=$expectedEntitlement firebaseUid=$uid '
        'active=${_state.activeEntitlements.join(', ')} '
        'purchaseAvailable=$isPurchaseAvailable)',
      );
    }
    return mirrored;
  }

  /// Polls Firestore `users/{uid}.subscriptionAccess` written by redeemPromoCode.
  Future<bool> _verifyPromoViaDurableMirror(String expectedEntitlement) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    const maxAttempts = 6;
    const retryDelay = Duration(milliseconds: 500);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(retryDelay);
      }

      final fromFirestore = await _loadFirestoreSubscriptionAccess(uid);
      if (fromFirestore == null || fromFirestore.isExpired) continue;

      _applyDurableEntitlements(
        fromFirestore,
        source: 'firestore-after-promo',
      );
      await SubscriptionEntitlementCache.saveForUid(
        uid: uid,
        entitlements: fromFirestore.entitlements,
        productId: fromFirestore.activeProductId,
        expiresAt: fromFirestore.expiresAt,
      );

      if (hasEntitlement(expectedEntitlement)) {
        if (kDebugMode) {
          debugPrint(
            'SubscriptionService: promo entitlement verified via mirror '
            '($expectedEntitlement, attempt=${attempt + 1})',
          );
        }
        return true;
      }
    }
    return false;
  }

  Future<void> refreshForActiveSession() async {
    if (_refreshForActiveSessionFuture != null) {
      await _refreshForActiveSessionFuture;
      return;
    }

    final future = _refreshForActiveSessionImpl();
    _refreshForActiveSessionFuture = future;
    try {
      await future;
    } finally {
      if (identical(_refreshForActiveSessionFuture, future)) {
        _refreshForActiveSessionFuture = null;
      }
    }
  }

  Future<void> _refreshForActiveSessionImpl() async {
    if (!_sdkConfigured) {
      await ensureInitialized();
    }
    if (!_sdkConfigured) return;
    await _ensureRevenueCatUserLinked();

    final now = DateTime.now();
    final offeringsFresh = _lastOfferingsRefreshAt != null &&
        now.difference(_lastOfferingsRefreshAt!) < _offeringsRefreshMinInterval;

    if (offeringsFresh) {
      await _fetchCustomerInfo();
      return;
    }

    await Future.wait([
      _fetchCustomerInfo(),
      refreshOfferings(),
    ]);
    _lastOfferingsRefreshAt = DateTime.now();
  }

  /// Reloads RevenueCat offerings (e.g. when opening the paywall).
  Future<void> refreshOfferings() async {
    if (!_sdkConfigured) return;
    try {
      _offerings = await Purchases.getOfferings();
      _lastOfferingsRefreshAt = DateTime.now();
      _logOfferingsSnapshot();
      notifyListeners();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.configurationError) {
        if (kDebugMode) {
          debugPrint(
            'SubscriptionService: getOfferings skipped (CONFIGURATION_ERROR): '
            'native offering may only contain Stripe/web products — '
            'entitlement reads are unaffected.',
          );
        }
        return;
      }
      if (code == PurchasesErrorCode.invalidCredentialsError) {
        if (kDebugMode) {
          debugPrint(
            'SubscriptionService: getOfferings skipped (invalid RevenueCat API key). '
            'Check REVENUECAT_* dart_defines for this build.',
          );
        }
        return;
      }
      debugPrint(
        'SubscriptionService: getOfferings failed '
        '(${kIsWeb ? 'web' : defaultTargetPlatform.name}): $e',
      );
    } catch (e, st) {
      if (_isInvalidCredentialsError(e)) {
        if (kDebugMode) {
          debugPrint(
            'SubscriptionService: getOfferings skipped (invalid RevenueCat API key). '
            'Check REVENUECAT_* dart_defines for this build.',
          );
        }
        return;
      }
      debugPrint(
        'SubscriptionService: getOfferings failed '
        '(${kIsWeb ? 'web' : defaultTargetPlatform.name}): $e\n$st',
      );
    }
  }

  void _logOfferingsSnapshot() {
    if (!kDebugMode) return;

    final offerings = _offerings;
    if (offerings == null) {
      debugPrint('SubscriptionService: offerings=null after getOfferings');
      return;
    }

    final current = offerings.current;
    if (current == null) {
      debugPrint(
        'SubscriptionService: no current offering. '
        'Configured offerings: ${offerings.all.keys.join(', ')}. '
        'In RevenueCat dashboard, set offering "default" as current and add '
        'web (Stripe) packages.',
      );
      return;
    }

    final packageIds = current.availablePackages
        .map((p) => '${p.identifier}→${p.storeProduct.identifier}')
        .join(', ');
    debugPrint(
      'SubscriptionService: offering "${current.identifier}" '
      '(${current.availablePackages.length} packages): $packageIds',
    );

    if (current.availablePackages.isEmpty) {
      debugPrint(
        'SubscriptionService: current offering has no packages. '
        'Add web Stripe products to offering "${current.identifier}" in RC.',
      );
    }
  }

  void _attachLifecycleHandler() {
    if (_lifecycleObserver != null) return;
    _lifecycleObserver = _SubscriptionLifecycleObserver(this);
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);
  }

  /// Whether any packages were returned from RevenueCat offerings.
  bool get hasAnyPackages {
    final offerings = _offerings;
    if (offerings == null) return false;
    return _allAvailablePackages(offerings).isNotEmpty;
  }

  /// Whether offerings have been fetched at least once.
  bool get hasLoadedOfferings => _offerings != null;

  List<Package> _allAvailablePackages(Offerings offerings) {
    final packages = <Package>[];
    for (final offering in offerings.all.values) {
      packages.addAll(offering.availablePackages);
    }
    return packages;
  }

  /// Finds a RevenueCat package by store product identifier across all offerings.
  ///
  /// Tries exact ID match first, then normalized / semantic matching for web
  /// Stripe products whose identifiers differ from App Store / Play IDs.
  Package? packageForProduct(String productId) {
    final offerings = _offerings;
    if (offerings == null) return null;

    final packages = _allAvailablePackages(offerings);
    if (packages.isEmpty) return null;

    Package? match(Package package) {
      final storeId = package.storeProduct.identifier;
      if (storeId == productId) return package;
      if (SubscriptionProductLookup.identifiersMatch(productId, storeId)) {
        return package;
      }
      if (SubscriptionProductLookup.identifiersMatch(
        productId,
        package.identifier,
      )) {
        return package;
      }
      return null;
    }

    for (final package in packages) {
      final found = match(package);
      if (found != null) return found;
    }

    final entitlement = SubscriptionProductLookup.entitlementIdForProduct(
      productId,
    );
    final wantsYearly = SubscriptionProductLookup.isYearlyProduct(productId);
    final wantsMonthly = SubscriptionProductLookup.isMonthlyProduct(productId);
    if (entitlement != null && (wantsYearly || wantsMonthly)) {
      for (final package in packages) {
        final pkgEntitlement = SubscriptionProductLookup.entitlementIdForProduct(
              package.storeProduct.identifier,
            ) ??
            SubscriptionProductLookup.entitlementIdForProduct(package.identifier);
        if (pkgEntitlement != entitlement) continue;

        final pkgYearly = package.packageType == PackageType.annual ||
            SubscriptionProductLookup.isYearlyProduct(
              package.storeProduct.identifier,
            );
        final pkgMonthly = package.packageType == PackageType.monthly ||
            SubscriptionProductLookup.isMonthlyProduct(
              package.storeProduct.identifier,
            );

        if (wantsYearly && pkgYearly) return package;
        if (wantsMonthly && pkgMonthly) return package;
      }
    }

    return null;
  }

  /// Logs all package identifiers when lookup fails (debug builds only).
  void logPackageLookupFailure(String productId) {
    final offerings = _offerings;
    debugPrint(
      'SubscriptionService: no package for productId=$productId '
      '(${kIsWeb ? 'web' : defaultTargetPlatform.name})',
    );

    if (offerings == null) {
      debugPrint('SubscriptionService: offerings=null');
      return;
    }

    if (offerings.all.isEmpty) {
      debugPrint('SubscriptionService: offerings.all is empty');
      return;
    }

    for (final entry in offerings.all.entries) {
      final offering = entry.value;
      if (offering.availablePackages.isEmpty) {
        debugPrint(
          'SubscriptionService: offering "${entry.key}" has no packages',
        );
        continue;
      }
      for (final package in offering.availablePackages) {
        debugPrint(
          'SubscriptionService: offering="${entry.key}" '
          'package="${package.identifier}" '
          'type=${package.packageType.name} '
          'storeProduct="${package.storeProduct.identifier}"',
        );
      }
    }
  }

  /// Localized price string from offerings, or null if unavailable.
  String? priceStringForProduct(String productId) =>
      packageForProduct(productId)?.storeProduct.priceString;

  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!_sdkConfigured) return null;
    try {
      _setLoading(true);
      // Purchases must land on the Firebase UID so other devices see them.
      await _ensureRevenueCatUserLinked();
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      _applyCustomerInfo(result.customerInfo);
      return result.customerInfo;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        _setLoading(false);
        return null;
      }
      rethrow;
    } finally {
      if (_state.isLoading) {
        _setLoading(false);
      }
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_sdkConfigured || kIsWeb) return null;
    try {
      _setLoading(true);
      await _ensureRevenueCatUserLinked();
      final info = await Purchases.restorePurchases();
      _applyCustomerInfo(info);
      return info;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _state = _state.copyWith(isLoading: loading);
    notifyListeners();
  }
}

/// Refreshes subscription state when the app resumes (e.g. after expiry in background
/// or returning from Stripe checkout on web).
class _SubscriptionLifecycleObserver with WidgetsBindingObserver {
  _SubscriptionLifecycleObserver(this._service);

  final SubscriptionService _service;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_service.refreshForActiveSession());
  }
}
