import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/coach_workload_analysis_access.dart';
import 'package:grinta/widget/account_create_profile_entry.dart';

/// Always-visible coach entry to open workload analysis (with Premium badge).
class CoachWorkloadAnalysisEntryButton extends StatelessWidget {
  const CoachWorkloadAnalysisEntryButton({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    final icon = SubscriptionPremiumBadge.withIconOverlay(
      context: context,
      colors: colors,
      showPremium: true,
      icon: Icon(Icons.insights_rounded, color: colors.primary),
    );

    if (compact) {
      return IconButton(
        tooltip: l10n.coachWorkloadAnalysisFabTooltip,
        onPressed: () => unawaited(openCoachWorkloadAnalysis(context)),
        icon: icon,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => unawaited(openCoachWorkloadAnalysis(context)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.coachWorkloadAnalysisTitle,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
