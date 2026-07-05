import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/ranking.dart';
import 'package:grinta/model/rankingPerDay.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/clubService.dart';
import 'package:grinta/services/ranking_per_day_service.dart';
import 'package:grinta/services/ranking_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_stats_ranking_helper.dart';
import 'package:grinta/widget/team_stats_ranking_evolution_chart.dart';
import 'package:grinta/widget/team_stats_ranking_table.dart';

class TeamStatsRankingSection extends StatefulWidget {
  const TeamStatsRankingSection({
    super.key,
    required this.team,
    required this.selectedCompetitionValue,
    this.seasonId,
    RankingService? rankingService,
    RankingPerDayService? rankingPerDayService,
    ClubService? clubService,
  })  : _rankingService = rankingService,
        _rankingPerDayService = rankingPerDayService,
        _clubService = clubService;

  final Team team;
  final String selectedCompetitionValue;
  final String? seasonId;
  final RankingService? _rankingService;
  final RankingPerDayService? _rankingPerDayService;
  final ClubService? _clubService;

  @override
  State<TeamStatsRankingSection> createState() =>
      _TeamStatsRankingSectionState();
}

class _TeamStatsRankingSectionState extends State<TeamStatsRankingSection>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Ranking? _ranking;
  List<RankingPerDay> _rankingPerDayEntries = const [];
  TeamStatsRankingTeamContext? _teamContext;
  Set<String> _selectedAffiliates = {};
  late final TabController _viewTabController;

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void didUpdateWidget(covariant TeamStatsRankingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCompetitionValue != widget.selectedCompetitionValue ||
        oldWidget.seasonId != widget.seasonId) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _viewTabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final filter =
        teamStatsRankingFilterFromSelection(widget.selectedCompetitionValue);

    if (filter == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _ranking = null;
        _rankingPerDayEntries = const [];
        _teamContext = null;
        _selectedAffiliates = {};
      });
      return;
    }

    setState(() => _loading = true);

    final rankingService = widget._rankingService ?? RankingService();
    final rankingPerDayService =
        widget._rankingPerDayService ?? RankingPerDayService();

    final teamContext = await resolveTeamStatsRankingTeamContext(
      widget.team,
      clubService: widget._clubService,
    );

    final results = await Future.wait([
      rankingService.getRankingsByCompetitionIdAndPoule(
        competitionId: filter.competitionId,
        poule: filter.poule,
      ),
      rankingPerDayService.getRankingsPerDayByCompetitionIdAndPoule(
        competitionId: filter.competitionId,
        poule: filter.poule,
      ),
    ]);

    if (!mounted) return;

    final rankings = results[0] as List<Ranking>;
    final perDayEntries = results[1] as List<RankingPerDay>;
    final ownAffiliate = teamContext.primaryAffiliate;

    setState(() {
      _loading = false;
      _teamContext = teamContext;
      _ranking = pickBestRankingDocument(rankings);
      _rankingPerDayEntries = perDayEntries;
      _selectedAffiliates = ownAffiliate.isNotEmpty ? {ownAffiliate} : {};
    });
  }

  Future<void> _openClubSelector() async {
    final teamContext = _teamContext;
    if (teamContext == null) {
      return;
    }

    final options = buildRankingClubOptions(
      _rankingPerDayEntries,
      teamContext,
    );
    if (options.isEmpty) {
      return;
    }

    final ownAffiliate = teamContext.primaryAffiliate;
    final result = await showTeamStatsRankingClubSelector(
      context: context,
      options: options,
      selectedAffiliates: _selectedAffiliates,
      ownTeamAffiliate: ownAffiliate,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedAffiliates = {
        ...result,
        if (ownAffiliate.isNotEmpty) ownAffiliate,
      };
    });
  }

  List<TeamStatsRankingEvolutionSeries> _evolutionSeries(
    AppColors colors,
  ) {
    final teamContext = _teamContext;
    if (teamContext == null || _selectedAffiliates.isEmpty) {
      return const [];
    }

    final grouped = groupRankingPerDayByAffiliate(_rankingPerDayEntries);
    final palette = teamStatsRankingChartColors(colors);
    final options = buildRankingClubOptions(
      _rankingPerDayEntries,
      teamContext,
    );
    final labelsByAffiliate = {
      for (final option in options) option.affiliateKey: option.displayName,
    };

    final series = <TeamStatsRankingEvolutionSeries>[];
    var colorIndex = 0;

    for (final affiliate in _selectedAffiliates) {
      final entries = grouped[affiliate];
      if (entries == null || entries.isEmpty) {
        continue;
      }

      series.add(
        TeamStatsRankingEvolutionSeries(
          affiliateKey: affiliate,
          label: labelsByAffiliate[affiliate] ?? affiliate,
          color: palette[colorIndex % palette.length],
          entries: entries,
          isOwnTeam: teamContext.matchesAffiliate(affiliate),
        ),
      );
      colorIndex++;
    }

    series.sort((a, b) {
      if (a.isOwnTeam != b.isOwnTeam) {
        return a.isOwnTeam ? -1 : 1;
      }
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });

    return series;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final filter =
        teamStatsRankingFilterFromSelection(widget.selectedCompetitionValue);

    if (filter == null) {
      return _messageCard(
        l10n.teamStatsRankingSelectCompetition,
        colors,
        textTheme,
      );
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final teamContext = _teamContext;
    if (teamContext == null) {
      return _messageCard(
        l10n.teamStatsRankingNoData,
        colors,
        textTheme,
      );
    }

    final matchdays = sortedMatchdaysFromRankingPerDay(_rankingPerDayEntries);
    final teamCount = rankingTeamCountFromEntries(_rankingPerDayEntries);
    final evolutionSeries = _evolutionSeries(colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _viewTabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          onTap: (_) => setState(() {}),
          tabs: [
            Tab(text: l10n.teamStatsRankingAtDate),
            Tab(text: l10n.teamStatsRankingEvolution),
          ],
        ),
        const SizedBox(height: 16),
        if (_viewTabController.index == 0)
          TeamStatsRankingTable(
            ranks: _ranking?.ranks ?? const [],
            teamContext: teamContext,
          )
        else ...[
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _rankingPerDayEntries.isEmpty
                  ? null
                  : _openClubSelector,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.teamStatsRankingAddClubs),
            ),
          ),
          const SizedBox(height: 12),
          TeamStatsRankingEvolutionChart(
            series: evolutionSeries,
            matchdays: matchdays,
            teamCount: teamCount,
          ),
        ],
      ],
    );
  }

  Widget _messageCard(
    String message,
    AppColors colors,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
