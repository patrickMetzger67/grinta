import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/rankingPerDay.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_stats_ranking_helper.dart';

class TeamStatsRankingEvolutionSeries {
  const TeamStatsRankingEvolutionSeries({
    required this.affiliateKey,
    required this.label,
    required this.color,
    required this.entries,
    required this.isOwnTeam,
  });

  final String affiliateKey;
  final String label;
  final Color color;
  final List<RankingPerDay> entries;
  final bool isOwnTeam;
}

class TeamStatsRankingEvolutionChart extends StatelessWidget {
  const TeamStatsRankingEvolutionChart({
    super.key,
    required this.series,
    required this.matchdays,
    required this.teamCount,
  });

  final List<TeamStatsRankingEvolutionSeries> series;
  final List<int> matchdays;
  final int teamCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    if (series.isEmpty || matchdays.isEmpty) {
      return _emptyCard(
        context,
        message: l10n.teamStatsRankingNoData,
      );
    }

    final maxRank = teamCount > 0 ? teamCount : 1;
    const chartHeight = 280.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: chartHeight,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: matchdays.length <= 1
                    ? 1
                    : (matchdays.length - 1).toDouble(),
                minY: 1,
                maxY: maxRank.toDouble(),
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: _horizontalInterval(maxRank),
                  verticalInterval: math.max(
                    1,
                    (matchdays.length - 1) / 4,
                  ).toDouble(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colors.border.withValues(alpha: 0.55),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: colors.border.withValues(alpha: 0.45),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: _horizontalInterval(maxRank),
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        final rank = maxRank - value.toInt() + 1;
                        if (rank < 1 || rank > maxRank) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          rank.toString(),
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if ((value - index).abs() > 0.001 ||
                            index < 0 ||
                            index >= matchdays.length) {
                          return const SizedBox.shrink();
                        }
                        final labelStep = _bottomLabelStep(matchdays.length);
                        if (index % labelStep != 0 &&
                            index != matchdays.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(
                            matchdays[index].toString(),
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipMargin: 12,
                    tooltipBorderRadius: BorderRadius.circular(12),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    tooltipBorder: BorderSide(color: colors.border),
                    getTooltipColor: (_) =>
                        colors.surface.withValues(alpha: 0.96),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final barIndex = spot.barIndex;
                        if (barIndex < 0 || barIndex >= series.length) {
                          return null;
                        }
                        final currentSeries = series[barIndex];
                        final dayIndex = spot.x.round();
                        if (dayIndex < 0 || dayIndex >= matchdays.length) {
                          return null;
                        }
                        final day = matchdays[dayIndex];
                        final rank = _rankForDay(currentSeries.entries, day);
                        final rankLabel = rank?.toString() ?? '—';

                        return LineTooltipItem(
                          '${currentSeries.label}\n'
                          '${l10n.periodMatchDay(day.toString())}: '
                          '${l10n.teamStatsRankingTooltipRank(rankLabel)}',
                          TextStyle(
                            color: currentSeries.color,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        );
                      }).whereType<LineTooltipItem>().toList();
                    },
                  ),
                ),
                lineBarsData: [
                  for (final currentSeries in series)
                    _buildLineBarData(
                      series: currentSeries,
                      matchdays: matchdays,
                      maxRank: maxRank,
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final currentSeries in series)
                _LegendChip(
                  label: currentSeries.label,
                  color: currentSeries.color,
                  isBold: currentSeries.isOwnTeam,
                ),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineBarData({
    required TeamStatsRankingEvolutionSeries series,
    required List<int> matchdays,
    required int maxRank,
  }) {
    final spots = <FlSpot>[];

    for (var index = 0; index < matchdays.length; index++) {
      final day = matchdays[index];
      final rank = _rankForDay(series.entries, day);
      if (rank == null) {
        continue;
      }
      spots.add(
        FlSpot(
          index.toDouble(),
          _chartYForRank(rank, maxRank),
        ),
      );
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      preventCurveOverShooting: true,
      barWidth: 4,
      isStrokeCapRound: true,
      isStrokeJoinRound: true,
      color: series.color,
      dotData: FlDotData(
        show: spots.length <= 1,
        getDotPainter: (spot, percent, bar, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: series.color,
            strokeWidth: 1.5,
            strokeColor: series.color.withValues(alpha: 0.35),
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  int? _rankForDay(List<RankingPerDay> entries, int day) {
    for (final entry in entries) {
      if (entry.day == day) {
        return entry.rank;
      }
    }
    return null;
  }

  double _chartYForRank(int rank, int maxRank) {
    return (maxRank - rank + 1).toDouble();
  }

  double _horizontalInterval(int maxRank) {
    if (maxRank <= 4) {
      return 1;
    }
    if (maxRank <= 10) {
      return 2;
    }
    return (maxRank / 5).ceilToDouble();
  }

  int _bottomLabelStep(int matchdayCount) {
    if (matchdayCount <= 8) {
      return 1;
    }
    if (matchdayCount <= 16) {
      return 2;
    }
    if (matchdayCount <= 24) {
      return 3;
    }
    return (matchdayCount / 6).ceil();
  }

  Widget _emptyCard(BuildContext context, {required String message}) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

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

List<Color> teamStatsRankingChartColors(AppColors colors) {
  return [
    colors.primary,
    colors.success,
    const Color(0xFF26C6DA),
    colors.warning,
    colors.secondary,
    const Color(0xFFAB47BC),
    colors.danger,
  ];
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
    this.isBold = false,
  });

  final String label;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

Future<Set<String>?> showTeamStatsRankingClubSelector({
  required BuildContext context,
  required List<TeamStatsRankingClubOption> options,
  required Set<String> selectedAffiliates,
  required String ownTeamAffiliate,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return _TeamStatsRankingClubSelectorSheet(
        options: options,
        initialSelection: selectedAffiliates,
        ownTeamAffiliate: ownTeamAffiliate,
      );
    },
  );
}

class _TeamStatsRankingClubSelectorSheet extends StatefulWidget {
  const _TeamStatsRankingClubSelectorSheet({
    required this.options,
    required this.initialSelection,
    required this.ownTeamAffiliate,
  });

  final List<TeamStatsRankingClubOption> options;
  final Set<String> initialSelection;
  final String ownTeamAffiliate;

  @override
  State<_TeamStatsRankingClubSelectorSheet> createState() =>
      _TeamStatsRankingClubSelectorSheetState();
}

class _TeamStatsRankingClubSelectorSheetState
    extends State<_TeamStatsRankingClubSelectorSheet> {
  late Set<String> _selection;

  @override
  void initState() {
    super.initState();
    _selection = Set<String>.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teamStatsRankingSelectClubsTitle,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final option in widget.options)
                    CheckboxListTile(
                      value: _selection.contains(option.affiliateKey) ||
                          option.isOwnTeam,
                      onChanged: option.isOwnTeam
                          ? null
                          : (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selection.add(option.affiliateKey);
                                } else {
                                  _selection.remove(option.affiliateKey);
                                }
                              });
                            },
                      title: Text(
                        option.displayName,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: option.isOwnTeam
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      subtitle: option.isOwnTeam
                          ? Text(
                              l10n.teamStatsRankingOwnTeamLabel,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            )
                          : null,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: colors.primary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(_selection);
              },
              child: Text(l10n.actionValidate),
            ),
          ],
        ),
      ),
    );
  }
}
