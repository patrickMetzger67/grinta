import 'package:cloud_firestore/cloud_firestore.dart';
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
  String get label {
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

  String get unit {
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
