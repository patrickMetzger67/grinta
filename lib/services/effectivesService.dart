import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/effectives.dart';
import 'subscription_limits_service.dart';

class EffectivesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'effectives';

  CollectionReference get _collection =>
      _firestore.collection(collectionName);

  /// CREATE
  Future<DocumentReference> addEffectives(Effectives effective) async {
    final teamId = effective.teamID?.trim() ?? '';
    final memberId = effective.memberID?.trim() ?? '';
    if (teamId.isNotEmpty &&
        memberId.isNotEmpty &&
        (effective.type ?? 0) == 0) {
      await SubscriptionLimitsService.instance.assertCanAddPlayer(
        teamId: teamId,
        memberId: memberId,
      );
    }

    effective.modificationDate = Timestamp.now();
    return await _collection.add(effective.toMap());
  }

  /// CREATE avec id custom
  Future<void> setEffectives(String id, Effectives effective) async {
    effective.modificationDate = Timestamp.now();
    await _collection.doc(id).set(effective.toMap());
  }

  /// READ ONE
  Future<Effectives?> getEffectivesById(String id) async {
    final doc = await _collection.doc(id).get();

    if (!doc.exists) return null;

    return Effectives.fromData(doc);
  }

  /// STREAM ONE
  Stream<Effectives?> streamEffectivesById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Effectives.fromData(doc);
    });
  }

  /// READ ALL
  Future<List<Effectives>> getAllEffectives() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
  }

  /// STREAM ALL
  Stream<List<Effectives>> streamAllEffectives() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
    });
  }

  /// READ BY CLUB
  Future<List<Effectives>> getEffectivesByClubId(String clubId) async {
    final snapshot = await _collection
        .where(keyEffectivesClubId, isEqualTo: clubId)
        .orderBy(keyEffectivesOrder)
        .get();

    return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
  }

  Stream<List<Effectives>> streamEffectivesByClubId(String clubId) {
    return _collection
        .where(keyEffectivesClubId, isEqualTo: clubId)
        .orderBy(keyEffectivesOrder)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
    });
  }

  /// READ BY MEMBER
  Future<List<Effectives>> getEffectivesByMemberId(String memberId) async {
    final snapshot = await _collection
        .where(keyEffectivesMemberID, isEqualTo: memberId)
        .orderBy(keyEffectivesDate, descending: true)
        .get();

    return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
  }

  /// READ BY MEMBER + TEAMID
  Future<Effectives?> getEffectivesPlayerByMemberIdAndTeamId(
      String memberId,
      String teamId,
      ) async {
    final querySnapshot = await _collection
        .where(keyEffectivesMemberID, isEqualTo: memberId)
        .where(keyEffectivesTeamID, isEqualTo: teamId)
        .where(keyEffectivesType, isEqualTo: 0)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) return null;
    return Effectives.fromData(querySnapshot.docs.first);
  }

  /// READ BY MEMBER + TEAMID
  Future<Effectives?> getEffectivesByMemberIdAndTeamId(
      String memberId,
      String teamId,
      ) async {
    final querySnapshot = await _collection
        .where(keyEffectivesMemberID, isEqualTo: memberId)
        .where(keyEffectivesTeamID, isEqualTo: teamId)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) return null;
    return Effectives.fromData(querySnapshot.docs.first);
  }

      /// READ ONE BY MEMBER + SEASON
  Future<Effectives?> getEffectivesByMemberAndSeason({
    required String memberId,
    required String seasonId,
  }) async {
    final snapshot = await _collection
        .where(keyEffectivesMemberID, isEqualTo: memberId)
        .where(keyEffectivesSeasonID, isEqualTo: seasonId)
        .orderBy(keyEffectivesDate, descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return Effectives.fromData(snapshot.docs.first);
  }
  Stream<Effectives?> streamEffectivesByMemberAndSeason({
    required String memberId,
    required String seasonId,
  }) {
    return _collection
        .where(keyEffectivesMemberID, isEqualTo: memberId)
        .where(keyEffectivesSeasonID, isEqualTo: seasonId)
        .orderBy(keyEffectivesDate, descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Effectives.fromData(snapshot.docs.first);
    });
  }

  Stream<List<Effectives>> streamEffectivesByMemberId(String memberId) {
    return _collection
        .where(keyEffectivesMemberID, isEqualTo: memberId)
        .orderBy(keyEffectivesDate, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
    });
  }

  /// READ BY TEAM
  Future<List<Effectives>> getEffectivesByTeamId(String teamId) async {
    final snapshot = await _collection
        .where(keyEffectivesTeamID, isEqualTo: teamId)
        .orderBy(keyEffectivesOrder)
        .get();

    return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
  }

  Stream<List<Effectives>> streamEffectivesByTeamId(String teamId) {
    return _collection
        .where(keyEffectivesTeamID, isEqualTo: teamId)
        .orderBy(keyEffectivesOrder)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
    });
  }

  /// READ BY SEASON
  Future<List<Effectives>> getEffectivesBySeasonId(String seasonId) async {
    final snapshot = await _collection
        .where(keyEffectivesSeasonID, isEqualTo: seasonId)
        .orderBy(keyEffectivesOrder)
        .get();

    return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
  }

  Stream<List<Effectives>> streamEffectivesBySeasonId(String seasonId) {
    return _collection
        .where(keyEffectivesSeasonID, isEqualTo: seasonId)
        .orderBy(keyEffectivesOrder)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
    });
  }

  /// READ BY CLUB + SEASON
  Future<List<Effectives>> getEffectivesByClubAndSeason({
    required String clubId,
    required String seasonId,
  }) async {
    final snapshot = await _collection
        .where(keyEffectivesClubId, isEqualTo: clubId)
        .where(keyEffectivesSeasonID, isEqualTo: seasonId)
        .orderBy(keyEffectivesOrder)
        .get();

    return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
  }

  Stream<List<Effectives>> streamEffectivesByClubAndSeason({
    required String clubId,
    required String seasonId,
  }) {
    return _collection
        .where(keyEffectivesClubId, isEqualTo: clubId)
        .where(keyEffectivesSeasonID, isEqualTo: seasonId)
        .orderBy(keyEffectivesOrder)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
    });
  }

  /// READ BY CLUB + SEASON + TEAM
  Future<List<Effectives>> getEffectivesByClubSeasonAndTeam({
    required String clubId,
    required String seasonId,
    required String teamId,
  }) async {
    final snapshot = await _collection
        .where(keyEffectivesClubId, isEqualTo: clubId)
        .where(keyEffectivesSeasonID, isEqualTo: seasonId)
        .where(keyEffectivesTeamID, isEqualTo: teamId)
        .orderBy(keyEffectivesOrder)
        .get();

    return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
  }

  Stream<List<Effectives>> streamEffectivesByClubSeasonAndTeam({
    required String clubId,
    required String seasonId,
    required String teamId,
  }) {
    return _collection
        .where(keyEffectivesClubId, isEqualTo: clubId)
        .where(keyEffectivesSeasonID, isEqualTo: seasonId)
        .where(keyEffectivesTeamID, isEqualTo: teamId)
        .orderBy(keyEffectivesOrder)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Effectives.fromData(doc)).toList();
    });
  }

  /// UPDATE
  Future<void> updateEffectives(Effectives effective) async {
    if (effective.ref == null) {
      throw Exception("Impossible de mettre à jour : ref est null");
    }

    effective.modificationDate = Timestamp.now();
    await effective.ref!.update(effective.toMap());
  }

  /// UPDATE BY ID
  Future<void> updateEffectivesById(String id, Map<String, dynamic> data) async {
    data[keyEffectivesDate] = Timestamp.now();
    await _collection.doc(id).update(data);
  }

  /// DELETE
  Future<void> deleteEffectives(Effectives effective) async {
    if (effective.ref == null) {
      throw Exception("Impossible de supprimer : ref est null");
    }

    await effective.ref!.delete();
  }

  /// DELETE BY ID
  Future<void> deleteEffectivesById(String id) async {
    await _collection.doc(id).delete();
  }

  /// TRACKERS - AJOUTER UN TRACKER
  Future<void> addTracker({
    required String effectivesId,
    required String trackerId,
  }) async {
    await _collection.doc(effectivesId).update({
      'trackers': FieldValue.arrayUnion([trackerId]),
      keyEffectivesDate: Timestamp.now(),
    });
  }

  /// TRACKERS - SUPPRIMER UN TRACKER
  Future<void> removeTracker({
    required String effectivesId,
    required String trackerId,
  }) async {
    await _collection.doc(effectivesId).update({
      'trackers': FieldValue.arrayRemove([trackerId]),
      keyEffectivesDate: Timestamp.now(),
    });
  }

  /// TRACKERS - REMPLACER LA LISTE COMPLETE
  Future<void> updateTrackers({
    required String effectivesId,
    required List<String> trackers,
  }) async {
    await _collection.doc(effectivesId).update({
      'trackers': trackers,
      keyEffectivesDate: Timestamp.now(),
    });
  }
}