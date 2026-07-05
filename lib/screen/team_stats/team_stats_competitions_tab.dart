import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/screen/team_stats/team_stats_ranking_section.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/services/team_player_stats_service.dart';
import 'package:grinta/services/teams_per_club_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/widget/team_stats_goals_bar_chart.dart';
import 'package:grinta/widget/team_stats_goals_trend_indicator.dart';
import 'package:grinta/widget/team_stats_players_table.dart';
import 'package:grinta/widget/team_stats_wdl_matches_dialog.dart';
import 'package:grinta/widget/team_stats_wdl_pie_chart.dart';
import 'package:grinta/widget/team_stats_wdl_trend_indicator.dart';
import 'package:provider/provider.dart';

/// Analysis tab: loads FFF competitions for the team's équipe and shows a filter dropdown.
class TeamStatsCompetitionsTab extends StatefulWidget {
  const TeamStatsCompetitionsTab({
    super.key,
    required this.team,
    required this.isManager,
    this.fallbackSeasonId,
    this.initialSubTabIndex = 0,
    TeamsPerClubService? teamsPerClubService,
    TeamCompetitionStatsService? teamCompetitionStatsService,
    TeamPlayerStatsService? teamPlayerStatsService,
  })  : _teamsPerClubService = teamsPerClubService,
        _teamCompetitionStatsService = teamCompetitionStatsService,
        _teamPlayerStatsService = teamPlayerStatsService;

  final Team team;
  final bool isManager;
  final String? fallbackSeasonId;
  final int initialSubTabIndex;
  final TeamsPerClubService? _teamsPerClubService;
  final TeamCompetitionStatsService? _teamCompetitionStatsService;
  final TeamPlayerStatsService? _teamPlayerStatsService;

  @override
  State<TeamStatsCompetitionsTab> createState() =>
      _TeamStatsCompetitionsTabState();
}

