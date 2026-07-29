import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as match_model;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/screen/coach_workload_analysis/coach_workload_analysis_models.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/player_activity_report_aggregator.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/season_period_ranges.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';
import 'package:grinta/util/training_finish_helper.dart';

/// Builds coach-facing workload summaries for a team over a period.
class CoachWorkloadAnalysisService {
  CoachWorkloadAnalysisService({
    TrainingService? trainingService,
    MatchService? matchService,
    MatchCompoService? matchCompoService,
    HighlightsService? highlightsService,
    TeamWorkloadSummaryService? teamWorkloadSummaryService,
    PersonalSportActivityService? personalSportActivityService,
  })  : _trainingService = trainingService ?? TrainingService(),
        _matchService = matchService ?? MatchService(),
        _matchCompoService = matchCompoService ?? MatchCompoService(),
        _highlightsService = highlightsService ?? HighlightsService(),
        _teamWorkloadSummaryService =
            teamWorkloadSummaryService ?? TeamWorkloadSummaryService(),
        _personalSportService =
            personalSportActivityService ?? PersonalSportActivityService();

  final TrainingService _trainingService;
  final MatchService _matchService;
  final MatchCompoService _matchCompoService;
  final HighlightsService _highlightsService;
  final TeamWorkloadSummaryService _teamWorkloadSummaryService;
  final PersonalSportActivityService _personalSportService;

  static const int _matchBatchSize = 6;
  static const int _personalBatchSize = 6;

  Future<CoachTeamWorkloadReport> loadTeamSummaries({
    required Team team,
    required String seasonId,
    required DateTime start,
    required DateTime end,
    required List<Player> players,
  }) async {
    if (players.isEmpty) {
      return const CoachTeamWorkloadReport(
        summaries: [],
        teamAverages: CoachTeamWorkloadAverages(),
      );
    }

    final teamId = team.keyTeam?.trim() ?? '';
    if (teamId.isEmpty) {
      return const CoachTeamWorkloadReport(
        summaries: [],
        teamAverages: CoachTeamWorkloadAverages(),
      );
    }

    final bounds = _normalizeRange(start: start, end: end);
    final period = SeasonPeriodRange(
      start: bounds.start,
      end: bounds.endInclusive,
    );
    final trainings = await _loadTrainings(
      teamId: teamId,
      seasonId: seasonId,
      period: period,
    );
    final matches = await _loadMatches(
      teamId: teamId,
      period: period,
    );

    final matchStatsByPlayer = await _aggregateMatchStatsByPlayer(
      teamId: teamId,
      matches: matches,
    );
    final trackerByPlayer = await _aggregateTrackerByPlayer(
      trainings: trainings,
      matches: matches,
    );
    final personalByPlayerKey = await _loadPersonalSportsByPlayers(
      players: players,
      start: bounds.start,
      end: bounds.endExclusive,
    );

    final summaries = <CoachPlayerWorkloadSummary>[];
    for (final player in players) {
      final memberId = effectiveMemberId(player)?.trim() ?? '';
      if (memberId.isEmpty) continue;
      final lookupIds = playerMemberLookupIds(player);
      final playerKey = memberId;

      var present = 0;
      var absent = 0;
      var trainingMinutes = 0;
      for (final training in trainings) {
        final presence = _presenceForLookupIds(training, lookupIds);
        if (presence == _Presence.present) {
          present++;
          trainingMinutes += training.duration ?? 0;
        } else if (presence == _Presence.absent) {
          absent++;
        }
      }

      var matchCount = 0;
      var matchMinutes = 0;
      for (final id in lookupIds) {
        final stats = matchStatsByPlayer[id];
        if (stats == null) continue;
        matchCount += stats.convocations;
        matchMinutes += stats.minutesPlayed;
      }

      final personal = personalByPlayerKey[playerKey] ?? const [];
      var personalMinutes = 0;
      var personalDistanceKm = 0.0;
      var hasPersonalDistance = false;
      for (final activity in personal) {
        if (activity.durationSeconds != null && activity.durationSeconds! > 0) {
          personalMinutes += (activity.durationSeconds! / 60).round();
        }
        if (activity.distanceMeters != null && activity.distanceMeters! > 0) {
          personalDistanceKm += activity.distanceMeters! / 1000;
          hasPersonalDistance = true;
        }
      }

      final trackerSessions = <Map<String, double>>[];
      for (final id in lookupIds) {
        trackerSessions.addAll(trackerByPlayer[id] ?? const []);
      }
      final avgWorkload = _averageMetric(
        trackerSessions,
        TeamWorkloadMetricKeys.workloadScore,
      );
      final trackerDistance = _sumMetric(
        trackerSessions,
        TeamWorkloadMetricKeys.distanceKm,
      );
      double? totalDistance;
      if (trackerDistance != null || hasPersonalDistance) {
        totalDistance = (trackerDistance ?? 0) + personalDistanceKm;
      }

      summaries.add(
        CoachPlayerWorkloadSummary(
          player: player,
          memberId: memberId,
          trainingPresent: present,
          trainingAbsent: absent,
          matchCount: matchCount,
          personalSportCount: personal.length,
          volumeMinutes: trainingMinutes + matchMinutes + personalMinutes,
          avgWorkloadScore: avgWorkload,
          totalDistanceKm: totalDistance == null
              ? null
              : double.parse(totalDistance.toStringAsFixed(2)),
        ),
      );
    }

    summaries.sort((a, b) {
      final kmA = a.totalDistanceKm ?? -1;
      final kmB = b.totalDistanceKm ?? -1;
      final byKm = kmB.compareTo(kmA);
      if (byKm != 0) return byKm;
      final loadA = a.avgWorkloadScore ?? -1;
      final loadB = b.avgWorkloadScore ?? -1;
      final byLoad = loadB.compareTo(loadA);
      if (byLoad != 0) return byLoad;
      final nameA = '${a.player.lastName ?? ''} ${a.player.firstName ?? ''}';
      final nameB = '${b.player.lastName ?? ''} ${b.player.firstName ?? ''}';
      return nameA.compareTo(nameB);
    });

    return CoachTeamWorkloadReport(
      summaries: summaries,
      teamAverages: _computeTeamAverages(summaries),
    );
  }

