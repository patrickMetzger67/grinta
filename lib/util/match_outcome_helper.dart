import 'package:grinta/model/match.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:grinta/util/match_goal_helper.dart';

enum MatchOutcome {
  win,
  draw,
  loss,
}

/// Win / draw / loss counts for pie charts and legends.
class TeamWdlCounts {
  const TeamWdlCounts({
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
  });

  final int wins;
  final int draws;
  final int losses;

  int get total => wins + draws + losses;

  bool get isEmpty => total == 0;

  /// Win rate = wins / total played matches (draws count in the denominator).
  double? get winRate => total == 0 ? null : wins / total;

  /// Average league points per match (3 for win, 1 for draw, 0 for loss).
  double? get avgPointsPerMatch =>
      total == 0 ? null : (wins * 3 + draws) / total;

  TeamWdlCounts increment(MatchOutcome outcome) {
    switch (outcome) {
      case MatchOutcome.win:
        return TeamWdlCounts(
          wins: wins + 1,
          draws: draws,
          losses: losses,
        );
      case MatchOutcome.draw:
        return TeamWdlCounts(
          wins: wins,
          draws: draws + 1,
          losses: losses,
        );
      case MatchOutcome.loss:
        return TeamWdlCounts(
          wins: wins,
          draws: draws,
          losses: losses + 1,
        );
    }
  }

  static TeamWdlCounts fromMatches({
    required Iterable<Match> matches,
    required String teamId,
    String? clubId,
    String? clubAffiliation,
    String? displayName,
  }) {
    var counts = const TeamWdlCounts();
    for (final match in matches) {
      final outcome = matchOutcomeForTeam(
        match: match,
        teamId: teamId,
        clubId: clubId,
        clubAffiliation: clubAffiliation,
        displayName: displayName,
      );
      if (outcome != null) {
        counts = counts.increment(outcome);
      }
    }
    return counts;
  }
}

enum TeamWdlTrendDirection {
  up,
  down,
  flat,
  insufficientData,
}

/// Trend comparing average points per match between season halves.
class TeamWdlHalfTrend {
  const TeamWdlHalfTrend({
    required this.direction,
    this.firstHalfPointsPerMatch,
    this.secondHalfPointsPerMatch,
  });

  final TeamWdlTrendDirection direction;
  final double? firstHalfPointsPerMatch;
  final double? secondHalfPointsPerMatch;

  /// Compares [firstHalf] vs [secondHalf] average points per match (3/1/0).
  /// [flatThreshold] is the absolute points-per-match delta treated as stable
  /// (default 0.10 ≈ one point every ten matches).
  static TeamWdlHalfTrend compare({
    required TeamWdlCounts firstHalf,
    required TeamWdlCounts secondHalf,
    double flatThreshold = 0.10,
  }) {
    final firstRate = firstHalf.avgPointsPerMatch;
    final secondRate = secondHalf.avgPointsPerMatch;
    if (firstRate == null || secondRate == null) {
      return const TeamWdlHalfTrend(
        direction: TeamWdlTrendDirection.insufficientData,
      );
    }

    final diff = secondRate - firstRate;
    if (diff.abs() <= flatThreshold) {
      return TeamWdlHalfTrend(
        direction: TeamWdlTrendDirection.flat,
        firstHalfPointsPerMatch: firstRate,
        secondHalfPointsPerMatch: secondRate,
      );
    }

    return TeamWdlHalfTrend(
      direction: diff > 0
          ? TeamWdlTrendDirection.up
          : TeamWdlTrendDirection.down,
      firstHalfPointsPerMatch: firstRate,
      secondHalfPointsPerMatch: secondRate,
    );
  }
}

/// Filters [matches] to those with the given [outcome] for the team.
List<Match> filterMatchesByOutcome({
  required List<Match> matches,
  required MatchOutcome outcome,
  required String teamId,
  String? clubId,
  String? clubAffiliation,
  String? displayName,
}) {
  return matches
      .where(
        (match) =>
            matchOutcomeForTeam(
              match: match,
              teamId: teamId,
              clubId: clubId,
              clubAffiliation: clubAffiliation,
              displayName: displayName,
            ) ==
            outcome,
      )
      .toList();
}

