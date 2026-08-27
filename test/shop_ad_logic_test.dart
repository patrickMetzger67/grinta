import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/shop_ad.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/shop_ad_logic.dart';

ShopAd _ad({
  String id = 'ad1',
  String name = 'GPS',
  String url = 'https://shop.grinta.io/products/gps',
  ShopAdTarget target = ShopAdTarget.all,
  DateTime? start,
  DateTime? end,
}) {
  return ShopAd(
    id: id,
    name: name,
    url: url,
    target: target,
    startDate: start,
    endDate: end,
  );
}

void main() {
  group('teamHasTrackerKit', () {
    test('false when no owners and withTracker is not true', () {
      final team = Team(name: 'U13', withTracker: false);
      expect(teamHasTrackerKit(team), isFalse);
    });

    test('true when withTracker is true even without owners', () {
      final team = Team(name: 'U13', withTracker: true);
      expect(teamHasTrackerKit(team), isTrue);
    });

    test('true when owners has a tracker owner id', () {
      final team = Team(name: 'U13', withTracker: false);
      team.owners = <dynamic>['owner-1'];
      expect(team.hasAnyTrackerOwners, isTrue);
      expect(teamHasTrackerKit(team), isTrue);
    });
  });

  group('resolveShopAdAudience', () {
    test('educator with no teams is coach-only', () {
      final audience = resolveShopAdAudience(
        isEducatorOrCoach: true,
        managedTeamsHaveKit: const [],
        memberTeamsHaveKit: const [],
        hasIndividualTracker: false,
      );
      expect(audience.isCoach, isTrue);
      expect(audience.isPlayer, isFalse);
      expect(audience.matchesCoachWithoutTracker, isFalse);
      expect(audience.matchesPlayerWithoutTracker, isFalse);
    });

    test('player on a roster is a player, not a coach', () {
      final audience = resolveShopAdAudience(
        isEducatorOrCoach: false,
        managedTeamsHaveKit: const [],
        memberTeamsHaveKit: const [true],
        hasIndividualTracker: true,
      );
      expect(audience.isCoach, isFalse);
      expect(audience.isPlayer, isTrue);
      expect(audience.matchesPlayerWithoutTracker, isFalse);
    });

    test('coach of a kit-less team matches coachWithoutTracker', () {
      final audience = resolveShopAdAudience(
        isEducatorOrCoach: true,
        managedTeamsHaveKit: const [false, true],
        memberTeamsHaveKit: const [],
        hasIndividualTracker: false,
      );
      expect(audience.matchesCoachWithoutTracker, isTrue);
    });

    test('player without individual tracker matches playerWithoutTracker', () {
      final audience = resolveShopAdAudience(
        isEducatorOrCoach: false,
        managedTeamsHaveKit: const [],
        memberTeamsHaveKit: const [true],
        hasIndividualTracker: false,
      );
      expect(audience.matchesPlayerWithoutTracker, isTrue);
    });

    test('player on a kit-less team matches even with an individual tracker',
        () {
      final audience = resolveShopAdAudience(
        isEducatorOrCoach: false,
        managedTeamsHaveKit: const [],
        memberTeamsHaveKit: const [false],
        hasIndividualTracker: true,
      );
      expect(audience.matchesPlayerWithoutTracker, isTrue);
    });

    test('playing coach matches both coach and player', () {
      final audience = resolveShopAdAudience(
        isEducatorOrCoach: true,
        managedTeamsHaveKit: const [true],
        memberTeamsHaveKit: const [true],
        hasIndividualTracker: true,
      );
      expect(audience.isCoach, isTrue);
      expect(audience.isPlayer, isTrue);
    });
  });

  group('shopAdMatchesTarget', () {
    const coachNoKit = ShopAdAudience(
      isCoach: true,
      isPlayer: false,
      hasManagedTeamWithoutTracker: true,
      isPlayerOnTeamWithoutTracker: false,
      hasIndividualTracker: false,
    );
    const playerWithKitAndWearable = ShopAdAudience(
      isCoach: false,
      isPlayer: true,
      hasManagedTeamWithoutTracker: false,
      isPlayerOnTeamWithoutTracker: false,
      hasIndividualTracker: true,
    );

    test('all matches everyone', () {
      expect(shopAdMatchesTarget(ShopAdTarget.all, coachNoKit), isTrue);
      expect(
        shopAdMatchesTarget(ShopAdTarget.all, playerWithKitAndWearable),
        isTrue,
      );
    });

    test('coach does not match a player-only audience', () {
      expect(
        shopAdMatchesTarget(ShopAdTarget.coach, playerWithKitAndWearable),
        isFalse,
      );
      expect(shopAdMatchesTarget(ShopAdTarget.coach, coachNoKit), isTrue);
    });

    test('coachWithoutTracker requires a managed team without a kit', () {
      expect(
        shopAdMatchesTarget(ShopAdTarget.coachWithoutTracker, coachNoKit),
        isTrue,
      );
      const coachWithKit = ShopAdAudience(
        isCoach: true,
        isPlayer: false,
        hasManagedTeamWithoutTracker: false,
        isPlayerOnTeamWithoutTracker: false,
        hasIndividualTracker: false,
      );
      expect(
        shopAdMatchesTarget(ShopAdTarget.coachWithoutTracker, coachWithKit),
        isFalse,
      );
    });

    test('playerWithoutTracker is false when player has kit + wearable', () {
      expect(
        shopAdMatchesTarget(
          ShopAdTarget.playerWithoutTracker,
          playerWithKitAndWearable,
        ),
        isFalse,
      );
    });
  });

  group('shopAdIsCurrent', () {
    final now = DateTime(2026, 8, 27, 12);

    test('true when now is inside inclusive bounds', () {
      expect(
        shopAdIsCurrent(
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 31, 23, 59),
          now: now,
        ),
        isTrue,
      );
    });

    test('false before startDate', () {
      expect(
        shopAdIsCurrent(
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 30),
          now: now,
        ),
        isFalse,
      );
    });

    test('false after endDate', () {
      expect(
        shopAdIsCurrent(
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
          now: now,
        ),
        isFalse,
      );
    });

    test('missing bounds are open-ended', () {
      expect(shopAdIsCurrent(now: now), isTrue);
      expect(
        shopAdIsCurrent(startDate: DateTime(2026, 1, 1), now: now),
        isTrue,
      );
    });

    test('inclusive on the exact start and end instants', () {
      expect(
        shopAdIsCurrent(
          startDate: now,
          endDate: now,
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('shopAdAlreadyShownOnLocalDay', () {
    final today = DateTime(2026, 8, 27, 18, 30);

    test('false when nothing was stored', () {
      expect(
        shopAdAlreadyShownOnLocalDay(nowLocal: today),
        isFalse,
      );
    });

    test('true when lastShownDate is today', () {
      expect(
        shopAdAlreadyShownOnLocalDay(
          lastShownDate: '2026-08-27',
          nowLocal: today,
        ),
        isTrue,
      );
    });

    test('false when lastShownDate is yesterday', () {
      expect(
        shopAdAlreadyShownOnLocalDay(
          lastShownDate: '2026-08-26',
          nowLocal: today,
        ),
        isFalse,
      );
    });

    test('uses lastShownAt local calendar day as fallback', () {
      expect(
        shopAdAlreadyShownOnLocalDay(
          lastShownAt: DateTime(2026, 8, 27, 1, 5),
          nowLocal: today,
        ),
        isTrue,
      );
      expect(
        shopAdAlreadyShownOnLocalDay(
          lastShownAt: DateTime(2026, 8, 26, 23, 50),
          nowLocal: today,
        ),
        isFalse,
      );
    });

    test('date string wins over timestamp', () {
      expect(
        shopAdAlreadyShownOnLocalDay(
          lastShownDate: '2026-08-27',
          lastShownAt: DateTime(2026, 8, 26),
          nowLocal: today,
        ),
        isTrue,
      );
    });
  });

  group('selectEligibleShopAds + pickRandomItem', () {
    final now = DateTime(2026, 8, 27, 12);
    const player = ShopAdAudience(
      isCoach: false,
      isPlayer: true,
      hasManagedTeamWithoutTracker: false,
      isPlayerOnTeamWithoutTracker: true,
      hasIndividualTracker: false,
    );

    test('filters to current matching ads', () {
      final ads = <ShopAd>[
        _ad(
          id: 'expired',
          target: ShopAdTarget.player,
          end: DateTime(2026, 8, 1),
        ),
        _ad(id: 'coach', target: ShopAdTarget.coach),
        _ad(
          id: 'ok',
          target: ShopAdTarget.playerWithoutTracker,
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 31),
        ),
        _ad(id: 'all', target: ShopAdTarget.all),
        _ad(id: 'noname', name: '', target: ShopAdTarget.all),
      ];

      final eligible = selectEligibleShopAds(
        ads: ads,
        audience: player,
        now: now,
      );
      expect(eligible.map((ad) => ad.id), ['ok', 'all']);
    });

    test('pickRandomItem is null on empty and deterministic with seed', () {
      expect(pickRandomItem<ShopAd>(const []), isNull);
      final ads = [_ad(id: 'a'), _ad(id: 'b'), _ad(id: 'c')];
      expect(pickRandomItem(ads, random: Random(1))?.id, isNotEmpty);
      expect(
        pickRandomItem(ads, random: Random(42))?.id,
        pickRandomItem(ads, random: Random(42))?.id,
      );
    });
  });

  group('formatShopAdLocalDate', () {
    test('pads year month day', () {
      expect(formatShopAdLocalDate(DateTime(2026, 8, 7)), '2026-08-07');
    });

    test('parse round-trips', () {
      expect(parseShopAdLocalDate('2026-08-27'), DateTime(2026, 8, 27));
      expect(parseShopAdLocalDate('bad'), isNull);
    });
  });
}
