import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../fieldGpsCorners.dart';

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
      altitude: map['altitude [m]'] != null &&
          map['altitude [m]'].toString().isNotEmpty
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

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }

  factory GpsPoint.fromMap(Map<String, dynamic> map) {
    return GpsPoint(
      lat: _toDouble(map['lat']),
      lng: _toDouble(map['lng']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }
}

class FootballFieldGps {
  final FieldCornerGps topLeft;
  final FieldCornerGps topRight;
  final FieldCornerGps bottomLeft;
  final FieldCornerGps bottomRight;

  final double fieldLengthMeters;
  final double fieldWidthMeters;

  const FootballFieldGps({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.fieldLengthMeters,
    required this.fieldWidthMeters,
  });

  factory FootballFieldGps.fromMap(Map<String, dynamic> map) {
    return FootballFieldGps(
      topLeft: _pointFromMap(map['topLeft']),
      topRight: _pointFromMap(map['topRight']),
      bottomLeft: _pointFromMap(map['bottomLeft']),
      bottomRight: _pointFromMap(map['bottomRight']),
      fieldLengthMeters: (map['fieldLengthMeters'] as num).toDouble(),
      fieldWidthMeters: (map['fieldWidthMeters'] as num).toDouble(),
    );
  }

  static FieldCornerGps _pointFromMap(Map<String, dynamic> m) {
    return FieldCornerGps(
      latitude: (m['latitude'] as num).toDouble(),
      longitude: (m['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topLeft': _pointToMap(topLeft),
      'topRight': _pointToMap(topRight),
      'bottomLeft': _pointToMap(bottomLeft),
      'bottomRight': _pointToMap(bottomRight),
      'fieldLengthMeters': fieldLengthMeters,
      'fieldWidthMeters': fieldWidthMeters,
    };
  }

  Map<String, dynamic> _pointToMap(FieldCornerGps p) {
    return {
      'latitude': p.latitude,
      'longitude': p.longitude,
    };
  }

  factory FootballFieldGps.fromFieldGpsCorners(FieldGpsCorners corners) {
    if (corners.topLeft == null ||
        corners.topRight == null ||
        corners.bottomLeft == null ||
        corners.bottomRight == null) {
      throw Exception(
        'Impossible de construire FootballFieldGps : les 4 coins GPS sont requis.',
      );
    }

    final rawPoints = <FieldCornerGps>[
      corners.topLeft!,
      corners.topRight!,
      corners.bottomLeft!,
      corners.bottomRight!,
    ];

    debugPrint('--- RAW CORNERS ---');
    debugPrint(
        'raw topLeft=${corners.topLeft!.latitude}, ${corners.topLeft!.longitude}');
    debugPrint(
        'raw topRight=${corners.topRight!.latitude}, ${corners.topRight!.longitude}');
    debugPrint(
        'raw bottomLeft=${corners.bottomLeft!.latitude}, ${corners.bottomLeft!.longitude}');
    debugPrint(
        'raw bottomRight=${corners.bottomRight!.latitude}, ${corners.bottomRight!.longitude}');

    final ordered = _buildCanonicalCorners(rawPoints);
    if (ordered == null || ordered.length != 4) {
      throw Exception(
        'Impossible de construire FootballFieldGps : ordre des coins introuvable.',
      );
    }

    final tl = ordered[0];
    final tr = ordered[1];
    final br = ordered[2];
    final bl = ordered[3];

    debugPrint('--- ORDERED CORNERS ---');
    debugPrint('tl=${tl.latitude}, ${tl.longitude}');
    debugPrint('tr=${tr.latitude}, ${tr.longitude}');
    debugPrint('br=${br.latitude}, ${br.longitude}');
    debugPrint('bl=${bl.latitude}, ${bl.longitude}');

    final topWidth = _distanceMeters(tl, tr);
    final bottomWidth = _distanceMeters(bl, br);
    final leftLength = _distanceMeters(tl, bl);
    final rightLength = _distanceMeters(tr, br);

    final diagonal1 = _distanceMeters(tl, br);
    final diagonal2 = _distanceMeters(tr, bl);

    final avgHorizontal = (topWidth + bottomWidth) / 2.0;
    final avgVertical = (leftLength + rightLength) / 2.0;

    final avgLength = math.max(avgHorizontal, avgVertical);
    final avgWidth = math.min(avgHorizontal, avgVertical);

    final topBottomDiffRatio = _relativeDifference(topWidth, bottomWidth);
    final leftRightDiffRatio = _relativeDifference(leftLength, rightLength);
    final diagonalDiffRatio = _relativeDifference(diagonal1, diagonal2);

    const maxOppositeSideDifferenceRatio = 0.20;
    const maxDiagonalDifferenceRatio = 0.20;

    const minFootball11Length = 90.0;
    const maxFootball11Length = 120.0;
    const minFootball11Width = 45.0;
    const maxFootball11Width = 90.0;

    final oppositeSidesOk =
        topBottomDiffRatio <= maxOppositeSideDifferenceRatio &&
            leftRightDiffRatio <= maxOppositeSideDifferenceRatio;

    final diagonalsOk = diagonalDiffRatio <= maxDiagonalDifferenceRatio;

    final football11SizeOk =
        avgLength >= minFootball11Length &&
            avgLength <= maxFootball11Length &&
            avgWidth >= minFootball11Width &&
            avgWidth <= maxFootball11Width;

    if (!oppositeSidesOk || !diagonalsOk || !football11SizeOk) {
      print('dans FootballFieldGps.fromFieldGpsCorners');
      print('ordered tl=${tl.latitude}, ${tl.longitude}');
      print('ordered tr=${tr.latitude}, ${tr.longitude}');
      print('ordered br=${br.latitude}, ${br.longitude}');
      print('ordered bl=${bl.latitude}, ${bl.longitude}');
      print('topWidth=$topWidth');
      print('bottomWidth=$bottomWidth');
      print('leftLength=$leftLength');
      print('rightLength=$rightLength');
      print('diagonal1=$diagonal1');
      print('diagonal2=$diagonal2');
      print('avgLength=$avgLength');
      print('avgWidth=$avgWidth');
      print('topBottomDiffRatio=$topBottomDiffRatio');
      print('leftRightDiffRatio=$leftRightDiffRatio');
      print('diagonalDiffRatio=$diagonalDiffRatio');

      final reasons = <String>[];

      if (!oppositeSidesOk) {
        reasons.add(
          'côtés opposés trop différents '
              '(haut=${topWidth.toStringAsFixed(2)}m, bas=${bottomWidth.toStringAsFixed(2)}m, '
              'gauche=${leftLength.toStringAsFixed(2)}m, droite=${rightLength.toStringAsFixed(2)}m)',
        );
        print(
        'côtés opposés trop différents '
            '(haut=${topWidth.toStringAsFixed(2)}m, bas=${bottomWidth.toStringAsFixed(2)}m, '
            'gauche=${leftLength.toStringAsFixed(2)}m, droite=${rightLength.toStringAsFixed(2)}m)',
        );
      }

      if (!diagonalsOk) {
        reasons.add(
          'diagonales trop différentes '
              '(${diagonal1.toStringAsFixed(2)}m vs ${diagonal2.toStringAsFixed(2)}m)',
        );
        print('diagonales trop différentes '
            '(${diagonal1.toStringAsFixed(2)}m vs ${diagonal2.toStringAsFixed(2)}m)');
      }

      if (!football11SizeOk) {
        reasons.add(
          'taille incompatible avec un terrain à 11 '
              '(longueur=${avgLength.toStringAsFixed(2)}m, largeur=${avgWidth.toStringAsFixed(2)}m)',
        );
        print('taille incompatible avec un terrain à 11 '
            '(longueur=${avgLength.toStringAsFixed(2)}m, largeur=${avgWidth.toStringAsFixed(2)}m)');
      }

      print('Impossible de construire FootballFieldGps : la géométrie du terrain est incohérente. ${reasons.join(' ; ')}.');
      throw Exception(
        'Impossible de construire FootballFieldGps : la géométrie du terrain est incohérente. ${reasons.join(' ; ')}.',
      );
    }

    return FootballFieldGps(
      topLeft: tl,
      topRight: tr,
      bottomLeft: bl,
      bottomRight: br,
      fieldLengthMeters: avgLength,
      fieldWidthMeters: avgWidth,
    );
  }

  static List<FieldCornerGps>? _buildCanonicalCorners(
      List<FieldCornerGps> points,
      ) {
    if (points.length != 4) return null;

    final centerLat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / 4.0;
    final centerLng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / 4.0;

    final sorted = [...points];
    sorted.sort((a, b) {
      final angleA = math.atan2(a.latitude - centerLat, a.longitude - centerLng);
      final angleB = math.atan2(b.latitude - centerLat, b.longitude - centerLng);
      return angleA.compareTo(angleB);
    });

    if (!_isClockwise(sorted)) {
      final reversed = [sorted[0], sorted[3], sorted[2], sorted[1]];
      sorted
        ..clear()
        ..addAll(reversed);
    }

    int topLeftIndex = 0;
    for (int i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final best = sorted[topLeftIndex];

      final isMoreNorth = current.latitude > best.latitude;
      final sameNorth = (current.latitude - best.latitude).abs() < 1e-10;
      final isMoreWest = current.longitude < best.longitude;

      if (isMoreNorth || (sameNorth && isMoreWest)) {
        topLeftIndex = i;
      }
    }

    final rotated = [
      sorted[topLeftIndex],
      sorted[(topLeftIndex + 1) % 4],
      sorted[(topLeftIndex + 2) % 4],
      sorted[(topLeftIndex + 3) % 4],
    ];

    if (rotated[1].longitude < rotated[3].longitude) {
      return [
        rotated[0],
        rotated[3],
        rotated[2],
        rotated[1],
      ];
    }

    return rotated;
  }

  Offset gpsToPitchMeters(FieldCornerGps gps) {
    final vTop = _gpsDeltaMeters(topLeft, topRight);
    final vBottom = _gpsDeltaMeters(bottomLeft, bottomRight);
    final vLeft = _gpsDeltaMeters(topLeft, bottomLeft);
    final vRight = _gpsDeltaMeters(topRight, bottomRight);

    final avgHorizontal = (vTop.distance + vBottom.distance) / 2.0;
    final avgVertical = (vLeft.distance + vRight.distance) / 2.0;

    late Offset rawLengthAxis;
    late Offset rawWidthAxis;

    if (avgHorizontal >= avgVertical) {
      rawLengthAxis = _normalize(vTop + vBottom);
      rawWidthAxis = _normalize(vLeft + vRight);

      if (_dot(rawLengthAxis, vTop) < 0) {
        rawLengthAxis = -rawLengthAxis;
      }
      if (_dot(rawWidthAxis, vLeft) < 0) {
        rawWidthAxis = -rawWidthAxis;
      }
    } else {
      rawLengthAxis = _normalize(vLeft + vRight);
      rawWidthAxis = _normalize(vTop + vBottom);

      if (_dot(rawLengthAxis, vLeft) < 0) {
        rawLengthAxis = -rawLengthAxis;
      }
      if (_dot(rawWidthAxis, vTop) < 0) {
        rawWidthAxis = -rawWidthAxis;
      }
    }

    final lengthAxis = _normalize(rawLengthAxis);

    var widthAxis = rawWidthAxis - lengthAxis * _dot(rawWidthAxis, lengthAxis);
    if (widthAxis.distance < 1e-6) {
      widthAxis = Offset(-lengthAxis.dy, lengthAxis.dx);
    }
    widthAxis = _normalize(widthAxis);

    final corners = [topLeft, topRight, bottomRight, bottomLeft];
    final projectedCorners = corners.map((p) {
      final v = _gpsDeltaMeters(topLeft, p);
      return Offset(
        _dot(v, lengthAxis),
        _dot(v, widthAxis),
      );
    }).toList();

    final minX = projectedCorners.map((e) => e.dx).reduce(math.min);
    final minY = projectedCorners.map((e) => e.dy).reduce(math.min);

    final v = _gpsDeltaMeters(topLeft, gps);

    final x = _dot(v, lengthAxis) - minX;
    final y = _dot(v, widthAxis) - minY;

    return Offset(x, y);
  }

  List<Offset> cornersToPitchMeters() {
    return [
      gpsToPitchMeters(topLeft),
      gpsToPitchMeters(topRight),
      gpsToPitchMeters(bottomRight),
      gpsToPitchMeters(bottomLeft),
    ];
  }

  static List<FieldCornerGps>? _orderCornersClockwise(
      List<FieldCornerGps> points,
      ) {
    if (points.length != 4) return null;

    final centerLat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / 4.0;
    final centerLng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / 4.0;

    final sorted = [...points];

    sorted.sort((a, b) {
      final angleA = math.atan2(a.latitude - centerLat, a.longitude - centerLng);
      final angleB = math.atan2(b.latitude - centerLat, b.longitude - centerLng);
      return angleA.compareTo(angleB);
    });

    if (!_isClockwise(sorted)) {
      final reversed = [sorted[0], sorted[3], sorted[2], sorted[1]];
      sorted
        ..clear()
        ..addAll(reversed);
    }

    int topLeftIndex = 0;
    for (int i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final best = sorted[topLeftIndex];

      final isMoreNorth = current.latitude > best.latitude;
      final sameNorth = (current.latitude - best.latitude).abs() < 1e-10;
      final isMoreWest = current.longitude < best.longitude;

      if (isMoreNorth || (sameNorth && isMoreWest)) {
        topLeftIndex = i;
      }
    }

    final rotated = [
      sorted[topLeftIndex],
      sorted[(topLeftIndex + 1) % 4],
      sorted[(topLeftIndex + 2) % 4],
      sorted[(topLeftIndex + 3) % 4],
    ];

    if (rotated[1].longitude < rotated[3].longitude) {
      return [
        rotated[0],
        rotated[3],
        rotated[2],
        rotated[1],
      ];
    }

    return rotated;
  }

  static bool _isClockwise(List<FieldCornerGps> points) {
    if (points.length != 4) return false;

    double sum = 0.0;
    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      sum +=
          (next.longitude - current.longitude) * (next.latitude + current.latitude);
    }

    return sum > 0;
  }

  static double _distanceMeters(FieldCornerGps a, FieldCornerGps b) {
    const earthRadius = 6371000.0;

    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(lat1) *
                math.cos(lat2) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadius * c;
  }

  static double _relativeDifference(double a, double b) {
    final maxValue = math.max(a, b);
    if (maxValue == 0) return 0.0;
    return (a - b).abs() / maxValue;
  }

  static Offset _gpsDeltaMeters(FieldCornerGps origin, FieldCornerGps target) {
    const earthRadius = 6371000.0;

    final lat1 = origin.latitude * math.pi / 180.0;
    final lat2 = target.latitude * math.pi / 180.0;
    final lon1 = origin.longitude * math.pi / 180.0;
    final lon2 = target.longitude * math.pi / 180.0;

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    final meanLat = (lat1 + lat2) / 2.0;

    final north = dLat * earthRadius;
    final east = dLon * earthRadius * math.cos(meanLat);

    return Offset(east, north);
  }

  static double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

  static Offset _normalize(Offset v) {
    final d = v.distance;
    if (d < 1e-9) return Offset.zero;
    return v / d;
  }
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

  final double walkingMeters;
  final double joggingMeters;
  final double runningMeters;
  final double highIntensityMeters;

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
  final String eventId;
  final double distanceKm;
  final Duration duration;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double maxValidatedSpeedKmh;
  final int samplesCount;

  // Non sauvegardé en Firestore
  final List<HeatmapPoint> heatmapPoints;

  // Nullable : null possible pour un entraînement
  final FootballFieldGps? fieldGps;

  final int sprintCount;
  final int highAccelerationCount;
  final Duration highSpeedDuration;
  final double maxAccelerationMps2;
  final List<FieldZoneStats> distanceByZones;
  final List<SpeedZoneStat> speedZones;
  final List<HalfStats> halfStats;
  final double workloadScore;
  final double workloadScorePerMinute;

  final String playerProfile;
  final double fatigueIndex;
  final double firstHalfDistanceKm;
  final double secondHalfDistanceKm;
  final List<DistanceTimelineStat> distanceTimeline;

  const TrackerAnalysisResult({
    required this.trackerId,
    required this.playerId,
    required this.eventId,
    required this.distanceKm,
    required this.duration,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.maxValidatedSpeedKmh,
    required this.samplesCount,
    required this.heatmapPoints,
    this.fieldGps,
    required this.sprintCount,
    required this.highAccelerationCount,
    required this.highSpeedDuration,
    required this.maxAccelerationMps2,
    required this.distanceByZones,
    required this.speedZones,
    required this.halfStats,
    required this.workloadScore,
    required this.workloadScorePerMinute,
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
      'eventId': eventId,
      'distanceKm': distanceKm,
      'durationMs': duration.inMilliseconds,
      'averageSpeedKmh': averageSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'maxValidatedSpeedKmh': maxValidatedSpeedKmh,
      'samplesCount': samplesCount,
      // heatmapPoints volontairement exclus
      'fieldGps': fieldGps?.toMap(),
      'sprintCount': sprintCount,
      'highAccelerationCount': highAccelerationCount,
      'highSpeedDuration': highSpeedDuration.inMilliseconds,
      'maxAccelerationMps2': maxAccelerationMps2,
      'distanceByZones': distanceByZones.map((e) => e.toMap()).toList(),
      'speedZones': speedZones.map((e) => e.toMap()).toList(),
      'halfStats': halfStats.map((e) => e.toMap()).toList(),
      'workloadScore': workloadScore,
      'workloadScorePerMinute': workloadScorePerMinute,
      'playerProfile': playerProfile,
      'fatigueIndex': fatigueIndex,
      'firstHalfDistanceKm': firstHalfDistanceKm,
      'secondHalfDistanceKm': secondHalfDistanceKm,
      'distanceTimeline': distanceTimeline.map((e) => e.toMap()).toList(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt)
          : FieldValue.serverTimestamp(),
    };
  }

  factory TrackerAnalysisResult.fromMap(Map<String, dynamic> map) {
    return TrackerAnalysisResult(
      trackerId: (map['trackerId'] ?? '').toString(),
      playerId: (map['playerId'] ?? '').toString(),
      eventId: (map['eventId'] ?? '').toString(),
      distanceKm: _toDouble(map['distanceKm']),
      duration: Duration(milliseconds: _toInt(map['durationMs'])),
      averageSpeedKmh: _toDouble(map['averageSpeedKmh']),
      maxSpeedKmh: _toDouble(map['maxSpeedKmh']),
      maxValidatedSpeedKmh: _toDouble(map['maxValidatedSpeedKmh']),
      samplesCount: _toInt(map['samplesCount']),
      heatmapPoints: const [],
      fieldGps: map['fieldGps'] != null
          ? FootballFieldGps.fromMap(
        Map<String, dynamic>.from(map['fieldGps'] as Map),
      )
          : null,
      sprintCount: _toInt(map['sprintCount']),
      highAccelerationCount: _toInt(map['highAccelerationCount']),
      highSpeedDuration: Duration(milliseconds: _toInt(map['highSpeedDuration'])),
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
      workloadScorePerMinute: _toDouble(map['workloadScorePerMinute']),
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

class MatchHeatmapSplit {
  final List<HeatmapPoint> firstHalfPoints;
  final List<HeatmapPoint> secondHalfPoints;

  const MatchHeatmapSplit({
    required this.firstHalfPoints,
    required this.secondHalfPoints,
  });
}

class HeatmapTimeSplitter {
  static MatchHeatmapSplit splitByHalves(List<HeatmapPoint> points) {
    if (points.isEmpty) {
      return const MatchHeatmapSplit(
        firstHalfPoints: [],
        secondHalfPoints: [],
      );
    }

    final sorted = [...points]..sort((a, b) => a.timeMs.compareTo(b.timeMs));

    final startTime = sorted.first.timeMs;
    final endTime = sorted.last.timeMs;
    final midTime = startTime + ((endTime - startTime) ~/ 2);

    final firstHalf = <HeatmapPoint>[];
    final secondHalf = <HeatmapPoint>[];

    for (final p in sorted) {
      if (p.timeMs <= midTime) {
        firstHalf.add(p);
      } else {
        secondHalf.add(p);
      }
    }

    return MatchHeatmapSplit(
      firstHalfPoints: firstHalf,
      secondHalfPoints: secondHalf,
    );
  }
}