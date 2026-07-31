import 'package:flutter/foundation.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/clubService.dart';
import 'package:grinta/services/ranking_per_day_service.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/services/team_player_stats_service.dart';
import 'package:grinta/services/team_typical_team_service.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';
import 'package:grinta/util/team_stats_ranking_helper.dart';
import 'package:intl/intl.dart';

/// Snapshot used to render / email an opponent analysis PDF.
class OpponentAnalysisReportData {
  const OpponentAnalysisReportData({
    required this.team,
    required this.teamName,
    required this.seasonId,
    required this.competitionUrl,
    required this.competitionLabel,
    required this.opponent,
    required this.upcomingMatch,
    required this.upcomingKickoff,
    required this.wdl,
    required this.trend,
    required this.players,
    required this.typicalTeam,
    required this.rankingSeries,
    required this.rankingMatchdays,
  });

  final Team team;
  final String teamName;
  final String seasonId;
  final String competitionUrl;
  final String competitionLabel;
  final TeamStatsOpponent opponent;
  final Match upcomingMatch;
  final DateTime upcomingKickoff;
  final TeamWdlStatsByPeriod wdl;
  final TeamWdlHalfTrend trend;
  final List<OpponentAnalysisPlayerRow> players;
  final TypicalTeamResult typicalTeam;
  final List<OpponentAnalysisRankingSeries> rankingSeries;
  final List<int> rankingMatchdays;
}

class OpponentAnalysisPlayerRow {
  const OpponentAnalysisPlayerRow({
    required this.displayName,
    required this.convocations,
    required this.starts,
    required this.minutesPlayed,
  });

  final String displayName;
  final int convocations;
  final int starts;
  final int minutesPlayed;
}

class OpponentAnalysisRankingPoint {
  const OpponentAnalysisRankingPoint({
    required this.matchday,
    this.rank,
    this.pts,
  });

  final int matchday;
  final int? rank;
  final int? pts;
}

class OpponentAnalysisRankingSeries {
  const OpponentAnalysisRankingSeries({
    required this.label,
    required this.isOwnTeam,
    required this.points,
  });

  final String label;
  final bool isOwnTeam;
  final List<OpponentAnalysisRankingPoint> points;
}

class OpponentAnalysisReportDataService {
  OpponentAnalysisReportDataService({
    TeamCompetitionStatsService? competitionStatsService,
    TeamPlayerStatsService? playerStatsService,
    TeamTypicalTeamService? typicalTeamService,
    RankingPerDayService? rankingPerDayService,
    ClubService? clubService,
  })  : _competitionStatsService =
            competitionStatsService ?? TeamCompetitionStatsService(),
        _playerStatsService = playerStatsService ?? TeamPlayerStatsService(),
        _typicalTeamService = typicalTeamService ?? TeamTypicalTeamService(),
        _rankingPerDayService =
            rankingPerDayService ?? RankingPerDayService(),
        _clubService = clubService ?? ClubService();

  static final OpponentAnalysisReportDataService instance =
      OpponentAnalysisReportDataService();

  final TeamCompetitionStatsService _competitionStatsService;
  final TeamPlayerStatsService _playerStatsService;
  final TeamTypicalTeamService _typicalTeamService;
  final RankingPerDayService _rankingPerDayService;
  final ClubService _clubService;

  Future<OpponentAnalysisReportData> build({
    required Team team,
    required String seasonId,
    required String competitionUrl,
    required String competitionLabel,
    required TeamStatsOpponent opponent,
    required Match upcomingMatch,
    required DateTime upcomingKickoff,
    String? teamName,
  }) async {
    final resolvedTeamName =
        (teamName ?? team.name ?? 'Equipe').trim();

    final teamId = team.keyTeam?.trim() ?? '';

    TeamWdlStatsByPeriod wdl;
    try {
      wdl = await _competitionStatsService.computeWdlStatsForTeam(
        team: team,
        seasonId: seasonId,
        competitionUrl: competitionUrl,
        opponentFilter: opponent,
      );
    } catch (e, st) {
      debugPrint('OpponentAnalysisReportDataService WDL failed: $e\n$st');
      wdl = TeamWdlStatsByPeriod(
        fullSeason: const TeamWdlPeriodData(
          counts: TeamWdlCounts(),
          matches: [],
        ),
        firstHalf: const TeamWdlPeriodData(
          counts: TeamWdlCounts(),
          matches: [],
        ),
        secondHalf: const TeamWdlPeriodData(
          counts: TeamWdlCounts(),
          matches: [],
        ),
        teamId: teamId,
        clubId: team.clubId,
        perspectiveDisplayName: opponent.displayName,
      );
    }

    List<OpponentAnalysisPlayerRow> playerRows = const [];
    try {
      final playersResult = await _playerStatsService.computePlayerStatsForTeam(
        team: team,
        seasonId: seasonId,
        competitionUrl: competitionUrl,
        opponentFilter: opponent,
        useMatchStats: true,
        forceRefresh: true,
      );
      playerRows = playersResult.statsByPlayerId.values
          .map(
            (stats) => OpponentAnalysisPlayerRow(
              displayName: (stats.displayName?.trim().isNotEmpty == true)
                  ? stats.displayName!.trim()
                  : (stats.player != null
                      ? playerDisplayName(stats.player!).trim()
                      : stats.playerId),
              convocations: stats.convocations,
              starts: stats.starts,
              minutesPlayed: stats.minutesPlayed,
            ),
          )
          .where((row) => row.displayName.isNotEmpty)
          .toList()
        ..sort((a, b) {
          final byStarts = b.starts.compareTo(a.starts);
          if (byStarts != 0) return byStarts;
          final byConvo = b.convocations.compareTo(a.convocations);
          if (byConvo != 0) return byConvo;
          return a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase());
        });
    } catch (e, st) {
      debugPrint('OpponentAnalysisReportDataService players failed: $e\n$st');
    }

