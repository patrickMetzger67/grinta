/// Aggregated HR metrics from Polar exercise samples (BPM).
class PolarHrStats {
  const PolarHrStats({
    required this.duration,
    required this.hrSamplesCount,
    this.avgHrBpm,
    this.maxHrBpm,
    this.minHrBpm,
    this.hrZoneSeconds = const <String, int>{},
  });

  final Duration duration;
  final int hrSamplesCount;
  final int? avgHrBpm;
  final int? maxHrBpm;
  final int? minHrBpm;

  /// Seconds spent in each zone (`z1`…`z5`).
  final Map<String, int> hrZoneSeconds;
}

/// Absolute BPM bands used when no HRmax is known.
///
/// z1 &lt;120 · z2 120–139 · z3 140–159 · z4 160–179 · z5 ≥180
const Map<String, (int minInclusive, int? maxExclusive)> kPolarAbsoluteHrZones =
    <String, (int, int?)>{
  'z1': (0, 120),
  'z2': (120, 140),
  'z3': (140, 160),
  'z4': (160, 180),
  'z5': (180, null),
};

/// Computes avg / max / min / duration / zone seconds from Polar HR samples.
///
/// [intervalSeconds] is the recording interval between samples (H10: 1 or 5).
/// When [hrMaxBpm] is set, zones use % of HRmax (60/70/80/90); otherwise
/// [kPolarAbsoluteHrZones] absolute bands apply.
PolarHrStats computePolarHrStats({
  required List<int> samples,
  required int intervalSeconds,
  int? hrMaxBpm,
}) {
  final interval = intervalSeconds <= 0 ? 1 : intervalSeconds;
  final valid = samples.where((bpm) => bpm > 0).toList(growable: false);

  if (valid.isEmpty) {
    return PolarHrStats(
      duration: Duration(seconds: samples.length * interval),
      hrSamplesCount: 0,
    );
  }

  var sum = 0;
  var max = valid.first;
  var min = valid.first;
  for (final bpm in valid) {
    sum += bpm;
    if (bpm > max) max = bpm;
    if (bpm < min) min = bpm;
  }

  final zones = <String, int>{
    'z1': 0,
    'z2': 0,
    'z3': 0,
    'z4': 0,
    'z5': 0,
  };

  final maxHr = hrMaxBpm;
  final usePercent = maxHr != null && maxHr > 0;
  for (final bpm in valid) {
    final zone = usePercent
        ? _zoneByPercent(bpm, maxHr)
        : _zoneByAbsolute(bpm);
    zones[zone] = (zones[zone] ?? 0) + interval;
  }

  return PolarHrStats(
    duration: Duration(seconds: samples.length * interval),
    hrSamplesCount: valid.length,
    avgHrBpm: (sum / valid.length).round(),
    maxHrBpm: max,
    minHrBpm: min,
    hrZoneSeconds: zones,
  );
}

String _zoneByAbsolute(int bpm) {
  for (final entry in kPolarAbsoluteHrZones.entries) {
    final min = entry.value.$1;
    final maxEx = entry.value.$2;
    if (bpm >= min && (maxEx == null || bpm < maxEx)) {
      return entry.key;
    }
  }
  return 'z5';
}

String _zoneByPercent(int bpm, int hrMax) {
  final pct = bpm / hrMax;
  if (pct < 0.60) return 'z1';
  if (pct < 0.70) return 'z2';
  if (pct < 0.80) return 'z3';
  if (pct < 0.90) return 'z4';
  return 'z5';
}

/// Lightweight exercise listing entry (platform-agnostic).
class PolarExerciseListItem {
  const PolarExerciseListItem({
    required this.path,
    required this.date,
    required this.entryId,
  });

  final String path;
  final DateTime date;
  final String entryId;
}

/// Picks the exercise whose start is closest to [eventAt] within the window.
///
/// Returns null when nothing falls in
/// `[eventAt - windowBefore, eventAt + windowAfter]`.
PolarExerciseListItem? pickExerciseNearEvent(
  List<PolarExerciseListItem> entries,
  DateTime eventAt, {
  Duration windowBefore = const Duration(hours: 6),
  Duration windowAfter = const Duration(hours: 4),
}) {
  if (entries.isEmpty) return null;

  final earliest = eventAt.subtract(windowBefore);
  final latest = eventAt.add(windowAfter);

  PolarExerciseListItem? best;
  Duration? bestDelta;

  for (final entry in entries) {
    final date = entry.date.toLocal();
    if (date.isBefore(earliest) || date.isAfter(latest)) continue;
    final delta = date.difference(eventAt).abs();
    if (best == null || bestDelta == null || delta < bestDelta) {
      best = entry;
      bestDelta = delta;
    }
  }

  return best;
}
