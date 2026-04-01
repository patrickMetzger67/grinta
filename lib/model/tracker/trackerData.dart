import 'package:cloud_firestore/cloud_firestore.dart';

class TrackerRaw {
  final String? trackerId;
  final int timeMs;
  final double latitude;
  final double longitude;
  final double speedMps;
  final double? altitude;

  TrackerRaw({
    required this.trackerId,
    required this.timeMs,
    required this.latitude,
    required this.longitude,
    required this.speedMps,
    this.altitude,
  });

  factory TrackerRaw.fromMap(Map<String, dynamic> map) {
    return TrackerRaw(
      trackerId: map['trackerId']?.toString(),
      timeMs: _toInt(map['time [POSIXms]']),
      latitude: _toDouble(map['latitude [deg]']),
      longitude: _toDouble(map['longitude [deg]']),
      speedMps: _toDouble(map['speed [m/s]']),
      altitude: map['altitude [m]'] != null && map['altitude [m]'].toString().isNotEmpty
          ? _toDouble(map['altitude [m]'])
          : null,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.parse(v.toString());
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.parse(v.toString().replaceAll(',', '.'));
  }
}

class GpsPoint {
  final double lat;
  final double lng;

  const GpsPoint({
    required this.lat,
    required this.lng,
  });
}

class FootballFieldGps {
  final GpsPoint topLeft;
  final GpsPoint topRight;
  final GpsPoint bottomLeft;
  final double fieldLengthMeters;
  final double fieldWidthMeters;

  const FootballFieldGps({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    this.fieldLengthMeters = 105.0,
    this.fieldWidthMeters = 68.0,
  });
}

class HeatmapPoint {
  final double xMeters;
  final double yMeters;
  final int timeMs;
  final double intensity;

  const HeatmapPoint({
    required this.xMeters,
    required this.yMeters,
    required this.timeMs,
    required this.intensity,
  });
}

class FieldZoneStats {
  final String zoneId;
  final double distanceMeters;
  final int sampleCount;
  final double occupancyPercent;

  const FieldZoneStats({
    required this.zoneId,
    required this.distanceMeters,
    required this.sampleCount,
    required this.occupancyPercent,
  });

  Map<String, dynamic> toMap() {
    return {
      'zoneId': zoneId,
      'distanceMeters': distanceMeters,
      'sampleCount': sampleCount,
      'occupancyPercent': occupancyPercent,
    };
  }

