import 'package:flutter/material.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_root_service.dart';
import 'package:grinta/widget/subscription_paywall.dart';

/// Whether the signed-in user can claim their own Insiders Intense GPS.
///
/// Coach-initiated claims stay available (team/player management). Players
/// need the `player_gps` entitlement (or root).
bool canConnectOwnIntenseGps({
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

/// Opens the paywall on the Joueur GPS plan.
Future<bool?> showPlayerGpsPaywall(BuildContext context) {
  return SubscriptionPaywall.show(
    context,
    allowSkip: true,
    initialKind: SubscriptionOfferingKind.player,
    initialPlayerTier: PlayerSubscriptionTier.gps,
  );
}
