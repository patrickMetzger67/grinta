import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/screen/agenda/agenda_screen.dart';
import 'package:grinta/services/agenda_service.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:intl/intl.dart';

/// Shows a dialog listing matches for a W/D/L pie chart segment.
void showTeamStatsWdlMatchesDialog({
  required BuildContext context,
  required String periodTitle,
  required MatchOutcome outcome,
  required List<Match> matches,
  required Team team,
}) {
  if (matches.isEmpty) {
    return;
  }

  showDialog<void>(
    context: context,
    builder: (dialogContext) => TeamStatsWdlMatchesDialog(
      periodTitle: periodTitle,
      outcome: outcome,
      matches: matches,
      team: team,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

class TeamStatsWdlMatchesDialog extends StatelessWidget {
  const TeamStatsWdlMatchesDialog({
    super.key,
    required this.periodTitle,
    required this.outcome,
    required this.matches,
    required this.team,
    required this.onClose,
  });

  final String periodTitle;
  final MatchOutcome outcome;
  final List<Match> matches;
  final Team team;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final locale = l10n.localeName;
    final sortedMatches = _sortedMatchesByDate(matches);
    final listEntries = _buildListEntries(sortedMatches);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          maxWidth: 520,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.teamStatsWdlMatchesDialogTitle(
                        _outcomeLabel(l10n, outcome),
                        periodTitle,
                      ),
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.actionClose,
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                itemCount: listEntries.length,
                separatorBuilder: (context, index) {
                  final entry = listEntries[index];
                  final next = listEntries[index + 1];
                  if (entry is _WdlMatchDayHeaderEntry) {
                    return const SizedBox(height: 8);
                  }
                  if (next is _WdlMatchDayHeaderEntry) {
                    return const SizedBox(height: 14);
                  }
                  return const SizedBox(height: 10);
                },
                itemBuilder: (context, index) {
                  final entry = listEntries[index];
                  return switch (entry) {
                    _WdlMatchDayHeaderEntry(:final date) =>
                      _MatchDayHeader(date: date, locale: locale),
                    _WdlMatchCardEntry(:final match) => () {
                        final item = AgendaService.matchToAgendaItem(
                          match: match,
                          team: team,
                        );
                        if (item == null) {
                          return const SizedBox.shrink();
                        }
                        return AgendaItemCard(item: item);
                      }(),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _outcomeLabel(AppLocalizations l10n, MatchOutcome outcome) {
    return switch (outcome) {
      MatchOutcome.win => l10n.statsWins,
      MatchOutcome.draw => l10n.statsDraws,
      MatchOutcome.loss => l10n.statsLosses,
    };
  }

  /// Oldest first, matching agenda chronological order.
  static List<Match> _sortedMatchesByDate(List<Match> matches) {
    return List<Match>.from(matches)
      ..sort((a, b) {
        final dateA = matchDateForTeamStats(a);
        final dateB = matchDateForTeamStats(b);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });
  }

  /// One date header per day, then match cards below (agenda day-row pattern).
  static List<_WdlMatchListEntry> _buildListEntries(List<Match> sortedMatches) {
    final entries = <_WdlMatchListEntry>[];
    DateTime? lastDay;

    for (final match in sortedMatches) {
      final date = matchDateForTeamStats(match);
      if (date != null) {
        final day = DateUtils.dateOnly(date);
        if (lastDay == null || day != lastDay) {
          entries.add(_WdlMatchDayHeaderEntry(day));
          lastDay = day;
        }
      }
      entries.add(_WdlMatchCardEntry(match));
    }

    return entries;
  }
}

sealed class _WdlMatchListEntry {
  const _WdlMatchListEntry();
}

final class _WdlMatchDayHeaderEntry extends _WdlMatchListEntry {
  const _WdlMatchDayHeaderEntry(this.date);

  final DateTime date;
}

final class _WdlMatchCardEntry extends _WdlMatchListEntry {
  const _WdlMatchCardEntry(this.match);

  final Match match;
}

class _MatchDayHeader extends StatelessWidget {
  const _MatchDayHeader({
    required this.date,
    required this.locale,
  });

  final DateTime date;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final today = DateUtils.dateOnly(DateTime.now());
    final isToday =
        DateUtils.dateOnly(date).millisecondsSinceEpoch ==
        today.millisecondsSinceEpoch;

    return Text(
      DateFormat.yMMMMd(locale).format(date),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: isToday ? colors.primary : colors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
