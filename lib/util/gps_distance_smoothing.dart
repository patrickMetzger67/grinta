import 'dart:math' as math;

/// GNSS path smoothing for distance accumulation.
///
/// High-rate Insiders samples (~10 Hz) include meter-scale jitter. Summing raw
/// haversine steps inflates distance (e.g. "2 km" while barely moving).
/// A hard step floor (e.g. 3 m) cannot fix this: at 10 Hz even real running
/// steps are often under 1 m.
///
/// Approach:
/// 1. EMA on lat/lon to damp high-frequency noise
/// 2. Accumulate distance on ~1 s commits (net displacement, not jagged path)
/// 3. Reject commits whose smoothed speed is below walking drift
class GpsDistanceSmoother {
  GpsDistanceSmoother({
    this.alpha = defaultAlpha,
    this.minDistanceSpeedMps = defaultMinDistanceSpeedMps,
    this.minCommitDtMs = defaultMinCommitDtMs,
  });

  /// EMA blend toward each new fix (0..1). Lower = stronger smoothing.
  static const double defaultAlpha = 0.08;

  /// Below this smoothed speed, treat displacement as stationary GNSS drift.
  /// ~1.0 m/s ≈ 3.6 km/h — under normal walking (~5 km/h), cuts post-EMA wander.
  static const double defaultMinDistanceSpeedMps = 1.0;

  /// Minimum time between distance commits. Net displacement over ~1 s is far
  /// more stable than summing ~10 Hz micro-steps.
  static const int defaultMinCommitDtMs = 1000;

  final double alpha;
  final double minDistanceSpeedMps;
  final int minCommitDtMs;

  double? _smoothLat;
  double? _smoothLon;
  double? _prevSmoothLat;
  double? _prevSmoothLon;
  int? _lastRawTimeMs;
  int? _lastCommitTimeMs;

  void reset() {
    _smoothLat = null;
    _smoothLon = null;
    _prevSmoothLat = null;
    _prevSmoothLon = null;
    _lastRawTimeMs = null;
    _lastCommitTimeMs = null;
  }

  /// Ingest one GNSS fix and return meters to add for this step (may be 0).
  ///
  /// On gaps larger than [maxDtMs] since the previous raw sample, the smoother
  /// snaps to the new fix and returns 0.
  double ingest({
    required int timeMs,
    required double latitude,
    required double longitude,
    required int minDtMs,
    required int maxDtMs,
    required double maxPlausibleSpeedMps,
    double minMeaningfulStepDistanceMeters = 0,
  }) {
    if (_smoothLat == null ||
        _smoothLon == null ||
        _lastRawTimeMs == null ||
        _lastCommitTimeMs == null) {
      _smoothLat = latitude;
      _smoothLon = longitude;
      _prevSmoothLat = latitude;
      _prevSmoothLon = longitude;
      _lastRawTimeMs = timeMs;
      _lastCommitTimeMs = timeMs;
      return 0;
    }

    final dtRawMs = timeMs - _lastRawTimeMs!;
    if (dtRawMs <= 0) return 0;
    _lastRawTimeMs = timeMs;

    if (dtRawMs > maxDtMs) {
      _smoothLat = latitude;
      _smoothLon = longitude;
      _prevSmoothLat = latitude;
      _prevSmoothLon = longitude;
      _lastCommitTimeMs = timeMs;
      return 0;
    }

    final a = alpha.clamp(0.01, 1.0);
    _smoothLat = a * latitude + (1 - a) * _smoothLat!;
    _smoothLon = a * longitude + (1 - a) * _smoothLon!;

    final commitDtMs = timeMs - _lastCommitTimeMs!;
    final requiredCommitDt = math.max(minDtMs, minCommitDtMs);
    if (commitDtMs < requiredCommitDt) {
      return 0;
    }

    final prevLat = _prevSmoothLat!;
    final prevLon = _prevSmoothLon!;
    final currLat = _smoothLat!;
    final currLon = _smoothLon!;

    final rawDistance = haversineMeters(prevLat, prevLon, currLat, currLon);
    final dtSec = commitDtMs / 1000.0;
    final maxStepDistance = maxPlausibleSpeedMps * dtSec * 1.5;
    final stepSpeedMps = dtSec > 0 ? rawDistance / dtSec : 0.0;

    _prevSmoothLat = currLat;
    _prevSmoothLon = currLon;
    _lastCommitTimeMs = timeMs;

    final isValid = rawDistance >= minMeaningfulStepDistanceMeters &&
        rawDistance <= maxStepDistance &&
        stepSpeedMps >= minDistanceSpeedMps;

    return isValid ? rawDistance : 0.0;
  }
}

double haversineMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadius = 6371000.0;

  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _degToRad(double deg) => deg * math.pi / 180.0;
