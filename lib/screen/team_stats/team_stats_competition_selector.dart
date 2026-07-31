import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/teams_per_club.dart';
import 'package:grinta/services/teams_per_club_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/util/fff_competition_url.dart';
import 'package:grinta/util/team_stats_competition_filter.dart';

/// Sentinel value for the "all competitions" dropdown option.
const String kTeamStatsAllCompetitionsValue = '__all__';

class TeamStatsCompetitionOption {
  const TeamStatsCompetitionOption({
    required this.value,
    required this.label,
    this.url,
  });

  final String value;
  final String label;
  final String? url;
}

String? teamStatsSeasonIdForTeam(Team team, String? fallbackSeasonId) {
  final teamSeasonId = team.seasonID?.trim() ?? '';
  if (teamSeasonId.isNotEmpty) return teamSeasonId;
  final fallback = fallbackSeasonId?.trim() ?? '';
  return fallback.isEmpty ? null : fallback;
}

Future<List<TeamStatsCompetitionOption>> loadTeamStatsCompetitionOptions({
  required Team team,
  required AppLocalizations l10n,
  String? fallbackSeasonId,
  TeamsPerClubService? teamsPerClubService,
  bool includeAllOption = true,
}) async {
  final clubId = team.clubId?.trim() ?? '';
  final equipeId = team.teamIdInTeamsPerClub?.trim() ?? '';
  final seasonId = teamStatsSeasonIdForTeam(team, fallbackSeasonId);

  if (clubId.isEmpty || equipeId.isEmpty || seasonId == null) {
    return const [];
  }

  final service = teamsPerClubService ?? TeamsPerClubService();
  final teamsPerClub = await service.getByClubIdAndSeason(
    clubId: clubId,
    seasonId: seasonId,
  );

  Equipe? equipe;
  if (teamsPerClub != null) {
    for (final entry in teamsPerClub.equipes) {
      if ((entry.id?.trim() ?? '') == equipeId) {
        equipe = entry;
        break;
      }
    }
  }

  final competitionOptions = <TeamStatsCompetitionOption>[];
  if (includeAllOption) {
    competitionOptions.add(
      TeamStatsCompetitionOption(
        value: kTeamStatsAllCompetitionsValue,
        label: l10n.teamStatsAllCompetitions,
      ),
    );
  }

  final seenUrls = <String>{};
  void addUrl(String rawUrl, {String? fallbackLabel}) {
    final url = rawUrl.trim();
    if (url.isEmpty || isFriendlyCompetitionUrl(url) || !seenUrls.add(url)) {
      return;
    }
    final info = parseFffCompetitionUrl(url);
    competitionOptions.add(
      TeamStatsCompetitionOption(
        value: url,
        label: info?.name ?? fallbackLabel ?? url,
        url: url,
      ),
    );
  }

  for (final url in equipe?.competitions ?? const <String>[]) {
    addUrl(url);
  }

  // Fallback: competitions stored on the Team document itself.
  if (seenUrls.isEmpty) {
    for (final competition in team.competitions ?? const <Competition>[]) {
      final url = (competition.urlCalendar ?? '').trim();
      if (url.isEmpty) continue;
      addUrl(url, fallbackLabel: competition.name);
    }
  }

  return competitionOptions;
}

/// FFF engagement URLs for [team] (excludes friendlies and the "all" sentinel).
Future<List<String>> loadTeamStatsCompetitionUrls({
  required Team team,
  String? fallbackSeasonId,
  TeamsPerClubService? teamsPerClubService,
}) async {
  final clubId = team.clubId?.trim() ?? '';
  final equipeId = team.teamIdInTeamsPerClub?.trim() ?? '';
  final seasonId = teamStatsSeasonIdForTeam(team, fallbackSeasonId);

  if (clubId.isEmpty || equipeId.isEmpty || seasonId == null) {
    return const [];
  }

  final service = teamsPerClubService ?? TeamsPerClubService();
  final teamsPerClub = await service.getByClubIdAndSeason(
    clubId: clubId,
    seasonId: seasonId,
  );

  Equipe? equipe;
  if (teamsPerClub != null) {
    for (final entry in teamsPerClub.equipes) {
      if ((entry.id?.trim() ?? '') == equipeId) {
        equipe = entry;
        break;
      }
    }
  }

  final urls = <String>[];
  final seen = <String>{};
  void addUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        isFriendlyCompetitionUrl(trimmed) ||
        !seen.add(trimmed)) {
      return;
    }
    urls.add(trimmed);
  }

  for (final url in equipe?.competitions ?? const <String>[]) {
    addUrl(url);
  }

  if (urls.isEmpty) {
    for (final competition in team.competitions ?? const <Competition>[]) {
      addUrl(competition.urlCalendar ?? '');
    }
  }
  return urls;
}

/// Resolves the team-stats competition URL that matches [match] fields.
Future<String?> resolveTeamStatsCompetitionUrlForMatch({
  required Team team,
  required Match match,
  String? fallbackSeasonId,
  TeamsPerClubService? teamsPerClubService,
}) async {
  final urls = await loadTeamStatsCompetitionUrls(
    team: team,
    fallbackSeasonId: fallbackSeasonId,
    teamsPerClubService: teamsPerClubService,
  );

  for (final url in urls) {
    final filter = competitionFilterFromUrl(url);
    if (filter != null && matchMatchesCompetitionFilter(match, filter)) {
      return url;
    }
  }
  return null;
}

String? teamStatsSelectedCompetitionUrl(String selectedValue) {
  if (selectedValue == kTeamStatsAllCompetitionsValue) {
    return null;
  }
  return selectedValue;
}

class TeamStatsCompetitionDropdown extends StatelessWidget {
  const TeamStatsCompetitionDropdown({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<TeamStatsCompetitionOption> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.teamStatsCompetitionFilterLabel,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        filled: true,
        fillColor: colors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.primary,
            width: 1.4,
          ),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          dropdownColor: colors.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.textSecondary,
            size: 22,
          ),
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(
                    option.label,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ),
    );
  }
}
