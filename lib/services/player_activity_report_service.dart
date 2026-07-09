import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/player_chat_stats_service.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/services/team_training_stats_service.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/ask_diego_activity_period.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_activity_report_aggregator.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/season_period_ranges.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';

/// Builds a player activity report for Ask Gio (trainings, matches, tracker).
class PlayerActivityReportService {
  PlayerActivityReportService({
    TeamCompetitionStatsService? teamCompetitionStatsService,
    MatchCompoService? matchCompoService,
    HighlightsService? highlightsService,
    TrainingService? trainingService,
    TeamWorkloadSummaryService? teamWorkloadSummaryService,
  })  : _teamCompetitionStatsService =
            teamCompetitionStatsService ?? TeamCompetitionStatsService(),
        _matchCompoService = matchCompoService ?? MatchCompoService(),
        _highlightsService = highlightsService ?? HighlightsService(),
        _trainingService = trainingService ?? TrainingService(),
        _teamWorkloadSummaryService =
            teamWorkloadSummaryService ?? TeamWorkloadSummaryService();

  final TeamCompetitionStatsService _teamCompetitionStatsService;
  final MatchCompoService _matchCompoService;
  final HighlightsService _highlightsService;
  final TrainingService _trainingService;
  final TeamWorkloadSummaryService _teamWorkloadSummaryService;

  static const int _matchBatchSize = 8;

  Future<Map<String, dynamic>> buildActivityReport({
    required AppSession session,
    required AskDiegoActivityPeriod period,
    required String localeCode,
  }) async {
    final playerId = session.selectedPlayerId?.trim();
    final player = session.selectedPlayer;
    final seasonId = (session.selectedSeason?.ref?.id ?? '').trim();
    final playerName = player == null ? null : playerDisplayName(player);

    if (playerId == null ||
        playerId.isEmpty ||
        player == null ||
        seasonId.isEmpty) {
      return _unavailableReport(
        period: period,
        playerId: playerId,
        playerName: playerName,
        reason: 'missing_session_player_or_season',
      );
    }

    final teams = PlayerChatStatsService.resolveTeamsForPlayerStats(session);
    if (teams.isEmpty) {
      return _unavailableReport(
        period: period,
        playerId: playerId,
        playerName: playerName,
        reason: 'no_roster_teams_for_season',
      );
    }

    final lookupIds = playerMemberLookupIds(player);
    if (lookupIds.isEmpty) {
      return _unavailableReport(
        period: period,
        playerId: playerId,
        playerName: playerName,
        reason: 'missing_player_member_ids',
      );
    }

    final previousPeriod = period.previousPeriod(localeCode);
    final range = SeasonPeriodRange(start: period.start, end: period.end);
    final previousRange = SeasonPeriodRange(
      start: previousPeriod.start,
      end: previousPeriod.end,
    );

    var present = 0;
    var absent = 0;
    var matchCount = 0;
    var totalMinutes = 0;
    final trackerSessions = <PlayerTrackerSessionMetrics>[];

    await Future.wait(
      teams.map(
        (Team team) => _aggregateTeamActivity(
          team: team,
          seasonId: seasonId,
          period: range,
          lookupIds: lookupIds,
          onTrainingPresent: () => present++,
          onTrainingAbsent: () => absent++,
          onMatch: ({required int minutes}) {
            matchCount++;
            totalMinutes += minutes;
          },
          trackerSessions: trackerSessions,
        ),
      ),
    );

    final previousTrackerSessions = <PlayerTrackerSessionMetrics>[];
    await Future.wait(
      teams.map(
        (Team team) => _aggregateTrackerSessionsForTeam(
          team: team,
          seasonId: seasonId,
          period: previousRange,
          lookupIds: lookupIds,
          trackerSessions: previousTrackerSessions,
        ),
      ),
    );

    final trainingTrackerSessions = trackerSessions
        .where((PlayerTrackerSessionMetrics s) => s.eventType == 'training')
        .toList();
    final matchTrackerSessions = trackerSessions
        .where((PlayerTrackerSessionMetrics s) => s.eventType == 'match')
        .toList();

    final previousTrainingTrackerSessions = previousTrackerSessions
        .where((PlayerTrackerSessionMetrics s) => s.eventType == 'training')
        .toList();
    final previousMatchTrackerSessions = previousTrackerSessions
        .where((PlayerTrackerSessionMetrics s) => s.eventType == 'match')
        .toList();

    final trainingAverages =
        aggregateTrackerSessionMetrics(trainingTrackerSessions);
    final matchAverages = aggregateTrackerSessionMetrics(matchTrackerSessions);
    final previousTrainingAverages =
        aggregateTrackerSessionMetrics(previousTrainingTrackerSessions);
    final previousMatchAverages =
        aggregateTrackerSessionMetrics(previousMatchTrackerSessions);

    final attendanceTotal = present + absent;
    final attendanceRate = playerTrainingAttendanceRate(
      presentCount: present,
      absentCount: absent,
    );

    return <String, dynamic>{
      'period': period.toJson(),
      'previousPeriod': previousPeriod.toJson(),
      'playerId': playerId,
      'playerName': playerName,
      'seasonId': seasonId,
      'trainings': <String, dynamic>{
        'present': present,
        'absent': absent,
        'totalWithPresenceMarked': attendanceTotal,
        'ratePercent': attendanceRate,
      },
      'matches': <String, dynamic>{
        'count': matchCount,
        'totalMinutes': totalMinutes,
        'averageMinutes': matchCount > 0 ? totalMinutes / matchCount : null,
      },
      'trackerPerformance': <String, dynamic>{
        'trainings': trainingAverages.toJson(),
        'matches': matchAverages.toJson(),
        'trendsVsPreviousPeriod': <String, dynamic>{
          'training': trackerTrendsToJson(
            computeTrackerTrends(
              current: trainingAverages,
              previous: previousTrainingAverages,
            ),
          ),
          'match': trackerTrendsToJson(
            computeTrackerTrends(
              current: matchAverages,
              previous: previousMatchAverages,
            ),
          ),
        },
      },
    };
  }

