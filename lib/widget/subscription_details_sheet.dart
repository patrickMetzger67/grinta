import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/subscription_paywall.dart';
import 'package:intl/intl.dart';

Future<void> showSubscriptionDetails(BuildContext context) async {
  if (kIsWeb) {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => const _SubscriptionDetailsDialog(),
    );
    return;
  }

  final colors = context.appColors;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => const _SubscriptionDetailsSheet(),
  );
}

class _SubscriptionDetailsDialog extends StatelessWidget {
  const _SubscriptionDetailsDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _SubscriptionDetailsBody(
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _SubscriptionDetailsSheet extends StatelessWidget {
  const _SubscriptionDetailsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _SubscriptionDetailsBody(
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _SubscriptionDetailsBody extends StatefulWidget {
  const _SubscriptionDetailsBody({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_SubscriptionDetailsBody> createState() =>
      _SubscriptionDetailsBodyState();
}

class _SubscriptionDetailsBodyState extends State<_SubscriptionDetailsBody> {
  late final Listenable _services = Listenable.merge([
    SubscriptionService.instance,
    UserTrialService.instance,
  ]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserTrialService.instance.ensureInitialized();
      SubscriptionService.instance.refreshForActiveSession();
    });
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date.toLocal());
  }

  String? _tierName(AppLocalizations l10n, SubscriptionService service) {
    final coachTier = service.coachTier;
    if (coachTier != null) {
      return switch (coachTier) {
        CoachTier.basic => l10n.subscriptionTierCoachBasic,
        CoachTier.elite => l10n.subscriptionTierCoachElite,
        CoachTier.pro => l10n.subscriptionTierCoachPro,
      };
    }
    if (service.hasPlayerSubscription) {
      return l10n.subscriptionTierPlayer;
    }
    return null;
  }

  String? _billingPeriodLabel(
    AppLocalizations l10n,
    SubscriptionBillingPeriod? period,
  ) {
    return switch (period) {
      SubscriptionBillingPeriod.monthly => l10n.subscriptionBillingPeriodMonthly,
      SubscriptionBillingPeriod.yearly => l10n.subscriptionBillingPeriodYearly,
      null => null,
    };
  }

  Future<void> _openChangePlan(BuildContext context) async {
    final subscription = SubscriptionService.instance;
    final initialKind = subscription.hasPlayerSubscription
        ? SubscriptionOfferingKind.player
        : SubscriptionOfferingKind.coach;

    final changed = await SubscriptionPaywall.show(
      context,
      changePlanMode: true,
      initialKind: initialKind,
    );

    if (!context.mounted) return;
    if (changed == true) {
      await subscription.refreshForActiveSession();
      if (!context.mounted) return;
      AppSnackbar.show(context, context.l10n.subscriptionPlanChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _services,
      builder: (context, _) {
        final subscription = SubscriptionService.instance;
        final trial = UserTrialService.instance;
        final tierName = _tierName(l10n, subscription);
        final isSubscribed = subscription.hasActivePaidSubscription;
        final activeTierName = tierName ?? l10n.subscriptionTierActive;
        final renewalDate = subscription.renewalDate;
        final billingPeriodLabel =
            _billingPeriodLabel(l10n, subscription.billingPeriod);
        final trialEndsAt = trial.trialEndsAt;
        final isOnTrial = !isSubscribed && trial.shouldShowTrial;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!kIsWeb) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(20, kIsWeb ? 20 : 0, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.subscriptionDetailsTitle,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: subscription.state.isLoading &&
                      !subscription.state.isInitialized
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : isSubscribed
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ActiveSubscriptionCard(
                              tierName: activeTierName,
                              billingPeriodLabel: billingPeriodLabel,
                              renewalDateLabel: renewalDate != null
                                  ? _formatDate(context, renewalDate)
                                  : null,
                              statusLabel: l10n.subscriptionStatusActive,
                              periodLabel: l10n.subscriptionPeriodLabel,
                              renewalLabel: l10n.subscriptionRenewalLabel,
                            ),
                            if (subscription.isPurchaseAvailable) ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => _openChangePlan(context),
                                icon: const Icon(Icons.swap_horiz_rounded),
                                label: Text(l10n.subscriptionChangePlan),
                              ),
                            ],
                          ],
                        )
                      : isOnTrial && trialEndsAt != null
                          ? _EmptyStateCard(
                              icon: Icons.timer_outlined,
                              message: l10n.subscriptionTrialEnds(
                                _formatDate(context, trialEndsAt),
                              ),
                            )
                          : _EmptyStateCard(
                              icon: Icons.workspace_premium_outlined,
                              message: l10n.subscriptionNone,
                            ),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveSubscriptionCard extends StatelessWidget {
  const _ActiveSubscriptionCard({
    required this.tierName,
    required this.billingPeriodLabel,
    required this.renewalDateLabel,
    required this.statusLabel,
    required this.periodLabel,
    required this.renewalLabel,
  });

  final String tierName;
  final String? billingPeriodLabel;
  final String? renewalDateLabel;
  final String statusLabel;
  final String periodLabel;
  final String renewalLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierName,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusBadge(label: statusLabel),
                  ],
                ),
              ),
            ],
          ),
          if (billingPeriodLabel != null || renewalDateLabel != null) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.border),
            const SizedBox(height: 12),
            if (billingPeriodLabel != null)
              _SubscriptionInfoRow(
                icon: Icons.calendar_month_outlined,
                label: periodLabel,
                value: billingPeriodLabel!,
              ),
            if (billingPeriodLabel != null && renewalDateLabel != null)
              const SizedBox(height: 12),
            if (renewalDateLabel != null)
              _SubscriptionInfoRow(
                icon: Icons.autorenew_rounded,
                label: renewalLabel,
                value: renewalDateLabel!,
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: textTheme.labelMedium?.copyWith(
          color: colors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SubscriptionInfoRow extends StatelessWidget {
  const _SubscriptionInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
