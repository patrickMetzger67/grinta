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
import 'package:grinta/widget/youtube_top_video_prompt.dart';
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

/// Coach/manager prompt: offer an opponent analysis report for a match this week.
///
/// Independent from the tip-of-the-week video (same shell timing only).
class OpponentAnalysisReportPrompt {
  OpponentAnalysisReportPrompt._();

  static bool _dialogOpen = false;
  static bool _offeredThisSession = false;
  static bool _settledNoOffer = false;
  static bool _polling = false;

  /// True for Educateur/Entraineur **or** manager/owner of a team this season.
  static bool isEligibleCoachOrManager(AppSession session) {
    final player = session.selectedPlayer;
    if (player == null) return false;
    if (player.isEducatorOrCoach) return true;
    if (session.hasManagedTeamsInSelectedSeason) return true;
    return false;
  }

  /// Poll until the dialog is shown, or until we know there is nothing to offer.
  ///
  /// Safe to call multiple times (from shell ready + agenda stream).
  static Future<void> startPolling() async {
    if (_polling || _offeredThisSession || _settledNoOffer) return;
    _polling = true;
    try {
      // Up to ~45s while AppSession / agenda hydrate after login.
      for (var attempt = 0; attempt < 15; attempt++) {
        if (_offeredThisSession || _settledNoOffer) return;
        await maybeShow();
        if (_offeredThisSession || _settledNoOffer) return;
        await Future<void>.delayed(const Duration(seconds: 3));
      }
      debugPrint(
        'OpponentAnalysisReportPrompt: polling ended without offer',
      );
    } finally {
      _polling = false;
    }
  }

  static Future<void> maybeShow() async {
    if (_dialogOpen || _offeredThisSession || _settledNoOffer) return;

    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) {
      debugPrint('OpponentAnalysisReportPrompt: no root context yet');
      return;
    }

    AppSession session;
    try {
      session = rootContext.read<AppSession>();
    } catch (_) {
      debugPrint('OpponentAnalysisReportPrompt: AppSession not in tree');
      return;
    }

    if (session.isLoading) {
      debugPrint('OpponentAnalysisReportPrompt: session still loading');
      return;
    }

    if (!isEligibleCoachOrManager(session)) {
      debugPrint(
        'OpponentAnalysisReportPrompt: settle — not coach/manager '
        '(educator=${session.selectedPlayer?.isEducatorOrCoach}, '
        'managed=${session.managedTeamsIdsForSelectedSeason})',
      );
      _settledNoOffer = true;
      return;
    }

    final teams = session.teamsForAgendaSelectedSeason;
    if (teams.isEmpty) {
      debugPrint('OpponentAnalysisReportPrompt: no agenda teams yet');
      return;
    }

    await OpponentAnalysisPromptStateService.instance.ensureInitialized();
    if (OpponentAnalysisPromptStateService.instance.isSnoozed) {
      debugPrint('OpponentAnalysisReportPrompt: settle — snoozed');
      _settledNoOffer = true;
      return;
    }

    final candidate = await _resolveUpcomingMatch(
      context: rootContext,
      session: session,
      teams: teams,
    );

    if (candidate == null) {
      // Keep polling — matches can arrive after teams hydrate.
      debugPrint(
        'OpponentAnalysisReportPrompt: no promptable match yet, will retry',
      );
      return;
    }

    if (!rootContext.mounted) return;