/// Returns win/draw/loss from the team's perspective for a played match.
MatchOutcome? matchOutcomeForTeam({
  required Match match,
  required String teamId,
  String? clubId,
  String? clubAffiliation,
  String? displayName,
}) {
  if (match.isMatchPlayed != true) {
    return null;
  }

  final MatchSide? side = teamSideForMatch(
    match: match,
    teamId: teamId,
    clubId: clubId,
    clubAffiliation: clubAffiliation,
    displayName: displayName,
  );
  if (side == null) {
    return null;
  }

  if (side == MatchSide.team1 && match.isTeam1Forfeit == true) {
    return MatchOutcome.loss;
  }
  if (side == MatchSide.team2 && match.isTeam2Forfeit == true) {
    return MatchOutcome.loss;
  }
  if (side == MatchSide.team1 && match.isTeam2Forfeit == true) {
    return MatchOutcome.win;
  }
  if (side == MatchSide.team2 && match.isTeam1Forfeit == true) {
    return MatchOutcome.win;
  }

  final int homeScore = match.homeScore ?? 0;
  final int awayScore = match.outSideScore ?? 0;

  final int teamScore = side == MatchSide.team1 ? homeScore : awayScore;
  final int opponentScore = side == MatchSide.team1 ? awayScore : homeScore;

  if (teamScore == opponentScore) {
    return MatchOutcome.draw;
  }
  if (teamScore > opponentScore) {
    return MatchOutcome.win;
  }
  return MatchOutcome.loss;
}

/// Goals scored and conceded from the team's perspective for a played match.
class TeamGoalsCounts {
  const TeamGoalsCounts({
    this.scored = 0,
    this.conceded = 0,
    this.matchCount = 0,
  });

  final int scored;
  final int conceded;
  final int matchCount;

  bool get isEmpty => matchCount == 0;

  /// Average goals scored per played match in this period.
  double? get avgScoredPerMatch =>
      matchCount == 0 ? null : scored / matchCount;

  /// Average goals conceded per played match in this period.
  double? get avgConcededPerMatch =>
      matchCount == 0 ? null : conceded / matchCount;

  static TeamGoalsCounts fromMatches({
    required Iterable<Match> matches,
    required String teamId,
    String? clubId,
    String? clubAffiliation,
    String? displayName,
  }) {
    var scored = 0;
    var conceded = 0;
    var matchCount = 0;

    for (final match in matches) {
      final goals = goalsForTeam(
        match: match,
        teamId: teamId,
        clubId: clubId,
        clubAffiliation: clubAffiliation,
        displayName: displayName,
      );
      if (goals == null) continue;

      matchCount++;
      scored += goals.$1;
      conceded += goals.$2;
    }

    return TeamGoalsCounts(
      scored: scored,
      conceded: conceded,
      matchCount: matchCount,
    );
  }
}

/// Trend comparing a per-match rate between season halves.
class TeamGoalsMetricHalfTrend {
  const TeamGoalsMetricHalfTrend({
    required this.direction,
    this.firstHalfRate,
    this.secondHalfRate,
  });

  final TeamWdlTrendDirection direction;
  final double? firstHalfRate;
  final double? secondHalfRate;

  /// Higher scored rate in H2 vs H1 is positive (up).
  static TeamGoalsMetricHalfTrend compareScored({
    required TeamGoalsCounts firstHalf,
    required TeamGoalsCounts secondHalf,
    double flatThreshold = 0.05,
  }) {
    return _compareRates(
      firstRate: firstHalf.avgScoredPerMatch,
      secondRate: secondHalf.avgScoredPerMatch,
      higherIsBetter: true,
      flatThreshold: flatThreshold,
    );
  }

  /// Lower conceded rate in H2 vs H1 is positive (up).
  static TeamGoalsMetricHalfTrend compareConceded({
    required TeamGoalsCounts firstHalf,
    required TeamGoalsCounts secondHalf,
    double flatThreshold = 0.05,
  }) {
    return _compareRates(
      firstRate: firstHalf.avgConcededPerMatch,
      secondRate: secondHalf.avgConcededPerMatch,
      higherIsBetter: false,
      flatThreshold: flatThreshold,
    );
  }

  static TeamGoalsMetricHalfTrend _compareRates({
    required double? firstRate,
    required double? secondRate,
    required bool higherIsBetter,
    required double flatThreshold,
  }) {
    if (firstRate == null || secondRate == null) {
      return const TeamGoalsMetricHalfTrend(
        direction: TeamWdlTrendDirection.insufficientData,
      );
    }

    final diff = secondRate - firstRate;
    if (diff.abs() <= flatThreshold) {
      return TeamGoalsMetricHalfTrend(
        direction: TeamWdlTrendDirection.flat,
        firstHalfRate: firstRate,
        secondHalfRate: secondRate,
      );
    }

    final bool improved = higherIsBetter ? diff > 0 : diff < 0;
    return TeamGoalsMetricHalfTrend(
      direction: improved
          ? TeamWdlTrendDirection.up
          : TeamWdlTrendDirection.down,
      firstHalfRate: firstRate,
      secondHalfRate: secondRate,
    );
  }
}

/// H1 vs H2 trends for goals scored and conceded.
class TeamGoalsHalfTrends {
  const TeamGoalsHalfTrends({
    required this.scored,
    required this.conceded,
  });

