import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/tracker/polar_session_analysis.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';

class ActivityMetrics {
  ActivityMetrics({
    this.eventId = '',
    Timestamp? timestamp,
    this.distanceKM = 0,
    this.distanceKMZScore = 0,
    this.highAccelerationCount = 0,
    this.highAccelerationCountZScore = 0,
    this.highSpeedDuration = 0,
    this.highSpeedDurationZScore = 0,
    this.maxAccelerationMps2 = 0,
    this.maxAccelerationMps2ZScore = 0,
    this.maxValidatedSpeedKmh = 0,
    this.maxValidatedSpeedKmhZScore = 0,
    this.sprintCount = 0,
    this.sprintCountZScore = 0,
    this.workloadScore = 0,
    this.workloadScoreZScore = 0,
    this.isPolarCardio = false,
  }) : timestamp = timestamp ?? Timestamp.fromDate(DateTime(1970, 1, 1));

  String eventId;
  Timestamp timestamp;

  double distanceKM;
  double distanceKMZScore;

  int highAccelerationCount;
  double highAccelerationCountZScore;

  double highSpeedDuration;
  double highSpeedDurationZScore;

  double maxAccelerationMps2;
  double maxAccelerationMps2ZScore;

  double maxValidatedSpeedKmh;
  double maxValidatedSpeedKmhZScore;

  int sprintCount;
  double sprintCountZScore;

  double workloadScore;
  double workloadScoreZScore;

  /// True when values come from [PolarSessionAnalysis] (cardio), not GPS workload.
  bool isPolarCardio;
}

enum MetricType {
  distanceKm,
  highAccelerationCount,
  highSpeedDuration,
  maxAccelerationMps2,
  maxValidatedSpeedKmh,
  sprintCount,
  workloadScore,
}

extension MetricTypeX on MetricType {
  String get label => labelFor(polarCardio: false);

  String labelFor({required bool polarCardio}) {
    if (polarCardio) {
      switch (this) {
        case MetricType.distanceKm:
          return 'Distance';
        case MetricType.highSpeedDuration:
          return 'Temps haute intensité (Z4+Z5)';
        case MetricType.maxValidatedSpeedKmh:
          return 'FC max';
        case MetricType.workloadScore:
          return 'FC moyenne';
        case MetricType.highAccelerationCount:
        case MetricType.maxAccelerationMps2:
        case MetricType.sprintCount:
          return labelFor(polarCardio: false);
      }
    }

    switch (this) {
      case MetricType.distanceKm:
        return 'Distance parcourue';
      case MetricType.highAccelerationCount:
        return 'Nombre d’accélérations fortes';
      case MetricType.highSpeedDuration:
        return 'Temps passé à haute vitesse';
      case MetricType.maxAccelerationMps2:
        return 'Accélération maximale';
      case MetricType.maxValidatedSpeedKmh:
        return 'Vitesse maximale validée';
      case MetricType.sprintCount:
        return 'Nombre de sprints';
      case MetricType.workloadScore:
        return 'Score de charge de travail';
    }
  }

  String get unit => unitFor(polarCardio: false);

  String unitFor({required bool polarCardio}) {
    if (polarCardio) {
      switch (this) {
        case MetricType.distanceKm:
          return 'km';
        case MetricType.highSpeedDuration:
          return 's';
        case MetricType.maxValidatedSpeedKmh:
        case MetricType.workloadScore:
          return 'bpm';
        case MetricType.highAccelerationCount:
        case MetricType.maxAccelerationMps2:
        case MetricType.sprintCount:
          return unitFor(polarCardio: false);
      }
    }

    switch (this) {
      case MetricType.distanceKm:
        return 'km';
      case MetricType.highAccelerationCount:
        return '';
      case MetricType.highSpeedDuration:
        return 's';
      case MetricType.maxAccelerationMps2:
        return 'm/s²';
      case MetricType.maxValidatedSpeedKmh:
        return 'km/h';
      case MetricType.sprintCount:
        return '';
      case MetricType.workloadScore:
        return 'pts';
    }
  }

  /// Metrics meaningful for Polar cardio rows in the dashboard panel.
  static const List<MetricType> polarCardioValues = <MetricType>[
    MetricType.workloadScore,
    MetricType.maxValidatedSpeedKmh,
    MetricType.highSpeedDuration,
    MetricType.distanceKm,
  ];
}

ActivityMetrics buildActivityMetricsFromSummary({
  required String eventId,
  required Timestamp timestamp,
  required TeamWorkloadSummary tws,

}) {
  final ActivityMetrics activityMetrics = ActivityMetrics(
    eventId: eventId,
    timestamp: timestamp,
  );

  for (final entry in tws.metricStats.entries) {
    final String metricKey = entry.key.toString().trim();

    if (metricKey.isEmpty) {
      continue;
    }

    final dynamic value = entry.value.mean;
    const dynamic zScore = 0;

    switch (metricKey) {
      case 'distanceKm':
        activityMetrics.distanceKM = _toDouble(value);
        activityMetrics.distanceKMZScore = _toDouble(zScore);
        break;

      case 'highAccelerationCount':
        activityMetrics.highAccelerationCount = _toInt(value);
        activityMetrics.highAccelerationCountZScore = _toDouble(zScore);
        break;

      case 'highSpeedDuration':
        activityMetrics.highSpeedDuration = _toDouble(value);
        activityMetrics.highSpeedDurationZScore = _toDouble(zScore);
        break;

      case 'maxAccelerationMps2':
        activityMetrics.maxAccelerationMps2 = _toDouble(value);
        activityMetrics.maxAccelerationMps2ZScore = _toDouble(zScore);
        break;

      case 'maxValidatedSpeedKmh':
        activityMetrics.maxValidatedSpeedKmh = _toDouble(value);
        activityMetrics.maxValidatedSpeedKmhZScore = _toDouble(zScore);
        break;

      case 'sprintCount':
        activityMetrics.sprintCount = _toInt(value);
        activityMetrics.sprintCountZScore = _toDouble(zScore);
        break;

      case 'workloadScore':
        activityMetrics.workloadScore = _toDouble(value);
        activityMetrics.workloadScoreZScore = _toDouble(zScore);
        break;
    }
  }

  return activityMetrics;
}


