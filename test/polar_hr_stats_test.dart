import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/polar_hr_stats.dart';

void main() {
  group('computePolarHrStats', () {
    test('computes avg/max/min/duration and absolute zones', () {
      final stats = computePolarHrStats(
        samples: const [100, 130, 150, 170, 190],
        intervalSeconds: 1,
      );

      expect(stats.hrSamplesCount, 5);
      expect(stats.avgHrBpm, 148);
      expect(stats.maxHrBpm, 190);
      expect(stats.minHrBpm, 100);
      expect(stats.duration, const Duration(seconds: 5));
      expect(stats.hrZoneSeconds['z1'], 1); // 100
      expect(stats.hrZoneSeconds['z2'], 1); // 130
      expect(stats.hrZoneSeconds['z3'], 1); // 150
      expect(stats.hrZoneSeconds['z4'], 1); // 170
      expect(stats.hrZoneSeconds['z5'], 1); // 190
    });

    test('ignores zero samples for avg but keeps duration from length', () {
      final stats = computePolarHrStats(
        samples: const [0, 140, 0, 160],
        intervalSeconds: 5,
      );

      expect(stats.hrSamplesCount, 2);
      expect(stats.avgHrBpm, 150);
      expect(stats.duration, const Duration(seconds: 20));
    });

    test('uses percent zones when hrMaxBpm is set', () {
      final stats = computePolarHrStats(
        samples: const [100, 130, 150, 170, 190],
        intervalSeconds: 1,
        hrMaxBpm: 200,
      );

      // 100=50% z1, 130=65% z2, 150=75% z3, 170=85% z4, 190=95% z5
      expect(stats.hrZoneSeconds['z1'], 1);
      expect(stats.hrZoneSeconds['z2'], 1);
      expect(stats.hrZoneSeconds['z3'], 1);
      expect(stats.hrZoneSeconds['z4'], 1);
      expect(stats.hrZoneSeconds['z5'], 1);
    });
  });

  group('pickExerciseNearEvent', () {
    final eventAt = DateTime(2026, 7, 26, 18, 0);

    test('picks closest exercise within window', () {
      final entries = [
        PolarExerciseListItem(
          path: '/a',
          date: DateTime(2026, 7, 26, 10, 0),
          entryId: 'far',
        ),
        PolarExerciseListItem(
          path: '/b',
          date: DateTime(2026, 7, 26, 17, 45),
          entryId: 'near',
        ),
        PolarExerciseListItem(
          path: '/c',
          date: DateTime(2026, 7, 26, 19, 0),
          entryId: 'after',
        ),
      ];

      final picked = pickExerciseNearEvent(entries, eventAt);
      expect(picked?.entryId, 'near');
    });

    test('returns null when nothing in window', () {
      final entries = [
        PolarExerciseListItem(
          path: '/a',
          date: DateTime(2026, 7, 20, 18, 0),
          entryId: 'old',
        ),
      ];
      expect(pickExerciseNearEvent(entries, eventAt), isNull);
    });
  });
}
