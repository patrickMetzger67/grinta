import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/matchCompo.dart';
import '../util/match_compo_pitch_mapper.dart';

String collectionMatchCompo = "matchCompo";

class MatchCompoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection =>
      _firestore.collection(collectionMatchCompo);

  Future<DocumentReference> addMatchCompo(MatchCompo matchCompo) async {
    return await _collection.add(matchCompo.toMap());
  }

  Future<void> updateMatchCompo(MatchCompo matchCompo) async {
    if (matchCompo.ref == null) {
      throw Exception("La référence du MatchCompo est nulle");
    }

    await matchCompo.ref!.update(matchCompo.toMap());
  }

  Future<void> saveMatchCompo(MatchCompo matchCompo) async {
    if (matchCompo.ref == null) {
      final docRef = await addMatchCompo(matchCompo);
      matchCompo.ref = docRef;
    } else {
      await updateMatchCompo(matchCompo);
    }
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
    final compos = await getMatchComposByMatchId(matchId);
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
    return streamMatchComposByMatchId(matchId).map((List<MatchCompo> compos) {
      return pickMatchCompoForProfileTeams(
        compos,
        profileTeamIds: profileTeamIds,
        preferredTeamId: preferredTeamId,
      );
    });
  }
}