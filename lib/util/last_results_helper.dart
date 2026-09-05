import 'package:grinta/model/last_results.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';

const int lastResultsSlotCount = 5;

/// Club id used as `lastResults` key for [side]: `match.clubs[0/1]` only.
///
/// Do not use `affiliationTeam1` / `affiliationTeam2` — those FFF ids do not
/// match `lastResults/{clubId}_{competitionId}` written from `clubs[]`.
String? clubIdForLastResults(Match match, MatchSide side) {
  return clubIdForMatchSide(match: match, side: side);
}

/// Lookup key for one club on [match], or null when club/competition is missing.
LastResultsKey? lastResultsKeyForMatchSide(Match match, MatchSide side) {
  return lastResultsKeyFromIds(
    clubId: clubIdForLastResults(match, side),
    competitionId: match.competitionID,
  );
}

/// Keys to read for both clubs on [match].
List<LastResultsKey> lastResultsKeysForMatch(Match match) {
  final competitionId = match.competitionID?.trim() ?? '';
  if (competitionId.isEmpty) {
    return const <LastResultsKey>[];
  }

  final keys = <LastResultsKey>[];
  final seen = <String>{};
  for (final side in MatchSide.values) {
    final clubId = clubIdForLastResults(match, side);
    final key = lastResultsKeyFromIds(
      clubId: clubId,
      competitionId: competitionId,
    );
    if (key == null || !seen.add(key.documentId)) {
      continue;
    }
    keys.add(key);
  }
  return keys;
}

/// Unique club+competition keys found on [matches].
Set<LastResultsKey> lastResultsKeysFromMatches(Iterable<Match> matches) {
  final keys = <LastResultsKey>{};
  for (final match in matches) {
    keys.addAll(lastResultsKeysForMatch(match));
  }
  return keys;
}

/// Last [lastResultsSlotCount] played results for [clubId] in [competitionId].
///
/// Oldest first. Upcoming / unplayed / exempt matches are omitted.
List<LastResultEntry> computeLastResultsForClub({
  required Iterable<Match> matches,
  required String clubId,
  required String competitionId,
  int limit = lastResultsSlotCount,
}) {
  final trimmedClubId = clubId.trim();
  final trimmedCompetitionId = competitionId.trim();
  if (trimmedClubId.isEmpty || trimmedCompetitionId.isEmpty || limit <= 0) {
    return const <LastResultEntry>[];
  }

  final played = <({Match match, MatchOutcome outcome, DateTime date})>[];
  for (final match in matches) {
    if ((match.competitionID?.trim() ?? '') != trimmedCompetitionId) {
      continue;
    }
    if (match.isMatchPlayed != true) {
      continue;
    }
    if (_isExemptMatch(match)) {
      continue;
    }

    final outcome = matchOutcomeForTeam(
      match: match,
      teamId: '',
      clubId: trimmedClubId,
    );
    if (outcome == null) {
      continue;
    }

    final date = matchDateForTeamStats(match);
    if (date == null) {
      continue;
    }

    played.add((match: match, outcome: outcome, date: date));
  }

  played.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) {
      return byDate;
    }
    return (a.match.id ?? '').compareTo(b.match.id ?? '');
  });

  final start = played.length > limit ? played.length - limit : 0;
  return played
      .sublist(start)
      .map(
        (entry) => LastResultEntry(
          outcome: entry.outcome,
          matchId: entry.match.id?.trim(),
          timestamp: entry.match.timestamp,
        ),
      )
      .toList(growable: false);
}

/// One [LastResults] document per club seen in [matches], grouped by competition.
Map<LastResultsKey, LastResults> computeLastResultsByClub(
  Iterable<Match> matches, {
  int limit = lastResultsSlotCount,
}) {
  final keys = lastResultsKeysFromMatches(matches);
  final byKey = <LastResultsKey, LastResults>{};
  for (final key in keys) {
    byKey[key] = LastResults(
      clubId: key.clubId,
      competitionId: key.competitionId,
      results: computeLastResultsForClub(
        matches: matches,
        clubId: key.clubId,
        competitionId: key.competitionId,
        limit: limit,
      ),
    );
  }
  return byKey;
}

/// Competitions whose `lastResults` docs are missing or older than a new result.
Set<String> competitionsNeedingRefresh({
  required Iterable<Match> matches,
  required Map<String, LastResults?> existingByDocId,
}) {
  final keys = lastResultsKeysFromMatches(matches);
  if (keys.isEmpty) {
    return const <String>{};
  }

  final latestPlayedByCompetition = <String, DateTime>{};
  for (final match in matches) {
    if (match.isMatchPlayed != true) {
      continue;
    }
    final competitionId = match.competitionID?.trim() ?? '';
    if (competitionId.isEmpty) {
      continue;
    }
    final date = matchDateForTeamStats(match);
    if (date == null) {
      continue;
    }
    final previous = latestPlayedByCompetition[competitionId];
    if (previous == null || date.isAfter(previous)) {
      latestPlayedByCompetition[competitionId] = date;
    }
  }

  final stale = <String>{};
  final competitions = keys.map((key) => key.competitionId).toSet();
  for (final competitionId in competitions) {
    DateTime? oldestUpdate;
    var missing = false;
    for (final key in keys) {
      if (key.competitionId != competitionId) {
        continue;
      }
      final existing = existingByDocId[key.documentId];
      final updatedAt = existing?.updatedAt?.toDate();
      if (existing == null || updatedAt == null) {
        missing = true;
        break;
      }
      if (oldestUpdate == null || updatedAt.isBefore(oldestUpdate)) {
        oldestUpdate = updatedAt;
      }
    }
    if (missing) {
      stale.add(competitionId);
      continue;
    }
    final latestPlayed = latestPlayedByCompetition[competitionId];
    if (latestPlayed != null &&
        oldestUpdate != null &&
        latestPlayed.isAfter(oldestUpdate)) {
      stale.add(competitionId);
    }
  }
  return stale;
}

/// Index of the slot to ring: [highlightMatchId] if present, else the latest.
int? lastResultsHighlightIndex({
  required List<LastResultEntry> results,
  String? highlightMatchId,
}) {
  final trimmedMatchId = highlightMatchId?.trim() ?? '';
  if (trimmedMatchId.isNotEmpty) {
    final index = results.indexWhere(
      (entry) => (entry.matchId?.trim() ?? '') == trimmedMatchId,
    );
    if (index >= 0) {
      return index;
    }
  }
  if (results.isEmpty) {
    return null;
  }
  return results.length - 1;
}

/// Always [lastResultsSlotCount] slots: known outcomes then empty placeholders.
List<MatchOutcome?> lastResultsDisplaySlots(List<LastResultEntry> results) {
  final slots = <MatchOutcome?>[
    for (final entry in results.take(lastResultsSlotCount)) entry.outcome,
  ];
  while (slots.length < lastResultsSlotCount) {
    slots.add(null);
  }
  return slots;
}

bool _isExemptMatch(Match match) {
  final team1 = match.team1 ?? '';
  final team2 = match.team2 ?? '';
  return team1.contains('Exempt') || team2.contains('Exempt');
}
