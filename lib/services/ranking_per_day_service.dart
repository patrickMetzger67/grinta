import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/rankingPerDay.dart';

class RankingPerDayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'rankingPerDay';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  static RankingPerDay fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return RankingPerDay.fromDocumentSnapshot(doc);
  }

  /// CREATE
  Future<String> createRankingPerDay(RankingPerDay rankingPerDay) async {
    try {
      final docRef = _collection.doc();
      await docRef.set(_rankingPerDayToMap(rankingPerDay));
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// CREATE with custom document id
  Future<void> setRankingPerDay({
    required String id,
    required RankingPerDay rankingPerDay,
    bool merge = true,
  }) async {
    try {
      await _collection
          .doc(id)
          .set(_rankingPerDayToMap(rankingPerDay), SetOptions(merge: merge));
    } catch (e) {
      rethrow;
    }
  }

  /// READ ONE
  Future<RankingPerDay?> getRankingPerDayById(String id) async {
    try {
      final doc = await _collection.doc(id).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ONE
  Stream<RankingPerDay?> streamRankingPerDayById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return fromFirestore(doc);
    });
  }

  /// READ ALL
  Future<List<RankingPerDay>> getAllRankingsPerDay() async {
    try {
      final query = await _collection.get();
      return query.docs
          .where((doc) => doc.data().isNotEmpty)
          .map(fromFirestore)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ALL
  Stream<List<RankingPerDay>> streamAllRankingsPerDay() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map(fromFirestore)
          .toList();
    });
  }

  /// UPDATE
  Future<void> updateRankingPerDay({
    required String id,
    required RankingPerDay rankingPerDay,
  }) async {
    try {
      await _collection.doc(id).update(_rankingPerDayToMap(rankingPerDay));
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE
  Future<void> deleteRankingPerDay(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// GET BY SEASON ID
  Future<List<RankingPerDay>> getRankingsPerDayBySeasonId(
    String seasonId,
  ) async {
    try {
      final query = await _collection
          .where(keyRankingPerDaySeasonID, isEqualTo: seasonId)
          .get();

      return query.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<RankingPerDay>> streamRankingsPerDayBySeasonId(String seasonId) {
    return _collection
        .where(keyRankingPerDaySeasonID, isEqualTo: seasonId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  /// GET BY COMPETITION ID
  Future<List<RankingPerDay>> getRankingsPerDayByCompetitionId(
    String competitionId,
  ) async {
    try {
      final query = await _collection
          .where(keyRankingPerDayCompetitionID, isEqualTo: competitionId)
          .get();

      return query.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<RankingPerDay>> streamRankingsPerDayByCompetitionId(
    String competitionId,
  ) {
    return _collection
        .where(keyRankingPerDayCompetitionID, isEqualTo: competitionId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  /// GET BY COMPETITION ID + POULE
  Future<List<RankingPerDay>> getRankingsPerDayByCompetitionIdAndPoule({
    required String competitionId,
    required String poule,
  }) async {
    try {
      final query = await _collection
          .where(keyRankingPerDayCompetitionID, isEqualTo: competitionId)
          .where(keyRankingPerDayPoule, isEqualTo: poule)
          .get();

      return query.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<RankingPerDay>> streamRankingsPerDayByCompetitionIdAndPoule({
    required String competitionId,
    required String poule,
  }) {
    return _collection
        .where(keyRankingPerDayCompetitionID, isEqualTo: competitionId)
        .where(keyRankingPerDayPoule, isEqualTo: poule)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  /// GET BY SEASON ID + COMPETITION ID
  Future<List<RankingPerDay>> getRankingsPerDayBySeasonIdAndCompetitionId({
    required String seasonId,
    required String competitionId,
  }) async {
    try {
      final query = await _collection
          .where(keyRankingPerDaySeasonID, isEqualTo: seasonId)
          .where(keyRankingPerDayCompetitionID, isEqualTo: competitionId)
          .get();

      return query.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<RankingPerDay>> streamRankingsPerDayBySeasonIdAndCompetitionId({
    required String seasonId,
    required String competitionId,
  }) {
    return _collection
        .where(keyRankingPerDaySeasonID, isEqualTo: seasonId)
        .where(keyRankingPerDayCompetitionID, isEqualTo: competitionId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  /// GET BY TEAM AFFILIATE
  Future<List<RankingPerDay>> getRankingsPerDayByTeamAffiliate(
    String teamAffiliate,
  ) async {
    try {
      final query = await _collection
          .where(keyRankingPerDayTeamAffiliate, isEqualTo: teamAffiliate)
          .get();

      return query.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<RankingPerDay>> streamRankingsPerDayByTeamAffiliate(
    String teamAffiliate,
  ) {
    return _collection
        .where(keyRankingPerDayTeamAffiliate, isEqualTo: teamAffiliate)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  /// GET BY SEASON + TEAM AFFILIATE (typical trend query)
  Future<List<RankingPerDay>> getRankingsPerDayBySeasonIdAndTeamAffiliate({
    required String seasonId,
    required String teamAffiliate,
  }) async {
    try {
      final query = await _collection
          .where(keyRankingPerDaySeasonID, isEqualTo: seasonId)
          .where(keyRankingPerDayTeamAffiliate, isEqualTo: teamAffiliate)
          .get();

      return query.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<RankingPerDay>> streamRankingsPerDayBySeasonIdAndTeamAffiliate({
    required String seasonId,
    required String teamAffiliate,
  }) {
    return _collection
        .where(keyRankingPerDaySeasonID, isEqualTo: seasonId)
        .where(keyRankingPerDayTeamAffiliate, isEqualTo: teamAffiliate)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  /// GET BY COMPETITION + POULE + TEAM AFFILIATE
  Future<List<RankingPerDay>> getRankingsPerDayByCompetitionPouleAndTeamAffiliate({
    required String competitionId,
    required String poule,
    required String teamAffiliate,
  }) async {
    try {
      final query = await _collection
          .where(keyRankingPerDayCompetitionID, isEqualTo: competitionId)
          .where(keyRankingPerDayPoule, isEqualTo: poule)
          .where(keyRankingPerDayTeamAffiliate, isEqualTo: teamAffiliate)
          .get();

      return query.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<RankingPerDay>> streamRankingsPerDayByCompetitionPouleAndTeamAffiliate({
    required String competitionId,
    required String poule,
    required String teamAffiliate,
  }) {
    return _collection
        .where(keyRankingPerDayCompetitionID, isEqualTo: competitionId)
        .where(keyRankingPerDayPoule, isEqualTo: poule)
        .where(keyRankingPerDayTeamAffiliate, isEqualTo: teamAffiliate)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  /// GET BY MATCHDAY
  Future<List<RankingPerDay>> getRankingsPerDayByDay(int day) async {
    try {
      final query =
          await _collection.where(keyRankingPerDayDay, isEqualTo: day).get();

      return query.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<RankingPerDay>> streamRankingsPerDayByDay(int day) {
    return _collection
        .where(keyRankingPerDayDay, isEqualTo: day)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Map<String, dynamic> _rankingPerDayToMap(RankingPerDay rankingPerDay) {
    return {
      keyRankingPerDayChType: rankingPerDay.chType,
      keyRankingPerDayCompetitionID: rankingPerDay.competitionID,
      keyRankingPerDayPoule: rankingPerDay.poule,
      keyRankingPerDayTeamName: rankingPerDay.teamName,
      keyRankingPerDayTeamAffiliate: rankingPerDay.teamAffiliate,
      keyRankingPerDaySeasonID: rankingPerDay.seasonID,
      keyRankingPerDayDay: rankingPerDay.day,
      keyRankingPerDayNbTeams: rankingPerDay.nbTeams,
      keyRankingPerDayJo: rankingPerDay.jo,
      keyRankingPerDayG: rankingPerDay.g,
      keyRankingPerDayN: rankingPerDay.n,
      keyRankingPerDayP: rankingPerDay.p,
      keyRankingPerDayPts: rankingPerDay.pts,
      keyRankingPerDayRank: rankingPerDay.rank,
      keyRankingPerDayBc: rankingPerDay.bc,
      keyRankingPerDayBp: rankingPerDay.bp,
      keyRankingPerDayDiff: rankingPerDay.diff,
    };
  }
}
