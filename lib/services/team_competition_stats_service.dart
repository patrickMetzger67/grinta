import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/ranking.dart';
import 'package:grinta/model/rankingPerDay.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/clubService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/ranking_per_day_service.dart';
import 'package:grinta/services/ranking_service.dart';
import 'package:grinta/services/seasonService.dart';
import 'package:grinta/util/buildTimestampFromDateAndTime.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/season_period_ranges.dart';
import 'package:grinta/util/team_stats_competition_filter.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';
import 'package:grinta/util/team_stats_ranking_helper.dart';

/// W/D/L counts and played matches for a single period.
class TeamWdlPeriodData {
  const TeamWdlPeriodData({
    required this.counts,
    required this.matches,
  });

  final TeamWdlCounts counts;
  final List<Match> matches;
}

/// W/D/L stats split across full season and both halves.
class TeamWdlStatsByPeriod {
  const TeamWdlStatsByPeriod({
    required this.fullSeason,
    required this.firstHalf,
    required this.secondHalf,
    required this.teamId,
    this.clubId,
    this.clubAffiliation,
    this.perspectiveDisplayName,
  });

  final TeamWdlPeriodData fullSeason;
  final TeamWdlPeriodData firstHalf;
  final TeamWdlPeriodData secondHalf;
  final String teamId;
  final String? clubId;
  final String? clubAffiliation;
  final String? perspectiveDisplayName;
}

/// Goals scored/conceded split across full season and both halves.
class TeamGoalsStatsByPeriod {
  const TeamGoalsStatsByPeriod({
    required this.fullSeason,
    required this.firstHalf,
    required this.secondHalf,
  });

  final TeamGoalsCounts fullSeason;
  final TeamGoalsCounts firstHalf;
  final TeamGoalsCounts secondHalf;
}

class _TeamMatchStatsContext {
  const _TeamMatchStatsContext({
    required this.matches,
    required this.teamId,
    required this.clubId,
    required this.clubAffiliation,
    required this.periods,
    this.perspectiveDisplayName,
  });

  final List<Match> matches;
  final String teamId;
  final String clubId;
  final String? clubAffiliation;
  final SeasonPeriodRanges periods;
  final String? perspectiveDisplayName;
}

class TeamCompetitionStatsService {
  TeamCompetitionStatsService({
    MatchService? matchService,
    SeasonService? seasonService,
    ClubService? clubService,
    RankingService? rankingService,
    RankingPerDayService? rankingPerDayService,
  })  : _matchService = matchService ?? MatchService(),
        _seasonService = seasonService ?? SeasonService(),
        _clubService = clubService ?? ClubService(),
        _rankingService = rankingService ?? RankingService(),
        _rankingPerDayService = rankingPerDayService ?? RankingPerDayService();

  final MatchService _matchService;
  final SeasonService _seasonService;
  final ClubService _clubService;
  final RankingService _rankingService;
  final RankingPerDayService _rankingPerDayService;

  /// Loads played matches for [team] in the current [seasonId] and computes
  /// win/draw/loss counts for the full season and each half.
  Future<TeamWdlStatsByPeriod> computeWdlStatsForTeam({
    required Team team,
    required String seasonId,
    String? competitionUrl,
    TeamStatsOpponent? opponentFilter,
  }) async {
    final context = await _loadMatchContext(
      team: team,
      seasonId: seasonId,
      competitionUrl: competitionUrl,
      opponentFilter: opponentFilter,
    );
    if (context == null) {
      const emptyPeriod = TeamWdlPeriodData(
        counts: TeamWdlCounts(),
        matches: <Match>[],
      );
      return const TeamWdlStatsByPeriod(
        fullSeason: emptyPeriod,
        firstHalf: emptyPeriod,
        secondHalf: emptyPeriod,
        teamId: '',
      );
    }

    TeamWdlPeriodData dataForPeriod(SeasonPeriodRange period) {
      final filtered = context.matches.where((match) {
        final date = matchDateForTeamStats(match);
        return date != null && period.contains(date);
      }).toList();
      return TeamWdlPeriodData(
        counts: TeamWdlCounts.fromMatches(
          matches: filtered,
          teamId: context.teamId,
          clubId: context.clubId.isEmpty ? null : context.clubId,
          clubAffiliation: context.clubAffiliation,
          displayName: context.perspectiveDisplayName,
        ),
        matches: filtered,
      );
    }

    return TeamWdlStatsByPeriod(
      fullSeason: dataForPeriod(context.periods.fullSeason),
      firstHalf: dataForPeriod(context.periods.firstHalf),
      secondHalf: dataForPeriod(context.periods.secondHalf),
      teamId: context.teamId,
      clubId: context.clubId.isEmpty ? null : context.clubId,
      clubAffiliation: context.clubAffiliation,
      perspectiveDisplayName: context.perspectiveDisplayName,
    );
  }