  factory FieldZoneStats.fromMap(Map<String, dynamic> map) {
    return FieldZoneStats(
      zoneId: (map['zoneId'] ?? '').toString(),
      distanceMeters: _toDouble(map['distanceMeters']),
      sampleCount: _toInt(map['sampleCount']),
      occupancyPercent: _toDouble(map['occupancyPercent']),
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

class HalfStats {
  final int halfIndex;
  final double averageSpeedKmh;
  final double distanceKm;
  final Duration duration;

  const HalfStats({
    required this.halfIndex,
    required this.averageSpeedKmh,
    required this.distanceKm,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'halfIndex': halfIndex,
      'averageSpeedKmh': averageSpeedKmh,
      'distanceKm': distanceKm,
      'durationMs': duration.inMilliseconds,
    };
  }

  factory HalfStats.fromMap(Map<String, dynamic> map) {
    return HalfStats(
      halfIndex: _toInt(map['halfIndex']),
      averageSpeedKmh: _toDouble(map['averageSpeedKmh']),
      distanceKm: _toDouble(map['distanceKm']),
      duration: Duration(milliseconds: _toInt(map['durationMs'])),
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

class DistanceTimelineStat {
  final int bucketStartMs;
  final int bucketEndMs;
  final String label;

  final double walkingMeters; // < 7 km/h
  final double joggingMeters; // 7 - 13 km/h
  final double runningMeters; // 13 - 18 km/h
  final double highIntensityMeters; // >= 18 km/h

  const DistanceTimelineStat({
    required this.bucketStartMs,
    required this.bucketEndMs,
    required this.label,
    required this.walkingMeters,
    required this.joggingMeters,
    required this.runningMeters,
    required this.highIntensityMeters,
  });

  double get totalMeters =>
      walkingMeters + joggingMeters + runningMeters + highIntensityMeters;

  Map<String, dynamic> toMap() {
    return {
      'bucketStartMs': bucketStartMs,
      'bucketEndMs': bucketEndMs,
      'label': label,
      'walkingMeters': walkingMeters,
      'joggingMeters': joggingMeters,
      'runningMeters': runningMeters,
      'highIntensityMeters': highIntensityMeters,
      'totalMeters': totalMeters,
    };
  }

  factory DistanceTimelineStat.fromMap(Map<String, dynamic> map) {
    return DistanceTimelineStat(
      bucketStartMs: TrackerAnalysisResult._toInt(map['bucketStartMs']),
      bucketEndMs: TrackerAnalysisResult._toInt(map['bucketEndMs']),
      label: (map['label'] ?? '').toString(),
      walkingMeters: TrackerAnalysisResult._toDouble(map['walkingMeters']),
      joggingMeters: TrackerAnalysisResult._toDouble(map['joggingMeters']),
      runningMeters: TrackerAnalysisResult._toDouble(map['runningMeters']),
      highIntensityMeters:
      TrackerAnalysisResult._toDouble(map['highIntensityMeters']),
    );
  }
}


class TrackerAnalysisResult {
  final String trackerId;
  final String playerId;
  final double distanceKm;
  final Duration duration;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double maxValidatedSpeedKmh;
  final int samplesCount;

  // Attention: non sauvegardé en Firestore
  final List<HeatmapPoint> heatmapPoints;

  final int sprintCount;
  final int highAccelerationCount;
  final Duration timeAbove20Kmh;
  final double maxAccelerationMps2;
  final List<FieldZoneStats> distanceByZones;
  final List<SpeedZoneStat> speedZones;
  final List<HalfStats> halfStats;
  final double workloadScore;

  final String playerProfile;
  final double fatigueIndex;
  final double firstHalfDistanceKm;
  final double secondHalfDistanceKm;
  final List<DistanceTimelineStat> distanceTimeline;

  const TrackerAnalysisResult({
    required this.trackerId,
    required this.playerId,
    required this.distanceKm,
    required this.duration,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.maxValidatedSpeedKmh,
    required this.samplesCount,
    required this.heatmapPoints,
    required this.sprintCount,
    required this.highAccelerationCount,
    required this.timeAbove20Kmh,
    required this.maxAccelerationMps2,
    required this.distanceByZones,
    required this.speedZones,
    required this.halfStats,
    required this.workloadScore,
    required this.playerProfile,
    required this.fatigueIndex,
    required this.firstHalfDistanceKm,
    required this.secondHalfDistanceKm,
    required this.distanceTimeline,
  });

  Map<String, dynamic> toMap({
    String? eventId,
    DateTime? createdAt,
  }) {
    return {
      'trackerId': trackerId,
      'playerId': playerId,
      'distanceKm': distanceKm,
      'durationMs': duration.inMilliseconds,
      'averageSpeedKmh': averageSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'maxValidatedSpeedKmh': maxValidatedSpeedKmh,
      'samplesCount': samplesCount,
      // heatmapPoints volontairement exclus
      'sprintCount': sprintCount,
      'highAccelerationCount': highAccelerationCount,
      'timeAbove20KmhMs': timeAbove20Kmh.inMilliseconds,
      'maxAccelerationMps2': maxAccelerationMps2,
      'distanceByZones': distanceByZones.map((e) => e.toMap()).toList(),
      'speedZones': speedZones.map((e) => e.toMap()).toList(),
      'halfStats': halfStats.map((e) => e.toMap()).toList(),
      'workloadScore': workloadScore,
      'playerProfile': playerProfile,
      'fatigueIndex': fatigueIndex,
      'firstHalfDistanceKm': firstHalfDistanceKm,
      'secondHalfDistanceKm': secondHalfDistanceKm,
      'distanceTimeline': distanceTimeline.map((e) => e.toMap()).toList(),
      'eventId': eventId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt) : FieldValue.serverTimestamp(),
    };
  }

  factory TrackerAnalysisResult.fromMap(Map<String, dynamic> map) {
    return TrackerAnalysisResult(
      trackerId: (map['trackerId'] ?? '').toString(),
      playerId: (map['playerId'] ?? '').toString(),
      distanceKm: _toDouble(map['distanceKm']),
      duration: Duration(milliseconds: _toInt(map['durationMs'])),
      averageSpeedKmh: _toDouble(map['averageSpeedKmh']),
      maxSpeedKmh: _toDouble(map['maxSpeedKmh']),
      maxValidatedSpeedKmh: _toDouble(map['maxValidatedSpeedKmh']),
      samplesCount: _toInt(map['samplesCount']),
      heatmapPoints: const [],
      sprintCount: _toInt(map['sprintCount']),
      highAccelerationCount: _toInt(map['highAccelerationCount']),
      timeAbove20Kmh: Duration(milliseconds: _toInt(map['timeAbove20KmhMs'])),
      maxAccelerationMps2: _toDouble(map['maxAccelerationMps2']),
      distanceByZones: (map['distanceByZones'] as List<dynamic>? ?? [])
          .map((e) => FieldZoneStats.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      speedZones: (map['speedZones'] as List<dynamic>? ?? [])
          .map((e) => SpeedZoneStat.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      halfStats: (map['halfStats'] as List<dynamic>? ?? [])
          .map((e) => HalfStats.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      workloadScore: _toDouble(map['workloadScore']),
      playerProfile: (map['playerProfile'] ?? '').toString(),
      fatigueIndex: _toDouble(map['fatigueIndex']),
      firstHalfDistanceKm: _toDouble(map['firstHalfDistanceKm']),
      secondHalfDistanceKm: _toDouble(map['secondHalfDistanceKm']),
      distanceTimeline: (map['distanceTimeline'] as List<dynamic>? ?? [])
          .map((e) => DistanceTimelineStat.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
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
class SpeedZoneStat {
  final String zoneId;
  final Duration duration;
  final double percentOfSession;

  const SpeedZoneStat({
    required this.zoneId,
    required this.duration,
    required this.percentOfSession,
  });

  Map<String, dynamic> toMap() {
    return {
      'zoneId': zoneId,
      'durationMs': duration.inMilliseconds,
      'percentOfSession': percentOfSession,
    };
  }

  factory SpeedZoneStat.fromMap(Map<String, dynamic> map) {
    return SpeedZoneStat(
      zoneId: (map['zoneId'] ?? '').toString(),
      duration: Duration(milliseconds: _toInt(map['durationMs'])),
      percentOfSession: _toDouble(map['percentOfSession']),
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



class TimelinePoint {
  final double timeSec;
  final double speedKmh;
  final double accelerationMps2;
  final bool isSprint;

  const TimelinePoint({
    required this.timeSec,
    required this.speedKmh,
    required this.accelerationMps2,
    required this.isSprint,
  });
}