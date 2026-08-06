import 'dart:math' as math;

/// GNSS path smoothing for distance accumulation.
///
/// High-rate Insiders samples (~10 Hz) include meter-scale jitter. Summing raw
/// haversine steps inflates distance (e.g. "2 km" in a few minutes while
/// walking or nearly still).
///
/// Approach:
/// 1. Buffer fixes into time windows (~2 s)
/// 2. Take the **median** lat/lon of each window (rejects outlier jumps)
/// 3. Accumulate haversine between consecutive medians
/// 4. Reject commits slower than [minDistanceSpeedMps] (stationary drift)
class GpsDistanceSmoother {
  GpsDistanceSmoother({
    this.minDistanceSpeedMps = defaultMinDistanceSpeedMps,
    this.windowMs = defaultWindowMs,
  });

  /// Below this window speed, treat displacement as stationary GNSS drift.
  /// ~1.0 m/s ≈ 3.6 km/h — under normal walking, above median-window wander.
  static const double defaultMinDistanceSpeedMps = 1.0;

  /// Median window length. Longer ⇒ more noise rejection, less path detail.
  static const int defaultWindowMs = 2000;

  final double minDistanceSpeedMps;
  final int windowMs;

  final List<double> _windowLats = <double>[];
  final List<double> _windowLons = <double>[];
  int? _windowStartMs;
  int? _lastRawTimeMs;
  double? _prevMedLat;
  double? _prevMedLon;
  int? _prevMedTimeMs;

  void reset() {
    _windowLats.clear();
    _windowLons.clear();
    _windowStartMs = null;
    _lastRawTimeMs = null;
    _prevMedLat = null;
    _prevMedLon = null;
    _prevMedTimeMs = null;
  }

  /// Ingest one GNSS fix and return meters to add (0 when not committing).
  double ingest({
    required int timeMs,
    required double latitude,
    required double longitude,
    required int minDtMs,
    required int maxDtMs,
    required double maxPlausibleSpeedMps,
    double minMeaningfulStepDistanceMeters = 0,
  }) {
    if (_lastRawTimeMs != null) {
      final dtRawMs = timeMs - _lastRawTimeMs!;
      if (dtRawMs <= 0) return 0;
      if (dtRawMs > maxDtMs) {
        _clearWindow();
        _prevMedLat = null;
        _prevMedLon = null;
        _prevMedTimeMs = null;
        _lastRawTimeMs = timeMs;
        _openWindow(timeMs, latitude, longitude);
        return 0;
      }
    }
    _lastRawTimeMs = timeMs;

    if (_windowStartMs == null) {
      _openWindow(timeMs, latitude, longitude);
      return 0;
    }

    _windowLats.add(latitude);
    _windowLons.add(longitude);

    if (timeMs - _windowStartMs! < windowMs) {
      return 0;
    }

    final medLat = _median(_windowLats);
    final medLon = _median(_windowLons);
    final medTimeMs = (_windowStartMs! + timeMs) ~/ 2;
    _clearWindow();
    // Next window starts at the current fix (not the median).
    _openWindow(timeMs, latitude, longitude);

    if (_prevMedLat == null ||
        _prevMedLon == null ||
        _prevMedTimeMs == null) {
      _prevMedLat = medLat;
      _prevMedLon = medLon;
      _prevMedTimeMs = medTimeMs;
      return 0;
    }

    final dtMs = medTimeMs - _prevMedTimeMs!;
    if (dtMs < math.max(minDtMs, windowMs ~/ 2)) {
      _prevMedLat = medLat;
      _prevMedLon = medLon;
      _prevMedTimeMs = medTimeMs;
      return 0;
    }

    final rawDistance = haversineMeters(
      _prevMedLat!,
      _prevMedLon!,
      medLat,
      medLon,
    );

    _prevMedLat = medLat;
    _prevMedLon = medLon;
    _prevMedTimeMs = medTimeMs;

    final dtSec = dtMs / 1000.0;
    final maxStepDistance = maxPlausibleSpeedMps * dtSec * 1.5;
    final stepSpeedMps = dtSec > 0 ? rawDistance / dtSec : 0.0;

    final isValid = rawDistance >= minMeaningfulStepDistanceMeters &&
        rawDistance <= maxStepDistance &&
        stepSpeedMps >= minDistanceSpeedMps;

    return isValid ? rawDistance : 0.0;
  }

  void _openWindow(int timeMs, double latitude, double longitude) {
    _windowStartMs = timeMs;
    _windowLats
      ..clear()
      ..add(latitude);
    _windowLons
      ..clear()
      ..add(longitude);
  }

  void _clearWindow() {
    _windowLats.clear();
    _windowLons.clear();
    _windowStartMs = null;
  }
}

double _median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = List<double>.from(values)..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2.0;
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

/// Caps personal-GPS average speed so jitter cannot invent sprint-pace km.
///
/// 5.0 m/s ≈ 18 km/h — above easy jogging, below sustained ~2:00 /km absurdity.
double clampPersonalGpsDistanceMeters({
  required double distanceMeters,
  required int durationSeconds,
  double maxAverageSpeedMps = 5.0,
}) {
  if (distanceMeters <= 0 || durationSeconds <= 0) return distanceMeters;
  final maxDistance = maxAverageSpeedMps * durationSeconds;
  if (distanceMeters <= maxDistance) return distanceMeters;
  return maxDistance;
}
