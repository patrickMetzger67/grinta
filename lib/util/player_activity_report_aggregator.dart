import 'package:grinta/model/tracker/team_workload_summary.dart';

/// Tracker metric keys exposed in player activity reports.
const List<String> kPlayerActivityTrackerMetricKeys = <String>[
  TeamWorkloadMetricKeys.distanceKm,
  TeamWorkloadMetricKeys.maxValidatedSpeedKmh,
  TeamWorkloadMetricKeys.sprintCount,
  TeamWorkloadMetricKeys.highAccelerationCount,
  TeamWorkloadMetricKeys.highSpeedDuration,
  TeamWorkloadMetricKeys.maxAccelerationMps2,
  TeamWorkloadMetricKeys.workloadScore,
];

/// One tracker session's raw metric values for a player.
class PlayerTrackerSessionMetrics {
  const PlayerTrackerSessionMetrics({
    required this.eventId,
    required this.eventType,
    required this.values,
  });

  final String eventId;
  final String eventType;
  final Map<String, double> values;
}

/// Aggregated averages for a set of tracker sessions.
class PlayerTrackerMetricAverages {
  const PlayerTrackerMetricAverages({
    required this.sessionsWithData,
    required this.averages,
  });

  final int sessionsWithData;
  final Map<String, double> averages;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionsWithData': sessionsWithData,
      'averages': averages.map(
        (String key, double value) => MapEntry(key, _roundMetric(key, value)),
      ),
    };
  }
}

/// Trend for one metric vs the previous period.
class PlayerTrackerMetricTrend {
  const PlayerTrackerMetricTrend({
    required this.current,
    required this.previous,
    required this.changePercent,
  });

  final double? current;
  final double? previous;
  final double? changePercent;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (current != null) 'current': current,
      if (previous != null) 'previous': previous,
      if (changePercent != null) 'changePercent': changePercent,
    };
  }
}

PlayerTrackerMetricAverages aggregateTrackerSessionMetrics(
  List<PlayerTrackerSessionMetrics> sessions,
) {
  if (sessions.isEmpty) {
    return const PlayerTrackerMetricAverages(
      sessionsWithData: 0,
      averages: <String, double>{},
    );
  }

  final sums = <String, double>{};
  final counts = <String, int>{};

  for (final session in sessions) {
    for (final key in kPlayerActivityTrackerMetricKeys) {
      final value = session.values[key];
      if (value == null || !value.isFinite) {
        continue;
      }
      sums[key] = (sums[key] ?? 0) + value;
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }

  final averages = <String, double>{};
  for (final key in kPlayerActivityTrackerMetricKeys) {
    final count = counts[key] ?? 0;
    if (count <= 0) {
      continue;
    }
    averages[key] = (sums[key] ?? 0) / count;
  }

  return PlayerTrackerMetricAverages(
    sessionsWithData: sessions.length,
    averages: averages,
  );
}

Map<String, PlayerTrackerMetricTrend> computeTrackerTrends({
  required PlayerTrackerMetricAverages current,
  required PlayerTrackerMetricAverages previous,
}) {
  final trends = <String, PlayerTrackerMetricTrend>{};

  for (final key in kPlayerActivityTrackerMetricKeys) {
    final currentValue = current.averages[key];
    final previousValue = previous.averages[key];
    if (currentValue == null && previousValue == null) {
      continue;
    }

    trends[key] = PlayerTrackerMetricTrend(
      current: currentValue != null ? _roundMetric(key, currentValue) : null,
      previous: previousValue != null ? _roundMetric(key, previousValue) : null,
      changePercent: _changePercent(currentValue, previousValue),
    );
  }

  return trends;
}

Map<String, dynamic> trackerTrendsToJson(
  Map<String, PlayerTrackerMetricTrend> trends,
) {
  return trends.map(
    (String key, PlayerTrackerMetricTrend trend) =>
        MapEntry(key, trend.toJson()),
  );
}

double? _changePercent(double? current, double? previous) {
  if (current == null || previous == null) {
    return null;
  }
  if (previous == 0) {
    return current == 0 ? 0 : null;
  }
  final change = ((current - previous) / previous.abs()) * 100;
  if (!change.isFinite) {
    return null;
  }
  return double.parse(change.toStringAsFixed(1));
}

double _roundMetric(String key, double value) {
  switch (key) {
    case TeamWorkloadMetricKeys.distanceKm:
    case TeamWorkloadMetricKeys.maxValidatedSpeedKmh:
    case TeamWorkloadMetricKeys.maxAccelerationMps2:
      return double.parse(value.toStringAsFixed(2));
    case TeamWorkloadMetricKeys.highSpeedDuration:
      return double.parse(value.toStringAsFixed(1));
    default:
      return double.parse(value.toStringAsFixed(1));
  }
}

/// Extracts player metric values from [playerScore].
Map<String, double> trackerValuesFromPlayerScore(
  TeamPlayerMetricScores playerScore,
) {
  final values = <String, double>{};
  for (final key in kPlayerActivityTrackerMetricKeys) {
    final metric = playerScore.getMetric(key);
    if (metric == null || !metric.value.isFinite) {
      continue;
    }
    values[key] = metric.value;
  }
  return values;
}