    // Avoid stacking on tip/welcome dialog — features stay independent.
    while (YoutubeTopVideoPrompt.isDialogOpen) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!rootContext.mounted) return;
      if (_offeredThisSession) return;
    }

    _dialogOpen = true;
    _offeredThisSession = true;
    debugPrint(
      'OpponentAnalysisReportPrompt: showing for '
      '${candidate.opponent.displayName} @ ${candidate.kickoff}',
    );
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

  static Team? _teamForMatch({
    required models.Match match,
    required List<Team> teams,
  }) {
    final ids = <String>{};
    final primary = match.teamID?.trim() ?? '';
    if (primary.isNotEmpty) ids.add(primary);
    for (final raw in match.teams ?? const []) {
      final id = raw?.toString().trim() ?? '';
      if (id.isNotEmpty) ids.add(id);
    }

    for (final team in teams) {
      final key = team.keyTeam?.trim() ?? '';
      if (key.isNotEmpty && ids.contains(key)) {
        return team;
      }
    }

    // Last resort: match by team display name on either side.
    for (final team in teams) {
      final name = (team.name ?? '').trim().toLowerCase();
      if (name.isEmpty) continue;
      if ((match.team1 ?? '').trim().toLowerCase() == name ||
          (match.team2 ?? '').trim().toLowerCase() == name) {
        return team;
      }
    }

    if (teams.length == 1) return teams.first;
    return null;
  }

  static Future<_UpcomingOpponentMatch?> _resolveUpcomingMatch({
    required BuildContext context,
    required AppSession session,
    required List<Team> teams,
  }) async {
    final now = DateTime.now();
    final weekStart = _weekStartMonday(now);
    final weekEnd = _weekEndSunday(weekStart);
    final seasonId = session.selectedSeason?.ref?.id?.trim() ?? '';

    debugPrint(
      'OpponentAnalysisReportPrompt: loading agenda '
      '${weekStart.toIso8601String()} → ${weekEnd.toIso8601String()} '
      'teams=${teams.map((t) => t.keyTeam).join(",")}',
    );

    final items = await AgendaService().loadAgendaItems(
      teams: teams,
      seasonId: seasonId.isEmpty ? null : seasonId,
      start: weekStart,
      end: weekEnd,
    );

    final matchItems = items
        .where((item) => item.type == AgendaItemType.match)
        .where((item) => item.match != null)
        .where((item) => item.match!.isMatchPlayed != true)
        .where((item) => !item.endAt.isBefore(now))
        .where((item) => !item.startAt.isBefore(weekStart))
        .where((item) => !item.startAt.isAfter(weekEnd))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    debugPrint(
      'OpponentAnalysisReportPrompt: agenda items=${items.length}, '
      'upcoming matches=${matchItems.length}',
    );
    for (final item in matchItems) {
      debugPrint(
        '  match ${item.id} start=${item.startAt} '
        'teamID=${item.match?.teamID} '
        'teams=${item.match?.teams} '
        '${item.match?.team1} vs ${item.match?.team2}',
      );
    }

    final state = OpponentAnalysisPromptStateService.instance;
    final l10n = context.l10n;

    for (final item in matchItems) {
      final match = item.match!;
      final matchId = match.id?.trim() ?? item.id.trim();
      if (matchId.isEmpty || !state.shouldPromptMatch(matchId)) {
        debugPrint(
          'OpponentAnalysisReportPrompt: skip $matchId '
          '(answered/snooze status=${state.shouldPromptMatch(matchId)})',
        );
        continue;
      }

      final team = _teamForMatch(match: match, teams: teams);
      if (team == null) {
        debugPrint(
          'OpponentAnalysisReportPrompt: skip $matchId — no matching team '
          'among ${teams.length} agenda teams',
        );
        continue;
      }

      final opponent = opponentForMatch(
        match: match,
        teamId: team.keyTeam ?? '',
        clubId: team.clubId,
      );
      if (opponent == null || opponent.displayName.trim().isEmpty) {
        debugPrint(
          'OpponentAnalysisReportPrompt: skip $matchId — opponent unresolved '
          'for team ${team.keyTeam} / ${team.name}',
        );
        continue;
      }

      final resolvedSeasonId =
          teamStatsSeasonIdForTeam(team, seasonId) ?? seasonId;
      if (resolvedSeasonId.isEmpty) {
        debugPrint('OpponentAnalysisReportPrompt: skip $matchId — no season');
        continue;
      }

      var competitionUrl = await resolveTeamStatsCompetitionUrlForMatch(
        team: team,
        match: match,
        fallbackSeasonId: resolvedSeasonId,
      );
      var competitionLabel = match.chType?.trim() ?? '';

      final options = await loadTeamStatsCompetitionOptions(
        team: team,
        l10n: l10n,
        fallbackSeasonId: resolvedSeasonId,
        includeAllOption: false,
      );

      if (competitionUrl != null && competitionUrl.trim().isNotEmpty) {
        for (final option in options) {
          if ((option.url ?? '').trim() == competitionUrl.trim()) {
            competitionLabel = option.label;
            break;
          }
        }
      } else if (options.isNotEmpty) {
        competitionUrl = options.first.url?.trim();
        competitionLabel = options.first.label;
        debugPrint(
          'OpponentAnalysisReportPrompt: $matchId fallback competition '
          '$competitionLabel',
        );
      }

      if (competitionUrl == null || competitionUrl.trim().isEmpty) {
        debugPrint(
          'OpponentAnalysisReportPrompt: skip $matchId — no competition',
        );
        continue;
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
