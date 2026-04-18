import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/season.dart';

class SeasonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'season';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// CREATE
  Future<String> createSeason(Season season) async {
    try {
      final docRef = (season.name != null && season.name!.isNotEmpty)
          ? _collection.doc(season.name)
          : _collection.doc();

      await docRef.set(_seasonToMap(season));
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// SET / UPSERT
  Future<void> setSeason(Season season) async {
    try {
      final docRef = (season.name != null && season.name!.isNotEmpty)
          ? _collection.doc(season.name)
          : _collection.doc();

      await docRef.set(_seasonToMap(season), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// READ ONE
  Future<Season?> getSeasonById(String seasonId) async {
    try {
      final doc = await _collection.doc(seasonId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return Season.fromDocumentSnapshot(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ONE
  Stream<Season?> streamSeasonById(String seasonId) {
    return _collection.doc(seasonId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Season.fromDocumentSnapshot(doc);
    });
  }

  /// READ ALL
  Future<List<Season>> getAllSeasons() async {
    try {
      final query = await _collection.get();
      return query.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => Season.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ALL
  Stream<List<Season>> streamAllSeasons() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => Season.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// WATCH ALL
  Stream<List<Season>> watchAllSeasons() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => Season.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// UPDATE
  Future<void> updateSeason({
    required String seasonId,
    required Season season,
  }) async {
    try {
      await _collection.doc(seasonId).update(_seasonToMap(season));
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE
  Future<void> deleteSeason(String seasonId) async {
    try {
      await _collection.doc(seasonId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// GET CURRENT SEASONS
  Future<Season?> getCurrentSeason() async {
    try {
      final query = await _collection
          .where(keySeasonCurrent, isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return Season.fromDocumentSnapshot(query.docs.first);
    } catch (e) {
      rethrow;
    }
  }

  Stream<Season?> streamCurrentSeason() {
    return _collection
        .where(keySeasonCurrent, isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Season.fromDocumentSnapshot(snapshot.docs.first);
    });
  }

  /// GET BY CLUB NAME
  Future<List<Season>> getSeasonsByClubName(String clubName) async {
    try {
      final query = await _collection
          .where(keySeasonClubName, isEqualTo: clubName)
          .get();

      return query.docs.map((doc) => Season.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Season>> streamSeasonsByClubName(String clubName) {
    return _collection
        .where(keySeasonClubName, isEqualTo: clubName)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Season.fromDocumentSnapshot(doc)).toList());
  }

  /// GET BY AFFILIATE NUMBER
  Future<List<Season>> getSeasonsByAffiliateNumber(
      String affiliateNumber,
      ) async {
    try {
      final query = await _collection
          .where(keySeasonAffiliateNumber, isEqualTo: affiliateNumber)
          .get();

      return query.docs.map((doc) => Season.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Season>> streamSeasonsByAffiliateNumber(
      String affiliateNumber,
      ) {
    return _collection
        .where(keySeasonAffiliateNumber, isEqualTo: affiliateNumber)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Season.fromDocumentSnapshot(doc)).toList());
  }

  /// GET NEW VERSION SEASONS
  Future<List<Season>> getNewVersionSeasons() async {
    try {
      final query = await _collection
          .where(keySeasonNewVersion, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Season.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Season>> streamNewVersionSeasons() {
    return _collection
        .where(keySeasonNewVersion, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Season.fromDocumentSnapshot(doc)).toList());
  }

  /// GET SEASONS BETWEEN DATES
  Future<List<Season>> getSeasonsBetweenDates({
    required Timestamp start,
    required Timestamp end,
  }) async {
    try {
      final query = await _collection
          .where(keySeasonStartDate, isGreaterThanOrEqualTo: start)
          .where(keySeasonEndDate, isLessThanOrEqualTo: end)
          .get();

      return query.docs.map((doc) => Season.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Season>> streamSeasonsBetweenDates({
    required Timestamp start,
    required Timestamp end,
  }) {
    return _collection
        .where(keySeasonStartDate, isGreaterThanOrEqualTo: start)
        .where(keySeasonEndDate, isLessThanOrEqualTo: end)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Season.fromDocumentSnapshot(doc)).toList());
  }

  /// SET CURRENT SEASON
  Future<void> setCurrentSeason({
    required String seasonId,
    bool isCurrent = true,
  }) async {
    try {
      await _collection.doc(seasonId).update({
        keySeasonCurrent: isCurrent,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// SET ONLY ONE CURRENT SEASON
  Future<void> setOnlyOneCurrentSeason(String seasonId) async {
    try {
      final allCurrent = await _collection
          .where(keySeasonCurrent, isEqualTo: true)
          .get();

      final batch = _firestore.batch();

      for (final doc in allCurrent.docs) {
        batch.update(doc.reference, {
          keySeasonCurrent: false,
        });
      }

      batch.set(
        _collection.doc(seasonId),
        {
          keySeasonCurrent: true,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE NEW VERSION FLAG
  Future<void> updateNewVersion({
    required String seasonId,
    required bool newVersion,
  }) async {
    try {
      await _collection.doc(seasonId).update({
        keySeasonNewVersion: newVersion,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE DATES
  Future<void> updateSeasonDates({
    required String seasonId,
    Timestamp? startDate,
    Timestamp? endDate,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (startDate != null) {
        data[keySeasonStartDate] = startDate;
      }
      if (endDate != null) {
        data[keySeasonEndDate] = endDate;
      }

      if (data.isNotEmpty) {
        await _collection.doc(seasonId).update(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// PRIVATE MAP BUILDER
  Map<String, dynamic> _seasonToMap(Season season) {
    return {
      keySeasonName: season.name,
      keySeasonStartDate: season.startDate,
      keySeasonEndDate: season.endDate,
      keySeasonCurrent: season.isCurrent ?? false,
      keySeasonClubName: season.clubName ?? '',
      keySeasonAffiliateNumber: season.affiliateNumber ?? '',
      keySeasonNewVersion: season.newVersion ?? false,
    };
  }
}