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
      expect(stats.hrTimeline, isNotEmpty);
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

  group('aggregateHrTimeline', () {
    test('averages samples into 5-minute buckets', () {
      // interval 60s → 5 samples per 5-min bucket
      final samples = <int>[
        for (var i = 0; i < 12; i++) 100 + i, // 12 minutes
      ];
      final timeline = aggregateHrTimeline(
        samples: samples,
        intervalSeconds: 60,
      );

      expect(timeline.length, 3); // 0–5, 5–10, 10–12
      expect(timeline[0].offsetMinutes, 0);
      expect(timeline[0].avgBpm, 102); // 100..104
      expect(timeline[1].offsetMinutes, 5);
      expect(timeline[1].avgBpm, 107); // 105..109
      expect(timeline[2].offsetMinutes, 10);
      // (110+111)/2 = 110.5 → Dart rounds half away from zero → 111
      expect(timeline[2].avgBpm, 111);
      expect(timeline[0].minBpm, 100);
      expect(timeline[0].maxBpm, 104);
    });

    test('skips all-zero buckets', () {
      final timeline = aggregateHrTimeline(
        samples: const [0, 0, 0, 0, 0, 150, 160, 170, 180, 190],
        intervalSeconds: 60,
      );
      expect(timeline.length, 1);
      expect(timeline.first.offsetMinutes, 5);
      expect(timeline.first.avgBpm, 170);
    });

    test('returns empty for empty samples', () {
      expect(
        aggregateHrTimeline(samples: const [], intervalSeconds: 1),
        isEmpty,
      );
    });
  });

  group('polarHrZoneBandsBpm', () {
    test('absolute bands use fixed BPM thresholds', () {
      final bands = polarHrZoneBandsBpm();
      expect(bands.map((b) => b.zone).toList(), ['z1', 'z2', 'z3', 'z4', 'z5']);
      expect(bands.first.y1, 80);
      expect(bands[1].y1, 120);
      expect(bands.last.y2, 200);
    });

    test('percent bands scale with hrMax', () {
      final bands = polarHrZoneBandsBpm(hrMaxBpm: 200);
      expect(bands.first.y1, 100);
      expect(bands.last.y2, 200);
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