class _TeamStatsCompetitionsTabState extends State<TeamStatsCompetitionsTab>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _statsLoading = false;
  bool _playersStatsLoading = false;
  bool _didInit = false;
  List<TeamStatsCompetitionOption> _options = const [];
  String _selectedValue = kTeamStatsAllCompetitionsValue;
  TeamWdlStatsByPeriod? _wdlStats;
  TeamGoalsStatsByPeriod? _goalsStats;
  TeamPlayerStatsResult? _playerStats;
  late final TabController _subTabController;

  int get _rankingSubTabIndex => 1;

  int get _goalsSubTabIndex => 2;

  int get _playersSubTabIndex => widget.isManager ? 3 : 0;

  @override
  void initState() {
    super.initState();
    final subTabCount = widget.isManager ? 4 : 1;
    final initialIndex = widget.isManager
        ? widget.initialSubTabIndex.clamp(0, subTabCount - 1)
        : 0;
    _subTabController = TabController(
      length: subTabCount,
      vsync: this,
      initialIndex: initialIndex,
    );
    _subTabController.addListener(_onSubTabChanged);
  }

  void _onSubTabChanged() {
    if (_subTabController.indexIsChanging) {
      return;
    }
    if (_subTabController.index == _playersSubTabIndex) {
      _loadPlayerStats();
    }
  }

  @override
  void dispose() {
    _subTabController.removeListener(_onSubTabChanged);
    _subTabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _loadCompetitions();
    }
  }

  String? _seasonIdForTeam() =>
      teamStatsSeasonIdForTeam(widget.team, widget.fallbackSeasonId);

  Future<void> _loadCompetitions() async {
    final options = await loadTeamStatsCompetitionOptions(
      team: widget.team,
      l10n: context.l10n,
      fallbackSeasonId: widget.fallbackSeasonId,
      teamsPerClubService: widget._teamsPerClubService,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _options = options;
      _selectedValue = kTeamStatsAllCompetitionsValue;
    });

    await _loadWdlStats();
  }

  String? _selectedCompetitionUrl() =>
      teamStatsSelectedCompetitionUrl(_selectedValue);

  Future<void> _loadWdlStats() async {
    final seasonId = _seasonIdForTeam();
    final teamId = widget.team.keyTeam?.trim() ?? '';
    if (seasonId == null || teamId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _statsLoading = false;
        _wdlStats = null;
        _goalsStats = null;
        _playerStats = null;
        _playersStatsLoading = false;
      });
      return;
    }

    if (!widget.isManager) {
      await _loadPlayerStats();
      return;
    }

    setState(() {
      _statsLoading = true;
      _playerStats = null;
    });

    final competitionUrl = _selectedCompetitionUrl();
    final service =
        widget._teamCompetitionStatsService ?? TeamCompetitionStatsService();
    final results = await Future.wait([
      service.computeWdlStatsForTeam(
        team: widget.team,
        seasonId: seasonId,
        competitionUrl: competitionUrl,
      ),
      service.computeGoalsStatsForTeam(
        team: widget.team,
        seasonId: seasonId,
        competitionUrl: competitionUrl,
      ),
    ]);

    if (!mounted) return;
    setState(() {
      _statsLoading = false;
      _wdlStats = results[0] as TeamWdlStatsByPeriod;
      _goalsStats = results[1] as TeamGoalsStatsByPeriod;
    });

    if (_subTabController.index == _playersSubTabIndex) {
      await _loadPlayerStats();
    }
  }

  Future<void> _loadPlayerStats() async {
    final seasonId = _seasonIdForTeam();
    if (seasonId == null) {
      if (!mounted) return;
      setState(() {
        _playersStatsLoading = false;
        _playerStats = null;
      });
      return;
    }

    setState(() => _playersStatsLoading = true);

    final service = widget._teamPlayerStatsService ?? TeamPlayerStatsService();
    final result = await service.computePlayerStatsForTeam(
      team: widget.team,
      seasonId: seasonId,
      competitionUrl: _selectedCompetitionUrl(),
    );

    if (!mounted) return;
    setState(() {
      _playersStatsLoading = false;
      _playerStats = result;
    });
  }

  String? _currentPlayerId(BuildContext context) {
    return context.read<AppSession>().selectedPlayerId;
  }

  List<TeamPlayerSeasonStats> _playerStatsRows() {
    final result = _playerStats;
    if (result == null) {
      return const [];
    }

    final rows = result.statsByPlayerId.values.toList()
      ..sort((a, b) {
        final last = (a.player?.lastName ?? '')
            .toLowerCase()
            .compareTo((b.player?.lastName ?? '').toLowerCase());
        if (last != 0) {
          return last;
        }
        return (a.player?.firstName ?? '')
            .toLowerCase()
            .compareTo((b.player?.firstName ?? '').toLowerCase());
      });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_options.length <= 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.teamStatsNoCompetitions,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        TeamStatsCompetitionDropdown(
          options: _options,
          selectedValue: _selectedValue,
          onChanged: (value) {
            setState(() {
              _selectedValue = value;
              _subTabController.index = 0;
            });
            _loadWdlStats();
          },
        ),
        const SizedBox(height: 24),
        if (_statsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.isManager &&
            _wdlStats != null &&
            _goalsStats != null) ...[
          if (widget.isManager) ...[
            TabBar(
              controller: _subTabController,
              labelColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              indicatorColor: colors.primary,
              onTap: (_) => setState(() {}),
              tabs: [
                Tab(text: l10n.teamStatsSubTabMatches),
                Tab(text: l10n.teamStatsSubTabRanking),
                Tab(text: l10n.teamStatsSubTabGoals),
                Tab(text: l10n.teamStatsSubTabPlayers),
              ],
            ),
            const SizedBox(height: 16),
            if (_subTabController.index == 0)
              ..._buildMatchesContent(l10n)
            else if (_subTabController.index == _rankingSubTabIndex)
              TeamStatsRankingSection(
                team: widget.team,
                selectedCompetitionValue: _selectedValue,
                seasonId: _seasonIdForTeam(),
              )
            else if (_subTabController.index == _goalsSubTabIndex)
              ..._buildGoalsContent(l10n)
            else
              _buildPlayersContent(context, l10n),
          ] else ...[
            Text(
              l10n.teamStatsSubTabPlayers,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _buildPlayersContent(context, l10n),
          ],
        ] else if (!widget.isManager) ...[
          Text(
            l10n.teamStatsSubTabPlayers,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildPlayersContent(context, l10n),
        ],
      ],
    );
  }

  List<Widget> _buildGoalsContent(AppLocalizations l10n) {
    final stats = _goalsStats!;
    return [
      TeamStatsGoalsTrendIndicator(
        trends: TeamGoalsHalfTrends.compare(
          firstHalf: stats.firstHalf,
          secondHalf: stats.secondHalf,
        ),
      ),
      const SizedBox(height: 16),
      TeamStatsGoalsBarChart(
        title: l10n.teamStatsPeriodFullSeason,
        counts: stats.fullSeason,
      ),
      const SizedBox(height: 16),
      TeamStatsGoalsBarChart(
        title: l10n.teamStatsPeriodFirstHalf,
        counts: stats.firstHalf,
      ),
      const SizedBox(height: 16),
      TeamStatsGoalsBarChart(
        title: l10n.teamStatsPeriodSecondHalf,
        counts: stats.secondHalf,
      ),
    ];
  }

  List<Widget> _buildMatchesContent(AppLocalizations l10n) {
    final stats = _wdlStats!;
    return [
      TeamStatsWdlTrendIndicator(
        trend: TeamWdlHalfTrend.compare(
          firstHalf: stats.firstHalf.counts,
          secondHalf: stats.secondHalf.counts,
        ),
      ),
      const SizedBox(height: 16),
      TeamStatsWdlPieChart(
        title: l10n.teamStatsPeriodFullSeason,
        counts: stats.fullSeason.counts,
        onSegmentTap: (outcome) => _openWdlMatchesDialog(
          periodTitle: l10n.teamStatsPeriodFullSeason,
          periodData: stats.fullSeason,
          outcome: outcome,
          stats: stats,
        ),
      ),
      const SizedBox(height: 16),
      TeamStatsWdlPieChart(
        title: l10n.teamStatsPeriodFirstHalf,
        counts: stats.firstHalf.counts,
        onSegmentTap: (outcome) => _openWdlMatchesDialog(
          periodTitle: l10n.teamStatsPeriodFirstHalf,
          periodData: stats.firstHalf,
          outcome: outcome,
          stats: stats,
        ),
      ),
      const SizedBox(height: 16),
      TeamStatsWdlPieChart(
        title: l10n.teamStatsPeriodSecondHalf,
        counts: stats.secondHalf.counts,
        onSegmentTap: (outcome) => _openWdlMatchesDialog(
          periodTitle: l10n.teamStatsPeriodSecondHalf,
          periodData: stats.secondHalf,
          outcome: outcome,
          stats: stats,
        ),
      ),
    ];
  }

  void _openWdlMatchesDialog({
    required String periodTitle,
    required TeamWdlPeriodData periodData,
    required MatchOutcome outcome,
    required TeamWdlStatsByPeriod stats,
  }) {
    final matches = filterMatchesByOutcome(
      matches: periodData.matches,
      outcome: outcome,
      teamId: stats.teamId,
      clubId: stats.clubId,
      clubAffiliation: stats.clubAffiliation,
    );
    if (matches.isEmpty) {
      return;
    }

    showTeamStatsWdlMatchesDialog(
      context: context,
      periodTitle: periodTitle,
      outcome: outcome,
      matches: matches,
      team: widget.team,
    );
  }

  Widget _buildPlayersContent(BuildContext context, AppLocalizations l10n) {
    if (_playersStatsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final visiblePlayerId =
        widget.isManager ? null : _currentPlayerId(context);

    return TeamStatsPlayersTable(
      stats: _playerStatsRows(),
      visiblePlayerId: visiblePlayerId,
    );
  }
}
