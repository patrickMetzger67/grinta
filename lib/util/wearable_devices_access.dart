import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/widget/subscription_paywall.dart';
import 'package:grinta/widget/wearable_devices_dialog.dart';
import 'package:provider/provider.dart';

/// Opens wearable devices for premium users, or the subscription paywall.
Future<void> openWearableDevices(
  BuildContext context, {
  required String playerId,
  required String initiatedBy,
  String? playerName,
  bool showCoachVisibility = false,
}) async {
  await UserTrialService.instance.ensureInitialized();
  await SubscriptionService.instance.refreshForActiveSession();
  if (!UserTrialService.instance.hasPremiumAccess) {
    if (!context.mounted) return;
    final appSession = context.read<AppSession>();
    await SubscriptionPaywall.show(
      context,
      allowSkip: true,
      initialKind: prefersCoachSubscriptionOffering(appSession)
          ? SubscriptionOfferingKind.coach
          : SubscriptionOfferingKind.player,
    );
    return;
  }

  if (!context.mounted) return;
  await showWearableDevicesDialog(
    context,
    playerId: playerId,
    initiatedBy: initiatedBy,
    playerName: playerName,
    showCoachVisibility: showCoachVisibility,
  );
}

void openWearableDevicesFromTap(
  BuildContext context, {
  required String playerId,
  required String initiatedBy,
  String? playerName,
  bool showCoachVisibility = false,
}) {
  unawaited(
    openWearableDevices(
      context,
      playerId: playerId,
      initiatedBy: initiatedBy,
      playerName: playerName,
      showCoachVisibility: showCoachVisibility,
    ),
  );
}