  Future<void> _aggregateTeamActivity({
    required Team team,
    required String seasonId,
    required SeasonPeriodRange period,
    required Set<String> lookupIds,
    required void Function() onTrainingPresent,
    required void Function() onTrainingAbsent,
    required void Function({required int minutes}) onMatch,
    required List<PlayerTrackerSessionMetrics> trackerSessions,
  }) async {
    final teamId = team.keyTeam?.trim() ?? '';
    if (teamId.isEmpty) {
      return;
    }

    await Future.wait([
      _aggregateTrainingActivityForTeam(
        teamId: teamId,
        seasonId: seasonId,
        period: period,
        lookupIds: lookupIds,
        onPresent: onTrainingPresent,
        onAbsent: onTrainingAbsent,
        trackerSessions: trackerSessions,
      ),
      _aggregateMatchActivityForTeam(
        team: team,
        seasonId: seasonId,
        period: period,
        lookupIds: lookupIds,
        onMatch: onMatch,
        trackerSessions: trackerSessions,
      ),
    ]);
  }

  Future<void> _aggregateTrainingActivityForTeam({
    required String teamId,
    required String seasonId,
    required SeasonPeriodRange period,
    required Set<String> lookupIds,
    required void Function() onPresent,
    required void Function() onAbsent,
    required List<PlayerTrackerSessionMetrics> trackerSessions,
  }) async {
    final trainings = await loadPastTrainingsForTeamSeason(
      trainingService: _trainingService,
      teamId: teamId,
      seasonId: seasonId,
      period: period,
    );

    for (final training in trainings) {
      final trainingDate = trainingDateForStats(training);
      if (trainingDate == null || !period.contains(trainingDate)) {
        continue;
      }

      final presence = _presenceForLookupIds(
        training: training,
        lookupIds: lookupIds,
      );
      if (presence == _TrainingPresence.present) {
        onPresent();
      } else if (presence == _TrainingPresence.absent) {
        onAbsent();
      }

      if (training.withTracker == true) {
        final eventId = training.docId?.trim() ?? '';
        if (eventId.isNotEmpty) {
          await _appendTrackerSessionIfFound(
            eventId: eventId,
            eventType: 'training',
            lookupIds: lookupIds,
            trackerSessions: trackerSessions,
          );
        }
      }
    }
  }

