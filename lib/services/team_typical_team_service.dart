import 'package:grinta/model/match.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/matchStatsService.dart';
import 'package:grinta/services/seasonService.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/util/season_period_ranges.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';

class TeamTypicalTeamService {
  TeamTypicalTeamService({
    TeamCompetitionStatsService? teamCompetitionStatsService,
    MatchStatsService? matchStatsService,
    SeasonService? seasonService,
  })  : _teamCompetitionStatsService =
            teamCompetitionStatsService ?? TeamCompetitionStatsService(),
        _matchStatsService = matchStatsService ?? MatchStatsService(),
        _seasonService = seasonService ?? SeasonService();

  final TeamCompetitionStatsService _teamCompetitionStatsService;
  final MatchStatsService _matchStatsService;
  final SeasonService _seasonService;

  static const int _matchBatchSize = 8;

  String? _cacheKey;
  TypicalTeamResult? _cachedResult;

  Future<TypicalTeamResult> computeTypicalTeamForOpponent({
    required Team team,
    required String seasonId,
    required String competitionUrl,
    required TeamStatsOpponent opponentFilter,
    bool forceRefresh = false,
  }) async {
    final teamId = team.keyTeam?.trim() ?? '';
    final normalizedSeasonId = seasonId.trim();
    final normalizedCompetitionUrl = competitionUrl.trim();
    final opponentKey = opponentFilter.key.trim();
    final key = '$teamId|$normalizedSeasonId|$normalizedCompetitionUrl|$opponentKey';

    if (!forceRefresh && _cacheKey == key && _cachedResult != null) {
      return _cachedResult!;
    }

    final matches = await _teamCompetitionStatsService.loadPlayedSeasonMatches(
      team: team,
      seasonId: normalizedSeasonId,
      competitionUrl: normalizedCompetitionUrl,
      opponentFilter: opponentFilter,
    );

    final season = await _seasonService.getSeasonById(normalizedSeasonId);
    final seasonPeriods = resolveSeasonPeriodRanges(
      seasonId: normalizedSeasonId,
      season: season,
    );

    final inputs = <TypicalTeamMatchInput>[];

    for (var i = 0; i < matches.length; i += _matchBatchSize) {
      final batch = matches.skip(i).take(_matchBatchSize).toList();
      final batchStats = await Future.wait(
        batch.map(
          (match) => _loadMatchStatsInput(
            match: match,
            opponentFilter: opponentFilter,
          ),
        ),
      );
      inputs.addAll(batchStats);
    }

    final result = computeTypicalTeamFromMatchStats(
      matches: inputs,
      seasonPeriods: seasonPeriods,
    );

    _cacheKey = key;
    _cachedResult = result;
    return result;
  }

  Future<TypicalTeamMatchInput> _loadMatchStatsInput({
    required Match match,
    required TeamStatsOpponent opponentFilter,
  }) async {
    final opponentTeamName = opponentTeamDisplayNameForMatch(
          match: match,
          opponent: opponentFilter,
        ) ??
        opponentFilter.displayName;
    final matchId = match.id?.trim() ?? '';

    if (matchId.isEmpty) {
      return TypicalTeamMatchInput(
        match: match,
        matchStats: null,
        opponentTeamName: opponentTeamName,
        matchDate: matchDateForTeamStats(match),
      );
    }

    final matchStats = await _matchStatsService.getMatchStatsByMatchId(matchId);

    return TypicalTeamMatchInput(
      match: match,
      matchStats: matchStats,
      opponentTeamName: opponentTeamName,
      matchDate: matchDateForTeamStats(match),
    );
  }
}
