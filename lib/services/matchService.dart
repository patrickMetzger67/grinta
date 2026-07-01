import 'dart:async' show StreamSubscription, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/engagement.dart';
import '../model/match.dart';
import 'engagement_service.dart';

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

  Stream<List<Match>> streamMatchesByTeamIdBetweenDates({
    required String teamId,
    required Timestamp start,
    required Timestamp end,
  }) {
    return _collection
        .where(keyMatchTeams, arrayContains: teamId)
        .where(keyMatchTimestamp, isGreaterThanOrEqualTo: start)
        .where(keyMatchTimestamp, isLessThan: end)
        .orderBy(keyMatchTimestamp)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Match.fromDocumentSnapshot(doc))
          .toList();
    });
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
          .where(keyMatchTeams, arrayContains: teamId)
          .get();

      return query.docs.map((doc) => Match.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Match>> getMatchesByTeamIdBetweenDates({
    required String teamId,
    required Timestamp start,
    required Timestamp end,
  }) async {
    try {
      final query = await _collection
          .where(keyMatchTeams, arrayContains: teamId)
          .where(keyMatchTimestamp, isGreaterThanOrEqualTo: start)
          .where(keyMatchTimestamp, isLessThanOrEqualTo: end)
          .get();

      return query.docs
          .map((doc) => Match.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Loads matches for a team by resolving its engagements, then querying
  /// [matchCalendar] with competition/poule/stage and date range. Club
  /// filtering is applied in Dart after the query (not in Firestore).
  ///
  /// When [clubId] is non-empty, only matches whose [clubs] array contains
  /// that id are kept — no fallback to unfiltered competition results.
  ///
  /// Falls back to the legacy [teams] arrayContains query only when no
  /// engagements are found, or when [clubId] is empty and engagement
  /// queries return no matches.
  Future<List<Match>> getMatchesForTeamEngagementsBetweenDates({
    required String teamId,
    required String clubId,
    required Timestamp start,
    required Timestamp end,
    String? seasonId,
    EngagementService? engagementService,
  }) async {
    final service = engagementService ?? EngagementService();
    final engagements = await service.getEngagementsForTeamAgenda(
      teamId: teamId,
      seasonId: seasonId,
    );

    if (kDebugMode) {
      debugPrint(
        'Agenda matches: teamId=$teamId clubId=$clubId '
        'seasonId=${seasonId ?? '(any)'} engagements=${engagements.length}',
      );
    }

    final Map<String, Match> matchesById = <String, Match>{};

    if (engagements.isNotEmpty) {
      await Future.wait(
        engagements.map(
          (engagement) => _loadMatchesForEngagementBetweenDates(
            engagement: engagement,
            clubId: clubId,
            start: start,
            end: end,
            matchesById: matchesById,
          ),
        ),
      );
    }

    final int engagementMatchCount = matchesById.length;
    final String trimmedClubId = clubId.trim();
    final bool shouldUseTeamFallback = trimmedClubId.isEmpty
        ? (engagements.isEmpty || matchesById.isEmpty)
        : engagements.isEmpty;

    if (shouldUseTeamFallback) {
      final List<Match> fallbackMatches =
          await _loadMatchesByTeamIdBetweenDatesFallback(
        teamId: teamId,
        start: start,
        end: end,
      );

      for (final Match match in fallbackMatches) {
        final String? matchId = match.id?.trim();
        if (matchId != null && matchId.isNotEmpty) {
          matchesById[matchId] = match;
        }
      }

      if (kDebugMode) {
        debugPrint(
          'Agenda matches fallback: teamId=$teamId '
          'engagementMatches=$engagementMatchCount '
          'fallbackAdded=${fallbackMatches.length} '
          'total=${matchesById.length}',
        );
      }
    } else if (kDebugMode) {
      debugPrint(
        'Agenda matches: teamId=$teamId engagements=${engagements.length} '
        'matches=${matchesById.length}',
      );
    }

    final List<Match> matches = matchesById.values.toList();
    matches.sort((a, b) {
      final Timestamp? aTs = a.timestamp;
      final Timestamp? bTs = b.timestamp;
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return aTs.compareTo(bTs);
    });
    return matches;
  }

  /// Realtime matches for agenda: resolves engagements, listens to each
  /// competition query, and falls back to the legacy team query when needed.
  Stream<List<Match>> streamMatchesForTeamEngagementsBetweenDates({
    required String teamId,
    required String clubId,
    required Timestamp start,
    required Timestamp end,
    String? seasonId,
    EngagementService? engagementService,
  }) {
    final service = engagementService ?? EngagementService();
    final String trimmedClubId = clubId.trim();

    return Stream<List<Match>>.multi((controller) {
      StreamSubscription<List<Engagement>>? engagementsSub;
      StreamSubscription<List<Match>>? fallbackSub;
      final Map<String, StreamSubscription<List<Match>>> engagementMatchSubs =
          <String, StreamSubscription<List<Match>>>{};
      final Map<String, List<Match>> matchesByEngagementKey =
          <String, List<Match>>{};
      final Set<String> pendingEngagementKeys = <String>{};
      List<Match> fallbackMatches = <Match>[];
      List<Engagement> latestEngagements = <Engagement>[];

      List<Match> buildEngagementMatches() {
        final Map<String, Match> matchesById = <String, Match>{};

        for (final List<Match> matches in matchesByEngagementKey.values) {
          for (final Match match in matches) {
            final String? matchId = match.id?.trim();
            if (matchId != null && matchId.isNotEmpty) {
              matchesById[matchId] = match;
            }
          }
        }

        final List<Match> matches = matchesById.values.toList();
        matches.sort((Match a, Match b) {
          final Timestamp? aTs = a.timestamp;
          final Timestamp? bTs = b.timestamp;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return aTs.compareTo(bTs);
        });
        return matches;
      }

      List<Match> buildMergedMatches() {
        final Map<String, Match> matchesById = <String, Match>{};

        for (final Match match in buildEngagementMatches()) {
          final String? matchId = match.id?.trim();
          if (matchId != null && matchId.isNotEmpty) {
            matchesById[matchId] = match;
          }
        }

        final bool shouldUseTeamFallback = _shouldUseAgendaTeamFallback(
          trimmedClubId: trimmedClubId,
          engagements: latestEngagements,
          engagementMatchCount: matchesById.length,
          pendingEngagementKeys: pendingEngagementKeys,
        );

        if (shouldUseTeamFallback) {
          for (final Match match in fallbackMatches) {
            final String? matchId = match.id?.trim();
            if (matchId != null && matchId.isNotEmpty) {
              matchesById[matchId] = match;
            }
          }
        }

        final List<Match> matches = matchesById.values.toList();
        matches.sort((Match a, Match b) {
          final Timestamp? aTs = a.timestamp;
          final Timestamp? bTs = b.timestamp;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return aTs.compareTo(bTs);
        });
        return matches;
      }

      void emitMerged() {
        controller.add(buildMergedMatches());
      }

      void syncFallbackSubscription() {
        final bool shouldUseTeamFallback = _shouldUseAgendaTeamFallback(
          trimmedClubId: trimmedClubId,
          engagements: latestEngagements,
          engagementMatchCount: buildEngagementMatches().length,
          pendingEngagementKeys: pendingEngagementKeys,
        );

        if (shouldUseTeamFallback) {
          fallbackSub ??= streamMatchesByTeamIdBetweenDates(
            teamId: teamId,
            start: start,
            end: end,
          ).listen(
            (List<Match> matches) {
              fallbackMatches = matches;
              emitMerged();
            },
            onError: controller.addError,
          );
          return;
        }

        if (fallbackSub != null) {
          unawaited(fallbackSub!.cancel());
          fallbackSub = null;
          fallbackMatches = <Match>[];
        }
      }

      void syncEngagementMatchStreams(List<Engagement> engagements) {
        latestEngagements = engagements;
        final Set<String> activeKeys = <String>{};

        for (final Engagement engagement in engagements) {
          final String? engagementDocId = engagement.ref?.id;
          if (engagementDocId == null || engagementDocId.isEmpty) {
            continue;
          }

          activeKeys.add(engagementDocId);

          if (engagementMatchSubs.containsKey(engagementDocId)) {
            continue;
          }

          pendingEngagementKeys.add(engagementDocId);

          final String engagementClubId = engagement.clubId?.trim() ?? '';
          final String resolvedClubId = trimmedClubId.isNotEmpty
              ? trimmedClubId
              : engagementClubId;

          engagementMatchSubs[engagementDocId] =
              _streamEngagementMatchesBetweenDates(
            engagement: engagement,
            clubId: resolvedClubId,
            start: start,
            end: end,
          ).listen(
            (List<Match> matches) {
              pendingEngagementKeys.remove(engagementDocId);
              matchesByEngagementKey[engagementDocId] = matches;
              syncFallbackSubscription();
              emitMerged();
            },
            onError: (Object error) {
              if (error is FirebaseException) {
                debugPrint(
                  'Firestore error streaming matches for engagement '
                  '(engagementId: $engagementDocId): '
                  '${error.code} - ${error.message}',
                );
              } else {
                debugPrint(
                  'Unexpected error streaming matches for engagement '
                  '(engagementId: $engagementDocId): $error',
                );
              }
              pendingEngagementKeys.remove(engagementDocId);
              matchesByEngagementKey[engagementDocId] = <Match>[];
              syncFallbackSubscription();
              emitMerged();
            },
          );
        }

        for (final String key in engagementMatchSubs.keys.toList()) {
          if (!activeKeys.contains(key)) {
            unawaited(engagementMatchSubs.remove(key)?.cancel());
            matchesByEngagementKey.remove(key);
            pendingEngagementKeys.remove(key);
          }
        }

        syncFallbackSubscription();
        emitMerged();
      }

      engagementsSub = service
          .streamEngagementsForTeamAgenda(
            teamId: teamId,
            seasonId: seasonId,
          )
          .listen(
        syncEngagementMatchStreams,
        onError: controller.addError,
      );

      controller.onCancel = () {
        unawaited(engagementsSub?.cancel());
        unawaited(fallbackSub?.cancel());
        for (final StreamSubscription<List<Match>> sub
            in engagementMatchSubs.values) {
          unawaited(sub.cancel());
        }
      };
    });
  }

  bool _shouldUseAgendaTeamFallback({
    required String trimmedClubId,
    required List<Engagement> engagements,
    required int engagementMatchCount,
    required Set<String> pendingEngagementKeys,
  }) {
    if (pendingEngagementKeys.isNotEmpty) {
      return false;
    }

    if (trimmedClubId.isEmpty) {
      return engagements.isEmpty || engagementMatchCount == 0;
    }

    return engagements.isEmpty;
  }

  Stream<List<Match>> _streamEngagementMatchesBetweenDates({
    required Engagement engagement,
    required String clubId,
    required Timestamp start,
    required Timestamp end,
  }) {
    final String competitionId = engagement.competitionId?.trim() ?? '';
    if (competitionId.isEmpty) {
      return Stream<List<Match>>.value(<Match>[]);
    }

    final String group = engagement.group?.trim() ?? '';
    final String stage = engagement.stage?.trim() ?? '';
    final String trimmedClubId = clubId.trim();

    Query<Map<String, dynamic>> query = _collection.where(
      keyMatchCompetitionID,
      isEqualTo: competitionId,
    );

    if (group.isNotEmpty) {
      query = query.where(keyMatchPoule, isEqualTo: group);
    }

    if (stage.isNotEmpty) {
      query = query.where(keyMatchStage, isEqualTo: stage);
    }

    return query
        .where(keyMatchTimestamp, isGreaterThanOrEqualTo: start)
        .where(keyMatchTimestamp, isLessThanOrEqualTo: end)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<Match> matches = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              Match.fromDocumentSnapshot(doc))
          .toList();

      if (trimmedClubId.isEmpty) {
        return matches;
      }

      return matches
          .where((Match match) {
            final List<dynamic>? clubs = match.clubs;
            if (clubs == null || clubs.isEmpty) {
              return false;
            }
            return clubs.any((club) => club?.toString() == trimmedClubId);
          })
          .toList();
    });
  }

  Future<List<Match>> _loadMatchesByTeamIdBetweenDatesFallback({
    required String teamId,
    required Timestamp start,
    required Timestamp end,
  }) async {
    try {
      return await getMatchesByTeamIdBetweenDates(
        teamId: teamId,
        start: start,
        end: end,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error in agenda fallback getMatchesByTeamIdBetweenDates'
        '(teamId: $teamId): ${e.code} - ${e.message}',
      );
      return <Match>[];
    } catch (e) {
      debugPrint(
        'Unexpected error in agenda fallback getMatchesByTeamIdBetweenDates'
        '(teamId: $teamId): $e',
      );
      return <Match>[];
    }
  }

  Future<void> _loadMatchesForEngagementBetweenDates({
    required Engagement engagement,
    required String clubId,
    required Timestamp start,
    required Timestamp end,
    required Map<String, Match> matchesById,
  }) async {
    final String competitionId = engagement.competitionId?.trim() ?? '';
    final String? engagementDocId = engagement.ref?.id;

    if (competitionId.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'Agenda engagement skip: empty competitionId '
          'engagementId=${engagementDocId ?? '(unknown)'} '
          'teamId=${engagement.teamId} teamIds=${engagement.teamIds}',
        );
      }
      return;
    }

    final String group = engagement.group?.trim() ?? '';
    final String stage = engagement.stage?.trim() ?? '';
    final String engagementClubId = engagement.clubId?.trim() ?? '';
    final String trimmedClubId = clubId.trim().isNotEmpty
        ? clubId.trim()
        : engagementClubId;

    final int beforeCount = matchesById.length;

    await _queryEngagementMatchesIntoMap(
      competitionId: competitionId,
      group: group,
      stage: stage,
      clubId: trimmedClubId,
      start: start,
      end: end,
      matchesById: matchesById,
      engagementDocId: engagementDocId,
    );

    final int totalForEngagement = matchesById.length - beforeCount;

    if (kDebugMode) {
      debugPrint(
        'Agenda engagement: id=${engagementDocId ?? '(unknown)'} '
        'competitionId=$competitionId group=${group.isEmpty ? '(any)' : group} '
        'stage=${stage.isEmpty ? '(any)' : stage} '
        'clubId=${trimmedClubId.isEmpty ? '(any)' : trimmedClubId} '
        'total=$totalForEngagement',
      );
    }
  }

  Future<void> _queryEngagementMatchesIntoMap({
    required String competitionId,
    required String group,
    required String stage,
    required String clubId,
    required Timestamp start,
    required Timestamp end,
    required Map<String, Match> matchesById,
    required String? engagementDocId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection.where(
        keyMatchCompetitionID,
        isEqualTo: competitionId,
      );

      if (group.isNotEmpty) {
        query = query.where(keyMatchPoule, isEqualTo: group);
      }

      if (stage.isNotEmpty) {
        query = query.where(keyMatchStage, isEqualTo: stage);
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query
          .where(keyMatchTimestamp, isGreaterThanOrEqualTo: start)
          .where(keyMatchTimestamp, isLessThanOrEqualTo: end)
          .get();

      final List<Match> matches = snapshot.docs
          .map((doc) => Match.fromDocumentSnapshot(doc))
          .toList();

      Iterable<Match> matchesToAdd = matches;
      if (clubId.isNotEmpty) {
        matchesToAdd = matches.where((match) {
          final List<dynamic>? clubs = match.clubs;
          if (clubs == null || clubs.isEmpty) {
            return false;
          }
          return clubs.any((club) => club?.toString() == clubId);
        });
      }

      for (final Match match in matchesToAdd) {
        final String? matchId = match.id?.trim();
        if (matchId != null && matchId.isNotEmpty) {
          matchesById[matchId] = match;
        }
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error loading matches for engagement '
        '(engagementId: ${engagementDocId ?? '(unknown)'}, '
        'competitionId: $competitionId, group: $group, stage: $stage, '
        'clubId: ${clubId.isEmpty ? '(any)' : clubId}): '
        '${e.code} - ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'Unexpected error loading matches for engagement '
        '(engagementId: ${engagementDocId ?? '(unknown)'}, '
        'competitionId: $competitionId): $e',
      );
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
    String? ownerId,
    bool clearOwnerId = false,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (withTracker != null) {
        data[keyMatchWithTracker] = withTracker;
      }
      if (isTrackerDataUploaded != null) {
        data[keyMatchIsTrackerDataUploaded] = isTrackerDataUploaded;
      }
      if (clearOwnerId) {
        data['ownerId'] = FieldValue.delete();
      } else {
        final trimmedOwnerId = ownerId?.trim();
        if (trimmedOwnerId != null && trimmedOwnerId.isNotEmpty) {
          data['ownerId'] = trimmedOwnerId;
        }
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