/// Maps Polar cardio into [ActivityMetrics] so dashboard lists stay clickable.
///
/// Field reuse (Polar has no GPS workload):
/// - [ActivityMetrics.workloadScore] ← avg HR (bpm)
/// - [ActivityMetrics.maxValidatedSpeedKmh] ← max HR (bpm)
/// - [ActivityMetrics.highSpeedDuration] ← Z4+Z5 seconds
/// - [ActivityMetrics.distanceKM] ← Loop distance when present
ActivityMetrics buildActivityMetricsFromPolarAnalysis({
  required String eventId,
  required Timestamp timestamp,
  required PolarSessionAnalysis analysis,
}) {
  final z4 = analysis.hrZoneSeconds['z4'] ?? 0;
  final z5 = analysis.hrZoneSeconds['z5'] ?? 0;
  final distanceM = analysis.distanceMeters ?? 0;

  return ActivityMetrics(
    eventId: eventId,
    timestamp: timestamp,
    isPolarCardio: true,
    workloadScore: (analysis.avgHrBpm ?? 0).toDouble(),
    maxValidatedSpeedKmh: (analysis.maxHrBpm ?? 0).toDouble(),
    highSpeedDuration: (z4 + z5).toDouble(),
    distanceKM: distanceM > 0 ? distanceM / 1000.0 : 0,
  );
}

/// Team-average Polar cardio for managers / roster staff.
ActivityMetrics buildActivityMetricsFromPolarAnalyses({
  required String eventId,
  required Timestamp timestamp,
  required List<PolarSessionAnalysis> analyses,
}) {
  if (analyses.isEmpty) {
    return ActivityMetrics(
      eventId: eventId,
      timestamp: timestamp,
      isPolarCardio: true,
    );
  }

  var avgHrSum = 0.0;
  var avgHrCount = 0;
  var maxHrSum = 0.0;
  var maxHrCount = 0;
  var highIntensitySum = 0.0;
  var distanceSumKm = 0.0;

  for (final analysis in analyses) {
    final avg = analysis.avgHrBpm;
    if (avg != null && avg > 0) {
      avgHrSum += avg;
      avgHrCount++;
    }
    final max = analysis.maxHrBpm;
    if (max != null && max > 0) {
      maxHrSum += max;
      maxHrCount++;
    }
    final z4 = analysis.hrZoneSeconds['z4'] ?? 0;
    final z5 = analysis.hrZoneSeconds['z5'] ?? 0;
    highIntensitySum += z4 + z5;
    final distanceM = analysis.distanceMeters ?? 0;
    if (distanceM > 0) {
      distanceSumKm += distanceM / 1000.0;
    }
  }

  final n = analyses.length.toDouble();
  return ActivityMetrics(
    eventId: eventId,
    timestamp: timestamp,
    isPolarCardio: true,
    workloadScore: avgHrCount > 0 ? avgHrSum / avgHrCount : 0,
    maxValidatedSpeedKmh: maxHrCount > 0 ? maxHrSum / maxHrCount : 0,
    highSpeedDuration: highIntensitySum / n,
    distanceKM: distanceSumKm / n,
  );
}

ActivityMetrics buildActivityMetricsFromPlayerScore({
  required String eventId,
  required Timestamp timestamp,
  required dynamic playerScore,

}) {
  final ActivityMetrics activityMetrics = ActivityMetrics(
    eventId: eventId,
    timestamp: timestamp,
  );

  for (final entry in playerScore.metrics.entries) {
    final String metricKey = entry.key.toString().trim();

    if (metricKey.isEmpty) {
      continue;
    }

    final dynamic value = entry.value.value;
    final dynamic zScore = entry.value.zScore;

    switch (metricKey) {
      case 'distanceKm':
        activityMetrics.distanceKM = _toDouble(value);
        activityMetrics.distanceKMZScore = _toDouble(zScore);
        break;

      case 'highAccelerationCount':
        activityMetrics.highAccelerationCount = _toInt(value);
        activityMetrics.highAccelerationCountZScore = _toDouble(zScore);
        break;

      case 'highSpeedDuration':
        activityMetrics.highSpeedDuration = _toDouble(value);
        activityMetrics.highSpeedDurationZScore = _toDouble(zScore);
        break;

      case 'maxAccelerationMps2':
        activityMetrics.maxAccelerationMps2 = _toDouble(value);
        activityMetrics.maxAccelerationMps2ZScore = _toDouble(zScore);
        break;

      case 'maxValidatedSpeedKmh':
        activityMetrics.maxValidatedSpeedKmh = _toDouble(value);
        activityMetrics.maxValidatedSpeedKmhZScore = _toDouble(zScore);
        break;

      case 'sprintCount':
        activityMetrics.sprintCount = _toInt(value);
        activityMetrics.sprintCountZScore = _toDouble(zScore);
        break;

      case 'workloadScore':
        activityMetrics.workloadScore = _toDouble(value);
        activityMetrics.workloadScoreZScore = _toDouble(zScore);
        break;
    }
  }

  return activityMetrics;
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  return 0;
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.round();
  }

  if (value is num) {
    return value.round();
  }

  if (value is String) {
    return int.tryParse(value) ??
        double.tryParse(value.replaceAll(',', '.'))?.round() ??
        0;
  }

  return 0;
}