  final TeamGoalsMetricHalfTrend scored;
  final TeamGoalsMetricHalfTrend conceded;

  static TeamGoalsHalfTrends compare({
    required TeamGoalsCounts firstHalf,
    required TeamGoalsCounts secondHalf,
  }) {
    return TeamGoalsHalfTrends(
      scored: TeamGoalsMetricHalfTrend.compareScored(
        firstHalf: firstHalf,
        secondHalf: secondHalf,
      ),
      conceded: TeamGoalsMetricHalfTrend.compareConceded(
        firstHalf: firstHalf,
        secondHalf: secondHalf,
      ),
    );
  }
}

/// Returns (scored, conceded) from the team's perspective, or null if unknown.
(int, int)? goalsForTeam({
  required Match match,
  required String teamId,
  String? clubId,
  String? clubAffiliation,
  String? displayName,
}) {
  if (match.isMatchPlayed != true) {
    return null;
  }

  final MatchSide? side = teamSideForMatch(
    match: match,
    teamId: teamId,
    clubId: clubId,
    clubAffiliation: clubAffiliation,
    displayName: displayName,
  );
  if (side == null) {
    return null;
  }

  final int homeScore = match.homeScore ?? 0;
  final int awayScore = match.outSideScore ?? 0;

  final int teamScore = side == MatchSide.team1 ? homeScore : awayScore;
  final int opponentScore = side == MatchSide.team1 ? awayScore : homeScore;

  return (teamScore, opponentScore);
}

MatchSide? teamSideForMatch({
  required Match match,
  required String teamId,
  String? clubId,
  String? clubAffiliation,
  String? displayName,
}) {
  final String trimmedTeamId = teamId.trim();
  final String trimmedClubId = clubId?.trim() ?? '';
  final String trimmedAffiliation = clubAffiliation?.trim() ?? '';

  bool matchesIdentifier(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return false;
    return normalized == trimmedClubId || normalized == trimmedAffiliation;
  }

  // Affiliation / clubs win over [Match.teams] index. Shared matches store
  // home then away Grinta ids, but the session team we open stats for must
  // follow the FFF club under the logo (500554 away ≠ teams[0] home).
  if (trimmedClubId.isNotEmpty || trimmedAffiliation.isNotEmpty) {
    if (matchesIdentifier(match.affiliationTeam1)) {
      return MatchSide.team1;
    }
    if (matchesIdentifier(match.affiliationTeam2)) {
      return MatchSide.team2;
    }

    final List<dynamic> clubs = match.clubs ?? const <dynamic>[];
    for (var i = 0; i < clubs.length && i < 2; i++) {
      final club = clubs[i]?.toString().trim() ?? '';
      if (club.isEmpty) {
        continue;
      }
      if (club == trimmedClubId || club == trimmedAffiliation) {
        return i == 0 ? MatchSide.team1 : MatchSide.team2;
      }
    }
  }

  if (trimmedTeamId.isNotEmpty) {
    final List<String> linkedTeamIds =
        normalizeTeamIdList(match.teams ?? const <dynamic>[]);
    final int linkedIndex = linkedTeamIds.indexOf(trimmedTeamId);

    // Matches often store only our team id in [teams]. Index 0 then does NOT
    // mean home — use isOwnClub (home=team1 / away=team2), same as teamIdForSide.
    if (linkedIndex >= 0) {
      if (linkedTeamIds.length == 1 && match.isOwnClub != null) {
        return match.isOwnClub == true ? MatchSide.team1 : MatchSide.team2;
      }
      if (linkedIndex == 0) {
        return MatchSide.team1;
      }
      if (linkedIndex == 1) {
        return MatchSide.team2;
      }
    }

    final String? primaryTeamId = match.teamID?.trim();
    if (primaryTeamId == trimmedTeamId) {
      if (match.isOwnClub == true) {
        return MatchSide.team1;
      }
      if (match.isOwnClub == false) {
        return MatchSide.team2;
      }
    }
  }

  final String normalizedDisplayName = _normalizeTeamDisplayName(displayName);
  if (normalizedDisplayName.isNotEmpty) {
    final String team1Name =
        _normalizeTeamDisplayName(match.team1).toLowerCase();
    final String team2Name =
        _normalizeTeamDisplayName(match.team2).toLowerCase();
    final String needle = normalizedDisplayName.toLowerCase();
    if (team1Name == needle) {
      return MatchSide.team1;
    }
    if (team2Name == needle) {
      return MatchSide.team2;
    }
  }

  return null;
}

String _normalizeTeamDisplayName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty || trimmed.contains('Exempt')) {
    return '';
  }
  return trimmed;
}
