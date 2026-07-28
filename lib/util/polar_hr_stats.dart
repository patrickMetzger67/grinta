/// One bucket of a HR timeline (typically 5-minute synthesis).
class PolarHrTimelinePoint {
  const PolarHrTimelinePoint({
    required this.offsetMinutes,
    required this.avgBpm,
    this.minBpm,
    this.maxBpm,
  });

  /// Minutes from session start (bucket start).
  final int offsetMinutes;

  /// Mean of valid BPM samples in the bucket.
  final int avgBpm;

  final int? minBpm;
  final int? maxBpm;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      't': offsetMinutes,
      'avg': avgBpm,
      if (minBpm != null) 'min': minBpm,
      if (maxBpm != null) 'max': maxBpm,
    };
  }

  factory PolarHrTimelinePoint.fromMap(Map<String, dynamic> map) {
    return PolarHrTimelinePoint(
      offsetMinutes: _toInt(map['t'] ?? map['offsetMinutes']),
      avgBpm: _toInt(map['avg'] ?? map['avgBpm']),
      minBpm: _toNullableInt(map['min'] ?? map['minBpm']),
      maxBpm: _toNullableInt(map['max'] ?? map['maxBpm']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  static int? _toNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString());
  }
}

/// Aggregated HR metrics from Polar exercise samples (BPM).
class PolarHrStats {
  const PolarHrStats({
    required this.duration,
    required this.hrSamplesCount,
    this.avgHrBpm,
    this.maxHrBpm,
    this.minHrBpm,
    this.hrZoneSeconds = const <String, int>{},
    this.hrTimeline = const <PolarHrTimelinePoint>[],
  });

  final Duration duration;
  final int hrSamplesCount;
  final int? avgHrBpm;
  final int? maxHrBpm;
  final int? minHrBpm;

  /// Seconds spent in each zone (`z1`…`z5`).
  final Map<String, int> hrZoneSeconds;

  /// HR averages per [kPolarHrTimelineBucket] (default 5 min).
  final List<PolarHrTimelinePoint> hrTimeline;
}

/// Default synthesis window for the player analysis HR chart.
const Duration kPolarHrTimelineBucket = Duration(minutes: 5);

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
      hrTimeline: aggregateHrTimeline(
        samples: samples,
        intervalSeconds: interval,
      ),
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
    hrTimeline: aggregateHrTimeline(
      samples: samples,
      intervalSeconds: interval,
    ),
  );
}

/// Averages HR samples into fixed [bucket] windows (default 5 minutes).
///
/// Empty / zero-only buckets are skipped. Partial trailing buckets are kept.
List<PolarHrTimelinePoint> aggregateHrTimeline({
  required List<int> samples,
  required int intervalSeconds,
  Duration bucket = kPolarHrTimelineBucket,
}) {
  if (samples.isEmpty) return const <PolarHrTimelinePoint>[];

  final interval = intervalSeconds <= 0 ? 1 : intervalSeconds;
  final bucketSeconds = bucket.inSeconds <= 0 ? 300 : bucket.inSeconds;
  final samplesPerBucket = (bucketSeconds / interval).ceil().clamp(1, 1 << 30);

  final points = <PolarHrTimelinePoint>[];
  for (var start = 0; start < samples.length; start += samplesPerBucket) {
    final end = (start + samplesPerBucket).clamp(0, samples.length);
    final chunk = <int>[
      for (final bpm in samples.sublist(start, end))
        if (bpm > 0) bpm,
    ];
    if (chunk.isEmpty) continue;

    var sum = 0;
    var min = chunk.first;
    var max = chunk.first;
    for (final bpm in chunk) {
      sum += bpm;
      if (bpm < min) min = bpm;
      if (bpm > max) max = bpm;
    }

    points.add(
      PolarHrTimelinePoint(
        offsetMinutes: (start * interval) ~/ 60,
        avgBpm: (sum / chunk.length).round(),
        minBpm: min,
        maxBpm: max,
      ),
    );
  }

  return points;
}

/// Horizontal BPM bands for the training-zones chart (bottom → top = z1…z5).
///
/// When [hrMaxBpm] is set, bands follow % HRmax (50–60 / 60–70 / … / 90–100).
/// Otherwise absolute [kPolarAbsoluteHrZones] with a display floor of 80 bpm.
List<({String zone, double y1, double y2})> polarHrZoneBandsBpm({
  int? hrMaxBpm,
  double absoluteFloorBpm = 80,
  double absoluteCeilingBpm = 200,
}) {
  final maxHr = hrMaxBpm;
  if (maxHr != null && maxHr > 0) {
    return <({String zone, double y1, double y2})>[
      (zone: 'z1', y1: maxHr * 0.50, y2: maxHr * 0.60),
      (zone: 'z2', y1: maxHr * 0.60, y2: maxHr * 0.70),
      (zone: 'z3', y1: maxHr * 0.70, y2: maxHr * 0.80),
      (zone: 'z4', y1: maxHr * 0.80, y2: maxHr * 0.90),
      (zone: 'z5', y1: maxHr * 0.90, y2: maxHr * 1.00),
    ];
  }

  return <({String zone, double y1, double y2})>[
    (zone: 'z1', y1: absoluteFloorBpm, y2: 120),
    (zone: 'z2', y1: 120, y2: 140),
    (zone: 'z3', y1: 140, y2: 160),
    (zone: 'z4', y1: 160, y2: 180),
    (zone: 'z5', y1: 180, y2: absoluteCeilingBpm),
  ];
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
