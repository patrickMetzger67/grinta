import 'dart:async' show unawaited;

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
import 'package:grinta/util/staff_session_access.dart';
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
  });

  final models.Match match;
  final String matchId;
  final Team team;
  final DateTime kickoff;
  final TeamStatsOpponent opponent;
}

/// Invisible host: uses [WebAppRoot] context (AppSession + overlay) to offer
/// the opponent-analysis prompt. Independent from the tip-of-the-week video.
class OpponentAnalysisPromptHost extends StatefulWidget {
  const OpponentAnalysisPromptHost({super.key});

  @override
  State<OpponentAnalysisPromptHost> createState() =>
      _OpponentAnalysisPromptHostState();
}

class _OpponentAnalysisPromptHostState
    extends State<OpponentAnalysisPromptHost> {
  @override
  void initState() {
    super.initState();
    OpponentAnalysisReportPrompt.bindHost(() => mounted ? context : null);
  }

  @override
  void dispose() {
    OpponentAnalysisReportPrompt.unbindHost();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild / re-check when player, season or managed teams change.
    context.select<AppSession, String?>((s) => s.selectedPlayerId);
    context.select<AppSession, String?>((s) => s.selectedSeason?.ref?.id);
    context.select<AppSession, int>(
      (s) => s.managedTeamsIdsForSelectedSeason.length,
    );
    context.select<AppSession, String>((s) => s.agendaTeamsKey);

    // Only after the home shell is ready (web Dashboard / mobile root).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(OpponentAnalysisReportPrompt.maybeShow());
    });
    return const SizedBox.shrink();
  }
}

/// Coach/manager prompt: offer an opponent analysis report for a match this week.
class OpponentAnalysisReportPrompt {
  OpponentAnalysisReportPrompt._();

  static bool _dialogOpen = false;
  static bool _offeredThisSession = false;
  static bool _settledNoOffer = false;
  static bool _polling = false;
  /// Set when [WebAppRoot] home shell finished boot (Dashboard visible on web).
  static bool _homeShellReady = false;
  static BuildContext? Function()? _hostContext;
  static List<AgendaItem> _latestAgendaItems = const [];

  static void bindHost(BuildContext? Function() contextGetter) {
    _hostContext = contextGetter;
  }

  static void unbindHost() {
    _hostContext = null;
  }

  /// Call once the main home shell is painted (web: Dashboard tab).
  /// Opponent prompt must not wait for the Agenda tab.
  static void markHomeShellReady() {
    if (_homeShellReady) return;
    _homeShellReady = true;
    debugPrint('OpponentAnalysisReportPrompt: home shell ready');
  }

  /// Feed live agenda items (same source as the agenda UI).
  static void noteAgendaItems(List<AgendaItem> items) {
    _latestAgendaItems = List<AgendaItem>.unmodifiable(items);
    unawaited(maybeShow());
  }

  static BuildContext? _resolveContext() {
    // Prefer root navigator (same as tip video) so the dialog is above the shell.
    final root = appNavigatorKey.currentContext;
    if (root != null && root.mounted) return root;
    final host = _hostContext?.call();
    if (host != null && host.mounted) return host;
    return null;
  }

  /// Educateur/Entraineur, manager/owner, or roster staff with team access.
  static bool isEligibleCoachOrManager(AppSession session) {
    final player = session.selectedPlayer;
    if (player == null) return false;
    if (player.isEducatorOrCoach) return true;
    if (session.hasManagedTeamsInSelectedSeason) return true;
    for (final team in session.teamsForAgendaSelectedSeason) {
      if (canAccessTeamSessionDetails(session, team.keyTeam)) {
        return true;
      }
    }
    return false;
  }

