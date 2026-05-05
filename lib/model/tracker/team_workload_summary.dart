import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trackerData.dart';

class TeamWorkloadMetricKeys {
  static const String distanceKm = 'distanceKm';
  static const String maxValidatedSpeedKmh = 'maxValidatedSpeedKmh';
  static const String sprintCount = 'sprintCount';
  static const String highAccelerationCount = 'highAccelerationCount';
  static const String highSpeedDuration = 'highSpeedDuration';
  static const String maxAccelerationMps2 = 'maxAccelerationMps2';
  static const String workloadScore = 'workloadScore';
  static const String workloadScorePerMinute = 'workloadScorePerMinute';

  static const List<String> all = [
    distanceKm,
    maxValidatedSpeedKmh,
    sprintCount,
    highAccelerationCount,
    highSpeedDuration,
    maxAccelerationMps2,
    workloadScore,
    workloadScorePerMinute,
  ];
}

class TeamMetricStat {
  final String metricKey;
  final double mean;
  final double standardDeviation;
  final double min;
  final double max;
  final int count;

  const TeamMetricStat({
    required this.metricKey,
    required this.mean,
    required this.standardDeviation,
    required this.min,
    required this.max,
    required this.count,
  });

  factory TeamMetricStat.fromValues({
    required String metricKey,
    required List<double> values,
  }) {
    final cleanValues = values.where((v) => v.isFinite).toList();

    if (cleanValues.isEmpty) {
      return TeamMetricStat(
        metricKey: metricKey,
        mean: 0,
        standardDeviation: 0,
        min: 0,
        max: 0,
        count: 0,
      );
    }

    final total = cleanValues.fold<double>(0.0, (sum, v) => sum + v);
    final mean = total / cleanValues.length;

    final variance = cleanValues.fold<double>(0.0, (sum, v) {
      final diff = v - mean;
      return sum + (diff * diff);
    }) / cleanValues.length;

    double minValue = cleanValues.first;
    double maxValue = cleanValues.first;

    for (final value in cleanValues) {
      if (value < minValue) minValue = value;
      if (value > maxValue) maxValue = value;
    }

    return TeamMetricStat(
      metricKey: metricKey,
      mean: mean,
      standardDeviation: math.sqrt(variance),
      min: minValue,
      max: maxValue,
      count: cleanValues.length,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'metricKey': metricKey,
      'mean': mean,
      'standardDeviation': standardDeviation,
      'min': min,
      'max': max,
      'count': count,
    };
  }

