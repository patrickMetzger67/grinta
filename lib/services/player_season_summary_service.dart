import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/player_activity_report_service.dart';
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
    required this.teamTrainingCount,
    required this.presentCount,
    required this.absentCount,
    required this.attendanceRate,
    required this.matchTrackerAverages,
    required this.trainingTrackerAverages,
    required this.unavailabilities,
  });

  final int teamMatchCount;
  final int convocations;
  final int starts;
  final int minutesPlayed;
  final int teamTrainingCount;
  final int presentCount;
  final int absentCount;
  final double? attendanceRate;
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
  })  : _teamPlayerStatsService =
            teamPlayerStatsService ?? TeamPlayerStatsService(),
        _teamTrainingStatsService =
            teamTrainingStatsService ?? TeamTrainingStatsService(),
        _teamCompetitionStatsService =
            teamCompetitionStatsService ?? TeamCompetitionStatsService(),
        _playerActivityReportService =
            playerActivityReportService ?? PlayerActivityReportService();

  final TeamPlayerStatsService _teamPlayerStatsService;
  final TeamTrainingStatsService _teamTrainingStatsService;
  final TeamCompetitionStatsService _teamCompetitionStatsService;
  final PlayerActivityReportService _playerActivityReportService;

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

    final matchStatsResult = await matchStatsFuture;
    final trainingStatsResult = await trainingStatsFuture;
    final matches = await matchesFuture;
    final trackerAverages = await trackerFuture;

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
      teamTrainingCount: trainingStatsResult.globalStats.trainingCount,
      presentCount: playerTrainingStats?.presentCount ?? 0,
      absentCount: playerTrainingStats?.absentCount ?? 0,
      attendanceRate: playerTrainingStats?.attendanceRate,
      matchTrackerAverages: trackerAverages.matches,
      trainingTrackerAverages: trackerAverages.trainings,
      unavailabilities: player.unavailabilitiesForSeason(normalizedSeasonId),
    );
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
