import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/pred_game_day.dart';
import '../util/prediction_game_helper.dart';

class PredGameDayClosedException implements Exception {
  const PredGameDayClosedException();
}

class PredGameDayIncompletePicksException implements Exception {
  const PredGameDayIncompletePicksException();
}

class PredGameDayService {
  PredGameDayService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'predGameDay';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<PredGameDay?> getById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;

    final snapshot = await _collection.doc(trimmed).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return PredGameDay.fromDocumentSnapshot(snapshot);
  }

  Stream<PredGameDay?> streamById(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return Stream<PredGameDay?>.value(null);
    }

    return _collection.doc(trimmed).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return PredGameDay.fromDocumentSnapshot(snapshot);
    });
  }

  /// Latest contest for [teamId], optionally restricted to [engagementId].
  Future<PredGameDay?> getLatestForTeam({
    required String teamId,
    String? engagementId,
  }) async {
    final trimmedTeamId = teamId.trim();
    if (trimmedTeamId.isEmpty) return null;

    Query<Map<String, dynamic>> query =
        _collection.where(keyPredGameDayTeamId, isEqualTo: trimmedTeamId);

    final trimmedEngagementId = engagementId?.trim() ?? '';
    if (trimmedEngagementId.isNotEmpty) {
      query = query.where(
        keyPredGameDayEngagementId,
        isEqualTo: trimmedEngagementId,
      );
    }

    final snapshot =
        await query.orderBy(keyPredGameDayDay, descending: true).limit(8).get();

    if (snapshot.docs.isEmpty) return null;

    final contests = snapshot.docs
        .map(PredGameDay.fromDocumentSnapshot)
        .toList();
    return pickPreferredContest(contests, DateTime.now());
  }

  Stream<PredGameDay?> streamLatestForTeam({
    required String teamId,
    String? engagementId,
  }) {
    final trimmedTeamId = teamId.trim();
    if (trimmedTeamId.isEmpty) {
      return Stream<PredGameDay?>.value(null);
    }

    Query<Map<String, dynamic>> query =
        _collection.where(keyPredGameDayTeamId, isEqualTo: trimmedTeamId);

    final trimmedEngagementId = engagementId?.trim() ?? '';
    if (trimmedEngagementId.isNotEmpty) {
      query = query.where(
        keyPredGameDayEngagementId,
        isEqualTo: trimmedEngagementId,
      );
    }

    return query
        .orderBy(keyPredGameDayDay, descending: true)
        .limit(8)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final contests = snapshot.docs
          .map(PredGameDay.fromDocumentSnapshot)
          .toList();
      return pickPreferredContest(contests, DateTime.now());
    });
  }

  /// Prefers the open contest with the soonest deadline, else the latest day.
  static PredGameDay? pickPreferredContest(
    List<PredGameDay> contests,
    DateTime now,
  ) {
    if (contests.isEmpty) return null;

    PredGameDay? openSoonest;
    for (final contest in contests) {
      if (!contest.isOpenAt(now)) continue;
      if (openSoonest == null) {
        openSoonest = contest;
        continue;
      }
      final current = contest.closesAt;
      final best = openSoonest.closesAt;
      if (current != null && (best == null || current.isBefore(best))) {
        openSoonest = contest;
      }
    }
    if (openSoonest != null) return openSoonest;

    final sorted = List<PredGameDay>.from(contests)
      ..sort((a, b) => b.day.compareTo(a.day));
    return sorted.first;
  }

  Future<void> submitEntry({
    required String contestId,
    required String playerId,
    required String userId,
    required Map<String, int> picks,
    DateTime? now,
  }) async {
    final trimmedContestId = contestId.trim();
    final trimmedPlayerId = playerId.trim();
    final trimmedUserId = userId.trim();
    if (trimmedContestId.isEmpty ||
        trimmedPlayerId.isEmpty ||
        trimmedUserId.isEmpty) {
      throw ArgumentError('contestId, playerId and userId are required');
    }

    final contest = await getById(trimmedContestId);
    if (contest == null) {
      throw StateError('predGameDay not found: $trimmedContestId');
    }

    final at = now ?? DateTime.now();
    if (!contest.isOpenAt(at)) {
      throw const PredGameDayClosedException();
    }

    final requiredIds = contest.matchIds.isNotEmpty
        ? contest.matchIds
        : contest.fixtures.map((f) => f.matchId).toList();
    for (final matchId in requiredIds) {
      if (!isValidPredictionPick(picks[matchId])) {
        throw const PredGameDayIncompletePicksException();
      }
    }

    final sanitized = <String, int>{};
    for (final matchId in requiredIds) {
      sanitized[matchId] = picks[matchId]!;
    }

    await _collection.doc(trimmedContestId).update(<String, dynamic>{
      '$keyPredGameDayEntries.$trimmedPlayerId': <String, dynamic>{
        keyPredGameDayEntryUserId: trimmedUserId,
        keyPredGameDayEntryPlayerId: trimmedPlayerId,
        keyPredGameDayEntryPicks: sanitized,
        keyPredGameDayEntrySubmittedAt: FieldValue.serverTimestamp(),
      },
    });
  }
}
