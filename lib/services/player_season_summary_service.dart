import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/player_activity_report_service.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/services/team_player_stats_service.dart';
import 'package:grinta/services/team_training_stats_service.dart';
import 'package:grinta/util/player_activity_report_aggregator.dart';
import 'package:grinta/util/player_photo_resolver.dart';

/// Assembled season summary for one roster player.
class PlayerSeasonSummary {
  const PlayerSeasonSummary({
    required this.teamMatchCount,
    required this.convocations,
    required this.starts,
    required this.minutesPlayed,
    required this.yellowCards,
    required this.redCards,
    required this.teamTrainingCount,
    required this.presentCount,
    required this.absentCount,
    required this.attendanceRate,
    required this.teamNames,
    required this.matchTrackerAverages,
    required this.trainingTrackerAverages,
    required this.unavailabilities,
  });

  final int teamMatchCount;
  final int convocations;
  final int starts;
  final int minutesPlayed;
  final int yellowCards;
  final int redCards;
  final int teamTrainingCount;
  final int presentCount;
  final int absentCount;
  final double? attendanceRate;
  final List<String> teamNames;
  final PlayerTrackerMetricAverages matchTrackerAverages;
  final PlayerTrackerMetricAverages trainingTrackerAverages;
  final List<Unavailability> unavailabilities;
}

/// Loads match, training, tracker and unavailability data for a player season card.
class PlayerSeasonSummaryService {
  PlayerSeasonSummaryService({
    TeamPlayerStatsService? teamPlayerStatsService,
    TeamTrainingStatsService? teamTrainingStatsService,
    TeamCompetitionStatsService? teamCompetitionStatsService,
    PlayerActivityReportService? playerActivityReportService,
    TeamService? teamService,
  })  : _teamPlayerStatsService =
            teamPlayerStatsService ?? TeamPlayerStatsService(),
        _teamTrainingStatsService =
            teamTrainingStatsService ?? TeamTrainingStatsService(),
        _teamCompetitionStatsService =
            teamCompetitionStatsService ?? TeamCompetitionStatsService(),
        _playerActivityReportService =
            playerActivityReportService ?? PlayerActivityReportService(),
        _teamService = teamService ?? TeamService();

  final TeamPlayerStatsService _teamPlayerStatsService;
  final TeamTrainingStatsService _teamTrainingStatsService;
  final TeamCompetitionStatsService _teamCompetitionStatsService;
  final PlayerActivityReportService _playerActivityReportService;
  final TeamService _teamService;

  Future<PlayerSeasonSummary> loadSummary({
    required Team team,
    required Player player,
    required String seasonId,
  }) async {
    final normalizedSeasonId = seasonId.trim();
    final lookupIds = playerMemberLookupIds(player);

    final matchStatsFuture = _teamPlayerStatsService.computePlayerStatsForTeam(
      team: team,
      seasonId: normalizedSeasonId,
    );
    final trainingStatsFuture = _teamTrainingStatsService.computeStatsForTeam(
      team: team,
      seasonId: normalizedSeasonId,
    );
    final matchesFuture = _teamCompetitionStatsService.loadPlayedSeasonMatches(
      team: team,
      seasonId: normalizedSeasonId,
    );
    final trackerFuture =
        _playerActivityReportService.loadSeasonTrackerAverages(
      team: team,
      player: player,
      seasonId: normalizedSeasonId,
    );
    final teamNamesFuture = _loadPlayerTeamNames(
      player: player,
      currentTeam: team,
    );

    final matchStatsResult = await matchStatsFuture;
    final trainingStatsResult = await trainingStatsFuture;
    final matches = await matchesFuture;
    final trackerAverages = await trackerFuture;
    final teamNames = await teamNamesFuture;

    final playerMatchStats = _firstMatch(
      matchStatsResult.statsByPlayerId,
      lookupIds,
    );
    final playerTrainingStats = _firstTraining(
      trainingStatsResult.statsByPlayerId,
      lookupIds,
    );

    return PlayerSeasonSummary(
      teamMatchCount: matches.length,
      convocations: playerMatchStats?.convocations ?? 0,
      starts: playerMatchStats?.starts ?? 0,
      minutesPlayed: playerMatchStats?.minutesPlayed ?? 0,
      yellowCards: playerMatchStats?.yellowCards ?? 0,
      redCards: playerMatchStats?.redCards ?? 0,
      teamTrainingCount: trainingStatsResult.globalStats.trainingCount,
      presentCount: playerTrainingStats?.presentCount ?? 0,
      absentCount: playerTrainingStats?.absentCount ?? 0,
      attendanceRate: playerTrainingStats?.attendanceRate,
      teamNames: teamNames,
      matchTrackerAverages: trackerAverages.matches,
      trainingTrackerAverages: trackerAverages.trainings,
      unavailabilities: player.unavailabilitiesForSeason(normalizedSeasonId),
    );
  }

  Future<List<String>> _loadPlayerTeamNames({
    required Player player,
    required Team currentTeam,
  }) async {
    final Map<String, String> namesByTeamId = <String, String>{};

    void addTeam(Team team) {
      final String teamId = (team.keyTeam ?? team.ref?.id ?? '').trim();
      final String name = team.name?.trim() ?? '';
      if (teamId.isEmpty || name.isEmpty) return;
      namesByTeamId[teamId] = name;
    }

    addTeam(currentTeam);

    try {
      final List<Team> grintaTeams =
          await _teamService.getTeamsForPlayerGrintaMembership(player);
      for (final Team team in grintaTeams) {
        addTeam(team);
      }
    } catch (_) {
      // Best-effort: keep current team chip.
    }

    for (final String memberId in playerMemberLookupIds(player)) {
      try {
        final List<Team> legacyTeams =
            await _teamService.getTeamsByPlayerId(memberId);
        for (final Team team in legacyTeams) {
          addTeam(team);
        }
      } catch (_) {
        // Ignore legacy lookup failures.
      }
    }

    final List<String> names = namesByTeamId.values.toList()
      ..sort(
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
    return names;
  }

  TeamPlayerSeasonStats? _firstMatch(
    Map<String, TeamPlayerSeasonStats> byId,
    Set<String> lookupIds,
  ) {
    for (final id in lookupIds) {
      final stats = byId[id];
      if (stats != null) {
        return stats;
      }
    }
    return null;
  }

  TeamTrainingPlayerStats? _firstTraining(
    Map<String, TeamTrainingPlayerStats> byId,
    Set<String> lookupIds,
  ) {
    for (final id in lookupIds) {
      final stats = byId[id];
      if (stats != null) {
        return stats;
      }
    }
    return null;
  }
}
