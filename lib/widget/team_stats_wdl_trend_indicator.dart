import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_outcome_helper.dart';

/// Row showing season-half trend (1ère vs 2ème partie) before W/D/L charts.
class TeamStatsWdlTrendIndicator extends StatelessWidget {
  const TeamStatsWdlTrendIndicator({
    super.key,
    required this.trend,
  });

  final TeamWdlHalfTrend trend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final (IconData icon, String label, Color color) = switch (trend.direction) {
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
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
