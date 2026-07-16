import 'dart:async' show Future, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/userService.dart' show UserService, kUserTrialDuration;
import 'package:grinta/services/user_root_service.dart';

/// Loads trial window from `users/{uid}` and exposes premium access helpers.
///
/// Premium access is always resolved for the **Firebase Auth user** (not device
/// or selected player/profile): paid RevenueCat entitlements for that UID,
/// an active Firestore trial on `users/{uid}`, or platform super admin (`isRoot`).
///
/// Document fields (see [UserService.createAccountIfNeeded]):
/// ```json
/// { "createdAt": Timestamp, "trialEndsAt": Timestamp, ... }
/// ```
class UserTrialService extends ChangeNotifier {
  UserTrialService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    SubscriptionService.instance.addListener(notifyListeners);
    UserRootService.instance.addListener(notifyListeners);
  }

  static final UserTrialService instance = UserTrialService._();

  static const Duration trialDuration = kUserTrialDuration;

  DateTime? _trialEndsAt;
  bool _initialized = false;
  Future<void>? _initFuture;
  String? _loadedUid;

  DateTime? get trialEndsAt => _trialEndsAt;

  bool get isOnTrial {
    final endsAt = _trialEndsAt;
    if (endsAt == null) return false;
    return DateTime.now().isBefore(endsAt);
  }

  /// Firestore trial window, suppressed once RevenueCat reports a paid entitlement.
  bool get shouldShowTrial =>
      isOnTrial && !SubscriptionService.instance.hasActivePaidSubscription;

  int get remainingTrialDays {
    final endsAt = _trialEndsAt;
    if (endsAt == null) return 0;
    final remaining = endsAt.difference(DateTime.now());
    if (remaining.isNegative) return 0;
    return remaining.inDays + (remaining.inHours.remainder(24) > 0 ? 1 : 0);
  }

  /// Paid subscription and trial are per Firebase user; super admins (`isRoot`)
  /// always bypass paywalls / premium feature gates.
  bool get hasPremiumAccess =>
      UserRootService.instance.isRoot ||
      SubscriptionService.instance.hasActivePaidSubscription ||
      shouldShowTrial;

  /// Réglages → Abonnement: always show so users can subscribe or manage a plan.
  bool get shouldShowSubscriptionMenu => true;

  void _onAuthChanged(User? user) {
    final uid = user?.uid;
    if (uid == _loadedUid) return;
    _trialEndsAt = null;
    _initialized = false;
    _initFuture = null;
    _loadedUid = null;
    if (uid != null) {
      unawaited(ensureInitialized());
    } else {
      notifyListeners();
    }
  }

  /// Loads Firestore trial fields and waits for RevenueCat to identify the
  /// current Firebase UID so [hasPremiumAccess] is accurate across devices.
  Future<void> ensureInitialized() async {
    if (!_initialized) {
      _initFuture ??= _load();
      await _initFuture;
    }
    await UserRootService.instance.ensureInitialized();
    await SubscriptionService.instance.ensureUserLinked();
  }

  Future<void> reload() async {
    _initialized = false;
    _initFuture = null;
    await ensureInitialized();
    notifyListeners();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _initialized = true;
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection(UserService.collectionName)
          .doc(uid)
          .get();
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;

      var trialEndsAt = _readTimestamp(doc.data()?['trialEndsAt']);
      if (trialEndsAt == null && doc.exists) {
        trialEndsAt = await UserService().backfillTrialFieldsIfMissing(uid);
      }
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;

      _trialEndsAt = trialEndsAt;
      _loadedUid = uid;
      _initialized = true;
      notifyListeners();
    } catch (e, st) {
      debugPrint('UserTrialService load failed: $e\n$st');
      _initialized = true;
      notifyListeners();
    }
  }

  DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