  /// Loads played matches for [team] in the current [seasonId] and computes
  /// goals scored/conceded for the full season and each half.
  /// Played matches for [team] in [seasonId] (full season window).
  Future<List<Match>> loadPlayedSeasonMatches({
    required Team team,
    required String seasonId,
    String? competitionUrl,
    TeamStatsOpponent? opponentFilter,
  }) async {
    final context = await _loadMatchContext(
      team: team,
      seasonId: seasonId,
      competitionUrl: competitionUrl,
      opponentFilter: opponentFilter,
    );
    return context?.matches ?? const [];
  }

  /// Clubs in the [competitionUrl] pool for the opponent dropdown.
  ///
  /// Championships list every team in the poule (ranking + pool matches).
  /// Cups list only opponents actually faced by [team].
  Future<List<TeamStatsOpponent>> loadOpponentsForTeam({
    required Team team,
    required String seasonId,
    required String competitionUrl,
  }) async {
    final matches = await loadCompetitionCalendarMatches(
      team: team,
      seasonId: seasonId,
      competitionUrl: competitionUrl,
    );

    final teamId = team.keyTeam?.trim() ?? '';
    final clubId = team.clubId?.trim() ?? '';
    final String? clubAffiliation = clubId.isEmpty
        ? null
        : (await _clubService.getClubById(clubId))?.affiliation?.trim();

    final filter = competitionFilterFromUrl(competitionUrl);
    final competitionId = filter?.engagementId?.trim() ?? '';
    if (filter == null || competitionId.isEmpty) {
      return buildCompetitionClubList(
        matches: matches,
        teamId: teamId,
        clubId: clubId.isEmpty ? null : clubId,
        clubAffiliation: clubAffiliation,
      );
    }

    final poule = filter.groupe.toString();
    final results = await Future.wait([
      _rankingService.getRankingsByCompetitionIdAndPoule(
        competitionId: competitionId,
        poule: poule,
      ),
      _rankingPerDayService.getRankingsPerDayByCompetitionIdAndPoule(
        competitionId: competitionId,
        poule: poule,
      ),
    ]);

    final rankings = results[0] as List<Ranking>;
    final perDayEntries = results[1] as List<RankingPerDay>;
    final ranking = pickBestRankingDocument(rankings);
    final affiliatesByTeamName = <String, String>{};
    for (final entry in perDayEntries) {
      final displayName = normalizeOpponentDisplayName(entry.teamName);
      final affiliate = entry.teamAffiliate?.trim() ?? '';
      if (displayName.isEmpty || affiliate.isEmpty) {
        continue;
      }
      affiliatesByTeamName.putIfAbsent(displayName.toLowerCase(), () => affiliate);
    }

    return buildCompetitionClubList(
      matches: matches,
      ranking: ranking,
      affiliatesByTeamName: affiliatesByTeamName,
      teamId: teamId,
      clubId: clubId.isEmpty ? null : clubId,
      clubAffiliation: clubAffiliation,
    );
  }

