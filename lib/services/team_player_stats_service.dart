import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/matchStatsService.dart';
import 'package:grinta/services/seasonService.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/services/team_players_service.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/season_period_ranges.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';

/// Aggregated season stats for one player.
class TeamPlayerSeasonStats {
  const TeamPlayerSeasonStats({
    required this.playerId,
    required this.player,
    required this.convocations,
    required this.starts,
    required this.minutesPlayed,
    required this.goals,
    required this.trends,
    this.displayName,
  });

  final String playerId;
  final Player? player;
  final int convocations;
  final int starts;
  final int minutesPlayed;
  final int goals;
  final TeamPlayerStatTrends trends;

  /// Full name from external sources (e.g. FFF matchStats), shown as-is in the UI.
  final String? displayName;
}

class TeamPlayerStatsResult {
  const TeamPlayerStatsResult({
    required this.statsByPlayerId,
    required this.rosterPlayers,
  });

  final Map<String, TeamPlayerSeasonStats> statsByPlayerId;
  final List<Player> rosterPlayers;
}

class TeamPlayerStatsService {
  TeamPlayerStatsService({
    TeamCompetitionStatsService? teamCompetitionStatsService,
    MatchCompoService? matchCompoService,
    HighlightsService? highlightsService,
    MatchStatsService? matchStatsService,
    TeamPlayersService? teamPlayersService,
    SeasonService? seasonService,
  })  : _teamCompetitionStatsService =
            teamCompetitionStatsService ?? TeamCompetitionStatsService(),
        _matchCompoService = matchCompoService ?? MatchCompoService(),
        _highlightsService = highlightsService ?? HighlightsService(),
        _matchStatsService = matchStatsService ?? MatchStatsService(),
        _teamPlayersService = teamPlayersService ?? TeamPlayersService(),
        _seasonService = seasonService ?? SeasonService();

  final TeamCompetitionStatsService _teamCompetitionStatsService;
  final MatchCompoService _matchCompoService;
  final HighlightsService _highlightsService;
  final MatchStatsService _matchStatsService;
  final TeamPlayersService _teamPlayersService;
  final SeasonService _seasonService;

  static const int _matchBatchSize = 8;

  String? _cacheKey;
  TeamPlayerStatsResult? _cachedResult;

  /// Loads played-match player stats for [team] in [seasonId].
  /// Results are cached until [team] or [seasonId] changes.
  Future<TeamPlayerStatsResult> computePlayerStatsForTeam({
    required Team team,
    required String seasonId,
    String? competitionUrl,
    TeamStatsOpponent? opponentFilter,
    bool useMatchStats = false,
    bool forceRefresh = false,
  }) async {
    final teamId = team.keyTeam?.trim() ?? '';
    final normalizedSeasonId = seasonId.trim();
    final normalizedCompetitionUrl = competitionUrl?.trim() ?? '';
    final opponentKey = opponentFilter?.key.trim() ?? '';
    final key =
        '$teamId|$normalizedSeasonId|$normalizedCompetitionUrl|$opponentKey|ms:$useMatchStats';

    if (!forceRefresh && _cacheKey == key && _cachedResult != null) {
      return _cachedResult!;
    }

    final matches = await _teamCompetitionStatsService.loadPlayedSeasonMatches(
      team: team,
      seasonId: normalizedSeasonId,
      competitionUrl: normalizedCompetitionUrl.isEmpty
          ? null
          : normalizedCompetitionUrl,
      opponentFilter: opponentFilter,
    );

    final season = await _seasonService.getSeasonById(normalizedSeasonId);
    final periods = resolveSeasonPeriodRanges(
      seasonId: normalizedSeasonId,
      season: season,
    );

    final rosterPlayers = opponentFilter != null
        ? const <Player>[]
        : teamId.isEmpty
            ? const <Player>[]
            : await _teamPlayersService.loadPlayers(teamId: teamId);

    final opponentPlayersById = <String, Player>{};
    final opponentDisplayNamesById = <String, String>{};

    final accumulators = <String, TeamPlayerMatchStatsAccumulator>{};
    final firstHalfAccumulators = <String, TeamPlayerMatchStatsAccumulator>{};
    final secondHalfAccumulators = <String, TeamPlayerMatchStatsAccumulator>{};
    var firstHalfMatchCount = 0;
    var secondHalfMatchCount = 0;

    void mergeInto(
      Map<String, TeamPlayerMatchStatsAccumulator> target,
      Map<String, TeamPlayerMatchStatsAccumulator> source,
    ) {
      for (final entry in source.entries) {
        final existing = target[entry.key];
        if (existing == null) {
          target[entry.key] = TeamPlayerMatchStatsAccumulator(
            playerId: entry.value.playerId,
          )
            ..convocations = entry.value.convocations
            ..starts = entry.value.starts
            ..minutesPlayed = entry.value.minutesPlayed
            ..goals = entry.value.goals;
        } else {
          existing.merge(entry.value);
        }
      }
    }

    for (var i = 0; i < matches.length; i += _matchBatchSize) {
      final batch = matches.skip(i).take(_matchBatchSize).toList();
      final batchResults = await Future.wait(
        batch.map(
          (match) => _loadMatchStats(
            match: match,
            teamId: teamId,
            opponentFilter: opponentFilter,
            opponentPlayersById: opponentFilter != null
                ? opponentPlayersById
                : null,
            opponentDisplayNamesById: opponentFilter != null
                ? opponentDisplayNamesById
                : null,
            useMatchStats: useMatchStats,
          ),
        ),
      );

      for (var j = 0; j < batch.length; j++) {
        final match = batch[j];
        final matchStats = batchResults[j];

        for (final entry in matchStats.entries) {
          final existing = accumulators[entry.key];
          if (existing == null) {
            accumulators[entry.key] = entry.value;
          } else {
            existing.merge(entry.value);
          }
        }

        final matchDate = matchDateForTeamStats(match);
        if (matchDate == null) {
          continue;
        }

        if (periods.firstHalf.contains(matchDate)) {
          firstHalfMatchCount++;
          mergeInto(firstHalfAccumulators, matchStats);
        } else if (periods.secondHalf.contains(matchDate)) {
          secondHalfMatchCount++;
          mergeInto(secondHalfAccumulators, matchStats);
        }
      }
    }

    final playersById = <String, Player>{};
    for (final player in rosterPlayers) {
      final memberId = effectiveMemberId(player)?.trim() ?? '';
      if (memberId.isNotEmpty) {
        playersById[memberId] = player;
      }
    }
    playersById.addAll(opponentPlayersById);

    final statsByPlayerId = <String, TeamPlayerSeasonStats>{};

    void addStats(String playerId, {Player? player, String? displayName}) {
      final normalizedId = playerId.trim();
      if (normalizedId.isEmpty || statsByPlayerId.containsKey(normalizedId)) {
        return;
      }

      final resolvedDisplayName =
          displayName ?? opponentDisplayNamesById[normalizedId];
      final accumulator = accumulators[normalizedId];
      final trends = TeamPlayerStatTrends.compare(
        firstHalf: TeamPlayerHalfCounts.fromAccumulator(
          accumulator: firstHalfAccumulators[normalizedId],
          teamMatchCount: firstHalfMatchCount,
        ),
        secondHalf: TeamPlayerHalfCounts.fromAccumulator(
          accumulator: secondHalfAccumulators[normalizedId],
          teamMatchCount: secondHalfMatchCount,
        ),
      );
      statsByPlayerId[normalizedId] = TeamPlayerSeasonStats(
        playerId: normalizedId,
        player: player ?? playersById[normalizedId],
        convocations: accumulator?.convocations ?? 0,
        starts: accumulator?.starts ?? 0,
        minutesPlayed: accumulator?.minutesPlayed ?? 0,
        goals: accumulator?.goals ?? 0,
        trends: trends,
        displayName: resolvedDisplayName,
      );
    }

    for (final player in rosterPlayers) {
      final memberId = effectiveMemberId(player)?.trim() ?? '';
      if (memberId.isEmpty) {
        continue;
      }
      addStats(memberId, player: player);
    }

    for (final entry in accumulators.entries) {
      addStats(entry.key);
    }

    final result = TeamPlayerStatsResult(
      statsByPlayerId: statsByPlayerId,
      rosterPlayers: rosterPlayers,
    );

    _cacheKey = key;
    _cachedResult = result;
    return result;
  }

