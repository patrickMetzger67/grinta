import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_outcome_helper.dart';

/// Grouped bar chart for goals scored vs conceded in a period.
class TeamStatsGoalsBarChart extends StatelessWidget {
  const TeamStatsGoalsBarChart({
    super.key,
    required this.title,
    required this.counts,
  });

  final String title;
  final TeamGoalsCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final goalColors = _goalColors(colors);

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
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (counts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.teamStatsNoPlayedMatches,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: _maxY(counts),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.border.withValues(alpha: 0.6),
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
                        interval: _yInterval(counts),
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final label = switch (value.toInt()) {
                            0 => l10n.teamStatsGoalsScored,
                            1 => l10n.teamStatsGoalsConceded,
                            _ => '',
                          };
                          if (label.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: counts.scored.toDouble(),
                          color: goalColors.scored,
                          width: 36,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: counts.conceded.toDouble(),
                          color: goalColors.conceded,
                          width: 36,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                  barTouchData: const BarTouchData(
                    enabled: false,
                  ),
                ),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
              ),
            ),
            const SizedBox(height: 16),
            _LegendRow(
              label: l10n.teamStatsGoalsScored,
              value: counts.scored,
              avgPerMatch: counts.avgScoredPerMatch,
              color: goalColors.scored,
            ),
            const SizedBox(height: 10),
            _LegendRow(
              label: l10n.teamStatsGoalsConceded,
              value: counts.conceded,
              avgPerMatch: counts.avgConcededPerMatch,
              color: goalColors.conceded,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.teamStatsGoalsMatchCount(counts.matchCount),
              style: textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _maxY(TeamGoalsCounts counts) {
    final maxValue = counts.scored > counts.conceded
        ? counts.scored
        : counts.conceded;
    if (maxValue <= 0) return 1;
    return (maxValue + 1).toDouble();
  }

  double _yInterval(TeamGoalsCounts counts) {
    final maxY = _maxY(counts);
    if (maxY <= 5) return 1;
    if (maxY <= 12) return 2;
    return (maxY / 5).ceilToDouble();
  }
}

({Color scored, Color conceded}) _goalColors(AppColors colors) {
  return (
    scored: colors.success,
    conceded: colors.primary,
  );
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.value,
    required this.avgPerMatch,
    required this.color,
  });

  final String label;
  final int value;
  final double? avgPerMatch;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final avgLabel = avgPerMatch == null
        ? '—'
        : l10n.teamStatsGoalsAvgPerMatch(avgPerMatch!);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value · $avgLabel',
          style: textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
