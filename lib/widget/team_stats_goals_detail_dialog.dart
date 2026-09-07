import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_stats_goals_detail_helper.dart';
import 'package:intl/intl.dart';

/// Opens a dialog listing scored or conceded goals for a histogram bar.
void showTeamStatsGoalsDetailDialog({
  required BuildContext context,
  required String periodTitle,
  required TeamStatsGoalBarKind kind,
  required List<Match> matches,
  required String teamId,
  String? clubId,
  String? clubAffiliation,
  String? perspectiveDisplayName,
  HighlightsService? highlightsService,
}) {
  if (matches.isEmpty) {
    return;
  }

  showDialog<void>(
    context: context,
    builder: (dialogContext) => TeamStatsGoalsDetailDialog(
      periodTitle: periodTitle,
      kind: kind,
      matches: matches,
      teamId: teamId,
      clubId: clubId,
      clubAffiliation: clubAffiliation,
      perspectiveDisplayName: perspectiveDisplayName,
      highlightsService: highlightsService,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

class TeamStatsGoalsDetailDialog extends StatefulWidget {
  const TeamStatsGoalsDetailDialog({
    super.key,
    required this.periodTitle,
    required this.kind,
    required this.matches,
    required this.teamId,
    required this.onClose,
    this.clubId,
    this.clubAffiliation,
    this.perspectiveDisplayName,
    this.highlightsService,
  });

  final String periodTitle;
  final TeamStatsGoalBarKind kind;
  final List<Match> matches;
  final String teamId;
  final String? clubId;
  final String? clubAffiliation;
  final String? perspectiveDisplayName;
  final HighlightsService? highlightsService;
  final VoidCallback onClose;

  @override
  State<TeamStatsGoalsDetailDialog> createState() =>
      _TeamStatsGoalsDetailDialogState();
}

class _TeamStatsGoalsDetailDialogState extends State<TeamStatsGoalsDetailDialog>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<TeamStatsGoalDetail> _goals = const [];
  TabController? _tabController;

  bool get _showScorersRanking => widget.kind == TeamStatsGoalBarKind.scored;

  @override
  void initState() {
    super.initState();
    if (_showScorersRanking) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          setState(() {});
        }
      });
    }
    _loadGoals();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final service = widget.highlightsService ?? HighlightsService();
    final teamIdForHighlights = widget.teamId.trim();

    final perMatch = await Future.wait(
      widget.matches.map((match) async {
        final matchId = match.id?.trim() ?? '';
        if (matchId.isEmpty) {
          return const <TeamStatsGoalDetail>[];
        }
        try {
          final highlights = await service.getHighlightsByMatchCalendarId(
            matchId,
            teamId: teamIdForHighlights.isEmpty ? null : teamIdForHighlights,
          );
          return teamGoalDetailsFromHighlights(
            match: match,
            highlights: highlights,
            kind: widget.kind,
            teamId: widget.teamId,
            clubId: widget.clubId,
            clubAffiliation: widget.clubAffiliation,
            displayName: widget.perspectiveDisplayName,
          );
        } catch (_) {
          return const <TeamStatsGoalDetail>[];
        }
      }),
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _goals = sortTeamGoalDetails(perMatch.expand((goals) => goals));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final locale = l10n.localeName;
    final tabController = _tabController;
    final showTabs = _showScorersRanking && tabController != null;

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
                      l10n.teamStatsGoalsDetailDialogTitle(
                        _kindLabel(l10n, widget.kind),
                        widget.periodTitle,
                      ),
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.actionClose,
                    onPressed: widget.onClose,
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (showTabs) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _GoalsDetailTabBar(
                  controller: tabController,
                  tabs: [
                    Tab(text: l10n.teamStatsGoalsDetailTabChronology),
                    Tab(text: l10n.teamStatsGoalsDetailTabScorersRanking),
                  ],
                  onTap: (_) => setState(() {}),
                ),
              ),
            ],
            Divider(height: 1, color: colors.border),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _goals.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                          child: Center(
                            child: Text(
                              l10n.teamStatsGoalsDetailEmpty,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : showTabs
                          ? IndexedStack(
                              index: tabController.index,
                              children: [
                                _ChronologyGoalsList(
                                  goals: _goals,
                                  locale: locale,
                                  unknownScorer:
                                      l10n.teamStatsGoalsDetailUnknownScorer,
                                ),
                                _ScorersRankingList(
                                  ranks: aggregateTeamGoalScorers(
                                    _goals,
                                    unknownLabel:
                                        l10n.teamStatsGoalsDetailUnknownScorer,
                                  ),
                                  goalCountLabel: (count) =>
                                      l10n.teamStatsGoalsDetailScorerGoalCount(
                                        count,
                                      ),
                                ),
                              ],
                            )
                          : _ChronologyGoalsList(
                              goals: _goals,
                              locale: locale,
                              unknownScorer:
                                  l10n.teamStatsGoalsDetailUnknownScorer,
                            ),
            ),
          ],
        ),
      ),
    );
  }

  String _kindLabel(AppLocalizations l10n, TeamStatsGoalBarKind kind) {
    return switch (kind) {
      TeamStatsGoalBarKind.scored => l10n.teamStatsGoalsScored,
      TeamStatsGoalBarKind.conceded => l10n.teamStatsGoalsConceded,
    };
  }
}

