import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/ranking.dart';

class RankingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'ranking';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  static Ranking fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Ranking(doc);
  }

  /// CREATE
  Future<String> createRanking(Ranking ranking) async {
    try {
      final docRef = ranking.id != null && ranking.id!.isNotEmpty
          ? _collection.doc(ranking.id)
          : _collection.doc();

      ranking.id = docRef.id;

      await docRef.set(_rankingToMap(ranking));
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// SET / UPSERT
  Future<void> setRanking(Ranking ranking) async {
    try {
      final docRef = ranking.id != null && ranking.id!.isNotEmpty
          ? _collection.doc(ranking.id)
          : _collection.doc();

      ranking.id = docRef.id;

      await docRef.set(_rankingToMap(ranking), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// READ ONE
  Future<Ranking?> getRankingById(String rankingId) async {
    try {
      final doc = await _collection.doc(rankingId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ONE
  Stream<Ranking?> streamRankingById(String rankingId) {
    return _collection.doc(rankingId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return fromFirestore(doc);
    });
  }

  /// READ ALL
  Future<List<Ranking>> getAllRankings() async {
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
  Stream<List<Ranking>> streamAllRankings() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map(fromFirestore)
          .toList();
    });
  }

  /// UPDATE
  Future<void> updateRanking(Ranking ranking) async {
    try {
      if (ranking.id == null || ranking.id!.isEmpty) {
        throw Exception("L'id du classement est null ou vide.");
      }

      await _collection.doc(ranking.id).update(_rankingToMap(ranking));
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE
  Future<void> deleteRanking(String rankingId) async {
    try {
      await _collection.doc(rankingId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// GET BY COMPETITION ID
  Future<List<Ranking>> getRankingsByCompetitionId(
    String competitionId,
  ) async {
    try {
      final query = await _collection
          .where(keyRankingCompetitionID, isEqualTo: competitionId)
          .get();

      return query.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Ranking>> streamRankingsByCompetitionId(String competitionId) {
    return _collection
        .where(keyRankingCompetitionID, isEqualTo: competitionId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  /// GET BY COMPETITION ID + POULE
  Future<List<Ranking>> getRankingsByCompetitionIdAndPoule({
    required String competitionId,
    required String poule,
  }) async {
    try {
      final query = await _collection
          .where(keyRankingCompetitionID, isEqualTo: competitionId)
          .where(keyRankingPoule, isEqualTo: poule)
          .get();

      return query.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Ranking>> streamRankingsByCompetitionIdAndPoule({
    required String competitionId,
    required String poule,
  }) {
    return _collection
        .where(keyRankingCompetitionID, isEqualTo: competitionId)
        .where(keyRankingPoule, isEqualTo: poule)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  /// GET BY CHAMPIONSHIP TYPE
  Future<List<Ranking>> getRankingsByChType(String chType) async {
    try {
      final query = await _collection
          .where(keyRankingChType, isEqualTo: chType)
          .get();

      return query.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Ranking>> streamRankingsByChType(String chType) {
    return _collection
        .where(keyRankingChType, isEqualTo: chType)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Map<String, dynamic> _rankToMap(Rank rank) {
    return {
      keyRankRang: rank.rang,
      keyRankTeam: rank.team,
      keyRankPts: rank.pts,
      keyRankJo: rank.jo,
      keyRankG: rank.g,
      keyRankN: rank.n,
      keyRankP: rank.p,
      keyRankF: rank.f,
      keyRankBP: rank.bp,
      keyRankBC: rank.bc,
      keyRankPE: rank.pe,
      keyRankDiff: rank.diff,
    };
  }

  Map<String, dynamic> _rankingToMap(Ranking ranking) {
    return {
      keyRankingId: ranking.id,
      keyRankingChType: ranking.chType,
      keyRankingCompetitionID: ranking.competitionID,
      keyRankingPoule: ranking.poule,
      keyRankingRanks:
          ranking.ranks?.map(_rankToMap).toList(growable: false) ?? [],
    };
  }
}
