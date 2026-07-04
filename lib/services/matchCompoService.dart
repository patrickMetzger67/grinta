import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/matchCompo.dart';
import '../util/match_compo_pitch_mapper.dart';

String collectionMatchCompo = "matchCompo";

class MatchCompoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection =>
      _firestore.collection(collectionMatchCompo);

  /// Deterministic doc id: `{matchId}_{teamId}`.
  static String buildDocumentId({
    required String matchId,
    required String teamId,
  }) {
    return '${matchId.trim()}_${teamId.trim()}';
  }

  DocumentReference docRefFor({
    required String matchId,
    required String teamId,
  }) {
    return _collection.doc(
      buildDocumentId(matchId: matchId, teamId: teamId),
    );
  }

  Future<DocumentReference> addMatchCompo(MatchCompo matchCompo) async {
    final matchId = matchCompo.matchID?.trim() ?? '';
    final teamId = matchCompo.teamID?.trim() ?? '';
    if (matchId.isEmpty || teamId.isEmpty) {
      throw Exception('matchID et teamID requis pour créer un MatchCompo');
    }

    final docRef = docRefFor(matchId: matchId, teamId: teamId);
    await docRef.set(matchCompo.toMap());
    return docRef;
  }

  Future<void> updateMatchCompo(MatchCompo matchCompo) async {
    final matchId = matchCompo.matchID?.trim() ?? '';
    final teamId = matchCompo.teamID?.trim() ?? '';
    if (matchId.isEmpty || teamId.isEmpty) {
      throw Exception('matchID et teamID requis pour mettre à jour un MatchCompo');
    }

    final docRef = docRefFor(matchId: matchId, teamId: teamId);
    matchCompo.ref = docRef;
    await docRef.set(matchCompo.toMap(), SetOptions(merge: true));
  }

  Future<void> saveMatchCompo(MatchCompo matchCompo) async {
    final matchId = matchCompo.matchID?.trim() ?? '';
    final teamId = matchCompo.teamID?.trim() ?? '';
    if (matchId.isEmpty || teamId.isEmpty) {
      throw Exception('matchID et teamID requis pour enregistrer un MatchCompo');
    }

    final docRef = docRefFor(matchId: matchId, teamId: teamId);
    matchCompo.ref = docRef;
    await docRef.set(matchCompo.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMatchCompo(MatchCompo matchCompo) async {
    if (matchCompo.ref == null) {
      throw Exception("La référence du MatchCompo est nulle");
    }

    await matchCompo.ref!.delete();
  }

  Future<void> deleteMatchCompoByRef(DocumentReference ref) async {
    await ref.delete();
  }

  Future<MatchCompo?> getMatchCompoByRef(DocumentReference ref) async {
    final doc = await ref.get();

    if (!doc.exists) return null;

    return MatchCompo.fromSnapshot(doc);
  }

  Future<MatchCompo?> getMatchCompoByMatchAndTeamId(
    String matchId,
    String teamId,
  ) async {
    final trimmedMatchId = matchId.trim();
    final trimmedTeamId = teamId.trim();
    if (trimmedMatchId.isEmpty || trimmedTeamId.isEmpty) return null;

    final canonicalDoc =
        await docRefFor(matchId: trimmedMatchId, teamId: trimmedTeamId).get();
    if (canonicalDoc.exists) {
      return MatchCompo.fromSnapshot(canonicalDoc);
    }

    return _loadLegacyMatchCompo(
      matchId: trimmedMatchId,
      teamId: trimmedTeamId,
    );
  }

  Stream<MatchCompo?> streamMatchCompoByMatchAndTeamId(
    String matchId,
    String teamId,
  ) {
    final trimmedMatchId = matchId.trim();
    final trimmedTeamId = teamId.trim();
    if (trimmedMatchId.isEmpty || trimmedTeamId.isEmpty) {
      return Stream<MatchCompo?>.value(null);
    }

    final canonicalRef =
        docRefFor(matchId: trimmedMatchId, teamId: trimmedTeamId);
    final legacyQuery = _collection
        .where(keyMatchCompoMatchId, isEqualTo: trimmedMatchId)
        .where(keyMatchCompoTeamID, isEqualTo: trimmedTeamId)
        .limit(1);

    return canonicalRef.snapshots().asyncExpand((canonicalSnap) {
      if (canonicalSnap.exists) {
        return Stream<MatchCompo?>.value(
          MatchCompo.fromSnapshot(canonicalSnap),
        );
      }

      return legacyQuery.snapshots().map((querySnap) {
        if (querySnap.docs.isEmpty) return null;
        return MatchCompo.fromSnapshot(querySnap.docs.first);
      });
    });
  }

  Future<List<MatchCompo>> getAllMatchCompos() async {
    final querySnapshot = await _collection.get();

    return querySnapshot.docs
        .map((doc) => MatchCompo.fromSnapshot(doc))
        .toList();
  }

  Stream<List<MatchCompo>> streamAllMatchCompos() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MatchCompo.fromSnapshot(doc);
      }).toList();
    });
  }

  Future<List<MatchCompo>> getMatchComposByMatchId(String matchId) async {
    final querySnapshot = await _collection
        .where(keyMatchCompoMatchId, isEqualTo: matchId)
        .get();

    return querySnapshot.docs
        .map((doc) => MatchCompo.fromSnapshot(doc))
        .toList();
  }

  Stream<List<MatchCompo>> streamMatchComposByMatchId(String matchId) {
    return _collection
        .where(keyMatchCompoMatchId, isEqualTo: matchId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MatchCompo.fromSnapshot(doc);
      }).toList();
    });
  }

  Future<List<MatchCompo>> getMatchComposByTeamId(String teamId) async {
    final querySnapshot = await _collection
        .where(keyMatchCompoTeamID, isEqualTo: teamId)
        .get();

    return querySnapshot.docs
        .map((doc) => MatchCompo.fromSnapshot(doc))
        .toList();
  }

  Stream<List<MatchCompo>> streamMatchComposByTeamId(String teamId) {
    return _collection
        .where(keyMatchCompoTeamID, isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MatchCompo.fromSnapshot(doc);
      }).toList();
    });
  }

  Future<List<MatchCompo>> getMatchComposBySeasonId(String seasonId) async {
    final querySnapshot = await _collection
        .where(keyMatchCompoSeasonID, isEqualTo: seasonId)
        .get();

    return querySnapshot.docs
        .map((doc) => MatchCompo.fromSnapshot(doc))
        .toList();
  }

  Stream<List<MatchCompo>> streamMatchComposBySeasonId(String seasonId) {
    return _collection
        .where(keyMatchCompoSeasonID, isEqualTo: seasonId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MatchCompo.fromSnapshot(doc);
      }).toList();
    });
  }

  Future<MatchCompo?> getFirstMatchCompoByMatchId(String matchId) async {
    final querySnapshot = await _collection
        .where(keyMatchCompoMatchId, isEqualTo: matchId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return MatchCompo.fromSnapshot(querySnapshot.docs.first);
  }

  Stream<MatchCompo?> streamFirstMatchCompoByMatchId(String matchId) {
    return _collection
        .where(keyMatchCompoMatchId, isEqualTo: matchId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return MatchCompo.fromSnapshot(snapshot.docs.first);
    });
  }

  Future<MatchCompo?> getMatchCompoForMatchAndTeamIds(
    String matchId, {
    required List<String> profileTeamIds,
    String? preferredTeamId,
  }) async {
    final teamId = _resolveTeamId(
      profileTeamIds: profileTeamIds,
      preferredTeamId: preferredTeamId,
    );
    if (teamId == null) return null;

    final trimmedMatchId = matchId.trim();
    if (trimmedMatchId.isEmpty) return null;

    final direct = await getMatchCompoByMatchAndTeamId(trimmedMatchId, teamId);
    if (direct != null) return direct;

    final compos = await getMatchComposByMatchId(trimmedMatchId);
    return pickMatchCompoForProfileTeams(
      compos,
      profileTeamIds: profileTeamIds,
      preferredTeamId: preferredTeamId,
    );
  }

  Stream<MatchCompo?> streamMatchCompoForMatchAndTeamIds(
    String matchId, {
    required List<String> profileTeamIds,
    String? preferredTeamId,
  }) {
    final teamId = _resolveTeamId(
      profileTeamIds: profileTeamIds,
      preferredTeamId: preferredTeamId,
    );
    if (teamId == null) {
      return Stream<MatchCompo?>.value(null);
    }

    final trimmedMatchId = matchId.trim();
    if (trimmedMatchId.isEmpty) {
      return Stream<MatchCompo?>.value(null);
    }

    return streamMatchCompoByMatchAndTeamId(trimmedMatchId, teamId);
  }

  String? _resolveTeamId({
    required List<String> profileTeamIds,
    String? preferredTeamId,
  }) {
    final preferred = preferredTeamId?.trim();
    if (preferred != null && preferred.isNotEmpty) return preferred;

    final ids = normalizeTeamIdList(profileTeamIds);
    if (ids.isEmpty) return null;
    return ids.first;
  }

  /// Updates one player's convocation answer atomically (safe under concurrent edits).
  Future<void> updatePlayerConvocationAnswer({
    required String matchId,
    required String teamId,
    required String playerId,
    required bool isPresent,
  }) async {
    final trimmedMatchId = matchId.trim();
    final trimmedTeamId = teamId.trim();
    final trimmedPlayerId = playerId.trim();
    if (trimmedMatchId.isEmpty ||
        trimmedTeamId.isEmpty ||
        trimmedPlayerId.isEmpty) {
      throw ArgumentError('matchId, teamId and playerId are required');
    }

    final existing = await getMatchCompoByMatchAndTeamId(
      trimmedMatchId,
      trimmedTeamId,
    );
    final docRef =
        existing?.ref ?? docRefFor(matchId: trimmedMatchId, teamId: trimmedTeamId);

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);

      final MatchCompo compo;
      if (snap.exists) {
        compo = MatchCompo.fromSnapshot(snap);
      } else {
        compo = MatchCompo(
          matchID: trimmedMatchId,
          teamID: trimmedTeamId,
        );
      }

      final convocations = List<PlayerConvo>.from(compo.convocation ?? const []);
      var updated = false;
      for (final PlayerConvo convo in convocations) {
        if (convo.playerID?.trim() == trimmedPlayerId) {
          convo.isPresent = isPresent;
          convo.asAnswer = true;
          updated = true;
          break;
        }
      }

      if (!updated) {
        convocations.add(
          PlayerConvo(
            playerID: trimmedPlayerId,
            isPresent: isPresent,
            asAnswer: true,
          ),
        );
      }

      transaction.set(
        docRef,
        {
          keyMatchCompoMatchId: trimmedMatchId,
          keyMatchCompoTeamID: trimmedTeamId,
          keyMatchCompoConvocation:
              convocations.map((PlayerConvo c) => c.toMap()).toList(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<MatchCompo?> _loadLegacyMatchCompo({
    required String matchId,
    required String teamId,
  }) async {
    final querySnapshot = await _collection
        .where(keyMatchCompoMatchId, isEqualTo: matchId)
        .where(keyMatchCompoTeamID, isEqualTo: teamId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return MatchCompo.fromSnapshot(querySnapshot.docs.first);
  }
}