  /// All season matches (played and upcoming) in the selected competition
  /// pool for [competitionUrl] — every match in that poule/stage, not only
  /// [team]'s fixtures.
  Future<List<Match>> loadCompetitionCalendarMatches({
    required Team team,
    required String seasonId,
    required String competitionUrl,
  }) async {
    final String normalizedSeasonId = seasonId.trim();
    final String normalizedCompetitionUrl = competitionUrl.trim();

    if (normalizedSeasonId.isEmpty || normalizedCompetitionUrl.isEmpty) {
      return const [];
    }

    final filter = competitionFilterFromUrl(normalizedCompetitionUrl);
    final String competitionId = filter?.engagementId?.trim() ?? '';
    if (filter == null || competitionId.isEmpty) {
      return const [];
    }

    final season = await _seasonService.getSeasonById(normalizedSeasonId);
    final periods = resolveSeasonPeriodRanges(
      seasonId: normalizedSeasonId,
      season: season,
    );

    final Timestamp start = Timestamp.fromDate(
      DateTime(
        periods.fullSeason.start.year,
        periods.fullSeason.start.month,
        periods.fullSeason.start.day,
      ),
    );
    final Timestamp end = Timestamp.fromDate(
      DateTime(
        periods.fullSeason.end.year,
        periods.fullSeason.end.month,
        periods.fullSeason.end.day,
        23,
        59,
        59,
        999,
      ),
    );

    final poolMatches = (await _matchService
            .getMatchesByCompetitionPouleStageBetweenDates(
          competitionId: competitionId,
          poule: filter.groupe.toString(),
          stage: filter.phase.toString(),
          start: start,
          end: end,
        ))
        .where((match) {
      final matchSeasonId = match.seasonID?.trim() ?? '';
      if (matchSeasonId.isNotEmpty && matchSeasonId != normalizedSeasonId) {
        return false;
      }
      return true;
    }).toList();

    final matchesById = <String, Match>{};
    for (final match in poolMatches) {
      final matchId = match.id?.trim();
      if (matchId != null && matchId.isNotEmpty) {
        matchesById[matchId] = match;
      }
    }

    final teamId = team.keyTeam?.trim() ?? '';
    final clubId = team.clubId?.trim() ?? '';
    if (teamId.isNotEmpty) {
      final teamMatches = filterMatchesByCompetition(
        await _loadSeasonMatches(
          teamId: teamId,
          clubId: clubId,
          seasonId: normalizedSeasonId,
          period: periods.fullSeason,
        ),
        filter: filter,
      );
      for (final match in teamMatches) {
        final matchId = match.id?.trim();
        if (matchId != null && matchId.isNotEmpty) {
          matchesById[matchId] = match;
        }
      }
    }

    return List<Match>.from(matchesById.values)
      ..sort((a, b) {
        final dateA = matchDateForTeamStats(a);
        final dateB = matchDateForTeamStats(b);
        if (dateA == null && dateB == null) {
          return 0;
        }
        if (dateA == null) {
          return 1;
        }
        if (dateB == null) {
          return -1;
        }
        return dateA.compareTo(dateB);
      });
  }

  Future<TeamGoalsStatsByPeriod> computeGoalsStatsForTeam({
    required Team team,
    required String seasonId,
    String? competitionUrl,
    TeamStatsOpponent? opponentFilter,
  }) async {
    final context = await _loadMatchContext(
      team: team,
      seasonId: seasonId,
      competitionUrl: competitionUrl,
      opponentFilter: opponentFilter,
    );
    if (context == null) {
      return const TeamGoalsStatsByPeriod(
        fullSeason: TeamGoalsCounts(),
        firstHalf: TeamGoalsCounts(),
        secondHalf: TeamGoalsCounts(),
      );
    }

    TeamGoalsCounts countsForPeriod(SeasonPeriodRange period) {
      final filtered = context.matches.where((match) {
        final date = matchDateForTeamStats(match);
        return date != null && period.contains(date);
      });
      return TeamGoalsCounts.fromMatches(
        matches: filtered,
        teamId: context.teamId,
        clubId: context.clubId.isEmpty ? null : context.clubId,
        clubAffiliation: context.clubAffiliation,
      );
    }

    return TeamGoalsStatsByPeriod(
      fullSeason: countsForPeriod(context.periods.fullSeason),
      firstHalf: countsForPeriod(context.periods.firstHalf),
      secondHalf: countsForPeriod(context.periods.secondHalf),
    );
  }

