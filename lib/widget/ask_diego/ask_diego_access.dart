import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/chat/chat_bot_sheet.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/widget/subscription_paywall.dart';
import 'package:provider/provider.dart';

/// Returns true when the signed-in user can use Ask Gio.
///
/// Otherwise shows the subscription paywall and returns false.
Future<bool> ensureAskGioAccess(BuildContext context) async {
  await UserTrialService.instance.ensureInitialized();
  await SubscriptionService.instance.refreshForActiveSession();
  if (!context.mounted) return false;
  if (UserTrialService.instance.hasPremiumAccess) return true;

  final appSession = context.read<AppSession>();
  await SubscriptionPaywall.show(
    context,
    allowSkip: true,
    initialKind: prefersCoachSubscriptionOffering(appSession)
        ? SubscriptionOfferingKind.coach
        : SubscriptionOfferingKind.player,
  );
  return false;
}

/// Opens Ask Diego for subscribers, or the subscription paywall otherwise.
Future<void> openAskDiego(BuildContext context) async {
  if (!await ensureAskGioAccess(context)) return;
  if (!context.mounted) return;
  await showAskDiegoSheet(context);
}

void openAskDiegoFromTap(BuildContext context) {
  unawaited(openAskDiego(context));
}
