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
}

class HalfStats {
  final int halfIndex; // 1 ou 2
  final double averageSpeedKmh;
  final double distanceKm;
  final Duration duration;

  const HalfStats({
    required this.halfIndex,
    required this.averageSpeedKmh,
    required this.distanceKm,
    required this.duration,
  });
}

class TrackerAnalysisResult {
  final String trackerId;
  final double distanceKm;
  final Duration duration;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final int samplesCount;
  final List<HeatmapPoint> heatmapPoints;

  final int sprintCount;
  final Duration timeAbove20Kmh;
  final double maxAccelerationMps2;
  final List<FieldZoneStats> distanceByZones;
  final List<HalfStats> halfStats;
  final double workloadScore;

  const TrackerAnalysisResult({
    required this.trackerId,
    required this.distanceKm,
    required this.duration,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.samplesCount,
    required this.heatmapPoints,
    required this.sprintCount,
    required this.timeAbove20Kmh,
    required this.maxAccelerationMps2,
    required this.distanceByZones,
    required this.halfStats,
    required this.workloadScore,
  });
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