import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/chat/chat_bot_sheet.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/widget/subscription_paywall.dart';
import 'package:provider/provider.dart';

/// Opens Ask Diego for subscribers, or the subscription paywall otherwise.
Future<void> openAskDiego(BuildContext context) async {
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
  await showAskDiegoSheet(context);
}

void openAskDiegoFromTap(BuildContext context) {
  unawaited(openAskDiego(context));
}
