import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:grinta/model/subscription_tier_limits.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/subscription_limits_service.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/create_member_sheet.dart';
import 'package:grinta/widget/subscription_paywall.dart';
import 'package:provider/provider.dart';

/// UI helpers for subscription tier caps (teams + roster).
class SubscriptionLimitsAccess {
  SubscriptionLimitsAccess._();

  static Future<bool> ensureCanCreateTeam(
    BuildContext context, {
    required String userId,
    required String seasonId,
  }) async {
    final appSession = context.read<AppSession>();
    final player = appSession.selectedPlayer;
    final playerId = player?.keyMember ?? appSession.selectedPlayerId;

    try {
      await SubscriptionLimitsService.instance.assertCanCreateTeam(
        userId: userId,
        seasonId: seasonId,
        playerId: playerId,
        player: player,
      );
      return true;
    } on SubscriptionLimitExceeded catch (e) {
      if (!context.mounted) return false;
      if (e.requiresUpgrade) {
        await _showTeamUpgradeDialog(context, e);
      } else {
        _showViolation(context, e);
      }
      return false;
    }
  }

  static Future<bool> ensureCanAddPlayer(
    BuildContext context, {
    required String teamId,
    required String memberId,
    String? firebaseUserId,
  }) async {
    try {
      await SubscriptionLimitsService.instance.assertCanAddPlayer(
        teamId: teamId,
        memberId: memberId,
        firebaseUserId: firebaseUserId,
      );
      return true;
    } on SubscriptionLimitExceeded catch (e) {
      if (!context.mounted) return false;
      _showViolation(context, e);
      return false;
    }
  }

  static Future<void> showTeamLimitExceeded(
    BuildContext context,
    SubscriptionLimitExceeded e,
  ) async {
    if (e.violation == SubscriptionLimitViolation.maxTeams && e.requiresUpgrade) {
      await _showTeamUpgradeDialog(context, e);
      return;
    }
    _showViolation(context, e);
  }

  static void showLimitExceeded(
    BuildContext context,
    SubscriptionLimitExceeded e,
  ) {
    _showViolation(context, e);
  }

  static Future<bool> ensureCanCreateProfile(
    BuildContext context, {
    required int currentProfileCount,
  }) async {
    try {
      await SubscriptionLimitsService.instance.assertCanCreateProfile(
        currentProfileCount: currentProfileCount,
      );
      return true;
    } on SubscriptionLimitExceeded catch (e) {
      if (!context.mounted) return false;
      if (e.requiresUpgrade) {
        await _showProfileUpgradeDialog(context, e);
      } else {
        _showViolation(context, e);
      }
      return false;
    }
  }

  static Future<void> openCreateProfileFlow(BuildContext context) async {
    final appSession = context.read<AppSession>();
    final profileCount = appSession.currentUserPlayers.length;

    await SubscriptionLimitsService.instance.ensureInitialized();
    await SubscriptionService.instance.refreshForActiveSession();

    final gate = SubscriptionLimitsService.instance.resolveProfileCreationGate(
      profileCount,
    );

    switch (gate) {
      case ProfileCreationGate.allowed:
        if (!context.mounted) return;
        await showCreateMemberSheet(context);
        return;
      case ProfileCreationGate.needsUpgrade:
        final maxProfiles =
            await SubscriptionLimitsService.instance.maxProfilesForUser();
        if (!context.mounted) return;
        await _showProfileUpgradeDialog(
          context,
          SubscriptionLimitExceeded(
            violation: SubscriptionLimitViolation.maxProfiles,
            tier: SubscriptionLimitsService.instance.resolveEffectiveTier(),
            limit: maxProfiles,
            requiresUpgrade: true,
          ),
        );
        return;
      case ProfileCreationGate.atMaxLimit:
        if (!context.mounted) return;
        final max =
            await SubscriptionLimitsService.instance.maxProfilesForUser();
        if (!context.mounted) return;
        AppSnackbar.show(
          context,
          context.l10n.subscriptionLimitMaxProfilesReached(max),
          isError: true,
        );
        return;
    }
  }

  static Future<void> _showProfileUpgradeDialog(
    BuildContext context,
    SubscriptionLimitExceeded e,
  ) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final subscription = SubscriptionService.instance;
    final hasPaidSubscription = subscription.hasActivePaidSubscription;
    final isCoachBasicUpgrade =
        hasPaidSubscription && subscription.coachTier == CoachTier.basic;

