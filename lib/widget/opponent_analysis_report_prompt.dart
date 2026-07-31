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
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_outcome_helper.dart';
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

/// Invisible host: keeps a [BuildContext] with [AppSession] for the prompt.
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Home: ask once per team (max), never re-run in the same app process.
class OpponentAnalysisReportPrompt {
  OpponentAnalysisReportPrompt._();

  /// Absolute lock: this process shows the prompt sequence at most once.
  static bool _locked = false;
  static BuildContext? Function()? _hostContext;

  static void bindHost(BuildContext? Function() contextGetter) {
    _hostContext = contextGetter;
  }

  static void unbindHost() {
    _hostContext = null;
  }

  /// Call once when the home shell is painted.
  static void onHomeShellReady() {
    if (_locked) return;
    _locked = true;
    unawaited(_runOnce());
  }

  static BuildContext? _resolveContext() {
    final root = appNavigatorKey.currentContext;
    if (root != null && root.mounted) return root;
    final host = _hostContext?.call();
    if (host != null && host.mounted) return host;
    return null;
  }

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

  static Future<void> _runOnce() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final context = _resolveContext();
    if (context == null) return;

    AppSession session;
    try {
      session = context.read<AppSession>();
    } catch (_) {
      return;
    }

    if (session.isLoading || !isEligibleCoachOrManager(session)) return;

    final teams = session.teamsForAgendaSelectedSeason;
    if (teams.isEmpty) return;

    await OpponentAnalysisPromptStateService.instance.ensureInitialized();
    if (OpponentAnalysisPromptStateService.instance.isSnoozed) return;

