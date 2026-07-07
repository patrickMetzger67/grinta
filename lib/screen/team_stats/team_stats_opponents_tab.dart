import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/services/opponent_stats_view_tracker.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/services/team_player_stats_service.dart';
import 'package:grinta/services/team_typical_team_service.dart';
import 'package:grinta/services/teams_per_club_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';
import 'package:grinta/widget/team_stats_players_table.dart';
import 'package:grinta/widget/team_stats_typical_team_section.dart';
import 'package:grinta/widget/team_stats_wdl_matches_dialog.dart';
import 'package:grinta/widget/team_stats_wdl_pie_chart.dart';
import 'package:grinta/widget/team_stats_wdl_trend_indicator.dart';
import 'package:provider/provider.dart';

/// Opponents tab: filter by competition and opponent, then W/D/L and player stats.
class TeamStatsOpponentsTab extends StatefulWidget {
  const TeamStatsOpponentsTab({
    super.key,
    required this.team,
    required this.isManager,
    this.fallbackSeasonId,
    this.initialCompetitionUrl,
    this.initialOpponentKey,
    this.initialOpponentName,
    this.initialMatchIdForViewTracking,
    TeamsPerClubService? teamsPerClubService,
    TeamCompetitionStatsService? teamCompetitionStatsService,
    TeamPlayerStatsService? teamPlayerStatsService,
    TeamTypicalTeamService? teamTypicalTeamService,
  })  : _teamsPerClubService = teamsPerClubService,
        _teamCompetitionStatsService = teamCompetitionStatsService,
        _teamPlayerStatsService = teamPlayerStatsService,
        _teamTypicalTeamService = teamTypicalTeamService;

  final Team team;
  final bool isManager;
  final String? fallbackSeasonId;
  final String? initialCompetitionUrl;
  final String? initialOpponentKey;
  final String? initialOpponentName;
  final String? initialMatchIdForViewTracking;
  final TeamsPerClubService? _teamsPerClubService;
  final TeamCompetitionStatsService? _teamCompetitionStatsService;
  final TeamPlayerStatsService? _teamPlayerStatsService;
  final TeamTypicalTeamService? _teamTypicalTeamService;

  @override
  State<TeamStatsOpponentsTab> createState() => _TeamStatsOpponentsTabState();
}

