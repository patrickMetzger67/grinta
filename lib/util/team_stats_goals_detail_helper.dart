import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_outcome_helper.dart';

/// Whether the tapped goals histogram bar is scored or conceded.
enum TeamStatsGoalBarKind {
  scored,
  conceded,
}

/// One goal event for the team-stats goals detail dialog.
class TeamStatsGoalDetail {
  const TeamStatsGoalDetail({
    required this.match,
    required this.kind,
    required this.minute,
    required this.extraTime,
    required this.goal,
  });

  final Match match;
  final TeamStatsGoalBarKind kind;
  final int minute;
  final int extraTime;
  final Goal goal;

  /// Minute label matching Grinta highlights UI (`12'` / `45'+2`).
  String get minuteLabel {
    if (extraTime > 0) {
      return "$minute'+$extraTime";
    }
    return "$minute'";
  }

  /// Best available scorer label (name, `#N name`, `#N`, or [unknownLabel]).
  String scorerLabel({required String unknownLabel}) {
    return goalHighlightLabel(goal: goal, fallback: unknownLabel);
  }

  /// Match identity with score when known (`Home 2-1 Away`).
  String matchLabel() {
    final home = (match.team1 ?? '').trim();
    final away = (match.team2 ?? '').trim();
    final homeScore = match.homeScore;
    final awayScore = match.outSideScore;

    final left = home.isEmpty ? '—' : home;
    final right = away.isEmpty ? '—' : away;

    if (homeScore != null && awayScore != null) {
      return '$left $homeScore-$awayScore $right';
    }
    if (home.isNotEmpty && away.isNotEmpty) {
      return '$left - $right';
    }
    return home.isNotEmpty ? home : away;
  }
}

/// Collects scored or conceded goal highlights for [match] from the team's
/// perspective, reusing affiliation / side helpers from match sheets.
List<TeamStatsGoalDetail> teamGoalDetailsFromHighlights({
  required Match match,
  required Iterable<Highlights> highlights,
  required TeamStatsGoalBarKind kind,
  required String teamId,
  String? clubId,
  String? clubAffiliation,
  String? displayName,
}) {
  final MatchSide? teamSide = teamSideForMatch(
    match: match,
    teamId: teamId,
    clubId: clubId,
    clubAffiliation: clubAffiliation,
    displayName: displayName,
  );
  if (teamSide == null) {
    return const [];
  }

  final MatchSide opponentSide =
      teamSide == MatchSide.team1 ? MatchSide.team2 : MatchSide.team1;
  final MatchSide wantedSide =
      kind == TeamStatsGoalBarKind.scored ? teamSide : opponentSide;

  final details = <TeamStatsGoalDetail>[];
  for (final highlight in highlights) {
    if (highlight.actionType != ActionType.goal) {
      continue;
    }
    final Goal? goal = highlight.value is Goal ? highlight.value as Goal : null;
    if (goal == null) {
      continue;
    }
    final MatchSide? goalSide = sideForAffiliationTeam(
      match,
      goal.affiliationTeam,
    );
    if (goalSide != wantedSide) {
      continue;
    }
    details.add(
      TeamStatsGoalDetail(
        match: match,
        kind: kind,
        minute: highlight.minute ?? 0,
        extraTime: highlight.extraTime ?? 0,
        goal: goal,
      ),
    );
  }

  details.sort((a, b) {
    final minuteCmp = a.minute.compareTo(b.minute);
    if (minuteCmp != 0) {
      return minuteCmp;
    }
    return a.extraTime.compareTo(b.extraTime);
  });
  return details;
}

/// Chronological sort for goal details across several matches.
List<TeamStatsGoalDetail> sortTeamGoalDetails(
  Iterable<TeamStatsGoalDetail> details,
) {
  final sorted = List<TeamStatsGoalDetail>.from(details);
  sorted.sort((a, b) {
    final dateA = matchDateForTeamStats(a.match);
    final dateB = matchDateForTeamStats(b.match);
    if (dateA == null && dateB == null) {
      // fall through
    } else if (dateA == null) {
      return 1;
    } else if (dateB == null) {
      return -1;
    } else {
      final dateCmp = dateA.compareTo(dateB);
      if (dateCmp != 0) {
        return dateCmp;
      }
    }
    final minuteCmp = a.minute.compareTo(b.minute);
    if (minuteCmp != 0) {
      return minuteCmp;
    }
    return a.extraTime.compareTo(b.extraTime);
  });
  return sorted;
}

/// Aggregated goal count for one scorer in the goals detail ranking tab.
class TeamStatsGoalScorerRank {
  const TeamStatsGoalScorerRank({
    required this.identityKey,
    required this.displayName,
    required this.goalCount,
  });

  /// Stable identity used for grouping (`id:…` or `name:…`).
  final String identityKey;

  /// Best available label for UI (name / `#N` / unknown).
  final String displayName;

  final int goalCount;
}

/// Groups [details] by player identity and sorts by goal count descending.
///
/// Identity prefers non-empty [Goal.playerId]; otherwise the display label
/// (case-insensitive) so duplicate names without ids stay merged.
List<TeamStatsGoalScorerRank> aggregateTeamGoalScorers(
  Iterable<TeamStatsGoalDetail> details, {
  required String unknownLabel,
}) {
  final byKey = <String, _ScorerAgg>{};

  for (final detail in details) {
    final playerId = detail.goal.playerId?.trim() ?? '';
    final label = detail.scorerLabel(unknownLabel: unknownLabel);
    final key = playerId.isNotEmpty
        ? 'id:${playerId.toLowerCase()}'
        : 'name:${label.toLowerCase()}';

    final existing = byKey[key];
    if (existing == null) {
      byKey[key] = _ScorerAgg(displayName: label, goalCount: 1);
      continue;
    }
    existing.goalCount += 1;
    // Prefer a richer label if a later entry has a real name over `#N`.
    if (_scorerLabelRank(label) > _scorerLabelRank(existing.displayName)) {
      existing.displayName = label;
    }
  }

  final ranks = byKey.entries
      .map(
        (entry) => TeamStatsGoalScorerRank(
          identityKey: entry.key,
          displayName: entry.value.displayName,
          goalCount: entry.value.goalCount,
        ),
      )
      .toList();

  ranks.sort((a, b) {
    final countCmp = b.goalCount.compareTo(a.goalCount);
    if (countCmp != 0) {
      return countCmp;
    }
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
  return ranks;
}

class _ScorerAgg {
  _ScorerAgg({
    required this.displayName,
    required this.goalCount,
  });

  String displayName;
  int goalCount;
}

int _scorerLabelRank(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) {
    return 0;
  }
  if (trimmed.startsWith('#')) {
    return 1;
  }
  return 2;
}
