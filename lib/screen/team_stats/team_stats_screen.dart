import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/team_stats/team_stats_calendars_tab.dart';
import 'package:grinta/screen/team_stats/team_stats_competitions_tab.dart';
import 'package:grinta/screen/team_stats/team_stats_opponents_tab.dart';
import 'package:grinta/screen/team_stats/team_stats_trainings_tab.dart';
import 'package:grinta/services/opponent_stats_view_tracker.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:provider/provider.dart';

/// Opens team statistics for [team] (manager or player view).
Future<void> openTeamStatsScreen(
  BuildContext context, {
  required Team team,
  required bool isManager,
  int initialTabIndex = 0,
  String? initialCompetitionUrl,
  String? initialOpponentKey,
  String? initialOpponentName,
  String? initialMatchIdForViewTracking,
}) {
  final seasonId = context.read<AppSession>().selectedSeason?.ref?.id;

  return Navigator.of(context).push<void>(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.teamStats,
      builder: (_) => TeamStatsScreen(
        team: team,
        isManager: isManager,
        fallbackSeasonId: seasonId,
        initialTabIndex: initialTabIndex,
        initialCompetitionUrl: initialCompetitionUrl,
        initialOpponentKey: initialOpponentKey,
        initialOpponentName: initialOpponentName,
        initialMatchIdForViewTracking: initialMatchIdForViewTracking,
      ),
    ),
  );
}

class TeamStatsScreen extends StatefulWidget {
  const TeamStatsScreen({
    super.key,
    required this.team,
    required this.isManager,
    this.fallbackSeasonId,
    this.initialTabIndex = 0,
    this.initialCompetitionUrl,
    this.initialOpponentKey,
    this.initialOpponentName,
    this.initialMatchIdForViewTracking,
  });

  final Team team;
  final bool isManager;
  final String? fallbackSeasonId;
  final int initialTabIndex;
  final String? initialCompetitionUrl;
  final String? initialOpponentKey;
  final String? initialOpponentName;
  final String? initialMatchIdForViewTracking;

  @override
  State<TeamStatsScreen> createState() => _TeamStatsScreenState();
}

class _TeamStatsScreenState extends State<TeamStatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String _teamName(BuildContext context) {
    final value = (widget.team.name ?? '').trim();
    return value.isEmpty ? context.l10n.entityTeam : value;
  }

  bool get _showOpponentsTab =>
      widget.isManager || UserTrialService.instance.hasPremiumAccess;

  int get _tabCount => _showOpponentsTab ? 4 : 3;

  @override
  void initState() {
    super.initState();
    final maxIndex = _tabCount - 1;
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, maxIndex),
    );
    _trackOpponentStatsViewIfNeeded();
  }

  void _trackOpponentStatsViewIfNeeded() {
    final matchId = widget.initialMatchIdForViewTracking?.trim() ?? '';
    final opponentKey = widget.initialOpponentKey?.trim() ?? '';
    if (matchId.isEmpty || opponentKey.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      OpponentStatsViewTracker.instance.markViewed(
        matchId: matchId,
        opponentKey: opponentKey,
        teamId: widget.team.keyTeam,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final teamName = _teamName(context);

    return ListenableBuilder(
      listenable: UserTrialService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(
              l10n.teamStatsScreenTitle(teamName),
              style: textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              indicatorColor: colors.primary,
              tabs: [
                Tab(text: l10n.teamStatsTabAnalysis),
                Tab(text: l10n.teamStatsTabTrainings),
                if (_showOpponentsTab) Tab(text: l10n.teamStatsTabOpponents),
                Tab(text: l10n.teamStatsTabCalendars),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              TeamStatsCompetitionsTab(
                team: widget.team,
                isManager: widget.isManager,
                fallbackSeasonId: widget.fallbackSeasonId,
              ),
              TeamStatsTrainingsTab(
                team: widget.team,
                isManager: widget.isManager,
                fallbackSeasonId: widget.fallbackSeasonId,
              ),
              if (_showOpponentsTab)
                TeamStatsOpponentsTab(
                  team: widget.team,
                  isManager: widget.isManager,
                  fallbackSeasonId: widget.fallbackSeasonId,
                  initialCompetitionUrl: widget.initialCompetitionUrl,
                  initialOpponentKey: widget.initialOpponentKey,
                  initialOpponentName: widget.initialOpponentName,
                  initialMatchIdForViewTracking:
                      widget.initialMatchIdForViewTracking,
                ),
              TeamStatsCalendarsTab(
                team: widget.team,
                fallbackSeasonId: widget.fallbackSeasonId,
              ),
            ],
          ),
        );
      },
    );
  }
}
