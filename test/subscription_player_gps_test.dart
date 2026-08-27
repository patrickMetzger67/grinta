import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/config/subscription_config.dart';

void main() {
  group('SubscriptionProductLookup player GPS', () {
    test('does not collapse playerGPS products onto the standard player tier', () {
      expect(
        SubscriptionProductLookup.semanticKey(
          SubscriptionProductIds.playerGpsMonthly,
        ),
        'player_gps_monthly',
      );
      expect(
        SubscriptionProductLookup.semanticKey(
          SubscriptionProductIds.playerGpsYearly,
        ),
        'player_gps_yearly',
      );
      expect(
        SubscriptionProductLookup.semanticKey(
          SubscriptionProductIds.playerMonthly,
        ),
        'player_monthly',
      );
      expect(
        SubscriptionProductLookup.semanticKey(
          SubscriptionProductIds.playerYearly,
        ),
        'player_yearly',
      );
    });

    test('maps store and Stripe-style identifiers to player_gps', () {
      expect(
        SubscriptionProductLookup.identifiersMatch(
          SubscriptionProductIds.playerGpsMonthly,
          'io.grinta.app.playerGPS.monthly',
        ),
        isTrue,
      );
      expect(
        SubscriptionProductLookup.identifiersMatch(
          SubscriptionProductIds.playerGpsYearly,
          'playergps_yearly',
        ),
        isTrue,
      );
      expect(
        SubscriptionProductLookup.identifiersMatch(
          SubscriptionProductIds.playerGpsMonthly,
          SubscriptionProductIds.playerMonthly,
        ),
        isFalse,
      );
      expect(
        SubscriptionProductLookup.entitlementIdForProduct(
          SubscriptionProductIds.playerGpsMonthly,
        ),
        SubscriptionEntitlementIds.playerGps,
      );
      expect(
        SubscriptionProductLookup.entitlementIdForProduct(
          SubscriptionProductIds.playerGpsYearly,
        ),
        SubscriptionEntitlementIds.playerGps,
      );
    });
  });

  group('SubscriptionEntitlementIds player GPS', () {
    test('accepts player_gps as a promo entitlement', () {
      expect(
        SubscriptionEntitlementIds.isKnown(SubscriptionEntitlementIds.playerGps),
        isTrue,
      );
      expect(SubscriptionEntitlementIds.isKnown('player'), isTrue);
      expect(SubscriptionEntitlementIds.isKnown('unknown'), isFalse);
      expect(
        SubscriptionEntitlementIds.hasPlayerGpsEntitlement({'playerGPS'}),
        isTrue,
      );
      expect(
        SubscriptionEntitlementIds.canonicalize({'playerGPS'}),
        contains(SubscriptionEntitlementIds.playerGps),
      );
    });

    test('player_gps grants player access and own Intense GPS', () {
      expect(
        SubscriptionEntitlementIds.grantsPlayerAccess({
          SubscriptionEntitlementIds.playerGps,
        }),
        isTrue,
      );
      expect(
        SubscriptionEntitlementIds.grantsPlayerAccess({
          SubscriptionEntitlementIds.player,
        }),
        isTrue,
      );
      expect(
        SubscriptionEntitlementIds.grantsPlayerAccess({
          SubscriptionEntitlementIds.coachBasic,
        }),
        isFalse,
      );
      expect(
        SubscriptionEntitlementIds.grantsOwnIntenseGpsAccess(
          entitlements: {SubscriptionEntitlementIds.playerGps},
          isRoot: false,
        ),
        isTrue,
      );
      expect(
        SubscriptionEntitlementIds.grantsOwnIntenseGpsAccess(
          entitlements: {SubscriptionEntitlementIds.player},
          isRoot: false,
        ),
        isFalse,
      );
      expect(
        SubscriptionEntitlementIds.grantsOwnIntenseGpsAccess(
          entitlements: {SubscriptionEntitlementIds.player},
          isRoot: false,
          initiatedBy: 'coach',
        ),
        isTrue,
      );
      expect(
        SubscriptionEntitlementIds.grantsOwnIntenseGpsAccess(
          entitlements: const {},
          isRoot: true,
        ),
        isTrue,
      );
    });
  });
}