  Future<CoachPlayerWorkloadDetail> loadPlayerDetail({
    required Team team,
    required String seasonId,
    required DateTime start,
    required DateTime end,
    required Player player,
  }) async {
    final teamId = team.keyTeam?.trim() ?? '';
    final memberId = effectiveMemberId(player)?.trim() ?? '';
    final lookupIds = playerMemberLookupIds(player);
    final bounds = _normalizeRange(start: start, end: end);
    final period = SeasonPeriodRange(
      start: bounds.start,
      end: bounds.endInclusive,
    );

    final trainings = teamId.isEmpty
        ? const <Training>[]
        : await _loadTrainings(
            teamId: teamId,
            seasonId: seasonId,
            period: period,
          );
    final matches = teamId.isEmpty
        ? const <match_model.Match>[]
        : await _loadMatches(teamId: teamId, period: period);
    final matchStatsByPlayer = teamId.isEmpty
        ? const <String, TeamPlayerMatchStatsAccumulator>{}
        : await _aggregateMatchStatsByPlayer(teamId: teamId, matches: matches);
    final trackerByEvent = await _loadTrackerByEventId(
      trainings: trainings,
      matches: matches,
    );
    final personal = <PersonalSportActivity>[];
    if (lookupIds.isNotEmpty) {
      final byId = <String, PersonalSportActivity>{};
      for (final id in lookupIds) {
        final items =
            await _personalSportService.fetchNonPrivateOwnedBetweenDates(
          memberId: id,
          start: bounds.start,
          end: bounds.endExclusive,
        );
        for (final activity in items) {
          final activityId = activity.id?.trim();
          if (activityId == null || activityId.isEmpty) continue;
          byId[activityId] = activity;
        }
      }
      personal.addAll(byId.values);
      personal.sort((a, b) => a.startAt.compareTo(b.startAt));
    }

    var present = 0;
    var absent = 0;
    var trainingMinutes = 0;
    final activities = <CoachWorkloadActivityItem>[];

    for (final training in trainings) {
      final presence = _presenceForLookupIds(training, lookupIds);
      if (presence == null) continue;
      final isPresent = presence == _Presence.present;
      if (isPresent) {
        present++;
        trainingMinutes += training.duration ?? 0;
      } else {
        absent++;
      }
      final eventId = training.docId?.trim() ?? '';
      final scores = eventId.isEmpty ? null : trackerByEvent[eventId];
      final playerScore = _scoreForLookupIds(scores, lookupIds);
      final values = playerScore == null
          ? const <String, double>{}
          : trackerValuesFromPlayerScore(playerScore);
      final date = training.dateTime?.toDate() ?? DateTime.now();
      activities.add(
        CoachWorkloadActivityItem(
          kind: CoachWorkloadActivityKind.training,
          startAt: date,
          training: training,
          workloadScore: values[TeamWorkloadMetricKeys.workloadScore],
          distanceKm: values[TeamWorkloadMetricKeys.distanceKm],
          maxValidatedSpeedKmh:
              values[TeamWorkloadMetricKeys.maxValidatedSpeedKmh],
          highAccelerationCount:
              values[TeamWorkloadMetricKeys.highAccelerationCount],
          highSpeedDurationSec:
              values[TeamWorkloadMetricKeys.highSpeedDuration],
          maxAccelerationMps2:
              values[TeamWorkloadMetricKeys.maxAccelerationMps2],
          durationMinutes: training.duration,
          wasPresent: isPresent,
        ),
      );
    }

    var matchCount = 0;
    var matchMinutes = 0;
    for (final id in lookupIds) {
      final stats = matchStatsByPlayer[id];
      if (stats == null) continue;
      matchCount += stats.convocations;
      matchMinutes += stats.minutesPlayed;
    }

    for (final match in matches) {
      final matchId = match.id?.trim() ?? '';
      if (matchId.isEmpty || teamId.isEmpty) continue;
      final compo = await _matchCompoService.getMatchCompoByMatchAndTeamId(
        matchId,
        teamId,
      );
      final highlights = await _highlightsService.getHighlightsByMatchCalendarId(
        matchId,
        teamId: teamId,
      );
      final stats = statsForMatch(
        match: match,
        compo: compo,
        highlights: highlights,
      );
      final playerStats = _statsForLookupIds(stats, lookupIds);
      if (playerStats == null || playerStats.convocations <= 0) continue;

      final scores = trackerByEvent[matchId];
      final playerScore = _scoreForLookupIds(scores, lookupIds);
      final values = playerScore == null
          ? const <String, double>{}
          : trackerValuesFromPlayerScore(playerScore);
      final date = match.timestamp?.toDate() ?? DateTime.now();
      activities.add(
        CoachWorkloadActivityItem(
          kind: CoachWorkloadActivityKind.match,
          startAt: date,
          match: match,
          workloadScore: values[TeamWorkloadMetricKeys.workloadScore],
          distanceKm: values[TeamWorkloadMetricKeys.distanceKm],
          maxValidatedSpeedKmh:
              values[TeamWorkloadMetricKeys.maxValidatedSpeedKmh],
          highAccelerationCount:
              values[TeamWorkloadMetricKeys.highAccelerationCount],
          highSpeedDurationSec:
              values[TeamWorkloadMetricKeys.highSpeedDuration],
          maxAccelerationMps2:
              values[TeamWorkloadMetricKeys.maxAccelerationMps2],
          durationMinutes: playerStats.minutesPlayed,
          wasPresent: true,
        ),
      );
    }

    var personalMinutes = 0;
    var personalDistanceKm = 0.0;
    var hasPersonalDistance = false;
    for (final activity in personal) {
      final minutes = activity.durationSeconds == null
          ? null
          : (activity.durationSeconds! / 60).round();
      if (minutes != null) personalMinutes += minutes;
      final distanceKm = activity.distanceMeters == null
          ? null
          : activity.distanceMeters! / 1000;
      if (distanceKm != null && distanceKm > 0) {
        personalDistanceKm += distanceKm;
        hasPersonalDistance = true;
      }
      activities.add(
        CoachWorkloadActivityItem(
          kind: CoachWorkloadActivityKind.personalSport,
          startAt: activity.startAt,
          personalSport: activity,
          distanceKm: distanceKm,
          durationMinutes: minutes,
          wasPresent: true,
        ),
      );
    }

    activities.sort((a, b) => b.startAt.compareTo(a.startAt));

    final trackerSessions = <Map<String, double>>[];
    for (final entry in trackerByEvent.values) {
      final score = _scoreForLookupIds(entry, lookupIds);
      if (score == null) continue;
      final values = trackerValuesFromPlayerScore(score);
      if (values.isNotEmpty) trackerSessions.add(values);
    }

    final trackerDistance = _sumMetric(
      trackerSessions,
      TeamWorkloadMetricKeys.distanceKm,
    );
    double? totalDistance;
    if (trackerDistance != null || hasPersonalDistance) {
      totalDistance = (trackerDistance ?? 0) + personalDistanceKm;
    }

    final summary = CoachPlayerWorkloadSummary(
      player: player,
      memberId: memberId,
      trainingPresent: present,
      trainingAbsent: absent,
      matchCount: matchCount,
      personalSportCount: personal.length,
      volumeMinutes: trainingMinutes + matchMinutes + personalMinutes,
      avgWorkloadScore: _averageMetric(
        trackerSessions,
        TeamWorkloadMetricKeys.workloadScore,
      ),
      totalDistanceKm: totalDistance == null
          ? null
          : double.parse(totalDistance.toStringAsFixed(2)),
    );

    return CoachPlayerWorkloadDetail(
      summary: summary,
      activities: activities,
    );
  }