  Future<Map<String, TeamPlayerMatchStatsAccumulator>> _loadMatchStats({
    required Match match,
    required String teamId,
    TeamStatsOpponent? opponentFilter,
    Map<String, Player>? opponentPlayersById,
    Map<String, String>? opponentDisplayNamesById,
    required bool useMatchStats,
  }) async {
    final matchId = match.id?.trim() ?? '';
    if (matchId.isEmpty) {
      return const {};
    }

    if (useMatchStats) {
      return _loadMatchStatsFromMatchStatsCollection(
        match: match,
        opponentFilter: opponentFilter,
        opponentPlayersById: opponentPlayersById,
        opponentDisplayNamesById: opponentDisplayNamesById,
      );
    }

    final effectiveTeamId = opponentFilter != null
        ? teamIdForOpponentInMatch(match: match, opponent: opponentFilter)
                ?.trim() ??
            ''
        : teamId.trim();
    if (effectiveTeamId.isEmpty) {
      return const {};
    }

    final compoFuture =
        _matchCompoService.getMatchCompoByMatchAndTeamId(matchId, effectiveTeamId);
    final highlightsFuture = _highlightsService.getHighlightsByMatchCalendarId(
      matchId,
      teamId: effectiveTeamId,
    );

    final results = await Future.wait([compoFuture, highlightsFuture]);
    final compo = results[0] as MatchCompo?;
    final highlights = results[1] as List<Highlights>;

    if (opponentPlayersById != null) {
      registerPlayersFromCompo(opponentPlayersById, compo);
    }

    return statsForMatch(
      match: match,
      compo: compo,
      highlights: highlights,
    );
  }

  Future<Map<String, TeamPlayerMatchStatsAccumulator>>
      _loadMatchStatsFromMatchStatsCollection({
    required Match match,
    required TeamStatsOpponent? opponentFilter,
    required Map<String, Player>? opponentPlayersById,
    required Map<String, String>? opponentDisplayNamesById,
  }) async {
    if (opponentFilter == null) {
      return const {};
    }

    final opponentTeamName = opponentTeamDisplayNameForMatch(
      match: match,
      opponent: opponentFilter,
    );
    if (opponentTeamName == null) {
      return const {};
    }

    final matchId = match.id?.trim() ?? '';
    if (matchId.isEmpty) {
      return const {};
    }

    final matchStats = await _matchStatsService.getMatchStatsByMatchId(matchId);

    if (opponentPlayersById != null) {
      registerPlayersFromMatchStats(
        target: opponentPlayersById,
        displayNames: opponentDisplayNamesById,
        matchStats: matchStats,
        opponentTeamName: opponentTeamName,
      );
    }

    return statsForMatchFromMatchStats(
      match: match,
      matchStats: matchStats,
      opponentTeamName: opponentTeamName,
    );
  }
}
