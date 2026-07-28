import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/util/whoop_hr_zones.dart';

void main() {
  group('whoopHrZoneBandsBpm', () {
    test('uses %-of-max bands when HRmax is known', () {
      final bands = whoopHrZoneBandsBpm(hrMaxBpm: 200);
      expect(bands.length, 6);
      expect(bands.first.zone, 'z0');
      expect(bands.first.maxBpm, 100);
      expect(bands.last.zone, 'z5');
      expect(bands.last.minBpm, 180);
      expect(bands.last.maxBpm, 200);
    });

    test('falls back without HRmax', () {
      final bands = whoopHrZoneBandsBpm();
      expect(bands.last.minBpm, 180);
    });
  });

  group('formatWhoopDuration / strain', () {
    test('formats short and long durations', () {
      expect(formatWhoopDuration(32 * 60 + 51), '32:51');
      expect(formatWhoopDuration(3661), '1:01:01');
    });

    test('formats strain with locale decimal separator', () {
      expect(formatWhoopStrain(14.6, locale: 'fr'), '14,6');
      expect(formatWhoopStrain(14.6, locale: 'en'), '14.6');
    });
  });

  group('PersonalSportActivity Whoop fields', () {
    test('hasHrZones and isWhoopImport', () {
      final now = DateTime.utc(2026, 7, 28, 9, 24);
      final withoutZones = PersonalSportActivity(
        memberId: 'm1',
        createdByUserId: 'u1',
        startAt: now,
        endAt: now.add(const Duration(minutes: 33)),
        typeId: 'run',
        visibility: PersonalSportVisibility.private,
        entryMode: PersonalSportEntryMode.import,
        externalSource: 'whoop',
        strain: 14.6,
      );
      final withZones = PersonalSportActivity(
        memberId: 'm1',
        createdByUserId: 'u1',
        startAt: now,
        endAt: now.add(const Duration(minutes: 33)),
        typeId: 'run',
        visibility: PersonalSportVisibility.private,
        entryMode: PersonalSportEntryMode.import,
        externalSource: 'whoop',
        hrZoneSeconds: const {'z5': 851},
      );
      expect(withoutZones.hasHrZones, isFalse);
      expect(withoutZones.isWhoopImport, isTrue);
      expect(withZones.hasHrZones, isTrue);
    });
  });
}
