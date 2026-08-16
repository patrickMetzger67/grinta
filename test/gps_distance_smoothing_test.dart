import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/gps_distance_smoothing.dart';

void main() {
  group('GpsDistanceSmoother', () {
    test('stationary jitter does not accumulate kilometers', () {
      final smoother = GpsDistanceSmoother();
      final random = math.Random(42);

      // ~10 Hz for 4m31 around a fixed point with ±4 m GPS noise.
      const baseLat = 48.5800;
      const baseLon = 7.7400;
      const startMs = 1_700_000_000_000;
      const sampleCount = 2590;
      const dtMs = 105;

      var total = 0.0;
      for (var i = 0; i < sampleCount; i++) {
        final lat = baseLat + _metersToLat((random.nextDouble() - 0.5) * 8);
        final lon = baseLon +
            _metersToLon((random.nextDouble() - 0.5) * 8, baseLat);
        total += smoother.ingest(
          timeMs: startMs + i * dtMs,
          latitude: lat,
          longitude: lon,
          minDtMs: 80,
          maxDtMs: 3000,
          maxPlausibleSpeedMps: 10.5,
        );
      }

      // Raw sum would be ~2 km; median windows must stay far below that.
      expect(total, lessThan(120), reason: 'got ${total.toStringAsFixed(1)} m');
    });

    test('steady walking ~1.4 m/s keeps most of the true distance', () {
      final total = _straightLineDistance(speedMps: 1.4, durationSec: 300);
      const trueDistance = 1.4 * 300;
      expect(total, greaterThan(trueDistance * 0.80));
      expect(total, lessThan(trueDistance * 1.10));
    });

    test('steady running ~5 m/s keeps most of the true distance', () {
      final total = _straightLineDistance(speedMps: 5.0, durationSec: 120);
      const trueDistance = 5.0 * 120;
      expect(total, greaterThan(trueDistance * 0.80));
      expect(total, lessThan(trueDistance * 1.10));
    });

    test('gap larger than maxDt snaps without adding a teleport', () {
      final smoother = GpsDistanceSmoother();
      const baseLat = 48.5800;
      const baseLon = 7.7400;
      const t0 = 1_700_000_000_000;

      expect(
        smoother.ingest(
          timeMs: t0,
          latitude: baseLat,
          longitude: baseLon,
          minDtMs: 80,
          maxDtMs: 3000,
          maxPlausibleSpeedMps: 10.5,
        ),
        0,
      );

      // 10 s gap, 200 m jump — must not count.
      final jumped = smoother.ingest(
        timeMs: t0 + 10000,
        latitude: baseLat,
        longitude: baseLon + _metersToLon(200, baseLat),
        minDtMs: 80,
        maxDtMs: 3000,
        maxPlausibleSpeedMps: 10.5,
      );
      expect(jumped, 0);
    });
  });

  group('clampPersonalGpsDistanceMeters', () {
    test('caps absurd average speed from jitter', () {
      // 2.20 km in 271 s ≈ 29 km/h — must clamp to ≤ 18 km/h.
      final clamped = clampPersonalGpsDistanceMeters(
        distanceMeters: 2200,
        durationSeconds: 271,
      );
      expect(clamped, closeTo(5.0 * 271, 0.1));
      expect(clamped, lessThan(2200));
    });

    test('keeps plausible jogging distance', () {
      final clamped = clampPersonalGpsDistanceMeters(
        distanceMeters: 1000,
        durationSeconds: 300, // 12 km/h
      );
      expect(clamped, 1000);
    });
  });

  group('haversineMeters', () {
    test('~111 km per degree latitude', () {
      final d = haversineMeters(48.0, 7.0, 49.0, 7.0);
      expect(d, closeTo(111200, 500));
    });
  });
}

double _metersToLat(double meters) => meters / 111320.0;

double _metersToLon(double meters, double atLat) {
  final cosLat = math.cos(atLat * math.pi / 180.0);
  return meters / (111320.0 * cosLat);
}

double _straightLineDistance({
  required double speedMps,
  required int durationSec,
  int dtMs = 100,
}) {
  final smoother = GpsDistanceSmoother();
  const baseLat = 48.5800;
  const baseLon = 7.7400;
  const startMs = 1_700_000_000_000;
  final steps = (durationSec * 1000) ~/ dtMs;
  var total = 0.0;
  for (var i = 0; i < steps; i++) {
    final metersEast = speedMps * (i * dtMs / 1000.0);
    total += smoother.ingest(
      timeMs: startMs + i * dtMs,
      latitude: baseLat,
      longitude: baseLon + _metersToLon(metersEast, baseLat),
      minDtMs: 80,
      maxDtMs: 3000,
      maxPlausibleSpeedMps: 10.5,
    );
  }
  return total;
}