    for (var i = 0; i < 20 && YoutubeTopVideoPrompt.isDialogOpen; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!context.mounted) return;
    }

    final items = await _loadWeekMatchItems(session, teams);
    final candidates = _pickOneMatchPerTeam(
      session: session,
      teams: teams,
      items: items,
    );
    if (candidates.isEmpty || !context.mounted) return;

    // One dialog per team, sequential — then never again this process.
    for (final candidate in candidates) {
      if (!context.mounted) return;
      if (OpponentAnalysisPromptStateService.instance.isSnoozed) return;
      if (!OpponentAnalysisPromptStateService.instance
          .shouldPromptMatch(candidate.matchId)) {
        continue;
      }

      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) => _OpponentAnalysisPromptDialog(candidate: candidate),
      );
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
      return await AgendaService().loadAgendaItems(
        teams: teams,
        seasonId: seasonId.isEmpty ? null : seasonId,
        start: weekStart,
        end: weekEnd,
      );
    } catch (e, st) {
      debugPrint('OpponentAnalysisReportPrompt: loadAgendaItems failed: $e\n$st');
      return const [];
    }
  }

  static Team? _teamForMatch({
    required models.Match match,
    required List<Team> teams,
  }) {
    final primary = match.teamID?.trim() ?? '';
    if (primary.isNotEmpty) {
      for (final team in teams) {
        if ((team.keyTeam?.trim() ?? '') == primary) return team;
      }
    }

    for (final raw in match.teams ?? const []) {
      final id = raw?.toString().trim() ?? '';
      if (id.isEmpty) continue;
      for (final team in teams) {
        if ((team.keyTeam?.trim() ?? '') == id) return team;
      }
    }

    return null;
  }

  static List<_UpcomingOpponentMatch> _pickOneMatchPerTeam({
    required AppSession session,
    required List<Team> teams,
    required List<AgendaItem> items,
  }) {
    final now = DateTime.now();
    final weekStart = _weekStartMonday(now);
    final weekEnd = _weekEndSunday(weekStart);
    final state = OpponentAnalysisPromptStateService.instance;
    final seenTeamIds = <String>{};
    final result = <_UpcomingOpponentMatch>[];

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

    for (final item in matchItems) {
      final match = item.match!;
      final matchId = match.id?.trim() ?? item.id.trim();
      if (matchId.isEmpty || !state.shouldPromptMatch(matchId)) continue;

      final team = _teamForMatch(match: match, teams: teams);
      if (team == null) continue;

      final teamId = team.keyTeam?.trim() ?? '';
      if (teamId.isEmpty || seenTeamIds.contains(teamId)) continue;

      if (!canAccessTeamSessionDetails(session, teamId) &&
          session.selectedPlayer?.isEducatorOrCoach != true) {
        continue;
      }

      final opponent = opponentForMatch(
        match: match,
        teamId: teamId,
        clubId: team.clubId,
      );
      if (opponent == null || opponent.displayName.trim().isEmpty) continue;

      final ownSide = teamSideForMatch(
        match: match,
        teamId: teamId,
        clubId: team.clubId,
      );
      if (ownSide != null) {
        final ownName = ownSide == MatchSide.team1
            ? (match.team1 ?? '').trim()
            : (match.team2 ?? '').trim();
        if (ownName.isNotEmpty &&
            _compactName(ownName) == _compactName(opponent.displayName)) {
          continue;
        }
      }

      seenTeamIds.add(teamId);
      result.add(
        _UpcomingOpponentMatch(
          match: match,
          matchId: matchId,
          team: team,
          kickoff: item.startAt,
          opponent: opponent,
        ),
      );
    }

    return result;
  }

  static String _compactName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
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

  static String _compactName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<
      ({
        String url,
        String label,
        String seasonId,
        TeamStatsOpponent opponent,
      })?> _resolveReportSource(AppSession session) async {
    final l10n = context.l10n;
    final team = widget.candidate.team;
    final match = widget.candidate.match;
    final seasonId = session.selectedSeason?.ref?.id?.trim() ?? '';
    final resolvedSeasonId =
        teamStatsSeasonIdForTeam(team, seasonId) ?? seasonId;
    if (resolvedSeasonId.isEmpty) return null;

    final options = await loadTeamStatsCompetitionOptions(
      team: team,
      l10n: l10n,
      fallbackSeasonId: resolvedSeasonId,
      includeAllOption: false,
    );
    if (options.isEmpty) return null;

    final matchUrl = await resolveTeamStatsCompetitionUrlForMatch(
      team: team,
      match: match,
      fallbackSeasonId: resolvedSeasonId,
    );

    final ordered = <TeamStatsCompetitionOption>[
      ...options.where((o) => (o.url ?? '').trim() == (matchUrl ?? '').trim()),
      ...options.where((o) => (o.url ?? '').trim() != (matchUrl ?? '').trim()),
    ];

    final needle = _compactName(widget.candidate.opponent.displayName);
    final stats = TeamCompetitionStatsService();

    for (final option in ordered) {
      final url = option.url?.trim() ?? '';
      if (url.isEmpty) continue;
      try {
        final opponents = await stats.loadOpponentsForTeam(
          team: team,
          seasonId: resolvedSeasonId,
          competitionUrl: url,
        );
        for (final opponent in opponents) {
          if (_compactName(opponent.displayName) == needle ||
              opponent.key == widget.candidate.opponent.key) {
            return (
              url: url,
              label: option.label,
              seasonId: resolvedSeasonId,
              opponent: opponent,
            );
          }
        }
      } catch (e, st) {
        debugPrint('Opponent analysis: loadOpponents failed: $e\n$st');
      }
    }

    if (matchUrl != null && matchUrl.trim().isNotEmpty) {
      String label = 'Compétition';
      for (final option in ordered) {
        if ((option.url ?? '').trim() == matchUrl.trim()) {
          label = option.label;
          break;
        }
      }
      return (
        url: matchUrl.trim(),
        label: label,
        seasonId: resolvedSeasonId,
        opponent: widget.candidate.opponent,
      );
    }

    return null;
  }

  Future<void> _onYes() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final colors = context.appColors;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final session = context.read<AppSession>();

    // Persist immediately so a reload never re-asks this match.
    await OpponentAnalysisPromptStateService.instance.markAccepted(_matchId);

    try {
      final source = await _resolveReportSource(session);
      if (source == null) {
        if (mounted) {
          messenger?.showSnackBar(
            SnackBar(
              content: Text(l10n.opponentAnalysisReportSendFailed),
              backgroundColor: colors.danger,
              duration: const Duration(seconds: 6),
            ),
          );
          Navigator.of(context, rootNavigator: true).pop();
        }
        return;
      }

      final data = await OpponentAnalysisReportDataService.instance.build(
        team: widget.candidate.team,
        seasonId: source.seasonId,
        competitionUrl: source.url,
        competitionLabel: source.label,
        opponent: source.opponent,
        upcomingMatch: widget.candidate.match,
        upcomingKickoff: widget.candidate.kickoff,
        teamName: widget.candidate.team.name,
      );

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
        messenger?.showSnackBar(
          SnackBar(
            content: Text(l10n.opponentAnalysisReportSendFailed),
            backgroundColor: colors.danger,
            duration: const Duration(seconds: 6),
          ),
        );
        Navigator.of(context, rootNavigator: true).pop();
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
    final teamName = (widget.candidate.team.name ?? '').trim();

    return AlertDialog(
      backgroundColor: colors.card,
      title: Text(l10n.opponentAnalysisPromptTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (teamName.isNotEmpty) ...[
            Text(
              teamName,
              style: TextStyle(
                color: colors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
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
