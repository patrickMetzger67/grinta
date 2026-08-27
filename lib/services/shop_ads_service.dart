import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/shop_ad.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/eshop_config_service.dart';
import 'package:grinta/services/shop_ad_audience_resolver.dart';
import 'package:grinta/services/shop_ads_preferences_service.dart';
import 'package:grinta/services/user_root_service.dart';
import 'package:grinta/util/shop_ad_logic.dart';

/// Loads shop ads, applies targeting / once-per-day rules, and writes counters.
class ShopAdsService {
  ShopAdsService._();

  static final ShopAdsService instance = ShopAdsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ShopAdAudienceResolver _audienceResolver = ShopAdAudienceResolver();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(kShopAdsCollection);

  Stream<List<ShopAd>> watchAll() {
    return _col.snapshots().map((snapshot) {
      final ads = snapshot.docs
          .map((doc) => ShopAd.fromDoc(doc.id, doc.data()))
          .toList();
      ads.sort((a, b) => b.startDate?.compareTo(a.startDate ?? DateTime(0)) ??
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return ads;
    });
  }

  Future<List<ShopAd>> fetchAll() async {
    final snapshot = await _col.get();
    return snapshot.docs
        .map((doc) => ShopAd.fromDoc(doc.id, doc.data()))
        .toList(growable: false);
  }

  Future<ShopAd?> fetchById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    final doc = await _col.doc(trimmed).get();
    if (!doc.exists) return null;
    return ShopAd.fromDoc(doc.id, doc.data());
  }

  String newAdId() => _col.doc().id;

  /// Root-only create/update of the ad document (`id` == docId).
  Future<void> save(ShopAd ad) async {
    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }
    final id = ad.id.trim();
    if (id.isEmpty) {
      throw ArgumentError('ad.id is required');
    }
    final existing = await _col.doc(id).get();
    final previous = existing.data();
    final payload = ad.copyWith(id: id).toMap();
    if (existing.exists && previous != null) {
      payload['nbDisplay'] = previous['nbDisplay'] ?? ad.nbDisplay;
      payload['nbClicks'] = previous['nbClicks'] ?? ad.nbClicks;
    } else {
      payload['nbDisplay'] = 0;
      payload['nbClicks'] = 0;
    }
    await _col.doc(id).set(payload, SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    final existing = await fetchById(trimmed);
    await _col.doc(trimmed).delete();
    final path = existing?.storagePath?.trim() ?? '';
    if (path.isNotEmpty) {
      try {
        await _storage.ref().child(path).delete();
      } catch (_) {}
    }
  }

  /// Uploads a visual under `ads/{adId}/…` and returns path + download URL.
  Future<({String storagePath, String imageUrl})> uploadVisual({
    required String adId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String fileExtension = 'jpg',
  }) async {
    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }
    final id = adId.trim();
    if (id.isEmpty || bytes.isEmpty) {
      throw ArgumentError('adId and image bytes are required');
    }
    final ext = fileExtension.replaceAll('.', '').toLowerCase();
    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final path =
        '$kShopAdsStoragePrefix/$id/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final ref = _storage.ref().child(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();
    return (storagePath: path, imageUrl: url);
  }

  Future<void> incrementDisplay(String adId) async {
    await _increment(adId, 'nbDisplay');
  }

  Future<void> incrementClicks(String adId) async {
    await _increment(adId, 'nbClicks');
  }

  Future<void> _increment(String adId, String field) async {
    final id = adId.trim();
    if (id.isEmpty) return;
    try {
      await _col.doc(id).update(<String, dynamic>{
        field: FieldValue.increment(1),
      });
    } catch (e, st) {
      debugPrint('ShopAdsService $field increment failed: $e\n$st');
    }
  }

  /// Picks a random current ad for [session], or null when none should show.
  Future<ShopAd?> pickAdToShow(
    AppSession session, {
    DateTime? now,
    Random? random,
  }) async {
    await EshopConfigService.instance.ensureInitialized();
    if (!EshopConfigService.instance.shopAdsEnabled) return null;

    final prefs = ShopAdsPreferencesService.instance;
    await prefs.ensureInitialized();
    if (!prefs.eshopAds) return null;
    if (prefs.alreadyShownToday(now: now)) return null;

    final ads = await fetchAll();
    if (ads.isEmpty) return null;

    final audience = await _audienceResolver.resolve(session);
    final eligible = selectEligibleShopAds(
      ads: ads,
      audience: audience,
      now: now ?? DateTime.now(),
    );
    return pickRandomItem(eligible, random: random);
  }
}