class _GoalsDetailTabBar extends StatelessWidget {
  const _GoalsDetailTabBar({
    required this.controller,
    required this.tabs,
    required this.onTap,
  });

  final TabController controller;
  final List<Widget> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: TabBar(
        controller: controller,
        onTap: onTap,
        tabs: tabs,
        isScrollable: false,
        tabAlignment: TabAlignment.fill,
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        indicator: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _ChronologyGoalsList extends StatelessWidget {
  const _ChronologyGoalsList({
    required this.goals,
    required this.locale,
    required this.unknownScorer,
  });

  final List<TeamStatsGoalDetail> goals;
  final String locale;
  final String unknownScorer;

  @override
  Widget build(BuildContext context) {
    final listEntries = _buildListEntries(goals);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: listEntries.length,
      separatorBuilder: (context, index) {
        final next = listEntries[index + 1];
        if (listEntries[index] is _GoalsDayHeaderEntry) {
          return const SizedBox(height: 8);
        }
        if (next is _GoalsDayHeaderEntry) {
          return const SizedBox(height: 14);
        }
        return const SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        final entry = listEntries[index];
        return switch (entry) {
          _GoalsDayHeaderEntry(:final date) =>
            _MatchDayHeader(date: date, locale: locale),
          _GoalsCardEntry(:final goal) => _GoalDetailCard(
              goal: goal,
              unknownScorer: unknownScorer,
            ),
        };
      },
    );
  }

  static List<_GoalsListEntry> _buildListEntries(
    List<TeamStatsGoalDetail> goals,
  ) {
    final entries = <_GoalsListEntry>[];
    DateTime? lastDay;

    for (final goal in goals) {
      final date = matchDateForTeamStats(goal.match);
      if (date != null) {
        final day = DateUtils.dateOnly(date);
        if (lastDay == null || day != lastDay) {
          entries.add(_GoalsDayHeaderEntry(day));
          lastDay = day;
        }
      }
      entries.add(_GoalsCardEntry(goal));
    }

    return entries;
  }
}

class _ScorersRankingList extends StatelessWidget {
  const _ScorersRankingList({
    required this.ranks,
    required this.goalCountLabel,
  });

  final List<TeamStatsGoalScorerRank> ranks;
  final String Function(int count) goalCountLabel;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: ranks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final rank = ranks[index];
        return _ScorerRankCard(
          rank: rank,
          goalCountLabel: goalCountLabel(rank.goalCount),
        );
      },
    );
  }
}

sealed class _GoalsListEntry {
  const _GoalsListEntry();
}

final class _GoalsDayHeaderEntry extends _GoalsListEntry {
  const _GoalsDayHeaderEntry(this.date);

  final DateTime date;
}

final class _GoalsCardEntry extends _GoalsListEntry {
  const _GoalsCardEntry(this.goal);

  final TeamStatsGoalDetail goal;
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

class _GoalDetailCard extends StatelessWidget {
  const _GoalDetailCard({
    required this.goal,
    required this.unknownScorer,
  });

  final TeamStatsGoalDetail goal;
  final String unknownScorer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final scorer = goal.scorerLabel(unknownLabel: unknownScorer);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              goal.minuteLabel,
              style: textTheme.titleSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scorer,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  goal.matchLabel(),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorerRankCard extends StatelessWidget {
  const _ScorerRankCard({
    required this.rank,
    required this.goalCountLabel,
  });

  final TeamStatsGoalScorerRank rank;
  final String goalCountLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rank.displayName,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            goalCountLabel,
            style: textTheme.titleSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
