import 'package:flutter/material.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_root_service.dart';
import 'package:grinta/widget/subscription_paywall.dart';

/// Whether the signed-in user may **use** their own Insiders Intense GPS
/// (sync to a match / training / personal activity).
///
/// Sensor **setup** (serial claim in Réglages) stays free. Coach-initiated
/// flows stay available. Players need `player_gps` (or root) only when syncing.
bool canUseOwnIntenseGps({
  String initiatedBy = 'player',
  SubscriptionService? subscription,
  bool? isRoot,
}) {
  return SubscriptionEntitlementIds.grantsOwnIntenseGpsAccess(
    entitlements: (subscription ?? SubscriptionService.instance)
        .activeEntitlements,
    isRoot: isRoot ?? UserRootService.instance.isRoot,
    initiatedBy: initiatedBy,
  );
}

/// @Deprecated Prefer [canUseOwnIntenseGps]. Kept for call-site compatibility.
bool canConnectOwnIntenseGps({
  String initiatedBy = 'player',
  SubscriptionService? subscription,
  bool? isRoot,
}) {
  return canUseOwnIntenseGps(
    initiatedBy: initiatedBy,
    subscription: subscription,
    isRoot: isRoot,
  );
}

/// Opens the paywall on the Joueur GPS plan.
///
/// Returns `true` when the user may use Intense GPS after the sheet closes
/// (subscribed, already entitled, or root).
Future<bool> ensurePlayerGpsForIntenseUse(BuildContext context) async {
  if (canUseOwnIntenseGps()) return true;
  await showPlayerGpsPaywall(context);
  return canUseOwnIntenseGps();
}

/// Opens the paywall on the Joueur GPS plan.
Future<bool?> showPlayerGpsPaywall(BuildContext context) {
  return SubscriptionPaywall.show(
    context,
    allowSkip: true,
    initialKind: SubscriptionOfferingKind.player,
    initialPlayerTier: PlayerSubscriptionTier.gps,
  );
}