  Future<List<Training>> _loadTrainings({
    required String teamId,
    required String seasonId,
    required SeasonPeriodRange period,
  }) async {
    final start = Timestamp.fromDate(
      DateTime(period.start.year, period.start.month, period.start.day),
    );
    final endExclusive = Timestamp.fromDate(
      DateTime(period.end.year, period.end.month, period.end.day)
          .add(const Duration(days: 1)),
    );
    final trainings = await _trainingService.getTrainingsByTeamIdBetweenDates(
      teamId: teamId,
      start: start,
      end: endExclusive,
    );
    return trainings.where((training) {
      // Planned / not-yet-finished sessions must not count in Analyse charge.
      if (!isTrainingFinished(training)) {
        return false;
      }
      final trainingSeasonId = training.seasonId?.trim() ?? '';
      if (trainingSeasonId.isNotEmpty && trainingSeasonId != seasonId) {
        return false;
      }
      final date = training.dateTime?.toDate();
      if (date == null) return false;
      return period.contains(date);
    }).toList();
  }

  Future<List<match_model.Match>> _loadMatches({
    required String teamId,
    required SeasonPeriodRange period,
  }) async {
    final start = Timestamp.fromDate(
      DateTime(period.start.year, period.start.month, period.start.day),
    );
    final endExclusive = Timestamp.fromDate(
      DateTime(period.end.year, period.end.month, period.end.day)
          .add(const Duration(days: 1)),
    );
    final matches = await _matchService.getMatchesByTeamIdBetweenDates(
      teamId: teamId,
      start: start,
      end: endExclusive,
    );
    return matches.where((match) {
      final date = match.timestamp?.toDate();
      if (date == null) return false;
      return period.contains(date);
    }).toList();
  }