  static Future<void> startPolling() async {
    if (_polling || _offeredThisSession || _settledNoOffer) return;
    if (!_homeShellReady) {
      debugPrint('OpponentAnalysisReportPrompt: startPolling deferred (home not ready)');
      return;
    }
    _polling = true;
    debugPrint('OpponentAnalysisReportPrompt: startPolling (home shell)');
    try {
      for (var attempt = 0; attempt < 30; attempt++) {
        if (_offeredThisSession || _settledNoOffer) return;
        await maybeShow();
        if (_offeredThisSession || _settledNoOffer) return;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      debugPrint('OpponentAnalysisReportPrompt: polling ended without offer');
    } finally {
      _polling = false;
    }
  }

  static Future<void> maybeShow() async {
    if (_dialogOpen || _offeredThisSession || _settledNoOffer) return;
    if (!_homeShellReady) return;

    final context = _resolveContext();
    if (context == null) {
      debugPrint('OpponentAnalysisReportPrompt: no context yet');
      return;
    }

    AppSession session;
    try {
      session = context.read<AppSession>();
    } catch (e) {
      debugPrint('OpponentAnalysisReportPrompt: AppSession missing ($e)');
      return;
    }

    if (session.isLoading) {
      debugPrint('OpponentAnalysisReportPrompt: session still loading');
      return;
    }

    if (!isEligibleCoachOrManager(session)) {
      debugPrint(
        'OpponentAnalysisReportPrompt: not eligible yet '
        '(educator=${session.selectedPlayer?.isEducatorOrCoach}, '
        'managed=${session.managedTeamsIdsForSelectedSeason}, '
        'agendaTeams=${session.agendaTeamsKey})',
      );
      // Do not settle — manager teams may still be hydrating.
      return;
    }

    final teams = session.teamsForAgendaSelectedSeason;
    if (teams.isEmpty) {
      debugPrint('OpponentAnalysisReportPrompt: no agenda teams yet');
      return;
    }

    await OpponentAnalysisPromptStateService.instance.ensureInitialized();
    if (OpponentAnalysisPromptStateService.instance.isSnoozed) {
      debugPrint('OpponentAnalysisReportPrompt: settle — snoozed until tomorrow');
      _settledNoOffer = true;
      return;
    }

    // On web, the Agenda tab is not mounted until selected — so live agenda
    // items may be empty. Always load this week independently as well.
    final loadedItems = await _loadWeekMatchItems(session, teams);
    final merged = <String, AgendaItem>{};
    for (final item in [..._latestAgendaItems, ...loadedItems]) {
      merged['${item.type.name}_${item.id}'] = item;
    }

    final candidate = _pickCandidate(
      session: session,
      teams: teams,
      items: merged.values.toList(),
    );
    if (candidate == null) {
      debugPrint(
        'OpponentAnalysisReportPrompt: no candidate '
        '(live=${_latestAgendaItems.length}, loaded=${loadedItems.length})',
      );
      return;
    }

    if (!context.mounted) return;

    while (YoutubeTopVideoPrompt.isDialogOpen) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) return;
      if (_offeredThisSession) return;
    }

