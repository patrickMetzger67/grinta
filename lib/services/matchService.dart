import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/match.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'matchCalendar';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// CREATE
  Future<String> createMatch(Match match) async {
    try {
      final docRef = match.id != null && match.id!.isNotEmpty
          ? _collection.doc(match.id)
          : _collection.doc();

      match.id = docRef.id;

      await docRef.set(match.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// READ ONE
  Future<Match?> getMatchById(String matchId) async {
    try {
      final doc = await _collection.doc(matchId).get();

      if (!doc.exists) return null;

      return Match.fromDocumentSnapshot(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ONE
  Stream<Match?> streamMatchById(String matchId) {
    return _collection.doc(matchId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Match.fromDocumentSnapshot(doc);
    });
  }

  /// GET MATCHES BY TEAM IN teams + withTracker = true + isTrackerDataUploaded = false
  Future<List<Match>> getMatchesToUploadTrackerData(String teamId) async {
    try {
      final query = await _collection
          .where(keyMatchTeams, arrayContains: teamId)
          .where(keyMatchWithTracker, isEqualTo: true)
          .where(keyMatchIsTrackerDataUploaded, isEqualTo: false)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error in getMatchesToUploadTrackerData(teamId: $teamId): '
            '${e.code} - ${e.message}',
      );
      return [];
    } catch (e) {
      debugPrint(
        'Unexpected error in getMatchesToUploadTrackerData(teamId: $teamId): $e',
      );
      return [];
    }
  }
  /// STREAM MATCHES BY TEAM IN teams + withTracker = true + isTrackerDataUploaded = false
  Stream<List<Match>> streamMatchesToUploadTrackerData(String teamId) {
    return _collection
        .where(keyMatchTeams, arrayContains: teamId)
        .where(keyMatchWithTracker, isEqualTo: true)
        .where(keyMatchIsTrackerDataUploaded, isEqualTo: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList())
        .handleError((error) {
      if (error is FirebaseException) {
        debugPrint(
          'Firestore error in streamMatchesToUploadTrackerData(teamId: $teamId): '
              '${error.code} - ${error.message}',
        );
      } else {
        debugPrint(
          'Unexpected error in streamMatchesToUploadTrackerData(teamId: $teamId): $error',
        );
      }
    });
  }

  /// READ ALL
  Future<List<Match>> getAllMatches() async {
    try {
      final query = await _collection.get();
      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ALL
  Stream<List<Match>> streamAllMatches() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    });
  }

  /// UPDATE
  Future<void> updateMatch(Match match) async {
    try {
      if (match.id == null || match.id!.isEmpty) {
        throw Exception("L'id du match est null ou vide.");
      }

      await _collection.doc(match.id).update(match.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE
  Future<void> deleteMatch(String matchId) async {
    try {
      await _collection.doc(matchId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// UPSERT
  Future<void> setMatch(Match match) async {
    try {
      if (match.id == null || match.id!.isEmpty) {
        final docRef = _collection.doc();
        match.id = docRef.id;
        await docRef.set(match.toMap());
      } else {
        await _collection.doc(match.id).set(match.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET BY SEASON ID
  Future<List<Match>> getMatchesBySeason(String seasonId) async {
    try {
      final query = await _collection
          .where(keyMatchSeasonID, isEqualTo: seasonId)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Match>> streamMatchesBySeason(String seasonId) {
    return _collection
        .where(keyMatchSeasonID, isEqualTo: seasonId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList());
  }

  /// GET BY TEAM ID
  Future<List<Match>> getMatchesByTeamId(String teamId) async {
    try {
      final query = await _collection
          .where(keyMatchTeamID, isEqualTo: teamId)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Match>> streamMatchesByTeamId(String teamId) {
    return _collection
        .where(keyMatchTeamID, isEqualTo: teamId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList());
  }

  /// GET BY COMPETITION ID
  Future<List<Match>> getMatchesByCompetitionId(String competitionId) async {
    try {
      final query = await _collection
          .where(keyMatchCompetitionID, isEqualTo: competitionId)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Match>> streamMatchesByCompetitionId(String competitionId) {
    return _collection
        .where(keyMatchCompetitionID, isEqualTo: competitionId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList());
  }

  /// GET BY CLUB ID (array contains)
  Future<List<Match>> getMatchesByClubId(String clubId) async {
    try {
      final query = await _collection
          .where(keyMatchClubs, arrayContains: clubId)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Match>> streamMatchesByClubId(String clubId) {
    return _collection
        .where(keyMatchClubs, arrayContains: clubId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList());
  }

  /// GET BY CLUB WHERE MATCH IS PLAYED
  Future<List<Match>> getMatchesByWhereIsPlayed(String clubId) async {
    try {
      final query = await _collection
          .where(keyMatchWhereMatchIsPlayed, isEqualTo: clubId)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Match>> streamMatchesByWhereIsPlayed(String clubId) {
    return _collection
        .where(keyMatchWhereMatchIsPlayed, isEqualTo: clubId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList());
  }

  /// GET ONLY VISIBLE MATCHES
  Future<List<Match>> getVisibleMatches() async {
    try {
      final query = await _collection
          .where(keyMatchIsMatchVisible, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Match>> streamVisibleMatches() {
    return _collection
        .where(keyMatchIsMatchVisible, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList());
  }

  /// GET HOME MATCHES
  Future<List<Match>> getHomeMatches() async {
    try {
      final query = await _collection
          .where(keyMatchIsOwnClub, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Match>> streamHomeMatches() {
    return _collection
        .where(keyMatchIsOwnClub, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList());
  }

  /// GET PLAYED MATCHES
  Future<List<Match>> getPlayedMatches() async {
    try {
      final query = await _collection
          .where(keyMatchIsMatchPlayed, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Match>> streamPlayedMatches() {
    return _collection
        .where(keyMatchIsMatchPlayed, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList());
  }

  /// GET MATCHES IN HIGHLIGHT
  Future<List<Match>> getHighlightMatches() async {
    try {
      final query = await _collection
          .where(keyMatchIsInHighLight, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Match>> streamHighlightMatches() {
    return _collection
        .where(keyMatchIsInHighLight, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList());
  }

  /// GET MATCHES WITH TRACKER
  Future<List<Match>> getMatchesWithTracker() async {
    try {
      final query = await _collection
          .where(keyMatchWithTracker, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Match>> streamMatchesWithTracker() {
    return _collection
        .where(keyMatchWithTracker, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList());
  }

  /// UPDATE SCORE
  Future<void> updateScore({
    required String matchId,
    required int homeScore,
    required int outsideScore,
    String? tab,
    bool isMatchPlayed = true,
  }) async {
    try {
      await _collection.doc(matchId).update({
        keyMatchHomeScore: homeScore,
        keyMatchOutsideScore: outsideScore,
        keyMatchTab: tab ?? '',
        keyMatchIsMatchPlayed: isMatchPlayed,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE CONVOCATION
  Future<void> updateConvo({
    required String matchId,
    Timestamp? dateTimeConvo,
    String? messageConvo,
    String? addressConvo,
  }) async {
    try {
      await _collection.doc(matchId).update({
        keyMatchDateTimeConvo: dateTimeConvo,
        keyMatchMessageConvo: messageConvo ?? '',
        keyMatchAddressConvo: addressConvo ?? '',
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE LIVE FOLLOWERS
  Future<void> updateLiveFollowers({
    required String matchId,
    required List<dynamic> liveFollowers,
  }) async {
    try {
      await _collection.doc(matchId).update({
        keyMatchLiveFollowers: liveFollowers,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// ADD ONE LIVE FOLLOWER
  Future<void> addLiveFollower({
    required String matchId,
    required dynamic follower,
  }) async {
    try {
      await _collection.doc(matchId).update({
        keyMatchLiveFollowers: FieldValue.arrayUnion([follower]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// REMOVE ONE LIVE FOLLOWER
  Future<void> removeLiveFollower({
    required String matchId,
    required dynamic follower,
  }) async {
    try {
      await _collection.doc(matchId).update({
        keyMatchLiveFollowers: FieldValue.arrayRemove([follower]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE MVP STATUS
  Future<void> updateMvpStatus({
    required String matchId,
    bool? mvpManaged,
    bool? isMvpStarted,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (mvpManaged != null) {
        data[keyMatchMvpManaged] = mvpManaged;
      }
      if (isMvpStarted != null) {
        data[keyMatchIsMvpStarted] = isMvpStarted;
      }

      if (data.isNotEmpty) {
        await _collection.doc(matchId).update(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE TRACKER STATUS
  Future<void> updateTrackerStatus({
    required String matchId,
    bool? withTracker,
    bool? isTrackerDataUploaded,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (withTracker != null) {
        data[keyMatchWithTracker] = withTracker;
      }
      if (isTrackerDataUploaded != null) {
        data[keyMatchIsTrackerDataUploaded] = isTrackerDataUploaded;
      }

      if (data.isNotEmpty) {
        await _collection.doc(matchId).update(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE HIGHLIGHT STATUS
  Future<void> updateHighlightStatus({
    required String matchId,
    required bool isInHighLight,
  }) async {
    try {
      await _collection.doc(matchId).update({
        keyMatchIsInHighLight: isInHighLight,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE VISIBILITY
  Future<void> updateVisibility({
    required String matchId,
    required bool isVisible,
  }) async {
    try {
      await _collection.doc(matchId).update({
        keyMatchIsMatchVisible: isVisible,
      });
    } catch (e) {
      rethrow;
    }
  }
}