  Future<Map<String, TeamPlayerMatchStatsAccumulator>>
      _aggregateMatchStatsByPlayer({
    required String teamId,
    required List<match_model.Match> matches,
  }) async {
    final byPlayer = <String, TeamPlayerMatchStatsAccumulator>{};
    for (var i = 0; i < matches.length; i += _matchBatchSize) {
      final batch = matches.skip(i).take(_matchBatchSize).toList();
      final results = await Future.wait(
        batch.map((match) async {
          final matchId = match.id?.trim() ?? '';
          if (matchId.isEmpty) {
            return const <String, TeamPlayerMatchStatsAccumulator>{};
          }
          final loaded = await Future.wait([
            _matchCompoService.getMatchCompoByMatchAndTeamId(matchId, teamId),
            _highlightsService.getHighlightsByMatchCalendarId(
              matchId,
              teamId: teamId,
            ),
          ]);
          return statsForMatch(
            match: match,
            compo: loaded[0] as MatchCompo?,
            highlights: loaded[1] as List<Highlights>,
          );
        }),
      );
      for (final stats in results) {
        for (final entry in stats.entries) {
          final key = entry.key.trim();
          if (key.isEmpty) continue;
          final acc = byPlayer.putIfAbsent(
            key,
            () => TeamPlayerMatchStatsAccumulator(playerId: key),
          );
          acc.merge(entry.value);
        }
      }
    }
    return byPlayer;
  }

