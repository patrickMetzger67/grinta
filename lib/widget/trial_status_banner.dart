import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/subscription_paywall.dart';
import 'package:provider/provider.dart';

/// Informational banner showing remaining free trial days with a paywall CTA.
class TrialStatusBanner extends StatelessWidget {
  const TrialStatusBanner({super.key});

  Future<void> _openPaywall(BuildContext context) async {
    await SubscriptionService.instance.refreshForActiveSession();
    if (!context.mounted) return;

    final appSession = context.read<AppSession>();
    final isCoach = appSession.managedTeamsIdsForSelectedSeason.isNotEmpty ||
        appSession.hasManagedTeamsInSelectedSeason;

    await SubscriptionPaywall.show(
      context,
      initialKind: isCoach
          ? SubscriptionOfferingKind.coach
          : SubscriptionOfferingKind.player,
      allowSkip: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        UserTrialService.instance,
        SubscriptionService.instance,
      ]),
      builder: (context, _) {
        final trial = UserTrialService.instance;
        if (!trial.shouldShowTrial) {
          return const SizedBox.shrink();
        }
        return _buildBanner(context, trial);
      },
    );
  }

  Widget _buildBanner(BuildContext context, UserTrialService trial) {

    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final days = trial.remainingTrialDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.timer_outlined,
                color: colors.primary,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.trialStatusTitle,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.trialDaysRemaining(days),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => _openPaywall(context),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(context.l10n.subscriptionPromptAction),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
