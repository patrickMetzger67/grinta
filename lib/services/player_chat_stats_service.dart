import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/seasonService.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/services/team_training_stats_service.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/player_stats_month_helper.dart';
import 'package:grinta/util/season_period_ranges.dart';
import 'package:grinta/util/team_list_visibility.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';

/// Builds per-player playing time and training attendance for Ask Diego context.
class PlayerChatStatsService {
  PlayerChatStatsService({
    TeamCompetitionStatsService? teamCompetitionStatsService,
    MatchCompoService? matchCompoService,
    HighlightsService? highlightsService,
    TrainingService? trainingService,
    SeasonService? seasonService,
  })  : _teamCompetitionStatsService =
            teamCompetitionStatsService ?? TeamCompetitionStatsService(),
        _matchCompoService = matchCompoService ?? MatchCompoService(),
        _highlightsService = highlightsService ?? HighlightsService(),
        _trainingService = trainingService ?? TrainingService(),
        _seasonService = seasonService ?? SeasonService();

  final TeamCompetitionStatsService _teamCompetitionStatsService;
  final MatchCompoService _matchCompoService;
  final HighlightsService _highlightsService;
  final TrainingService _trainingService;
  final SeasonService _seasonService;

  static const int _matchBatchSize = 8;

  Future<Map<String, dynamic>> buildPlayerStatsContext({
    required AppSession session,
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
      return _emptyPlayerStatsContext(
        playerId: playerId,
        playerName: playerName,
        seasonId: seasonId.isEmpty ? null : seasonId,
        reason: 'missing_session_player_or_season',
      );
    }

    final teams = _resolveTeamsForPlayerStats(session);
    if (teams.isEmpty) {
      return _emptyPlayerStatsContext(
        playerId: playerId,
        playerName: playerName,
        seasonId: seasonId,
        reason: 'no_roster_teams_for_season',
      );
    }

    final lookupIds = playerMemberLookupIds(player);
    if (lookupIds.isEmpty) {
      return _emptyPlayerStatsContext(
        playerId: playerId,
        playerName: playerName,
        seasonId: seasonId,
        reason: 'missing_player_member_ids',
      );
    }

    final season = await _seasonService.getSeasonById(seasonId);
    final periods = resolveSeasonPeriodRanges(
      seasonId: seasonId,
      season: season,
    );

    final playingTimeBuckets = <String, MonthPlayingTimeBucket>{};
    final trainingBuckets = <String, MonthTrainingAttendanceBucket>{};
    var seasonTotalMinutes = 0;
    var seasonPresent = 0;
    var seasonAbsent = 0;

    await Future.wait(
      teams.map(
        (Team team) => _aggregateTeamStats(
          team: team,
          seasonId: seasonId,
          period: periods.fullSeason,
          lookupIds: lookupIds,
          playingTimeBuckets: playingTimeBuckets,
          trainingBuckets: trainingBuckets,
          onPlayingTime: (int minutes) => seasonTotalMinutes += minutes,
          onTraining: ({required int present, required int absent}) {
            seasonPresent += present;
            seasonAbsent += absent;
          },
        ),
      ),
    );

    final seasonRate = playerTrainingAttendanceRate(
      presentCount: seasonPresent,
      absentCount: seasonAbsent,
    );

    return <String, dynamic>{
      'playerId': playerId,
      'playerName': playerName,
      'seasonId': seasonId,
      'teamIds': teams
          .map((Team team) => team.keyTeam?.trim() ?? '')
          .where((String id) => id.isNotEmpty)
          .toList(),
      'memberLookupIds': lookupIds.toList()..sort(),
      'playingTime': <String, dynamic>{
        'seasonTotalMinutes': seasonTotalMinutes,
        'byMonth': sortedPlayingTimeByMonth(playingTimeBuckets, localeCode),
      },
      'trainingAttendance': <String, dynamic>{
        'seasonRatePercent': seasonRate,
        'byMonth': sortedTrainingAttendanceByMonth(trainingBuckets, localeCode),
      },
    };
  }

  /// Teams where the selected player is on the roster for the selected season.
  ///
  /// Prefer [AppSession.memberTeamsForSelectedSeason], then merged session teams,
  /// then agenda-visible teams — Grinta members are often only present on the
  /// manager/agenda path when the grinta index query lags.
  static List<Team> _resolveTeamsForPlayerStats(AppSession session) {
    final Player? player = session.selectedPlayer;
    final String? playerId = session.selectedPlayerId?.trim();
    final String? seasonId = session.selectedSeason?.ref?.id;
    if (player == null ||
        playerId == null ||
        playerId.isEmpty ||
        seasonId == null) {
      return const <Team>[];
    }

    final Set<String> seenTeamIds = <String>{};
    final List<Team> resolved = <Team>[];

    void addTeams(List<Team> teams) {
      for (final Team team in teams) {
        final String teamId = team.keyTeam?.trim() ?? '';
        if (teamId.isEmpty || seenTeamIds.contains(teamId)) {
          continue;
        }
        if (!teamContainsMemberOnRoster(team, player)) {
          continue;
        }
        seenTeamIds.add(teamId);
        resolved.add(team);
      }
    }

    addTeams(session.memberTeamsForSelectedSeason);

    if (resolved.isEmpty) {
      final Map<String, Team>? seasonTeams =
          session.teams[playerId]?[seasonId];
      if (seasonTeams != null) {
        addTeams(seasonTeams.values.toList());
      }
    }

    if (resolved.isEmpty) {
      addTeams(session.teamsForAgendaSelectedSeason);
    }

    return resolved;
  }