  Future<void> _aggregateMatchActivityForTeam({
    required Team team,
    required String seasonId,
    required SeasonPeriodRange period,
    required Set<String> lookupIds,
    required void Function({required int minutes}) onMatch,
    required List<PlayerTrackerSessionMetrics> trackerSessions,
  }) async {
    final teamId = team.keyTeam?.trim() ?? '';
    if (teamId.isEmpty) {
      return;
    }

    final matches = await _teamCompetitionStatsService.loadPlayedSeasonMatches(
      team: team,
      seasonId: seasonId,
    );

    for (var i = 0; i < matches.length; i += _matchBatchSize) {
      final batch = matches.skip(i).take(_matchBatchSize).toList();
      final batchResults = await Future.wait(
        batch.map((match) => _loadMatchStats(match: match, teamId: teamId)),
      );

      for (var j = 0; j < batch.length; j++) {
        final match = batch[j];
        final matchDate = matchDateForTeamStats(match);
        if (matchDate == null || !period.contains(matchDate)) {
          continue;
        }

        final playerStats = _statsForLookupIds(
          matchStats: batchResults[j],
          lookupIds: lookupIds,
        );
        if (playerStats == null || playerStats.convocations <= 0) {
          continue;
        }

        onMatch(minutes: playerStats.minutesPlayed);

        if (match.withTracker == true) {
          final eventId = match.id?.trim() ?? '';
          if (eventId.isNotEmpty) {
            await _appendTrackerSessionIfFound(
              eventId: eventId,
              eventType: 'match',
              lookupIds: lookupIds,
              trackerSessions: trackerSessions,
            );
          }
        }
      }
    }
  }

  Future<void> _aggregateTrackerSessionsForTeam({
    required Team team,
    required String seasonId,
    required SeasonPeriodRange period,
    required Set<String> lookupIds,
    required List<PlayerTrackerSessionMetrics> trackerSessions,
  }) async {
    final teamId = team.keyTeam?.trim() ?? '';
    if (teamId.isEmpty) {
      return;
    }

    final trainings = await loadPastTrainingsForTeamSeason(
      trainingService: _trainingService,
      teamId: teamId,
      seasonId: seasonId,
      period: period,
    );

    for (final training in trainings) {
      if (training.withTracker != true) {
        continue;
      }
      final trainingDate = trainingDateForStats(training);
      if (trainingDate == null || !period.contains(trainingDate)) {
        continue;
      }
      final eventId = training.docId?.trim() ?? '';
      if (eventId.isEmpty) {
        continue;
      }
      await _appendTrackerSessionIfFound(
        eventId: eventId,
        eventType: 'training',
        lookupIds: lookupIds,
        trackerSessions: trackerSessions,
      );
    }

    final matches = await _teamCompetitionStatsService.loadPlayedSeasonMatches(
      team: team,
      seasonId: seasonId,
    );

    for (var i = 0; i < matches.length; i += _matchBatchSize) {
      final batch = matches.skip(i).take(_matchBatchSize).toList();
      final batchResults = await Future.wait(
        batch.map((match) => _loadMatchStats(match: match, teamId: teamId)),
      );

      for (var j = 0; j < batch.length; j++) {
        final match = batch[j];
        if (match.withTracker != true) {
          continue;
        }
        final matchDate = matchDateForTeamStats(match);
        if (matchDate == null || !period.contains(matchDate)) {
          continue;
        }
        final playerStats = _statsForLookupIds(
          matchStats: batchResults[j],
          lookupIds: lookupIds,
        );
        if (playerStats == null || playerStats.convocations <= 0) {
          continue;
        }
        final eventId = match.id?.trim() ?? '';
        if (eventId.isEmpty) {
          continue;
        }
        await _appendTrackerSessionIfFound(
          eventId: eventId,
          eventType: 'match',
          lookupIds: lookupIds,
          trackerSessions: trackerSessions,
        );
      }
    }
  }

