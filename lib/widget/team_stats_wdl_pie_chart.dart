import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_outcome_helper.dart';

/// Pie chart for win / draw / loss with a shared legend layout.
class TeamStatsWdlPieChart extends StatelessWidget {
  const TeamStatsWdlPieChart({
    super.key,
    required this.title,
    required this.counts,
    this.onSegmentTap,
  });

  final String title;
  final TeamWdlCounts counts;
  final ValueChanged<MatchOutcome>? onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final wdlColors = _wdlColors(colors);
    final textTheme = Theme.of(context).textTheme;
    final sectionOutcomes = <MatchOutcome>[];
    final sections = _buildSections(
      context: context,
      counts: counts,
      sectionOutcomes: sectionOutcomes,
    );

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
          _ChartTitleRow(
            periodTitle: title,
            counts: counts,
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
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 28,
                      startDegreeOffset: -90,
                      sections: sections,
                      pieTouchData: PieTouchData(
                        enabled: onSegmentTap != null,
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (onSegmentTap == null ||
                              !event.isInterestedForInteractions ||
                              !_isPieChartSegmentTapCommitEvent(event)) {
                            return;
                          }
                          final touchedSection =
                              pieTouchResponse?.touchedSection;
                          if (touchedSection == null) {
                            return;
                          }
                          final index = touchedSection.touchedSectionIndex;
                          if (index < 0 || index >= sectionOutcomes.length) {
                            return;
                          }
                          onSegmentTap!(sectionOutcomes[index]);
                        },
                      ),
                    ),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _LegendRow(
                        label: l10n.statsWins,
                        value: counts.wins,
                        total: counts.total,
                        color: wdlColors.wins,
                        onTap: counts.wins > 0 && onSegmentTap != null
                            ? () => onSegmentTap!(MatchOutcome.win)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _LegendRow(
                        label: l10n.statsDraws,
                        value: counts.draws,
                        total: counts.total,
                        color: wdlColors.draws,
                        onTap: counts.draws > 0 && onSegmentTap != null
                            ? () => onSegmentTap!(MatchOutcome.draw)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _LegendRow(
                        label: l10n.statsLosses,
                        value: counts.losses,
                        total: counts.total,
                        color: wdlColors.losses,
                        onTap: counts.losses > 0 && onSegmentTap != null
                            ? () => onSegmentTap!(MatchOutcome.loss)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections({
    required BuildContext context,
    required TeamWdlCounts counts,
    required List<MatchOutcome> sectionOutcomes,
  }) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final wdlColors = _wdlColors(colors);

    final sections = <PieChartSectionData>[];

    void addSection({
      required MatchOutcome outcome,
      required double value,
      required Color color,
    }) {
      if (value <= 0) return;
      sectionOutcomes.add(outcome);
      sections.add(
        PieChartSectionData(
          value: value,
          color: color,
          radius: 46,
          title: value >= 1 ? value.toStringAsFixed(0) : '',
          titleStyle: textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    addSection(
      outcome: MatchOutcome.win,
      value: counts.wins.toDouble(),
      color: wdlColors.wins,
    );
    addSection(
      outcome: MatchOutcome.draw,
      value: counts.draws.toDouble(),
      color: wdlColors.draws,
    );
    addSection(
      outcome: MatchOutcome.loss,
      value: counts.losses.toDouble(),
      color: wdlColors.losses,
    );

    return sections;
  }
}

/// Desktop/web fire both tap-down and tap-up; mobile only tap-down is interactive.
bool _isPieChartSegmentTapCommitEvent(FlTouchEvent event) {
  final isDesktopOrWeb = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  if (isDesktopOrWeb) {
    return event is FlTapUpEvent;
  }

  return event is FlTapDownEvent;
}

class _ChartTitleRow extends StatelessWidget {
  const _ChartTitleRow({
    required this.periodTitle,
    required this.counts,
  });

  final String periodTitle;
  final TeamWdlCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(
      color: colors.textPrimary,
      fontWeight: FontWeight.w800,
    );
    final avgPoints = counts.avgPointsPerMatch;

    return RichText(
      text: TextSpan(
        style: titleStyle,
        children: [
          TextSpan(
            text: '$periodTitle - ${l10n.teamStatsGoalsMatchCount(counts.total)}',
          ),
          if (avgPoints != null) ...[
            const TextSpan(text: ' - '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  Icons.functions_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
            TextSpan(text: l10n.teamStatsAvgPointsPerMatch(avgPoints)),
          ],
        ],
      ),
    );
  }
}

/// W/D/L palette aligned with [TrainingMetricLineChart] in metrics_panel.dart.
({Color wins, Color draws, Color losses}) _wdlColors(AppColors colors) {
  return (
    wins: colors.success,
    draws: colors.warning,
    losses: colors.primary,
  );
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    this.onTap,
  });

  final String label;
  final int value;
  final int total;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final double ratio = total <= 0 ? 0 : value / total;

    final row = Row(
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
          '$value (${(ratio * 100).round()}%)',
          style: textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return row;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }
}