  static Map<String, dynamic> unavailablePlayerStatsContext({
    required AppSession session,
    required String reason,
  }) {
    final player = session.selectedPlayer;
    return _emptyPlayerStatsContext(
      playerId: session.selectedPlayerId,
      playerName: player == null ? null : playerDisplayName(player),
      seasonId: session.selectedSeason?.ref?.id,
      reason: reason,
    );
  }

  static Map<String, dynamic> _emptyPlayerStatsContext({
    required String? playerId,
    required String? playerName,
    required String? seasonId,
    required String reason,
  }) {
    return <String, dynamic>{
      'playerId': playerId,
      'playerName': playerName,
      'seasonId': seasonId,
      'playerStatsUnavailableReason': reason,
      'playingTime': <String, dynamic>{
        'seasonTotalMinutes': 0,
        'byMonth': const <Map<String, dynamic>>[],
      },
      'trainingAttendance': <String, dynamic>{
        'seasonRatePercent': null,
        'byMonth': const <Map<String, dynamic>>[],
      },
    };
  }

  Future<void> _aggregateTeamStats({
    required Team team,
    required String seasonId,
    required SeasonPeriodRange period,
    required Set<String> lookupIds,
    required Map<String, MonthPlayingTimeBucket> playingTimeBuckets,
    required Map<String, MonthTrainingAttendanceBucket> trainingBuckets,
    required void Function(int minutes) onPlayingTime,
    required void Function({required int present, required int absent})
        onTraining,
  }) async {
    final teamId = team.keyTeam?.trim() ?? '';
    if (teamId.isEmpty) {
      return;
    }

    await Future.wait([
      _aggregatePlayingTimeForTeam(
        team: team,
        seasonId: seasonId,
        lookupIds: lookupIds,
        playingTimeBuckets: playingTimeBuckets,
        onPlayingTime: onPlayingTime,
      ),
      _aggregateTrainingAttendanceForTeam(
        teamId: teamId,
        seasonId: seasonId,
        period: period,
        lookupIds: lookupIds,
        trainingBuckets: trainingBuckets,
        onTraining: onTraining,
      ),
    ]);
  }

  Future<void> _aggregatePlayingTimeForTeam({
    required Team team,
    required String seasonId,
    required Set<String> lookupIds,
    required Map<String, MonthPlayingTimeBucket> playingTimeBuckets,
    required void Function(int minutes) onPlayingTime,
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
        final matchStats = batchResults[j];
        final playerStats = _statsForLookupIds(
          matchStats: matchStats,
          lookupIds: lookupIds,
        );
        if (playerStats == null || playerStats.convocations <= 0) {
          continue;
        }

        final matchDate = matchDateForTeamStats(match);
        if (matchDate == null) {
          continue;
        }

        final bucket = playingTimeBucketForDate(playingTimeBuckets, matchDate);
        bucket.addMatch(matchMinutes: playerStats.minutesPlayed);
        onPlayingTime(playerStats.minutesPlayed);
      }
    }
  }

  Future<void> _aggregateTrainingAttendanceForTeam({
    required String teamId,
    required String seasonId,
    required SeasonPeriodRange period,
    required Set<String> lookupIds,
    required Map<String, MonthTrainingAttendanceBucket> trainingBuckets,
    required void Function({required int present, required int absent})
        onTraining,
  }) async {
    final trainings = await loadPastTrainingsForTeamSeason(
      trainingService: _trainingService,
      teamId: teamId,
      seasonId: seasonId,
      period: period,
    );

    for (final training in trainings) {
      final trainingDate = trainingDateForStats(training);
      if (trainingDate == null) {
        continue;
      }

      final presence = _presenceForLookupIds(
        training: training,
        lookupIds: lookupIds,
      );
      if (presence == null) {
        continue;
      }

      final bucket =
          trainingAttendanceBucketForDate(trainingBuckets, trainingDate);
      if (presence == _TrainingPresence.present) {
        bucket.present++;
        onTraining(present: 1, absent: 0);
      } else if (presence == _TrainingPresence.absent) {
        bucket.absent++;
        onTraining(present: 0, absent: 1);
      }
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

    final compoFuture =
        _matchCompoService.getMatchCompoByMatchAndTeamId(matchId, teamId);
    final highlightsFuture = _highlightsService.getHighlightsByMatchCalendarId(
      matchId,
      teamId: teamId,
    );

    final results = await Future.wait([compoFuture, highlightsFuture]);
    final compo = results[0] as MatchCompo?;
    final highlights = results[1] as List<Highlights>;

    return statsForMatch(
      match: match,
      compo: compo,
      highlights: highlights,
    );
  }
}

enum _TrainingPresence {
  present,
  absent,
}