    _dialogOpen = true;
    _offeredThisSession = true;
    debugPrint(
      'OpponentAnalysisReportPrompt: SHOW '
      '${candidate.opponent.displayName} @ ${candidate.kickoff} '
      'team=${candidate.team.name}',
    );
    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) => _OpponentAnalysisPromptDialog(candidate: candidate),
      );
    } catch (e, st) {
      debugPrint('OpponentAnalysisReportPrompt: showDialog failed: $e\n$st');
      _offeredThisSession = false;
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

  static Future<List<AgendaItem>> _loadWeekMatchItems(
    AppSession session,
    List<Team> teams,
  ) async {
    final now = DateTime.now();
    final weekStart = _weekStartMonday(now);
    final weekEnd = _weekEndSunday(weekStart);
    final seasonId = session.selectedSeason?.ref?.id?.trim() ?? '';
    try {
      final items = await AgendaService().loadAgendaItems(
        teams: teams,
        seasonId: seasonId.isEmpty ? null : seasonId,
        start: weekStart,
        end: weekEnd,
      );
      debugPrint(
        'OpponentAnalysisReportPrompt: loaded ${items.length} agenda items '
        'for week $weekStart → $weekEnd',
      );
      return items;
    } catch (e, st) {
      debugPrint('OpponentAnalysisReportPrompt: loadAgendaItems failed: $e\n$st');
      return const [];
    }
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

  static _UpcomingOpponentMatch? _pickCandidate({
    required AppSession session,
    required List<Team> teams,
    required List<AgendaItem> items,
  }) {
    final now = DateTime.now();
    final weekStart = _weekStartMonday(now);
    final weekEnd = _weekEndSunday(weekStart);
    final state = OpponentAnalysisPromptStateService.instance;

    final matchItems = items
        .where((item) => item.type == AgendaItemType.match)
        .where((item) => item.match != null)
        .where(
          (item) =>
              item.startAt.isAfter(now.subtract(const Duration(hours: 2))),
        )
        .where((item) => !item.startAt.isBefore(weekStart))
        .where((item) => !item.startAt.isAfter(weekEnd))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    debugPrint(
      'OpponentAnalysisReportPrompt: pick from ${items.length} items → '
      '${matchItems.length} match(es) in week '
      '${weekStart.toLocal()}..${weekEnd.toLocal()}',
    );

    for (final item in matchItems) {
      final match = item.match!;
      final matchId = match.id?.trim() ?? item.id.trim();
      if (matchId.isEmpty || !state.shouldPromptMatch(matchId)) {
        debugPrint(
          'OpponentAnalysisReportPrompt: skip $matchId (already answered)',
        );
        continue;
      }

      final team = _teamForMatch(match: match, teams: teams);
      if (team == null) {
        debugPrint(
          'OpponentAnalysisReportPrompt: skip $matchId — team not matched '
          '(teamID=${match.teamID}, teams=${match.teams}, '
          '${match.team1} vs ${match.team2})',
        );
        continue;
      }

      if (!canAccessTeamSessionDetails(session, team.keyTeam) &&
          session.selectedPlayer?.isEducatorOrCoach != true) {
        debugPrint(
          'OpponentAnalysisReportPrompt: skip $matchId — no access to '
          '${team.keyTeam}',
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
          'OpponentAnalysisReportPrompt: skip $matchId — no opponent for '
          '${team.name}',
        );
        continue;
      }

      return _UpcomingOpponentMatch(
        match: match,
        matchId: matchId,
        team: team,
        kickoff: item.startAt,
        opponent: opponent,
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

  Future<({String url, String label, String seasonId})?> _resolveCompetition(
    AppSession session,
  ) async {
    final l10n = context.l10n;
    final team = widget.candidate.team;
    final match = widget.candidate.match;
    final seasonId = session.selectedSeason?.ref?.id?.trim() ?? '';
    final resolvedSeasonId =
        teamStatsSeasonIdForTeam(team, seasonId) ?? seasonId;
    if (resolvedSeasonId.isEmpty) return null;

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
    }

    if (competitionUrl == null || competitionUrl.trim().isEmpty) {
      return null;
    }
    if (competitionLabel.isEmpty) {
      competitionLabel = 'Compétition';
    }
    return (
      url: competitionUrl.trim(),
      label: competitionLabel,
      seasonId: resolvedSeasonId,
    );
  }

  Future<void> _onYes() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final colors = context.appColors;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final session = context.read<AppSession>();

    try {
      final competition = await _resolveCompetition(session);
      if (competition == null) {
        throw StateError('competition_unresolved');
      }

      final data = await OpponentAnalysisReportDataService.instance.build(
        team: widget.candidate.team,
        seasonId: competition.seasonId,
        competitionUrl: competition.url,
        competitionLabel: competition.label,
        opponent: widget.candidate.opponent,
        upcomingMatch: widget.candidate.match,
        upcomingKickoff: widget.candidate.kickoff,
        teamName: widget.candidate.team.name,
      );

      // Only after the report payload is ready: don't re-ask for this match.
      await OpponentAnalysisPromptStateService.instance.markAccepted(_matchId);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final sent = await showOpponentAnalysisReportEmailDialog(
        context: appNavigatorKey.currentContext ?? context,
        data: data,
      );
      if (sent) {
        await OpponentAnalysisPromptStateService.instance.markSent(_matchId);
      }
    } catch (e, st) {
      debugPrint('Opponent analysis prompt yes failed: $e\n$st');
      if (mounted) {
        final detail = e.toString();
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              detail.contains('competition_unresolved')
                  ? l10n.opponentAnalysisReportSendFailed
                  : '${l10n.opponentAnalysisReportSendFailed}\n$detail',
            ),
            backgroundColor: colors.danger,
            duration: const Duration(seconds: 6),
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
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              height: 1.4,
            ),
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
