import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/team.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/services/agenda_service.dart';
import 'package:grinta/services/opponent_analysis_prompt_state_service.dart';
import 'package:grinta/services/opponent_analysis_report_data_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';
import 'package:grinta/widget/opponent_analysis_report_email_dialog.dart';
import 'package:provider/provider.dart';

class _UpcomingOpponentMatch {
  const _UpcomingOpponentMatch({
    required this.match,
    required this.matchId,
    required this.team,
    required this.kickoff,
    required this.opponent,
    required this.competitionUrl,
    required this.competitionLabel,
    required this.seasonId,
  });

  final models.Match match;
  final String matchId;
  final Team team;
  final DateTime kickoff;
  final TeamStatsOpponent opponent;
  final String competitionUrl;
  final String competitionLabel;
  final String seasonId;
}

/// Coach prompt: offer an opponent analysis report for a match this week.
///
/// Call after the tip-of-the-week prompt (same shell readiness hook).
class OpponentAnalysisReportPrompt {
  OpponentAnalysisReportPrompt._();

  static bool _dialogOpen = false;

  static Future<void> maybeShow() async {
    if (_dialogOpen) return;

    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) return;

    AppSession session;
    try {
      session = rootContext.read<AppSession>();
    } catch (_) {
      return;
    }

    final player = session.selectedPlayer;
    if (player == null || player.isEducatorOrCoach != true) return;

    await OpponentAnalysisPromptStateService.instance.ensureInitialized();
    if (OpponentAnalysisPromptStateService.instance.isSnoozed) return;

    final candidate = await _resolveUpcomingMatch(
      context: rootContext,
      session: session,
    );
    if (candidate == null) return;
    if (!rootContext.mounted) return;

    _dialogOpen = true;
    try {
      await showDialog<void>(
        context: rootContext,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) => _OpponentAnalysisPromptDialog(candidate: candidate),
      );
    } finally {
      _dialogOpen = false;
    }
  }

  static DateTime _weekStartMonday(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static DateTime _weekEndSunday(DateTime weekStart) {
    return weekStart
        .add(const Duration(days: 7))
        .subtract(const Duration(milliseconds: 1));
  }

  static Future<_UpcomingOpponentMatch?> _resolveUpcomingMatch({
    required BuildContext context,
    required AppSession session,
  }) async {
    final teams = session.teamsForAgendaSelectedSeason;
    if (teams.isEmpty) return null;

    final now = DateTime.now();
    final weekStart = _weekStartMonday(now);
    final weekEnd = _weekEndSunday(weekStart);
    final seasonId = session.selectedSeason?.ref?.id?.trim() ?? '';

    final items = await AgendaService().loadAgendaItems(
      teams: teams,
      seasonId: seasonId.isEmpty ? null : seasonId,
      start: weekStart,
      end: weekEnd,
    );

    final matchItems = items
        .where((item) => item.type == AgendaItemType.match)
        .where((item) => !item.isDone)
        .where((item) => item.match != null)
        .where((item) => item.match!.isMatchPlayed != true)
        .where((item) => !item.startAt.isBefore(weekStart))
        .where((item) => !item.startAt.isAfter(weekEnd))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    final state = OpponentAnalysisPromptStateService.instance;
    final l10n = context.l10n;

    for (final item in matchItems) {
      final match = item.match!;
      final matchId = match.id?.trim() ?? item.id.trim();
      if (matchId.isEmpty || !state.shouldPromptMatch(matchId)) {
        continue;
      }

      final teamId = match.teamID?.trim() ?? '';
      Team? team;
      for (final candidate in teams) {
        if ((candidate.keyTeam?.trim() ?? '') == teamId) {
          team = candidate;
          break;
        }
      }
      team ??= teams.length == 1 ? teams.first : null;
      if (team == null) continue;

      final opponent = opponentForMatch(
        match: match,
        teamId: team.keyTeam ?? '',
        clubId: team.clubId,
      );
      if (opponent == null || opponent.displayName.trim().isEmpty) {
        continue;
      }

      final resolvedSeasonId =
          teamStatsSeasonIdForTeam(team, seasonId) ?? seasonId;
      if (resolvedSeasonId.isEmpty) continue;

      final competitionUrl = await resolveTeamStatsCompetitionUrlForMatch(
        team: team,
        match: match,
        fallbackSeasonId: resolvedSeasonId,
      );
      if (competitionUrl == null || competitionUrl.trim().isEmpty) {
        continue;
      }

      final options = await loadTeamStatsCompetitionOptions(
        team: team,
        l10n: l10n,
        fallbackSeasonId: resolvedSeasonId,
        includeAllOption: false,
      );
      String competitionLabel = match.chType?.trim() ?? '';
      for (final option in options) {
        if ((option.url ?? '').trim() == competitionUrl.trim()) {
          competitionLabel = option.label;
          break;
        }
      }
      if (competitionLabel.isEmpty) {
        competitionLabel = 'Compétition';
      }

      return _UpcomingOpponentMatch(
        match: match,
        matchId: matchId,
        team: team,
        kickoff: item.startAt,
        opponent: opponent,
        competitionUrl: competitionUrl.trim(),
        competitionLabel: competitionLabel,
        seasonId: resolvedSeasonId,
      );
    }

    return null;
  }
}

