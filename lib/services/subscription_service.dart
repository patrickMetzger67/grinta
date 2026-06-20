import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat-backed subscription state, exposed app-wide via [ChangeNotifier].
///
/// Call [ensureInitialized] once at startup; listens to Firebase Auth and
/// syncs CustomerInfo on login/logout. RevenueCat is the source of truth on
/// mobile; web returns [SubscriptionState.unavailable] until Stripe is wired.
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  static final SubscriptionService instance = SubscriptionService._();

  SubscriptionState _state = SubscriptionState.initial();
  Offerings? _offerings;
  bool _sdkConfigured = false;
  String? _loggedInUid;
  Future<void>? _initFuture;

  SubscriptionState get state => _state;
  Offerings? get offerings => _offerings;

  bool get isSubscribed => _state.isSubscribed;
  CoachTier? get coachTier => _state.coachTier;
  bool get hasPlayerSubscription => _state.hasPlayerSubscription;
  DateTime? get subscriptionExpiresAt => _state.subscriptionExpiresAt;
  Set<String> get activeEntitlements => _state.activeEntitlements;

  bool hasEntitlement(String entitlementId) =>
      _state.hasEntitlement(entitlementId);

  /// Whether native IAP is available on this platform (iOS/Android with API key).
  bool get isNativeStoreAvailable {
    if (kIsWeb) return false;
    return _apiKeyForPlatform.isNotEmpty;
  }

  String get _apiKeyForPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return kRevenueCatIosApiKey;
      case TargetPlatform.android:
        return kRevenueCatAndroidApiKey;
      default:
        return '';
    }
  }

  Future<void> ensureInitialized() async {
    _initFuture ??= _initialize();
    await _initFuture;
  }

  Future<void> _initialize() async {
    if (!isNativeStoreAvailable) {
      _state = SubscriptionState.unavailable(
        error: kIsWeb
            ? 'Web subscriptions not configured (Stripe placeholder).'
            : 'RevenueCat API key missing. Pass REVENUECAT_*_API_KEY via --dart-define.',
      );
      notifyListeners();
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

      final config = PurchasesConfiguration(_apiKeyForPlatform);
      await Purchases.configure(config);
      _sdkConfigured = true;

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _logInRevenueCat(uid);
      } else {
        _state = _state.copyWith(isLoading: false, isInitialized: true);
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('SubscriptionService init failed: $e\n$st');
      _state = SubscriptionState.unavailable(error: e.toString());
      notifyListeners();
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (!_sdkConfigured && isNativeStoreAvailable) {
      await ensureInitialized();
    }

    final String? uid = user?.uid;
    if (uid == _loggedInUid) return;

    if (uid == null) {
      await _logOutRevenueCat();
      return;
    }

    if (_sdkConfigured) {
      await _logInRevenueCat(uid);
    }
  }

  Future<void> _logInRevenueCat(String uid) async {
    if (!_sdkConfigured) return;

    try {
      _setLoading(true);
      final result = await Purchases.logIn(uid);
      _loggedInUid = uid;
      _applyCustomerInfo(result.customerInfo);
      await _refreshOfferings();
    } catch (e, st) {
      debugPrint('SubscriptionService logIn failed: $e\n$st');
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
    final active = _extractActiveEntitlements(info);
    final coachTier = _resolveCoachTier(active);
    final hasPlayer = active.contains(SubscriptionEntitlementIds.player);
    final expiresAt = _latestExpiration(info, active);

    _state = SubscriptionState(
      isLoading: false,
      isInitialized: true,
      activeEntitlements: active,
      coachTier: coachTier,
      hasPlayerSubscription: hasPlayer,
      subscriptionExpiresAt: expiresAt,
      managementUrl: info.managementURL,
    );
    notifyListeners();
  }

  Set<String> _extractActiveEntitlements(CustomerInfo info) {
    final Set<String> active = <String>{};
    for (final id in SubscriptionEntitlementIds.coachTiersOrdered) {
      if (info.entitlements.active.containsKey(id)) {
        active.add(id);
      }
    }
    if (info.entitlements.active.containsKey(SubscriptionEntitlementIds.player)) {
      active.add(SubscriptionEntitlementIds.player);
    }
    return active;
  }

  CoachTier? _resolveCoachTier(Set<String> active) {
    for (final id in SubscriptionEntitlementIds.coachTiersOrdered) {
      if (active.contains(id)) {
        return CoachTier.fromEntitlementId(id);
      }
    }
    return null;
  }

  DateTime? _latestExpiration(CustomerInfo info, Set<String> active) {
    DateTime? latest;
    for (final id in active) {
      final entitlement = info.entitlements.active[id];
      final exp = entitlement?.expirationDate;
      if (exp == null) continue;
      final parsed = DateTime.tryParse(exp);
      if (parsed == null) continue;
      if (latest == null || parsed.isAfter(latest)) {
        latest = parsed;
      }
    }
    return latest;
  }

  Future<void> refreshCustomerInfo() async {
    if (!_sdkConfigured) return;
    try {
      final info = await Purchases.getCustomerInfo();
      _applyCustomerInfo(info);
    } catch (e, st) {
      debugPrint('SubscriptionService refresh failed: $e\n$st');
    }
  }

  Future<void> _refreshOfferings() async {
    if (!_sdkConfigured) return;
    try {
      _offerings = await Purchases.getOfferings();
      notifyListeners();
    } catch (e, st) {
      debugPrint('SubscriptionService offerings failed: $e\n$st');
    }
  }

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
    if (!_sdkConfigured) return null;
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