    TypicalTeamResult typicalTeam;
    try {
      typicalTeam = await _typicalTeamService.computeTypicalTeamForOpponent(
        team: team,
        seasonId: seasonId,
        competitionUrl: competitionUrl,
        opponentFilter: opponent,
        forceRefresh: true,
      );
    } catch (e, st) {
      debugPrint('OpponentAnalysisReportDataService typical team failed: $e\n$st');
      typicalTeam = const TypicalTeamResult(
        probableStarters: [],
        probableSubstitutes: [],
        matchesWithSquadData: 0,
        totalPlayedMatches: 0,
      );
    }

    final ranking = await _loadRankingEvolution(
      team: team,
      competitionUrl: competitionUrl,
      opponent: opponent,
    );

    final trend = TeamWdlHalfTrend.compare(
      firstHalf: wdl.firstHalf.counts,
      secondHalf: wdl.secondHalf.counts,
    );

    return OpponentAnalysisReportData(
      team: team,
      teamName: resolvedTeamName.isEmpty ? 'Equipe' : resolvedTeamName,
      seasonId: seasonId,
      competitionUrl: competitionUrl,
      competitionLabel: competitionLabel.trim().isEmpty
          ? 'Competition'
          : competitionLabel.trim(),
      opponent: opponent,
      upcomingMatch: upcomingMatch,
      upcomingKickoff: upcomingKickoff,
      wdl: wdl,
      trend: trend,
      players: playerRows,
      typicalTeam: typicalTeam,
      rankingSeries: ranking.series,
      rankingMatchdays: ranking.matchdays,
    );
  }

  Future<({List<OpponentAnalysisRankingSeries> series, List<int> matchdays})>
      _loadRankingEvolution({
    required Team team,
    required String competitionUrl,
    required TeamStatsOpponent opponent,
  }) async {
    final filter = teamStatsRankingFilterFromSelection(competitionUrl);
    if (filter == null) {
      return (series: const <OpponentAnalysisRankingSeries>[], matchdays: const <int>[]);
    }

    try {
      final entries =
          await _rankingPerDayService.getRankingsPerDayByCompetitionIdAndPoule(
        competitionId: filter.competitionId,
        poule: filter.poule,
      );
      if (entries.isEmpty) {
        return (
          series: const <OpponentAnalysisRankingSeries>[],
          matchdays: const <int>[],
        );
      }

      final teamContext = await resolveTeamStatsRankingTeamContext(
        team,
        clubService: _clubService,
      );
      final grouped = groupRankingPerDayByAffiliate(entries);
      final options = buildRankingClubOptions(entries, teamContext);
      final matchdays = sortedMatchdaysFromRankingPerDay(entries);

      String? opponentAffiliate;
      final opponentName = opponent.displayName.trim().toLowerCase();
      final opponentAff = opponent.affiliation?.trim() ?? '';
      final opponentClub = opponent.clubId?.trim() ?? '';

      for (final option in options) {
        if (opponentAff.isNotEmpty && option.affiliateKey == opponentAff) {
          opponentAffiliate = option.affiliateKey;
          break;
        }
        if (opponentClub.isNotEmpty && option.affiliateKey == opponentClub) {
          opponentAffiliate = option.affiliateKey;
          break;
        }
        if (option.displayName.trim().toLowerCase() == opponentName) {
          opponentAffiliate = option.affiliateKey;
          break;
        }
      }

      final selected = <String>{
        if (teamContext.primaryAffiliate.isNotEmpty) teamContext.primaryAffiliate,
        if (opponentAffiliate != null) opponentAffiliate,
      };

      final series = <OpponentAnalysisRankingSeries>[];
      for (final affiliate in selected) {
        final list = grouped[affiliate];
        if (list == null || list.isEmpty) continue;
        String label = affiliate;
        for (final option in options) {
          if (option.affiliateKey == affiliate) {
            label = option.displayName;
            break;
          }
        }
        series.add(
          OpponentAnalysisRankingSeries(
            label: label,
            isOwnTeam: teamContext.matchesAffiliate(affiliate),
            points: [
              for (final entry in list)
                if ((entry.day ?? 0) > 0)
                  OpponentAnalysisRankingPoint(
                    matchday: entry.day!,
                    rank: entry.rank,
                    pts: entry.pts,
                  ),
            ],
          ),
        );
      }

      series.sort((a, b) {
        if (a.isOwnTeam != b.isOwnTeam) {
          return a.isOwnTeam ? -1 : 1;
        }
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });

      return (series: series, matchdays: matchdays);
    } catch (_) {
      return (
        series: const <OpponentAnalysisRankingSeries>[],
        matchdays: const <int>[],
      );
    }
  }

  static String formatKickoff(DateTime kickoff, {String locale = 'fr'}) {
    return DateFormat.Hm(locale).format(kickoff);
  }

  static String formatWeekday(DateTime kickoff, {String locale = 'fr'}) {
    final label = DateFormat.EEEE(locale).format(kickoff);
    if (label.isEmpty) return label;
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }
}
