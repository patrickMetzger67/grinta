import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/teams_per_club.dart';

class TeamsPerClubService {
  static const String collectionName = 'teamsPerClub';

  final FirebaseFirestore _firestore;

  TeamsPerClubService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(collectionName);
  }

  /// Deterministic doc id: `{clubId}_{seasonId}`.
  static String buildDocumentId({
    required String clubId,
    required String seasonId,
  }) {
    return '${clubId.trim()}_${seasonId.trim()}';
  }

  DocumentReference<Map<String, dynamic>> docRefFor({
    required String clubId,
    required String seasonId,
  }) {
    return _collection.doc(
      buildDocumentId(clubId: clubId, seasonId: seasonId),
    );
  }

  static TeamsPerClub fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return TeamsPerClub.fromDocumentSnapshot(snapshot);
  }

  static Map<String, dynamic> toFirestore(TeamsPerClub teamsPerClub) {
    return teamsPerClub.toMap();
  }

  /// READ ONE by club + season (direct doc lookup).
  Future<TeamsPerClub?> getByClubIdAndSeason({
    required String clubId,
    required String seasonId,
  }) async {
    final snapshot = await docRefFor(
      clubId: clubId,
      seasonId: seasonId,
    ).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return fromFirestore(snapshot);
  }

  /// READ ALL seasons for a club.
  Future<List<TeamsPerClub>> getByClubId(String clubId) async {
    final snapshot = await _collection
        .where(keyTeamsPerClubClubId, isEqualTo: clubId)
        .get();

    return snapshot.docs.map(fromFirestore).toList();
  }

  /// STREAM ONE by club + season.
  Stream<TeamsPerClub?> streamByClubIdAndSeason({
    required String clubId,
    required String seasonId,
  }) {
    return docRefFor(clubId: clubId, seasonId: seasonId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return fromFirestore(snapshot);
    });
  }

  Stream<TeamsPerClub?> watchByClubIdAndSeason({
    required String clubId,
    required String seasonId,
  }) =>
      streamByClubIdAndSeason(clubId: clubId, seasonId: seasonId);

  /// STREAM ALL seasons for a club.
  Stream<List<TeamsPerClub>> streamByClubId(String clubId) {
    return _collection
        .where(keyTeamsPerClubClubId, isEqualTo: clubId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Stream<List<TeamsPerClub>> watchByClubId(String clubId) =>
      streamByClubId(clubId);

  /// CREATE / UPSERT.
  Future<void> setTeamsPerClub(
    TeamsPerClub teamsPerClub, {
    bool merge = true,
  }) async {
    final clubId = teamsPerClub.clubId?.trim() ?? '';
    final seasonId = teamsPerClub.seasonId?.trim() ?? '';

    if (clubId.isEmpty || seasonId.isEmpty) {
      throw Exception('clubId et seasonId sont requis');
    }

    await docRefFor(clubId: clubId, seasonId: seasonId).set(
      toFirestore(teamsPerClub),
      SetOptions(merge: merge),
    );
  }

  Future<void> deleteByClubIdAndSeason({
    required String clubId,
    required String seasonId,
  }) async {
    await docRefFor(clubId: clubId, seasonId: seasonId).delete();
  }
}