  Future<Map<String, List<Map<String, double>>>> _aggregateTrackerByPlayer({
    required List<Training> trainings,
    required List<match_model.Match> matches,
  }) async {
    final byPlayer = <String, List<Map<String, double>>>{};
    final eventIds = <String>{
      for (final t in trainings)
        if (t.withTracker == true && (t.docId?.trim().isNotEmpty ?? false))
          t.docId!.trim(),
      for (final m in matches)
        if (m.withTracker == true && (m.id?.trim().isNotEmpty ?? false))
          m.id!.trim(),
    };

    for (final eventId in eventIds) {
      final summary = await _teamWorkloadSummaryService.getByEventId(eventId);
      if (summary == null) continue;
      for (final score in summary.playerScores) {
        final playerId = score.playerId.trim();
        if (playerId.isEmpty) continue;
        final values = trackerValuesFromPlayerScore(score);
        if (values.isEmpty) continue;
        byPlayer.putIfAbsent(playerId, () => <Map<String, double>>[]).add(values);
      }
    }
    return byPlayer;
  }

  Future<Map<String, TeamWorkloadSummary?>> _loadTrackerByEventId({
    required List<Training> trainings,
    required List<match_model.Match> matches,
  }) async {
    final eventIds = <String>{
      for (final t in trainings)
        if (t.withTracker == true && (t.docId?.trim().isNotEmpty ?? false))
          t.docId!.trim(),
      for (final m in matches)
        if (m.withTracker == true && (m.id?.trim().isNotEmpty ?? false))
          m.id!.trim(),
    };
    final out = <String, TeamWorkloadSummary?>{};
    for (final eventId in eventIds) {
      out[eventId] = await _teamWorkloadSummaryService.getByEventId(eventId);
    }
    return out;
  }

  /// Normalizes analysis ranges.
  ///
  /// Callers pass `[start, end)` where [end] is exclusive (next day at 00:00),
  /// matching [CoachWorkloadAnalysisScreen].
  ({DateTime start, DateTime endInclusive, DateTime endExclusive})
      _normalizeRange({
    required DateTime start,
    required DateTime end,
  }) {
    final startDay = DateTime(start.year, start.month, start.day);
    // Midnight → exclusive bound as-is; any later time → next calendar day.
    final DateTime endExclusive = (end.hour == 0 &&
            end.minute == 0 &&
            end.second == 0 &&
            end.millisecond == 0)
        ? DateTime(end.year, end.month, end.day)
        : DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
    final safeEndExclusive = endExclusive.isAfter(startDay)
        ? endExclusive
        : startDay.add(const Duration(days: 1));
    final endInclusive = safeEndExclusive.subtract(const Duration(days: 1));
    return (
      start: startDay,
      endInclusive: endInclusive,
      endExclusive: safeEndExclusive,
    );
  }