  Future<void> _appendTrackerSessionIfFound({
    required String eventId,
    required String eventType,
    required Set<String> lookupIds,
    required List<PlayerTrackerSessionMetrics> trackerSessions,
  }) async {
    if (trackerSessions.any(
      (PlayerTrackerSessionMetrics session) => session.eventId == eventId,
    )) {
      return;
    }

    final summary = await _teamWorkloadSummaryService.getByEventId(eventId);
    if (summary == null) {
      return;
    }

    for (final playerScore in summary.playerScores) {
      if (!lookupIds.contains(playerScore.playerId.trim())) {
        continue;
      }
      final values = trackerValuesFromPlayerScore(playerScore);
      if (values.isEmpty) {
        continue;
      }
      trackerSessions.add(
        PlayerTrackerSessionMetrics(
          eventId: eventId,
          eventType: eventType,
          values: values,
        ),
      );
      return;
    }
  }

  TeamPlayerMatchStatsAccumulator? _statsForLookupIds({
    required Map<String, TeamPlayerMatchStatsAccumulator> matchStats,
    required Set<String> lookupIds,
  }) {
    TeamPlayerMatchStatsAccumulator? found;
    for (final entry in matchStats.entries) {
      if (!lookupIds.contains(entry.key.trim())) {
        continue;
      }
      found ??= TeamPlayerMatchStatsAccumulator(playerId: entry.key);
      found.merge(entry.value);
    }
    return found;
  }

  _TrainingPresence? _presenceForLookupIds({
    required Training training,
    required Set<String> lookupIds,
  }) {
    for (final playerTraining in training.playerTraining) {
      final memberId = playerTraining.playerId?.trim() ?? '';
      if (memberId.isEmpty || !lookupIds.contains(memberId)) {
        continue;
      }

      if (_isPresent(playerTraining.presenceType)) {
        return _TrainingPresence.present;
      }
      if (_isAbsent(playerTraining.presenceType)) {
        return _TrainingPresence.absent;
      }
      return null;
    }
    return null;
  }

  bool _isPresent(PresenceType? type) {
    return type == PresenceType.present || type == PresenceType.late;
  }

  bool _isAbsent(PresenceType? type) {
    return type == PresenceType.absent;
  }

  Future<Map<String, TeamPlayerMatchStatsAccumulator>> _loadMatchStats({
    required Match match,
    required String teamId,
  }) async {
    final matchId = match.id?.trim() ?? '';
    if (matchId.isEmpty) {
      return const {};
    }

    final results = await Future.wait([
      _matchCompoService.getMatchCompoByMatchAndTeamId(matchId, teamId),
      _highlightsService.getHighlightsByMatchCalendarId(
        matchId,
        teamId: teamId,
      ),
    ]);

    return statsForMatch(
      match: match,
      compo: results[0] as MatchCompo?,
      highlights: results[1] as List<Highlights>,
    );
  }

  Map<String, dynamic> _unavailableReport({
    required AskDiegoActivityPeriod period,
    required String? playerId,
    required String? playerName,
    required String reason,
  }) {
    return <String, dynamic>{
      'period': period.toJson(),
      'playerId': playerId,
      'playerName': playerName,
      'dataUnavailableReason': reason,
      'trainings': <String, dynamic>{
        'present': 0,
        'absent': 0,
        'totalWithPresenceMarked': 0,
        'ratePercent': null,
      },
      'matches': <String, dynamic>{
        'count': 0,
        'totalMinutes': 0,
        'averageMinutes': null,
      },
      'trackerPerformance': <String, dynamic>{
        'trainings': const PlayerTrackerMetricAverages(
          sessionsWithData: 0,
          averages: <String, double>{},
        ).toJson(),
        'matches': const PlayerTrackerMetricAverages(
          sessionsWithData: 0,
          averages: <String, double>{},
        ).toJson(),
        'trendsVsPreviousPeriod': <String, dynamic>{
          'training': const <String, dynamic>{},
          'match': const <String, dynamic>{},
        },
      },
    };
  }
}

enum _TrainingPresence {
  present,
  absent,
}
