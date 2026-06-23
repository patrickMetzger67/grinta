import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat-backed subscription state, exposed app-wide via [ChangeNotifier].
///
/// Call [ensureInitialized] once at startup; listens to Firebase Auth and
/// syncs CustomerInfo on login/logout. Mobile uses App Store / Play Billing;
/// web uses RevenueCat Web Billing (Stripe checkout hosted by RevenueCat).
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
  _SubscriptionLifecycleObserver? _lifecycleObserver;

  SubscriptionState get state => _state;
  Offerings? get offerings => _offerings;

  /// True when RevenueCat reports at least one non-expired paid entitlement.
  bool get isSubscribed => _state.isSubscribed;

  /// Active RevenueCat entitlement (paid store subscription), not trial-only.
  bool get hasActivePaidSubscription => _state.activeEntitlements.isNotEmpty;

  CoachTier? get coachTier => _state.coachTier;
  bool get hasPlayerSubscription => _state.hasPlayerSubscription;
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

  Future<void> _initialize() async {
    if (!isPurchaseAvailable) {
      _state = SubscriptionState.unavailable(error: _unavailableReason());
      notifyListeners();
      return;
    }

    final apiKey = _apiKeyForPlatform;

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

      if (kDebugMode) {
        final prefix = apiKey.length >= 7 ? apiKey.substring(0, 7) : apiKey;
        debugPrint(
          'SubscriptionService: configuring RevenueCat '
          '(${kIsWeb ? 'web' : defaultTargetPlatform.name}, key=$prefix…)',
        );
      }

      final config = PurchasesConfiguration(apiKey);
      await Purchases.configure(config);
      _sdkConfigured = true;

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      await refreshOfferings();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
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
      _state = SubscriptionState.unavailable(
        error: 'RevenueCat configure failed ($platform): $e. '
            'Verify ${_apiKeyEnvHint()} in dart_defines.json and run with '
            '--dart-define-from-file=dart_defines.json.',
      );
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

    if (_sdkConfigured) {
      await _logInRevenueCat(uid);
    }
  }

  /// Links RevenueCat to the signed-in Firebase user before entitlement reads.
  Future<void> _ensureRevenueCatUserLinked() async {
    if (!_sdkConfigured) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == _loggedInUid) return;

    await _logInRevenueCat(uid);
  }

  static bool _isAnonymousRevenueCatUser(String appUserId) =>
      appUserId.startsWith(r'$RCAnonymousID');

  Future<void> _logInRevenueCat(String uid) async {
    if (!_sdkConfigured) return;

    try {
      _setLoading(true);
      final result = await Purchases.logIn(uid);
      _loggedInUid = uid;
      _applyCustomerInfo(result.customerInfo);
      await refreshCustomerInfo();
      await refreshOfferings();

      if (kDebugMode) {
        final info = result.customerInfo;
        final activeKeys = info.entitlements.active.keys.toList();
        debugPrint(
          'SubscriptionService: logIn firebaseUid=$uid '
          'rcAppUserId=${info.originalAppUserId} '
          'activeEntitlements=${activeKeys.join(', ')}',
        );
        if (!kIsWeb && activeKeys.isNotEmpty) {
          debugPrint(
            'SubscriptionService: cross-platform entitlements synced after logIn '
            '(e.g. web Stripe purchase): ${activeKeys.join(', ')}',
          );
        }
      }
    } catch (e, st) {
      debugPrint(
        'SubscriptionService: Purchases.logIn FAILED (firebaseUid=$uid): $e\n$st',
      );
      _state = _state.copyWith(
        isLoading: false,
        isInitialized: true,
        lastError: e.toString(),
      );
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
    if (firebaseUid != null &&
        _loggedInUid != firebaseUid &&
        _isAnonymousRevenueCatUser(info.originalAppUserId)) {
      if (kDebugMode) {
        debugPrint(
          'SubscriptionService: ignoring anonymous CustomerInfo '
          '(rcAppUserId=${info.originalAppUserId}) while Firebase uid=$firebaseUid '
          'is not yet linked to RevenueCat',
        );
      }
      return;
    }

    final active = _extractActiveEntitlements(info);
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
    notifyListeners();
  }

  Set<String> _extractActiveEntitlements(CustomerInfo info) {
    final Set<String> active = <String>{};
    for (final id in SubscriptionEntitlementIds.coachTiersOrdered) {
      final entitlement = info.entitlements.active[id];
      if (entitlement != null && _isEntitlementCurrentlyValid(entitlement)) {
        active.add(id);
      }
    }
    final playerEntitlement =
        info.entitlements.active[SubscriptionEntitlementIds.player];
    if (playerEntitlement != null &&
        _isEntitlementCurrentlyValid(playerEntitlement)) {
      active.add(SubscriptionEntitlementIds.player);
    }
    return active;
  }

  /// RevenueCat normally omits expired entitlements from [active]; this guards
  /// stale sandbox payloads so expired subscribers can re-subscribe.
  bool _isEntitlementCurrentlyValid(EntitlementInfo entitlement) {
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

  /// Refreshes RevenueCat state when the user opens profile / navigation.
  Future<void> refreshForActiveSession() async {
    if (!_sdkConfigured) {
      await ensureInitialized();
    }
    if (!_sdkConfigured) return;
    await _ensureRevenueCatUserLinked();
    await Future.wait([
      refreshCustomerInfo(),
      refreshOfferings(),
    ]);
  }

  /// Reloads RevenueCat offerings (e.g. when opening the paywall).
  Future<void> refreshOfferings() async {
    if (!_sdkConfigured) return;
    try {
      _offerings = await Purchases.getOfferings();
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
      debugPrint(
        'SubscriptionService: getOfferings failed '
        '(${kIsWeb ? 'web' : defaultTargetPlatform.name}): $e',
      );
    } catch (e, st) {
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
