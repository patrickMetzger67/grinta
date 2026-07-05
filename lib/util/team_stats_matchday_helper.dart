import 'package:flutter/material.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';

/// Whether a calendar group is keyed by championship [Match.day] or cup [Match.tour].
enum TeamStatsMatchdayGroupKind { day, tour }

/// Matches grouped by championship matchday ([Match.day]) or cup round ([Match.tour]).
class TeamStatsMatchdayGroup {
  const TeamStatsMatchdayGroup({
    required this.kind,
    required this.matches,
    this.day,
    this.tour,
  });

  final TeamStatsMatchdayGroupKind kind;
  final int? day;
  final String? tour;
  final List<Match> matches;

  /// Unique calendar dates for this group, oldest first.
  List<DateTime> get uniqueDates {
    final dates = <DateTime>{};
    for (final match in matches) {
      final date = matchDateForTeamStats(match);
      if (date != null) {
        dates.add(DateUtils.dateOnly(date));
      }
    }
    return dates.toList()..sort();
  }
}

/// Returns a positive matchday number, or null when [Match.day] is missing.
int? matchdayNumber(Match match) {
  final day = match.day;
  if (day == null || day <= 0) {
    return null;
  }
  return day;
}

/// Returns a non-empty cup round label, or null when [Match.tour] is missing.
String? matchTour(Match match) {
  final tour = match.tour?.trim();
  if (tour == null || tour.isEmpty) {
    return null;
  }
  return tour;
}

/// Dropdown / navigator label: "Journée X" for league days, raw tour text for cups.
String matchdayGroupLabel(AppLocalizations l10n, TeamStatsMatchdayGroup group) {
  return switch (group.kind) {
    TeamStatsMatchdayGroupKind.day =>
      l10n.periodMatchDay(group.day.toString()),
    TeamStatsMatchdayGroupKind.tour => group.tour!,
  };
}

/// True when [match] involves [teamId] or the club identified by [clubId] /
/// [clubAffiliation].
///
/// Checks [Match.teams], [Match.teamID], affiliations, and [Match.clubs] —
/// cup pool matches often omit [Match.teams] but still carry [Match.teamID]
/// or club ids.
bool matchIncludesTeam(
  Match match,
  String teamId, {
  String? clubId,
  String? clubAffiliation,
}) {
  final trimmedTeamId = teamId.trim();
  if (trimmedTeamId.isNotEmpty) {
    if (normalizeTeamIdList(match.teams ?? const <dynamic>[])
        .contains(trimmedTeamId)) {
      return true;
    }
    if (match.teamID?.trim() == trimmedTeamId) {
      return true;
    }
  }

  final trimmedClubId = clubId?.trim() ?? '';
  final trimmedAffiliation = clubAffiliation?.trim() ?? '';
  if (trimmedClubId.isEmpty && trimmedAffiliation.isEmpty) {
    return false;
  }

  bool clubMatches(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return false;
    }
    return normalized == trimmedClubId ||
        (trimmedAffiliation.isNotEmpty && normalized == trimmedAffiliation);
  }

  if (clubMatches(match.affiliationTeam1) ||
      clubMatches(match.affiliationTeam2)) {
    return true;
  }

  for (final club in match.clubs ?? const <dynamic>[]) {
    if (clubMatches(club?.toString())) {
      return true;
    }
  }

  return false;
}

/// Groups [matches] by [Match.day] when set, otherwise by [Match.tour] for cups.
///
/// League ([day]) groups include every match in the pool. Cup ([tour]) groups
/// only include matches where [teamId] is listed in [Match.teams]; empty tour
/// groups are omitted from the result.
List<TeamStatsMatchdayGroup> groupMatchesByMatchday(
  List<Match> matches, {
  String? teamId,
  String? clubId,
  String? clubAffiliation,
}) {
  final trimmedTeamId = teamId?.trim() ?? '';
  final trimmedClubId = clubId?.trim() ?? '';
  final trimmedAffiliation = clubAffiliation?.trim() ?? '';
  final filterCupByTeam =
      trimmedTeamId.isNotEmpty ||
      trimmedClubId.isNotEmpty ||
      trimmedAffiliation.isNotEmpty;

  final byDay = <int, List<Match>>{};
  final byTour = <String, List<Match>>{};

  for (final match in matches) {
    final day = matchdayNumber(match);
    if (day != null) {
      byDay.putIfAbsent(day, () => <Match>[]).add(match);
      continue;
    }

    final tour = matchTour(match);
    if (tour != null) {
      if (filterCupByTeam &&
          !matchIncludesTeam(
            match,
            trimmedTeamId,
            clubId: trimmedClubId,
            clubAffiliation: trimmedAffiliation,
          )) {
        continue;
      }
      byTour.putIfAbsent(tour, () => <Match>[]).add(match);
    }
  }

  final groups = <TeamStatsMatchdayGroup>[
    for (final day in byDay.keys)
      TeamStatsMatchdayGroup(
        kind: TeamStatsMatchdayGroupKind.day,
        day: day,
        matches: sortMatchesByDateTime(byDay[day]!),
      ),
    for (final tour in byTour.keys)
      if (byTour[tour]!.isNotEmpty)
        TeamStatsMatchdayGroup(
          kind: TeamStatsMatchdayGroupKind.tour,
          tour: tour,
          matches: sortMatchesByDateTime(byTour[tour]!),
        ),
  ]..sort(_compareMatchdayGroups);

  return groups;
}

int _compareMatchdayGroups(
  TeamStatsMatchdayGroup a,
  TeamStatsMatchdayGroup b,
) {
  final dateA = _earliestMatchDate(a.matches);
  final dateB = _earliestMatchDate(b.matches);
  if (dateA != null && dateB != null) {
    return dateA.compareTo(dateB);
  }
  if (dateA != null) {
    return -1;
  }
  if (dateB != null) {
    return 1;
  }

  if (a.kind == TeamStatsMatchdayGroupKind.day &&
      b.kind == TeamStatsMatchdayGroupKind.day) {
    return a.day!.compareTo(b.day!);
  }
  if (a.kind == TeamStatsMatchdayGroupKind.tour &&
      b.kind == TeamStatsMatchdayGroupKind.tour) {
    return a.tour!.compareTo(b.tour!);
  }
  return a.kind.index.compareTo(b.kind.index);
}

DateTime? _earliestMatchDate(List<Match> matches) {
  DateTime? earliest;
  for (final match in matches) {
    final date = matchDateForTeamStats(match);
    if (date == null) {
      continue;
    }
    if (earliest == null || date.isBefore(earliest)) {
      earliest = date;
    }
  }
  return earliest;
}

/// Oldest first, matching agenda chronological order.
List<Match> sortMatchesByDateTime(List<Match> matches) {
  return List<Match>.from(matches)
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