    final title = isCoachBasicUpgrade
        ? l10n.subscriptionLimitProfileCoachBasicTitle
        : l10n.subscriptionLimitProfileUpgradeTitle;
    final message = isCoachBasicUpgrade
        ? l10n.subscriptionLimitProfileCoachBasicMessage
        : hasPaidSubscription
            ? l10n.subscriptionChangePlanSubtitle
            : l10n.subscriptionLimitProfileUpgradeMessage;
    final upgradeLabel = hasPaidSubscription
        ? l10n.subscriptionChangePlan
        : l10n.subscriptionSubscribe;

    final upgrade = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
              child: Text(upgradeLabel),
            ),
          ],
        );
      },
    );

    if (upgrade != true || !context.mounted) return;

    await subscription.refreshForActiveSession();
    if (!context.mounted) return;

    if (subscription.hasActivePaidSubscription) {
      final initialKind = subscription.hasPlayerSubscription
          ? SubscriptionOfferingKind.player
          : SubscriptionOfferingKind.coach;
      await SubscriptionPaywall.show(
        context,
        changePlanMode: isCoachBasicUpgrade,
        initialKind: initialKind,
      );
      return;
    }

    await SubscriptionPaywall.show(
      context,
      allowSkip: true,
      initialKind: SubscriptionOfferingKind.player,
    );
  }

  static void _showViolation(BuildContext context, SubscriptionLimitExceeded e) {
    final l10n = context.l10n;

    if (e.violation == SubscriptionLimitViolation.maxTeams) {
      if (e.requiresUpgrade) {
        unawaited(_showTeamUpgradeDialog(context, e));
      } else {
        AppSnackbar.show(
          context,
          l10n.subscriptionLimitMaxTeamsReached(e.limit ?? 0),
          isError: true,
        );
      }
      return;
    }

    if (e.violation == SubscriptionLimitViolation.maxProfiles &&
        e.requiresUpgrade) {
      unawaited(_showProfileUpgradeDialog(context, e));
      return;
    }

    final message = switch (e.violation) {
      SubscriptionLimitViolation.maxPlayersPerTeam =>
        l10n.subscriptionLimitMaxPlayersReached(e.limit ?? 0),
      SubscriptionLimitViolation.maxProfiles =>
        l10n.subscriptionLimitMaxProfilesReached(e.limit ?? 0),
      SubscriptionLimitViolation.playerTierOnlySelf =>
        l10n.subscriptionLimitPlayerTierOnlySelf,
      SubscriptionLimitViolation.maxTeams => '',
    };
    AppSnackbar.show(context, message, isError: true);
  }

  static Future<void> _showTeamUpgradeDialog(
    BuildContext context,
    SubscriptionLimitExceeded e,
  ) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final subscription = SubscriptionService.instance;
    final hasPaidSubscription = subscription.hasActivePaidSubscription;
    final isCoachBasicUpgrade =
        hasPaidSubscription && subscription.coachTier == CoachTier.basic;

    final title = isCoachBasicUpgrade
        ? l10n.subscriptionLimitTeamCoachBasicTitle
        : l10n.subscriptionLimitTeamUpgradeTitle;
    final message = isCoachBasicUpgrade
        ? l10n.subscriptionLimitTeamCoachBasicMessage
        : hasPaidSubscription
            ? l10n.subscriptionChangePlanSubtitle
            : l10n.subscriptionLimitTeamUpgradeMessage;
    final upgradeLabel = hasPaidSubscription
        ? l10n.subscriptionChangePlan
        : l10n.subscriptionSubscribe;

    final upgrade = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
              child: Text(upgradeLabel),
            ),
          ],
        );
      },
    );

    if (upgrade != true || !context.mounted) return;

    await subscription.refreshForActiveSession();
    if (!context.mounted) return;

    if (subscription.hasActivePaidSubscription) {
      final initialKind = subscription.hasPlayerSubscription
          ? SubscriptionOfferingKind.player
          : SubscriptionOfferingKind.coach;
      await SubscriptionPaywall.show(
        context,
        changePlanMode: isCoachBasicUpgrade,
        initialKind: initialKind,
      );
      return;
    }

    await SubscriptionPaywall.show(
      context,
      allowSkip: true,
      initialKind: SubscriptionOfferingKind.player,
    );
  }
}