  factory TeamMetricStat.fromMap(Map<String, dynamic> map) {
    return TeamMetricStat(
      metricKey: (map['metricKey'] ?? '').toString(),
      mean: _toDouble(map['mean']),
      standardDeviation: _toDouble(map['standardDeviation']),
      min: _toDouble(map['min']),
      max: _toDouble(map['max']),
      count: _toInt(map['count']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }
}

class PlayerMetricScore {
  final String metricKey;
  final double value;
  final double zScore;
  final double tScore;

  const PlayerMetricScore({
    required this.metricKey,
    required this.value,
    required this.zScore,
    required this.tScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'metricKey': metricKey,
      'value': value,
      'zScore': zScore,
      'tScore': tScore,
    };
  }

  factory PlayerMetricScore.fromMap(Map<String, dynamic> map) {
    return PlayerMetricScore(
      metricKey: (map['metricKey'] ?? '').toString(),
      value: _toDouble(map['value']),
      zScore: _toDouble(map['zScore']),
      tScore: _toDouble(map['tScore']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }
}

class TeamPlayerMetricScores {
  final String playerId;
  final String trackerId;
  final Map<String, PlayerMetricScore> metrics;

  const TeamPlayerMetricScores({
    required this.playerId,
    required this.trackerId,
    required this.metrics,
  });

  PlayerMetricScore? getMetric(String metricKey) {
    return metrics[metricKey];
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'trackerId': trackerId,
      'metrics': metrics.map(
            (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  factory TeamPlayerMetricScores.fromMap(Map<String, dynamic> map) {
    final rawMetrics = _toMap(map['metrics']);

    return TeamPlayerMetricScores(
      playerId: (map['playerId'] ?? '').toString(),
      trackerId: (map['trackerId'] ?? '').toString(),
      metrics: rawMetrics.map(
            (key, value) => MapEntry(
          key,
          PlayerMetricScore.fromMap(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }
}

class TeamWorkloadSummary {
  final String eventId;

  final double totalWorkloadScore;
  final double averageWorkloadScore;
  final double teamWorkloadPerMinute;
  final double averagePlayerWorkloadPerMinute;
  final int playersCount;

  final Duration sessionDuration;

  final Map<String, TeamMetricStat> metricStats;
  final List<TeamPlayerMetricScores> playerScores;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TeamWorkloadSummary({
    required this.eventId,
    required this.totalWorkloadScore,
    required this.averageWorkloadScore,
    required this.teamWorkloadPerMinute,
    required this.averagePlayerWorkloadPerMinute,
    required this.playersCount,
    required this.sessionDuration,
    required this.metricStats,
    required this.playerScores,
    this.createdAt,
    this.updatedAt,
  });

  factory TeamWorkloadSummary.fromPlayerResults({
    required String eventId,
    required List<TrackerAnalysisResult> playerResults,
    Duration? sessionDuration,
  }) {
    final validResults = playerResults.where((r) {
      return r.samplesCount > 0 && r.duration.inMilliseconds > 0;
    }).toList();

    final playersCount = validResults.length;

    final totalWorkloadScore = validResults.fold<double>(
      0.0,
          (sum, r) => sum + r.workloadScore,
    );


    final averageWorkloadScore = playersCount > 0
        ? totalWorkloadScore / playersCount
        : 0.0;

    final resolvedSessionDuration =
        sessionDuration ?? _maxDuration(validResults);

    final sessionMinutes =
        resolvedSessionDuration.inMilliseconds / 60000.0;

    final teamWorkloadPerMinute = sessionMinutes > 0
        ? totalWorkloadScore / sessionMinutes
        : 0.0;

    final averagePlayerWorkloadPerMinute = playersCount > 0
        ? validResults.fold<double>(
      0.0,
          (sum, r) => sum + _resolvePlayerWorkloadPerMinute(r),
    ) /
        playersCount
        : 0.0;

    final metricStats = <String, TeamMetricStat>{};

    for (final metricKey in TeamWorkloadMetricKeys.all) {
      final values = validResults.map((r) {
        return _extractMetricValue(r, metricKey);
      }).toList();

      metricStats[metricKey] = TeamMetricStat.fromValues(
        metricKey: metricKey,
        values: values,
      );
    }

    final playerScores = validResults.map((result) {
      final metrics = <String, PlayerMetricScore>{};

      for (final metricKey in TeamWorkloadMetricKeys.all) {
        final value = _extractMetricValue(result, metricKey);
        final stat = metricStats[metricKey]!;

        final zScore = stat.standardDeviation > 0
            ? (value - stat.mean) / stat.standardDeviation
            : 0.0;

        final tScore = 50.0 + (10.0 * zScore);

        metrics[metricKey] = PlayerMetricScore(
          metricKey: metricKey,
          value: value,
          zScore: zScore,
          tScore: tScore,
        );
      }

      return TeamPlayerMetricScores(
        playerId: result.playerId,
        trackerId: result.trackerId,
        metrics: metrics,
      );
    }).toList();

    return TeamWorkloadSummary(
      eventId: eventId,
      totalWorkloadScore: totalWorkloadScore,
      averageWorkloadScore: averageWorkloadScore,
      teamWorkloadPerMinute: teamWorkloadPerMinute,
      averagePlayerWorkloadPerMinute: averagePlayerWorkloadPerMinute,
      playersCount: playersCount,
      sessionDuration: resolvedSessionDuration,
      metricStats: metricStats,
      playerScores: playerScores,
    );
  }

  static double _extractMetricValue(
      TrackerAnalysisResult result,
      String metricKey,
      ) {
    switch (metricKey) {
      case TeamWorkloadMetricKeys.distanceKm:
        return _safeDouble(result.distanceKm);

      case TeamWorkloadMetricKeys.maxValidatedSpeedKmh:
        return _safeDouble(result.maxValidatedSpeedKmh);

      case TeamWorkloadMetricKeys.sprintCount:
        return result.sprintCount.toDouble();

      case TeamWorkloadMetricKeys.highAccelerationCount:
        return result.highAccelerationCount.toDouble();

      case TeamWorkloadMetricKeys.highSpeedDuration:
        return result.highSpeedDuration.inMilliseconds / 1000.0;

      case TeamWorkloadMetricKeys.maxAccelerationMps2:
        return _safeDouble(result.maxAccelerationMps2);

      case TeamWorkloadMetricKeys.workloadScore:
        return _safeDouble(result.workloadScore);

      case TeamWorkloadMetricKeys.workloadScorePerMinute:
        return _resolvePlayerWorkloadPerMinute(result);

      default:
        return 0.0;
    }
  }

  static double _resolvePlayerWorkloadPerMinute(
      TrackerAnalysisResult result,
      ) {
    if (result.workloadScorePerMinute.isFinite &&
        result.workloadScorePerMinute > 0) {
      return result.workloadScorePerMinute;
    }

    final minutes = result.duration.inMilliseconds / 60000.0;

    if (minutes <= 0) return 0.0;

    return result.workloadScore / minutes;
  }

  static Duration _maxDuration(List<TrackerAnalysisResult> results) {
    int maxMs = 0;

    for (final result in results) {
      if (result.duration.inMilliseconds > maxMs) {
        maxMs = result.duration.inMilliseconds;
      }
    }

    return Duration(milliseconds: maxMs);
  }

  static double _safeDouble(double value) {
    if (!value.isFinite) return 0.0;
    return value;
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'totalWorkloadScore': totalWorkloadScore,
      'averageWorkloadScore': averageWorkloadScore,
      'teamWorkloadPerMinute': teamWorkloadPerMinute,
      'averagePlayerWorkloadPerMinute': averagePlayerWorkloadPerMinute,
      'playersCount': playersCount,
      'sessionDurationMs': sessionDuration.inMilliseconds,
      'metricStats': metricStats.map(
            (key, value) => MapEntry(key, value.toMap()),
      ),
      'playerScores': playerScores.map((e) => e.toMap()).toList(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory TeamWorkloadSummary.fromMap(Map<String, dynamic> map) {
    final rawMetricStats = _toMap(map['metricStats']);

    final metricStats = rawMetricStats.map(
          (key, value) => MapEntry(
        key,
        TeamMetricStat.fromMap(
          Map<String, dynamic>.from(value as Map),
        ),
      ),
    );

    final rawPlayerScores = map['playerScores'] as List<dynamic>? ?? [];

    return TeamWorkloadSummary(
      eventId: (map['eventId'] ?? '').toString(),
      totalWorkloadScore: _toDouble(map['totalWorkloadScore']),
      averageWorkloadScore: _toDouble(map['averageWorkloadScore']),
      teamWorkloadPerMinute: _toDouble(map['teamWorkloadPerMinute']),
      averagePlayerWorkloadPerMinute:
      _toDouble(map['averagePlayerWorkloadPerMinute']),
      playersCount: _toInt(map['playersCount']),
      sessionDuration: Duration(
        milliseconds: _toInt(map['sessionDurationMs']),
      ),
      metricStats: metricStats,
      playerScores: rawPlayerScores.map((e) {
        return TeamPlayerMetricScores.fromMap(
          Map<String, dynamic>.from(e as Map),
        );
      }).toList(),
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  static Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}