  Future<_TeamMatchStatsContext?> _loadMatchContext({
    required Team team,
    required String seasonId,
    String? competitionUrl,
    TeamStatsOpponent? opponentFilter,
  }) async {
    final String teamId = team.keyTeam?.trim() ?? '';
    final String clubId = team.clubId?.trim() ?? '';
    final String normalizedSeasonId = seasonId.trim();
    final String normalizedCompetitionUrl = competitionUrl?.trim() ?? '';

    if (teamId.isEmpty || normalizedSeasonId.isEmpty) {
      return null;
    }

    final season = await _seasonService.getSeasonById(normalizedSeasonId);
    final periods = resolveSeasonPeriodRanges(
      seasonId: normalizedSeasonId,
      season: season,
    );

    final String? clubAffiliation =
        clubId.isEmpty ? null : (await _clubService.getClubById(clubId))?.affiliation;

    if (opponentFilter != null && normalizedCompetitionUrl.isNotEmpty) {
      final poolMatches = await loadCompetitionCalendarMatches(
        team: team,
        seasonId: normalizedSeasonId,
        competitionUrl: normalizedCompetitionUrl,
      );
      final matches = filterMatchesByOpponent(
        matches: poolMatches
            .where((match) => match.isMatchPlayed == true)
            .toList(),
        opponent: opponentFilter,
      );

      return _TeamMatchStatsContext(
        matches: matches,
        teamId: '',
        clubId: opponentFilter.clubId?.trim() ?? '',
        clubAffiliation: opponentFilter.affiliation?.trim(),
        periods: periods,
        perspectiveDisplayName: opponentFilter.displayName,
      );
    }

    final filteredByCompetition = filterMatchesByCompetition(
      await _loadPlayedSeasonMatches(
        teamId: teamId,
        clubId: clubId,
        seasonId: normalizedSeasonId,
        period: periods.fullSeason,
      ),
      filter: competitionFilterFromUrl(competitionUrl),
    );

    return _TeamMatchStatsContext(
      matches: filteredByCompetition,
      teamId: teamId,
      clubId: clubId,
      clubAffiliation: clubAffiliation?.trim(),
      periods: periods,
    );
  }

  Future<List<Match>> _loadPlayedSeasonMatches({
    required String teamId,
    required String clubId,
    required String seasonId,
    required SeasonPeriodRange period,
  }) async {
    final matches = await _loadSeasonMatches(
      teamId: teamId,
      clubId: clubId,
      seasonId: seasonId,
      period: period,
    );

    return matches.where((match) => match.isMatchPlayed == true).toList();
  }

  Future<List<Match>> _loadSeasonMatches({
    required String teamId,
    required String clubId,
    required String seasonId,
    required SeasonPeriodRange period,
  }) async {
    final Timestamp start = Timestamp.fromDate(
      DateTime(period.start.year, period.start.month, period.start.day),
    );
    final Timestamp end = Timestamp.fromDate(
      DateTime(
        period.end.year,
        period.end.month,
        period.end.day,
        23,
        59,
        59,
        999,
      ),
    );

    final matches = await _matchService.getMatchesForTeamEngagementsBetweenDates(
      teamId: teamId,
      clubId: clubId,
      seasonId: seasonId,
      start: start,
      end: end,
    );

    return matches.where((match) {
      final matchSeasonId = match.seasonID?.trim() ?? '';
      if (matchSeasonId.isNotEmpty && matchSeasonId != seasonId) {
        return false;
      }

      return true;
    }).toList();
  }
}

/// Calendar date for a match, used when splitting stats by season half.
DateTime? matchDateForTeamStats(Match match) {
  if (match.timestamp != null) {
    return match.timestamp!.toDate();
  }

  final dateCh = match.dateCh?.trim() ?? '';
  final timeCh = match.timeCh?.trim() ?? '';
  if (dateCh.isEmpty) {
    return null;
  }

  return buildTimestampFromDateAndTime(
    date: dateCh,
    time: timeCh.isEmpty ? '00:00' : timeCh,
  ).toDate();
}
