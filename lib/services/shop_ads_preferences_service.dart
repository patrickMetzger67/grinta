import 'dart:async' show Future, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/shop_ad.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/shop_ad_logic.dart';

/// User-level shop-ad opt-out and once-per-day impression stamp.
///
/// Fields on `users/{uid}`:
/// - [UserDocumentFields.eshopAds] (`bool`, missing ⇒ `true`)
/// - [UserDocumentFields.eshopAdsLastShownAt] (Timestamp)
/// - [UserDocumentFields.eshopAdsLastShownDate] (`YYYY-MM-DD` local)
class ShopAdsPreferencesService extends ChangeNotifier {
  ShopAdsPreferencesService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  static final ShopAdsPreferencesService instance =
      ShopAdsPreferencesService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _eshopAds = true;
  String? _lastShownDate;
  DateTime? _lastShownAt;
  bool _initialized = false;
  Future<void>? _initFuture;
  String? _loadedUid;

  /// Overrideable clock for tests (local calendar day).
  @visibleForTesting
  DateTime Function() nowLocal = DateTime.now;

  /// Whether the user wants shop ads. Missing / unloaded ⇒ `true`.
  bool get eshopAds => _eshopAds;

  String? get lastShownDate => _lastShownDate;

  DateTime? get lastShownAt => _lastShownAt;

  bool get isInitialized => _initialized;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection(UserService.collectionName).doc(uid);

  void _onAuthChanged(User? user) {
    final uid = user?.uid;
    if (uid == _loadedUid) return;
    _eshopAds = true;
    _lastShownDate = null;
    _lastShownAt = null;
    _initialized = false;
    _initFuture = null;
    _loadedUid = null;
    notifyListeners();
    if (uid != null) {
      unawaited(ensureInitialized());
    }
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _load();
    await _initFuture;
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
      return;
    }

    try {
      final snap = await _userRef(uid).get();
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;
      _applyMap(snap.data());
      _loadedUid = uid;
      _initialized = true;
      notifyListeners();
    } catch (e, st) {
      debugPrint('ShopAdsPreferencesService load failed: $e\n$st');
      _initialized = true;
    }
  }

  void _applyMap(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    _eshopAds = map[UserDocumentFields.eshopAds] != false;
    final rawDate = map[UserDocumentFields.eshopAdsLastShownDate];
    final parsedDate = rawDate?.toString().trim() ?? '';
    _lastShownDate = parsedDate.isEmpty ? null : parsedDate;
    _lastShownAt = parseShopAdDate(map[UserDocumentFields.eshopAdsLastShownAt]);
  }

  /// Persist the settings toggle. Default / missing remains `true`.
  Future<void> setEshopAds(bool enabled) async {
    await ensureInitialized();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final previous = _eshopAds;
    _eshopAds = enabled;
    notifyListeners();

    try {
      await _userRef(uid).set(
        <String, dynamic>{
          UserDocumentFields.eshopAds: enabled,
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      _eshopAds = previous;
      notifyListeners();
      debugPrint('ShopAdsPreferencesService setEshopAds failed: $e\n$st');
      rethrow;
    }
  }

  bool alreadyShownToday({DateTime? now}) {
    return shopAdAlreadyShownOnLocalDay(
      lastShownDate: _lastShownDate,
      lastShownAt: _lastShownAt,
      nowLocal: now ?? nowLocal(),
    );
  }

  /// Stamp today's local date so no further ad is shown until tomorrow.
  Future<void> markShownToday({DateTime? now}) async {
    await ensureInitialized();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final when = now ?? nowLocal();
    final date = formatShopAdLocalDate(when);
    final previousDate = _lastShownDate;
    final previousAt = _lastShownAt;
    _lastShownDate = date;
    _lastShownAt = when;

    try {
      await _userRef(uid).set(
        <String, dynamic>{
          UserDocumentFields.eshopAdsLastShownDate: date,
          UserDocumentFields.eshopAdsLastShownAt: FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      _lastShownDate = previousDate;
      _lastShownAt = previousAt;
      debugPrint('ShopAdsPreferencesService markShownToday failed: $e\n$st');
    }
  }

  /// Test helper to seed in-memory prefs without Firestore.
  @visibleForTesting
  void debugSetState({
    bool eshopAds = true,
    String? lastShownDate,
    DateTime? lastShownAt,
  }) {
    _eshopAds = eshopAds;
    _lastShownDate = lastShownDate;
    _lastShownAt = lastShownAt;
    _initialized = true;
  }
}