class _OpponentAnalysisPromptDialog extends StatefulWidget {
  const _OpponentAnalysisPromptDialog({required this.candidate});

  final _UpcomingOpponentMatch candidate;

  @override
  State<_OpponentAnalysisPromptDialog> createState() =>
      _OpponentAnalysisPromptDialogState();
}

class _OpponentAnalysisPromptDialogState
    extends State<_OpponentAnalysisPromptDialog> {
  var _busy = false;

  String get _matchId => widget.candidate.matchId;

  Future<void> _onYes() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final colors = context.appColors;
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      // Oui → ne plus reposer la question pour ce match.
      await OpponentAnalysisPromptStateService.instance.markSent(_matchId);

      final data = await OpponentAnalysisReportDataService.instance.build(
        team: widget.candidate.team,
        seasonId: widget.candidate.seasonId,
        competitionUrl: widget.candidate.competitionUrl,
        competitionLabel: widget.candidate.competitionLabel,
        opponent: widget.candidate.opponent,
        upcomingMatch: widget.candidate.match,
        upcomingKickoff: widget.candidate.kickoff,
        teamName: widget.candidate.team.name,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await showOpponentAnalysisReportEmailDialog(
        context: appNavigatorKey.currentContext ?? context,
        data: data,
      );
    } catch (e) {
      debugPrint('Opponent analysis prompt yes failed: $e');
      if (mounted) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(l10n.opponentAnalysisReportSendFailed),
            backgroundColor: colors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onRemindTomorrow() async {
    if (_busy) return;
    setState(() => _busy = true);
    await OpponentAnalysisPromptStateService.instance.snoozeUntilTomorrow();
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _onSkip() async {
    if (_busy) return;
    setState(() => _busy = true);
    await OpponentAnalysisPromptStateService.instance.markSkipped(_matchId);
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final locale = Localizations.localeOf(context).languageCode;
    final weekday = OpponentAnalysisReportDataService.formatWeekday(
      widget.candidate.kickoff,
      locale: locale,
    );
    final time = OpponentAnalysisReportDataService.formatKickoff(
      widget.candidate.kickoff,
      locale: locale,
    );
    final opponent = widget.candidate.opponent.displayName;

    return AlertDialog(
      backgroundColor: colors.card,
      title: Text(l10n.opponentAnalysisPromptTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.opponentAnalysisPromptMessage(weekday, time, opponent),
            style: TextStyle(color: colors.textPrimary, fontSize: 15, height: 1.4),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: _busy ? null : _onSkip,
          child: Text(l10n.opponentAnalysisPromptSkip),
        ),
        TextButton(
          onPressed: _busy ? null : _onRemindTomorrow,
          child: Text(l10n.opponentAnalysisPromptRemindTomorrow),
        ),
        FilledButton(
          onPressed: _busy ? null : _onYes,
          child: Text(l10n.opponentAnalysisPromptYes),
        ),
      ],
    );
  }
}
