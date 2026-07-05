import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_outcome_helper.dart';

/// Row showing season-half trends for goals scored and conceded.
class TeamStatsGoalsTrendIndicator extends StatelessWidget {
  const TeamStatsGoalsTrendIndicator({
    super.key,
    required this.trends,
  });

  final TeamGoalsHalfTrends trends;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.teamStatsTrendLabel,
            style: textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _TrendRow(
            label: l10n.teamStatsGoalsTrendScored,
            trend: trends.scored,
          ),
          const SizedBox(height: 10),
          _TrendRow(
            label: l10n.teamStatsGoalsTrendConceded,
            trend: trends.conceded,
          ),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.label,
    required this.trend,
  });

  final String label;
  final TeamGoalsMetricHalfTrend trend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final (IconData icon, String statusLabel, Color color) =
        switch (trend.direction) {
      TeamWdlTrendDirection.up => (
          Icons.trending_up,
          l10n.teamStatsTrendUp,
          colors.success,
        ),
      TeamWdlTrendDirection.down => (
          Icons.trending_down,
          l10n.teamStatsTrendDown,
          colors.danger,
        ),
      TeamWdlTrendDirection.flat => (
          Icons.trending_flat,
          l10n.teamStatsTrendFlat,
          colors.textSecondary,
        ),
      TeamWdlTrendDirection.insufficientData => (
          Icons.trending_flat,
          l10n.teamStatsTrendInsufficientData,
          colors.textSecondary,
        ),
    };

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                statusLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
