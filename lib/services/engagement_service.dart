import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/engagement.dart';

class EngagementService {
  static const String collectionName = 'engagement';

  final FirebaseFirestore _firestore;

  EngagementService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(collectionName);
  }

  DocumentReference<Map<String, dynamic>> docRefFor(String id) {
    return _collection.doc(id.trim());
  }

  static Engagement fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return Engagement.fromDocumentSnapshot(snapshot);
  }

  static Map<String, dynamic> toFirestore(Engagement engagement) {
    return engagement.toMap();
  }

  /// READ ONE by document id.
  Future<Engagement?> getById(String id) async {
    final snapshot = await docRefFor(id).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return fromFirestore(snapshot);
  }

  /// STREAM ONE by document id.
  Stream<Engagement?> streamById(String id) {
    return docRefFor(id).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return fromFirestore(snapshot);
    });
  }

  Stream<Engagement?> watchById(String id) => streamById(id);

  /// READ ALL for a club.
  Future<List<Engagement>> getByClubId(String clubId) async {
    final snapshot = await _collection
        .where(keyEngagementClubId, isEqualTo: clubId)
        .get();

    return snapshot.docs.map(fromFirestore).toList();
  }

  Stream<List<Engagement>> streamByClubId(String clubId) {
    return _collection
        .where(keyEngagementClubId, isEqualTo: clubId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Stream<List<Engagement>> watchByClubId(String clubId) =>
      streamByClubId(clubId);

  /// READ ALL for a club and season.
  Future<List<Engagement>> getByClubIdAndSeasonId({
    required String clubId,
    required String seasonId,
  }) async {
    final snapshot = await _collection
        .where(keyEngagementClubId, isEqualTo: clubId)
        .where(keyEngagementSeasonId, isEqualTo: seasonId)
        .get();

    return snapshot.docs.map(fromFirestore).toList();
  }

  Stream<List<Engagement>> streamByClubIdAndSeasonId({
    required String clubId,
    required String seasonId,
  }) {
    return _collection
        .where(keyEngagementClubId, isEqualTo: clubId)
        .where(keyEngagementSeasonId, isEqualTo: seasonId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Stream<List<Engagement>> watchByClubIdAndSeasonId({
    required String clubId,
    required String seasonId,
  }) =>
      streamByClubIdAndSeasonId(clubId: clubId, seasonId: seasonId);

  /// READ ALL where [teamId] is listed in [teamIds].
  Future<List<Engagement>> getByTeamIdInTeamIds(String teamId) async {
    final trimmedTeamId = teamId.trim();
    if (trimmedTeamId.isEmpty) {
      return <Engagement>[];
    }

    final snapshot = await _collection
        .where(keyEngagementTeamIds, arrayContains: trimmedTeamId)
        .get();

    return snapshot.docs.map(fromFirestore).toList();
  }

  /// Engagements linked to [teamId] for agenda match loading.
  ///
  /// Merges documents where [teamId] appears in [teamIds] or in legacy
  /// [teamId], optionally filtered to [seasonId] when provided.
  Future<List<Engagement>> getEngagementsForTeamAgenda({
    required String teamId,
    String? seasonId,
  }) async {
    final trimmedTeamId = teamId.trim();
    if (trimmedTeamId.isEmpty) {
      return <Engagement>[];
    }

    final trimmedSeasonId = seasonId?.trim() ?? '';
    final Map<String, Engagement> byDocumentId = <String, Engagement>{};

    void absorb(Iterable<Engagement> engagements) {
      for (final Engagement engagement in engagements) {
        final String? documentId = engagement.ref?.id;
        if (documentId == null || documentId.isEmpty) {
          continue;
        }

        if (trimmedSeasonId.isNotEmpty) {
          final String engagementSeasonId = engagement.seasonId?.trim() ?? '';
          if (engagementSeasonId.isNotEmpty &&
              engagementSeasonId != trimmedSeasonId) {
            continue;
          }
        }

        byDocumentId[documentId] = engagement;
      }
    }

    final List<Engagement> fromTeamIds =
        await getByTeamIdInTeamIds(trimmedTeamId);
    final List<Engagement> fromLegacyTeamId =
        await getByTeamId(trimmedTeamId);

    absorb(fromTeamIds);
    absorb(fromLegacyTeamId);

    if (kDebugMode) {
      debugPrint(
        'Agenda engagements: teamId=$trimmedTeamId '
        'seasonId=${trimmedSeasonId.isEmpty ? '(any)' : trimmedSeasonId} '
        'fromTeamIds=${fromTeamIds.length} '
        'fromLegacyTeamId=${fromLegacyTeamId.length} '
        'merged=${byDocumentId.length}',
      );
    }

    return byDocumentId.values.toList();
  }

  Stream<List<Engagement>> streamByTeamIdInTeamIds(String teamId) {
    final trimmedTeamId = teamId.trim();
    if (trimmedTeamId.isEmpty) {
      return Stream<List<Engagement>>.value(<Engagement>[]);
    }

    return _collection
        .where(keyEngagementTeamIds, arrayContains: trimmedTeamId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  /// READ ALL for a team.
  Future<List<Engagement>> getByTeamId(String teamId) async {
    final snapshot = await _collection
        .where(keyEngagementTeamId, isEqualTo: teamId)
        .get();

    return snapshot.docs.map(fromFirestore).toList();
  }

  Stream<List<Engagement>> streamByTeamId(String teamId) {
    return _collection
        .where(keyEngagementTeamId, isEqualTo: teamId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Stream<List<Engagement>> watchByTeamId(String teamId) =>
      streamByTeamId(teamId);

  /// READ ALL for a club, season, and team.
  Future<List<Engagement>> getByClubIdSeasonIdAndTeamId({
    required String clubId,
    required String seasonId,
    required String teamId,
  }) async {
    final snapshot = await _collection
        .where(keyEngagementClubId, isEqualTo: clubId)
        .where(keyEngagementSeasonId, isEqualTo: seasonId)
        .where(keyEngagementTeamId, isEqualTo: teamId)
        .get();

    return snapshot.docs.map(fromFirestore).toList();
  }

  Stream<List<Engagement>> streamByClubIdSeasonIdAndTeamId({
    required String clubId,
    required String seasonId,
    required String teamId,
  }) {
    return _collection
        .where(keyEngagementClubId, isEqualTo: clubId)
        .where(keyEngagementSeasonId, isEqualTo: seasonId)
        .where(keyEngagementTeamId, isEqualTo: teamId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  Stream<List<Engagement>> watchByClubIdSeasonIdAndTeamId({
    required String clubId,
    required String seasonId,
    required String teamId,
  }) =>
      streamByClubIdSeasonIdAndTeamId(
        clubId: clubId,
        seasonId: seasonId,
        teamId: teamId,
      );

  /// READ default engagement for a club, season, and team.
  Future<Engagement?> getDefaultByClubIdSeasonIdAndTeamId({
    required String clubId,
    required String seasonId,
    required String teamId,
  }) async {
    final snapshot = await _collection
        .where(keyEngagementClubId, isEqualTo: clubId)
        .where(keyEngagementSeasonId, isEqualTo: seasonId)
        .where(keyEngagementTeamId, isEqualTo: teamId)
        .where(keyEngagementIsDefault, isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return fromFirestore(snapshot.docs.first);
  }

  Stream<Engagement?> streamDefaultByClubIdSeasonIdAndTeamId({
    required String clubId,
    required String seasonId,
    required String teamId,
  }) {
    return _collection
        .where(keyEngagementClubId, isEqualTo: clubId)
        .where(keyEngagementSeasonId, isEqualTo: seasonId)
        .where(keyEngagementTeamId, isEqualTo: teamId)
        .where(keyEngagementIsDefault, isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return fromFirestore(snapshot.docs.first);
    });
  }

  Stream<Engagement?> watchDefaultByClubIdSeasonIdAndTeamId({
    required String clubId,
    required String seasonId,
    required String teamId,
  }) =>
      streamDefaultByClubIdSeasonIdAndTeamId(
        clubId: clubId,
        seasonId: seasonId,
        teamId: teamId,
      );

  /// CREATE with auto-generated id, or an optional explicit document id.
  Future<String> createEngagement(
    Engagement engagement, {
    String? documentId,
  }) async {
    final data = toFirestore(engagement);

    if (documentId != null && documentId.trim().isNotEmpty) {
      await _collection.doc(documentId.trim()).set(data);
      return documentId.trim();
    }

    final docRef = await _collection.add(data);
    return docRef.id;
  }

  /// CREATE / UPSERT by document id.
  Future<void> setEngagement(
    Engagement engagement, {
    required String documentId,
    bool merge = true,
  }) async {
    final id = documentId.trim();
    if (id.isEmpty) {
      throw Exception('documentId est requis');
    }

    await _collection.doc(id).set(
      toFirestore(engagement),
      SetOptions(merge: merge),
    );
  }

  /// CREATE / UPSERT by document id, merging [grintaTeamId] into [teamIds].
  Future<void> upsertEngagementWithTeamId({
    required String documentId,
    required Engagement engagement,
    required String grintaTeamId,
    bool merge = true,
  }) async {
    final id = documentId.trim();
    if (id.isEmpty) {
      throw Exception('documentId est requis');
    }

    final teamId = grintaTeamId.trim();
    if (teamId.isEmpty) {
      throw Exception('grintaTeamId est requis');
    }

    final data = toFirestore(engagement)
      ..remove(keyEngagementTeamIds);
    data[keyEngagementTeamIds] = FieldValue.arrayUnion(<String>[teamId]);

    await _collection.doc(id).set(
      data,
      SetOptions(merge: merge),
    );
  }

  /// UPDATE by document reference.
  Future<void> updateEngagement(Engagement engagement) async {
    if (engagement.ref == null) {
      throw Exception('Impossible de mettre à jour : ref est null');
    }

    await engagement.ref!.update(toFirestore(engagement));
  }

  /// UPDATE by document id.
  Future<void> updateEngagementById({
    required String id,
    required Map<String, dynamic> fields,
  }) async {
    await _collection.doc(id).update(fields);
  }

  /// DELETE by document id.
  Future<void> deleteById(String id) async {
    await _collection.doc(id).delete();
  }

  /// DELETE by document reference.
  Future<void> deleteEngagement(Engagement engagement) async {
    if (engagement.ref == null) {
      throw Exception('Impossible de supprimer : ref est null');
    }

    await engagement.ref!.delete();
  }

  /// Removes [teamId] from one engagement's [teamIds] array (atomic [arrayRemove]).
  Future<void> removeTeamIdFromEngagement({
    required String docId,
    required String teamId,
  }) async {
    final id = docId.trim();
    final trimmedTeamId = teamId.trim();
    if (id.isEmpty || trimmedTeamId.isEmpty) {
      return;
    }

    await _collection.doc(id).set(
      <String, dynamic>{
        keyEngagementTeamIds: FieldValue.arrayRemove(<String>[trimmedTeamId]),
      },
      SetOptions(merge: true),
    );
  }

  /// Removes [teamId] from every engagement whose [teamIds] contains it.
  Future<void> removeTeamIdFromAllEngagements(String teamId) async {
    final trimmedTeamId = teamId.trim();
    if (trimmedTeamId.isEmpty) {
      return;
    }

    final snapshot = await _collection
        .where(keyEngagementTeamIds, arrayContains: trimmedTeamId)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    const int batchLimit = 500;
    for (var i = 0; i < snapshot.docs.length; i += batchLimit) {
      final batch = _firestore.batch();
      final end = (i + batchLimit < snapshot.docs.length)
          ? i + batchLimit
          : snapshot.docs.length;

      for (var j = i; j < end; j++) {
        final docRef = snapshot.docs[j].reference;
        batch.set(
          docRef,
          <String, dynamic>{
            keyEngagementTeamIds:
                FieldValue.arrayRemove(<String>[trimmedTeamId]),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    }
  }
}
