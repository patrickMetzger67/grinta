import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/subscription_paywall.dart';

/// Coach Pro subscription checks for linking GPS tracker kits to a team.
class TeamTrackerAccess {
  TeamTrackerAccess._();

  /// Whether the signed-in user has an active Coach Pro (or higher) entitlement.
  static bool hasCoachProTrackerAccess() {
    final CoachTier? tier = SubscriptionService.instance.coachTier;
    return tier?.satisfies(CoachTier.pro) ?? false;
  }

  /// Refreshes subscription state and prompts upgrade when Coach Pro is required.
  ///
  /// Returns `true` when the user may assign or edit team tracker kits.
  static Future<bool> ensureCoachProForTeamTrackers(BuildContext context) async {
    await SubscriptionService.instance.refreshForActiveSession();
    if (hasCoachProTrackerAccess()) {
      return true;
    }
    if (!context.mounted) {
      return false;
    }
    return _promptCoachProUpgrade(context);
  }

  static Future<bool> _promptCoachProUpgrade(BuildContext context) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final subscription = SubscriptionService.instance;
    final hasPaidCoachSubscription =
        subscription.hasActivePaidSubscription && subscription.coachTier != null;

    final upgrade = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.teamDetailTrackerCoachProRequiredTitle),
          content: Text(
            hasPaidCoachSubscription
                ? l10n.subscriptionTierCoachProDesc
                : l10n.teamDetailTrackerCoachProRequiredMessage,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                hasPaidCoachSubscription
                    ? l10n.subscriptionChangePlan
                    : l10n.subscriptionSubscribe,
              ),
            ),
          ],
        );
      },
    );

    if (upgrade != true || !context.mounted) {
      return false;
    }

    await subscription.refreshForActiveSession();
    if (!context.mounted) {
      return false;
    }
    if (hasCoachProTrackerAccess()) {
      return true;
    }

    await SubscriptionPaywall.show(
      context,
      changePlanMode: hasPaidCoachSubscription,
      initialKind: SubscriptionOfferingKind.coach,
    );

    await subscription.refreshForActiveSession();
    return hasCoachProTrackerAccess();
  }
}
