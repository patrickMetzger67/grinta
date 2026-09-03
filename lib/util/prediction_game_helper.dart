import 'package:grinta/model/engagement.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/pred_game_day.dart';
import 'package:grinta/util/highlight_minute_helper.dart';
import 'package:grinta/util/team_stats_matchday_helper.dart';

/// Players may submit picks until this duration before the first kick-off.
const Duration kPredictionGameLockBeforeFirstKickoff = Duration(hours: 12);

/// Deterministic Firestore document id for a team + engagement + journée.
String predGameDayDocumentId({
  required String teamId,
  required String engagementId,
  required int day,
}) {
  return '${teamId.trim()}_${engagementId.trim()}_$day';
}

/// Display label for an engagement in the team settings dropdown.
String predictionGameEngagementLabel(Engagement engagement) {
  final name = engagement.name?.trim() ?? '';
  if (name.isNotEmpty) return name;

  final parts = <String>[
    if ((engagement.competitionId ?? '').trim().isNotEmpty)
      engagement.competitionId!.trim(),
    if ((engagement.group ?? '').trim().isNotEmpty) engagement.group!.trim(),
    if ((engagement.stage ?? '').trim().isNotEmpty) engagement.stage!.trim(),
  ];
  return parts.join(' · ');
}

/// True when [match] belongs to the same competition / group / stage.
bool matchBelongsToPredictionEngagement(Match match, Engagement engagement) {
  final competitionId = (engagement.competitionId ?? '').trim();
  if (competitionId.isEmpty) return false;
  if ((match.competitionID ?? '').trim() != competitionId) return false;

  final group = (engagement.group ?? '').trim();
  if (group.isNotEmpty && (match.poule ?? '').trim() != group) {
    return false;
  }

  final stage = (engagement.stage ?? '').trim();
  if (stage.isNotEmpty && (match.stage ?? '').trim() != stage) {
    return false;
  }

  return true;
}

/// Kick-off from `dateCh`/`timeCh`, falling back to [Match.timestamp].
DateTime? resolvePredictionMatchKickoff(Match match) {
  return matchKickoffDateTime(match) ?? match.timestamp?.toDate();
}

DateTime predictionClosesAt(DateTime firstKickoff) {
  return firstKickoff.subtract(kPredictionGameLockBeforeFirstKickoff);
}

bool isValidPredictionPick(int? pick) {
  return pick == predGameDayPickHome ||
      pick == predGameDayPickAway ||
      pick == predGameDayPickDraw;
}

/// Next unplayed journée whose lock deadline is still in the future.
class PredictionMatchdaySelection {
  const PredictionMatchdaySelection({
    required this.day,
    required this.matches,
    required this.firstKickoff,
    required this.closesAt,
  });

  final int day;
  final List<Match> matches;
  final DateTime firstKickoff;
  final DateTime closesAt;
}

/// Picks the earliest journée (by day number) that is still open for picks.
PredictionMatchdaySelection? selectNextPredictionMatchday({
  required List<Match> matches,
  required Engagement engagement,
  required DateTime now,
  Duration lockBeforeFirstKickoff = kPredictionGameLockBeforeFirstKickoff,
}) {
  final byDay = <int, List<Match>>{};

  for (final match in matches) {
    if (match.isMatchPlayed == true) continue;
    if (!matchBelongsToPredictionEngagement(match, engagement)) continue;

    final day = matchdayNumber(match);
    if (day == null) continue;
    if (resolvePredictionMatchKickoff(match) == null) continue;

    byDay.putIfAbsent(day, () => <Match>[]).add(match);
  }

  final days = byDay.keys.toList()..sort();
  for (final day in days) {
    final dayMatches = List<Match>.from(byDay[day]!)
      ..sort((a, b) {
        final kickA = resolvePredictionMatchKickoff(a);
        final kickB = resolvePredictionMatchKickoff(b);
        if (kickA == null && kickB == null) return 0;
        if (kickA == null) return 1;
        if (kickB == null) return -1;
        return kickA.compareTo(kickB);
      });

    final firstKickoff = resolvePredictionMatchKickoff(dayMatches.first);
    if (firstKickoff == null) continue;

    final closesAt = firstKickoff.subtract(lockBeforeFirstKickoff);
    if (!closesAt.isAfter(now)) continue;

    return PredictionMatchdaySelection(
      day: day,
      matches: dayMatches,
      firstKickoff: firstKickoff,
      closesAt: closesAt,
    );
  }

  return null;
}

PredGameDayFixture fixtureFromMatch(Match match) {
  return PredGameDayFixture(
    matchId: match.id?.trim() ?? '',
    team1: match.team1?.trim() ?? '',
    team2: match.team2?.trim() ?? '',
    team1UrlLogo: match.team1UrlLogo?.trim(),
    team2UrlLogo: match.team2UrlLogo?.trim(),
    kickoffAt: resolvePredictionMatchKickoff(match),
    day: matchdayNumber(match),
  );
}

PredGameDay buildPredGameDayFromSelection({
  required String teamId,
  required String engagementId,
  required Engagement engagement,
  required PredictionMatchdaySelection selection,
  DateTime? createdAt,
}) {
  final fixtures = selection.matches
      .map(fixtureFromMatch)
      .where((fixture) => fixture.matchId.isNotEmpty)
      .toList();

  return PredGameDay(
    id: predGameDayDocumentId(
      teamId: teamId,
      engagementId: engagementId,
      day: selection.day,
    ),
    teamId: teamId.trim(),
    engagementId: engagementId.trim(),
    competitionId: (engagement.competitionId ?? '').trim(),
    group: (engagement.group ?? '').trim(),
    stage: (engagement.stage ?? '').trim(),
    day: selection.day,
    seasonId: (engagement.seasonId ?? '').trim(),
    clubId: (engagement.clubId ?? '').trim(),
    matchIds: fixtures.map((fixture) => fixture.matchId).toList(),
    fixtures: fixtures,
    firstKickoffAt: selection.firstKickoff,
    closesAt: selection.closesAt,
    createdAt: createdAt,
  );
}