  /// Loads non-private personal sports for each player, trying all member
  /// lookup aliases so roster id mismatches still resolve.
  Future<Map<String, List<PersonalSportActivity>>> _loadPersonalSportsByPlayers({
    required List<Player> players,
    required DateTime start,
    required DateTime end,
  }) async {
    final out = <String, List<PersonalSportActivity>>{};

    for (var i = 0; i < players.length; i += _personalBatchSize) {
      final batch = players.skip(i).take(_personalBatchSize).toList();
      final results = await Future.wait(
        batch.map((player) async {
          final memberId = effectiveMemberId(player)?.trim() ?? '';
          if (memberId.isEmpty) {
            return MapEntry(memberId, const <PersonalSportActivity>[]);
          }
          final lookupIds = playerMemberLookupIds(player);
          final byId = <String, PersonalSportActivity>{};
          for (final id in lookupIds) {
            final items =
                await _personalSportService.fetchNonPrivateOwnedBetweenDates(
              memberId: id,
              start: start,
              end: end,
            );
            for (final activity in items) {
              final activityId = activity.id?.trim();
              if (activityId == null || activityId.isEmpty) continue;
              byId[activityId] = activity;
            }
          }
          final merged = byId.values.toList()
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
          return MapEntry(memberId, merged);
        }),
      );
      for (final entry in results) {
        if (entry.key.isEmpty) continue;
        out[entry.key] = entry.value;
      }
    }
    return out;
  }

  TeamPlayerMetricScores? _scoreForLookupIds(
    TeamWorkloadSummary? summary,
    Set<String> lookupIds,
  ) {
    if (summary == null) return null;
    for (final score in summary.playerScores) {
      if (lookupIds.contains(score.playerId.trim())) return score;
    }
    return null;
  }

  TeamPlayerMatchStatsAccumulator? _statsForLookupIds(
    Map<String, TeamPlayerMatchStatsAccumulator> stats,
    Set<String> lookupIds,
  ) {
    TeamPlayerMatchStatsAccumulator? found;
    for (final entry in stats.entries) {
      if (!lookupIds.contains(entry.key.trim())) continue;
      found ??= TeamPlayerMatchStatsAccumulator(playerId: entry.key);
      found.merge(entry.value);
    }
    return found;
  }

  _Presence? _presenceForLookupIds(Training training, Set<String> lookupIds) {
    for (final playerTraining in training.playerTraining) {
      final memberId = playerTraining.playerId?.trim() ?? '';
      if (memberId.isEmpty || !lookupIds.contains(memberId)) continue;
      final type = playerTraining.presenceType;
      if (type == PresenceType.present || type == PresenceType.late) {
        return _Presence.present;
      }
      if (type == PresenceType.absent) {
        return _Presence.absent;
      }
      return null;
    }
    return null;
  }

  double? _averageMetric(List<Map<String, double>> sessions, String key) {
    var sum = 0.0;
    var count = 0;
    for (final session in sessions) {
      final value = session[key];
      if (value == null || !value.isFinite) continue;
      sum += value;
      count++;
    }
    if (count == 0) return null;
    return double.parse((sum / count).toStringAsFixed(1));
  }

  double? _sumMetric(List<Map<String, double>> sessions, String key) {
    var sum = 0.0;
    var count = 0;
    for (final session in sessions) {
      final value = session[key];
      if (value == null || !value.isFinite) continue;
      sum += value;
      count++;
    }
    if (count == 0) return null;
    return sum;
  }

  CoachTeamWorkloadAverages _computeTeamAverages(
    List<CoachPlayerWorkloadSummary> summaries,
  ) {
    if (summaries.isEmpty) {
      return const CoachTeamWorkloadAverages();
    }

    double? avg(Iterable<double> values) {
      final list = values.toList();
      if (list.isEmpty) return null;
      final sum = list.fold<double>(0, (a, b) => a + b);
      return sum / list.length;
    }

    return CoachTeamWorkloadAverages(
      avgWorkloadScore: avg([
        for (final s in summaries)
          if (s.avgWorkloadScore != null) s.avgWorkloadScore!,
      ]),
      totalDistanceKm: avg([
        for (final s in summaries)
          if (s.totalDistanceKm != null) s.totalDistanceKm!,
      ]),
      sessionCount: avg([
        for (final s in summaries) s.sessionCount.toDouble(),
      ]),
      trainingCount: avg([
        for (final s in summaries) s.trainingPresent.toDouble(),
      ]),
      matchCount: avg([
        for (final s in summaries) s.matchCount.toDouble(),
      ]),
      presencePercent: avg([
        for (final s in summaries)
          if (s.presencePercent != null) s.presencePercent!,
      ]),
      volumeMinutes: avg([
        for (final s in summaries) s.volumeMinutes.toDouble(),
      ]),
    );
  }
}

enum _Presence { present, absent }