class _TeamStatsOpponentsTabState extends State<TeamStatsOpponentsTab>
    with SingleTickerProviderStateMixin {
  bool _loadingCompetitions = true;
  bool _loadingOpponents = false;
  bool _statsLoading = false;
  bool _playersStatsLoading = false;
  bool _typicalTeamLoading = false;
  bool _didInit = false;
  List<TeamStatsCompetitionOption> _competitionOptions = const [];
  String? _selectedCompetitionValue;
  List<TeamStatsOpponent> _opponents = const [];
  String? _selectedOpponentKey;
  TeamWdlStatsByPeriod? _wdlStats;
  TeamPlayerStatsResult? _playerStats;
  TypicalTeamResult? _typicalTeam;
  late final TabController _subTabController;

  TeamCompetitionStatsService get _statsService =>
      widget._teamCompetitionStatsService ?? TeamCompetitionStatsService();

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
    _subTabController.addListener(_onSubTabChanged);
    _trackOpponentViewIfNeeded();
  }

  void _trackOpponentViewIfNeeded() {
    final matchId = widget.initialMatchIdForViewTracking?.trim() ?? '';
    final opponentKey = _selectedOpponentKey?.trim() ??
        widget.initialOpponentKey?.trim() ??
        '';
    if (matchId.isEmpty || opponentKey.isEmpty) return;

    OpponentStatsViewTracker.instance.markViewed(
      matchId: matchId,
      opponentKey: opponentKey,
      teamId: widget.team.keyTeam,
    );
  }

  void _onSubTabChanged() {
    if (_subTabController.indexIsChanging) {
      return;
    }
    if (_subTabController.index == 1) {
      _loadPlayerStats();
    } else if (_subTabController.index == 2) {
      _loadTypicalTeam();
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

  TeamStatsOpponent? _selectedOpponent() {
    final key = _selectedOpponentKey?.trim() ?? '';
    if (key.isEmpty) {
      return null;
    }
    for (final opponent in _opponents) {
      if (opponent.key == key) {
        return opponent;
      }
    }
    return null;
  }

  String? _resolveOpponentKey(List<TeamStatsOpponent> opponents) {
    final initialKey = widget.initialOpponentKey?.trim() ?? '';
    if (initialKey.isNotEmpty &&
        opponents.any((opponent) => opponent.key == initialKey)) {
      return initialKey;
    }

    final initialName = widget.initialOpponentName?.trim() ?? '';
    if (initialName.isNotEmpty) {
      final normalized = initialName.toLowerCase();
      for (final opponent in opponents) {
        if (opponent.displayName.trim().toLowerCase() == normalized) {
          return opponent.key;
        }
      }
    }

    return opponents.isNotEmpty ? opponents.first.key : null;
  }

  String? _resolveCompetitionValue(List<TeamStatsCompetitionOption> options) {
    final initialUrl = widget.initialCompetitionUrl?.trim() ?? '';
    if (initialUrl.isNotEmpty) {
      for (final option in options) {
        if (option.value == initialUrl || option.url == initialUrl) {
          return option.value;
        }
      }
    }
    return options.isNotEmpty ? options.first.value : null;
  }

  Future<void> _loadCompetitions() async {
    final options = await loadTeamStatsCompetitionOptions(
      team: widget.team,
      l10n: context.l10n,
      fallbackSeasonId: widget.fallbackSeasonId,
      teamsPerClubService: widget._teamsPerClubService,
      includeAllOption: false,
    );

    if (!mounted) return;

    final selectedValue = _resolveCompetitionValue(options);
    setState(() {
      _loadingCompetitions = false;
      _competitionOptions = options;
      _selectedCompetitionValue = selectedValue;
      _opponents = const [];
      _selectedOpponentKey = null;
      _wdlStats = null;
      _playerStats = null;
      _typicalTeam = null;
    });

    if (selectedValue != null) {
      await _loadOpponents(selectedValue);
    }
  }

  Future<void> _loadOpponents(String competitionValue) async {
    final seasonId = _seasonIdForTeam();
    final competitionUrl = teamStatsSelectedCompetitionUrl(competitionValue);
    if (seasonId == null || competitionUrl == null) {
      if (!mounted) return;
      setState(() {
        _loadingOpponents = false;
        _opponents = const [];
        _selectedOpponentKey = null;
        _wdlStats = null;
        _playerStats = null;
      });
      return;
    }

    setState(() {
      _loadingOpponents = true;
      _opponents = const [];
      _selectedOpponentKey = null;
      _wdlStats = null;
      _playerStats = null;
      _typicalTeam = null;
    });

    final opponents = await _statsService.loadOpponentsForTeam(
      team: widget.team,
      seasonId: seasonId,
      competitionUrl: competitionUrl,
    );

    if (!mounted) return;

    final selectedKey = _resolveOpponentKey(opponents);
    setState(() {
      _loadingOpponents = false;
      _opponents = opponents;
      _selectedOpponentKey = selectedKey;
    });

    if (selectedKey != null) {
      await _loadStats();
    }
  }

  Future<void> _loadStats() async {
    final seasonId = _seasonIdForTeam();
    final competitionUrl =
        teamStatsSelectedCompetitionUrl(_selectedCompetitionValue ?? '');
    final opponent = _selectedOpponent();

    if (seasonId == null || competitionUrl == null || opponent == null) {
      if (!mounted) return;
      setState(() {
        _statsLoading = false;
        _playersStatsLoading = false;
        _typicalTeamLoading = false;
        _wdlStats = null;
        _playerStats = null;
        _typicalTeam = null;
      });
      return;
    }

    setState(() {
      _statsLoading = true;
      _playerStats = null;
      _typicalTeam = null;
    });

    final wdlStats = await _statsService.computeWdlStatsForTeam(
      team: widget.team,
      seasonId: seasonId,
      competitionUrl: competitionUrl,
      opponentFilter: opponent,
    );

    if (!mounted) return;
    setState(() {
      _statsLoading = false;
      _wdlStats = wdlStats;
    });

    if (_subTabController.index == 1) {
      await _loadPlayerStats();
    } else if (_subTabController.index == 2) {
      await _loadTypicalTeam();
    }
  }

  Future<void> _loadTypicalTeam() async {
    final seasonId = _seasonIdForTeam();
    final competitionUrl =
        teamStatsSelectedCompetitionUrl(_selectedCompetitionValue ?? '');
    final opponent = _selectedOpponent();

    if (seasonId == null || competitionUrl == null || opponent == null) {
      if (!mounted) return;
      setState(() {
        _typicalTeamLoading = false;
        _typicalTeam = null;
      });
      return;
    }

    setState(() => _typicalTeamLoading = true);

    final service =
        widget._teamTypicalTeamService ?? TeamTypicalTeamService();
    final result = await service.computeTypicalTeamForOpponent(
      team: widget.team,
      seasonId: seasonId,
      competitionUrl: competitionUrl,
      opponentFilter: opponent,
    );

    if (!mounted) return;
    setState(() {
      _typicalTeamLoading = false;
      _typicalTeam = result;
    });
  }

  Future<void> _loadPlayerStats() async {
    final seasonId = _seasonIdForTeam();
    final competitionUrl =
        teamStatsSelectedCompetitionUrl(_selectedCompetitionValue ?? '');
    final opponent = _selectedOpponent();

    if (seasonId == null || competitionUrl == null || opponent == null) {
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
      competitionUrl: competitionUrl,
      opponentFilter: opponent,
      useMatchStats: true,
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

    return result.statsByPlayerId.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    if (_loadingCompetitions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_competitionOptions.isEmpty) {
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
          options: _competitionOptions,
          selectedValue: _selectedCompetitionValue!,
          onChanged: (value) {
            setState(() {
              _selectedCompetitionValue = value;
              _subTabController.index = 0;
            });
            _loadOpponents(value);
          },
        ),
        const SizedBox(height: 16),
        if (_loadingOpponents)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_opponents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.teamStatsNoOpponents,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          )
        else ...[
          _TeamStatsOpponentDropdown(
            opponents: _opponents,
            selectedKey: _selectedOpponentKey!,
            onChanged: (key) {
              setState(() {
                _selectedOpponentKey = key;
                _subTabController.index = 0;
              });
              _loadStats();
            },
          ),
          const SizedBox(height: 24),
          if (_statsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_wdlStats != null) ...[
            TabBar(
              controller: _subTabController,
              labelColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              indicatorColor: colors.primary,
              onTap: (_) => setState(() {}),
              tabs: [
                Tab(text: l10n.teamStatsSubTabMatches),
                Tab(text: l10n.teamStatsSubTabPlayers),
                Tab(text: l10n.teamStatsSubTabTypicalTeam),
              ],
            ),
            const SizedBox(height: 16),
            if (_subTabController.index == 0)
              ..._buildMatchesContent(l10n)
            else if (_subTabController.index == 1)
              _buildPlayersContent(context, l10n)
            else
              _buildTypicalTeamContent(l10n),
          ],
        ],
      ],
    );
  }

  List<Widget> _buildMatchesContent(AppLocalizations l10n) {
    final stats = _wdlStats!;
    if (stats.fullSeason.counts.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            l10n.teamStatsNoPlayedMatches,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.appColors.textSecondary,
                ),
          ),
        ),
      ];
    }

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
      displayName: stats.perspectiveDisplayName,
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

  Widget _buildTypicalTeamContent(AppLocalizations l10n) {
    if (_typicalTeamLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final result = _typicalTeam;
    if (result == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            l10n.teamStatsTypicalTeamNoData,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.appColors.textSecondary,
                ),
          ),
        ),
      );
    }

    return TeamStatsTypicalTeamSection(result: result);
  }
}

class _TeamStatsOpponentDropdown extends StatelessWidget {
  const _TeamStatsOpponentDropdown({
    required this.opponents,
    required this.selectedKey,
    required this.onChanged,
  });

  final List<TeamStatsOpponent> opponents;
  final String selectedKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.teamStatsOpponentFilterLabel,
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
          value: selectedKey,
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
          items: opponents
              .map(
                (opponent) => DropdownMenuItem<String>(
                  value: opponent.key,
                  child: Text(
                    opponent.displayName,
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
