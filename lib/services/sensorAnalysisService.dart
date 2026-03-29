import 'dart:math';

import '../model/tracker/trackerData.dart';

class SensorAnalysisService {
  /// Paramètres ajustables
  static const double sprintThresholdKmh = 20.0;
  static const double sprintThresholdMps = sprintThresholdKmh / 3.6;

  /// Une accélération forte > 2 m/s² est déjà très significative
  static const double minSprintAccelerationMps2 = 2.0;

  /// Évite les gros sauts GPS aberrants
  static const double maxAcceptedStepDistanceMeters = 50.0;

  /// Si la fréquence est irrégulière on utilise le delta temps réel
  static TrackerAnalysisResult analyzeSensorData({
    required String trackerId,
    required List<TrackerRaw> allSamples,
    required bool isMatch,
    FootballFieldGps? fieldGps,
  }) {
    final samples = allSamples.where((s) {
      if (s.trackerId == null || s.trackerId!.isEmpty) return true;
      return s.trackerId == trackerId;
    }).toList()
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));

    if (samples.isEmpty) {
      return TrackerAnalysisResult(
        trackerId: trackerId,
        distanceKm: 0,
        duration: Duration.zero,
        averageSpeedKmh: 0,
        maxSpeedKmh: 0,
        samplesCount: 0,
        heatmapPoints: const [],
        sprintCount: 0,
        timeAbove20Kmh: Duration.zero,
        maxAccelerationMps2: 0,
        distanceByZones: const [],
        halfStats: const [],
        workloadScore: 0,
      );
    }

    final List<HeatmapPoint> heatmapPoints = [];
    final Map<String, double> zoneDistanceMeters = {};
    final Map<String, int> zoneSamples = {};

    double totalDistanceMeters = 0;
    double speedSumMps = 0;
    double maxSpeedMps = 0;
    double maxAccelerationMps2 = 0;
    int sprintCount = 0;
    int timeAbove20Ms = 0;

    bool inSprint = false;

    final startMs = samples.first.timeMs;
    final endMs = samples.last.timeMs;
    final totalDurationMs = max(0, endMs - startMs);

    for (int i = 0; i < samples.length; i++) {
      final current = samples[i];
      speedSumMps += current.speedMps;
      maxSpeedMps = max(maxSpeedMps, current.speedMps);

      if (i > 0) {
        final prev = samples[i - 1];
        final dtMs = current.timeMs - prev.timeMs;

        if (dtMs <= 0) continue;

        final dtSec = dtMs / 1000.0;

        final rawDistance = _haversineMeters(
          prev.latitude,
          prev.longitude,
          current.latitude,
          current.longitude,
        );

        final stepDistance =
        rawDistance <= maxAcceptedStepDistanceMeters ? rawDistance : 0.0;

        totalDistanceMeters += stepDistance;

        final avgStepSpeed = (prev.speedMps + current.speedMps) / 2.0;

        if (avgStepSpeed >= sprintThresholdMps) {
          timeAbove20Ms += dtMs;
        }

        final acceleration = (current.speedMps - prev.speedMps) / dtSec;
        if (acceleration > maxAccelerationMps2) {
          maxAccelerationMps2 = acceleration;
        }

        final isSprintNow = current.speedMps >= sprintThresholdMps &&
            acceleration >= minSprintAccelerationMps2;

        if (isSprintNow && !inSprint) {
          sprintCount++;
          inSprint = true;
        } else if (current.speedMps < sprintThresholdMps * 0.9) {
          inSprint = false;
        }

        if (isMatch && fieldGps != null) {
          final projectedCurrent = _projectGpsToField(
            latitude: current.latitude,
            longitude: current.longitude,
            field: fieldGps,
          );

          if (projectedCurrent != null) {
            heatmapPoints.add(
              HeatmapPoint(
                xMeters: projectedCurrent.$1,
                yMeters: projectedCurrent.$2,
                timeMs: current.timeMs,
                intensity: max(0.2, current.speedMps),
              ),
            );

            final zoneId = _computeZoneId(
              xMeters: projectedCurrent.$1,
              yMeters: projectedCurrent.$2,
              fieldLengthMeters: fieldGps.fieldLengthMeters,
              fieldWidthMeters: fieldGps.fieldWidthMeters,
            );

            zoneDistanceMeters[zoneId] =
                (zoneDistanceMeters[zoneId] ?? 0) + stepDistance;
            zoneSamples[zoneId] = (zoneSamples[zoneId] ?? 0) + 1;
          }
        }
      } else {
        if (isMatch && fieldGps != null) {
          final projectedCurrent = _projectGpsToField(
            latitude: current.latitude,
            longitude: current.longitude,
            field: fieldGps,
          );

          if (projectedCurrent != null) {
            heatmapPoints.add(
              HeatmapPoint(
                xMeters: projectedCurrent.$1,
                yMeters: projectedCurrent.$2,
                timeMs: current.timeMs,
                intensity: max(0.2, current.speedMps),
              ),
            );

            final zoneId = _computeZoneId(
              xMeters: projectedCurrent.$1,
              yMeters: projectedCurrent.$2,
              fieldLengthMeters: fieldGps.fieldLengthMeters,
              fieldWidthMeters: fieldGps.fieldWidthMeters,
            );

            zoneSamples[zoneId] = (zoneSamples[zoneId] ?? 0) + 1;
          }
        }
      }
    }

    final averageSpeedMps = samples.isNotEmpty ? speedSumMps / samples.length : 0.0;

    final halfStats = _computeHalfStats(samples);

    final distanceByZones = zoneSamples.keys.map((zoneId) {
      final count = zoneSamples[zoneId] ?? 0;
      final percent = samples.isEmpty ? 0.0 : (count / samples.length) * 100.0;
      return FieldZoneStats(
        zoneId: zoneId,
        distanceMeters: zoneDistanceMeters[zoneId] ?? 0.0,
        sampleCount: count,
        occupancyPercent: percent,
      );
    }).toList()
      ..sort((a, b) => a.zoneId.compareTo(b.zoneId));

    final workloadScore = _computeWorkloadScore(
      distanceMeters: totalDistanceMeters,
      timeAbove20Ms: timeAbove20Ms,
      sprintCount: sprintCount,
      maxAccelerationMps2: maxAccelerationMps2,
    );

    return TrackerAnalysisResult(
      trackerId: trackerId,
      distanceKm: totalDistanceMeters / 1000.0,
      duration: Duration(milliseconds: totalDurationMs),
      averageSpeedKmh: averageSpeedMps * 3.6,
      maxSpeedKmh: maxSpeedMps * 3.6,
      samplesCount: samples.length,
      heatmapPoints: heatmapPoints,
      sprintCount: sprintCount,
      timeAbove20Kmh: Duration(milliseconds: timeAbove20Ms),
      maxAccelerationMps2: maxAccelerationMps2,
      distanceByZones: distanceByZones,
      halfStats: halfStats,
      workloadScore: workloadScore,
    );
  }

  static List<HalfStats> _computeHalfStats(List<TrackerRaw> samples) {
    if (samples.length < 2) return const [];

    final startMs = samples.first.timeMs;
    final endMs = samples.last.timeMs;
    final totalMs = endMs - startMs;

    if (totalMs <= 0) return const [];

    final midMs = startMs + (totalMs ~/ 2);

    final firstHalf = samples.where((s) => s.timeMs <= midMs).toList();
    final secondHalf = samples.where((s) => s.timeMs > midMs).toList();

    final result = <HalfStats>[];

    if (firstHalf.length >= 2) {
      result.add(_buildHalfStats(1, firstHalf));
    }
    if (secondHalf.length >= 2) {
      result.add(_buildHalfStats(2, secondHalf));
    }

    return result;
  }

  static HalfStats _buildHalfStats(int halfIndex, List<TrackerRaw> samples) {
    double speedSumMps = 0;
    double distanceMeters = 0;

    for (int i = 0; i < samples.length; i++) {
      speedSumMps += samples[i].speedMps;

      if (i > 0) {
        final d = _haversineMeters(
          samples[i - 1].latitude,
          samples[i - 1].longitude,
          samples[i].latitude,
          samples[i].longitude,
        );

        if (d <= maxAcceptedStepDistanceMeters) {
          distanceMeters += d;
        }
      }
    }

    final averageSpeedMps = speedSumMps / samples.length;
    final durationMs = samples.last.timeMs - samples.first.timeMs;

    return HalfStats(
      halfIndex: halfIndex,
      averageSpeedKmh: averageSpeedMps * 3.6,
      distanceKm: distanceMeters / 1000.0,
      duration: Duration(milliseconds: durationMs),
    );
  }

  /// Charge de travail simplifiée
  ///
  /// Exemple de formule :
  /// - distance (m) pondérée
  /// - temps à haute intensité
  /// - nombre de sprints
  /// - accélération max
  ///
  /// À ajuster selon ta logique métier.
  static double _computeWorkloadScore({
    required double distanceMeters,
    required int timeAbove20Ms,
    required int sprintCount,
    required double maxAccelerationMps2,
  }) {
    final distancePart = distanceMeters / 100.0;
    final highSpeedPart = (timeAbove20Ms / 1000.0) / 10.0;
    final sprintPart = sprintCount * 5.0;
    final accelPart = maxAccelerationMps2 * 10.0;

    return distancePart + highSpeedPart + sprintPart + accelPart;
  }

  /// Découpage simple du terrain en 6 zones :
  /// 3 bandes dans la longueur x 2 bandes dans la largeur
  ///
  /// Zone ids :
  /// - DEF_LEFT
  /// - DEF_RIGHT
  /// - MID_LEFT
  /// - MID_RIGHT
  /// - ATT_LEFT
  /// - ATT_RIGHT
  static String _computeZoneId({
    required double xMeters,
    required double yMeters,
    required double fieldLengthMeters,
    required double fieldWidthMeters,
  }) {
    final thirdLength = fieldLengthMeters / 3.0;
    final halfWidth = fieldWidthMeters / 2.0;

    final lengthLabel = xMeters < thirdLength
        ? 'DEF'
        : xMeters < thirdLength * 2
        ? 'MID'
        : 'ATT';

    final widthLabel = yMeters < halfWidth ? 'LEFT' : 'RIGHT';

    return '${lengthLabel}_$widthLabel';
  }

  static double _haversineMeters(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const earthRadius = 6371000.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_degToRad(lat1)) *
                cos(_degToRad(lat2)) *
                sin(dLon / 2) *
                sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degToRad(double deg) => deg * pi / 180.0;

  static (double, double)? _projectGpsToField({
    required double latitude,
    required double longitude,
    required FootballFieldGps field,
  }) {
    final p = _toLocalMeters(
      originLat: field.topLeft.lat,
      originLng: field.topLeft.lng,
      lat: latitude,
      lng: longitude,
    );

    final right = _toLocalMeters(
      originLat: field.topLeft.lat,
      originLng: field.topLeft.lng,
      lat: field.topRight.lat,
      lng: field.topRight.lng,
    );

    final down = _toLocalMeters(
      originLat: field.topLeft.lat,
      originLng: field.topLeft.lng,
      lat: field.bottomLeft.lat,
      lng: field.bottomLeft.lng,
    );

    final rightNorm = _normalize(right.$1, right.$2);
    final downNorm = _normalize(down.$1, down.$2);

    final projLength = _dot(p.$1, p.$2, rightNorm.$1, rightNorm.$2);
    final projWidth = _dot(p.$1, p.$2, downNorm.$1, downNorm.$2);

    final realLength = sqrt(right.$1 * right.$1 + right.$2 * right.$2);
    final realWidth = sqrt(down.$1 * down.$1 + down.$2 * down.$2);

    if (realLength == 0 || realWidth == 0) return null;

    final xRatio = projLength / realLength;
    final yRatio = projWidth / realWidth;

    final xMeters = xRatio * field.fieldLengthMeters;
    final yMeters = yRatio * field.fieldWidthMeters;

    if (xMeters < -5 ||
        xMeters > field.fieldLengthMeters + 5 ||
        yMeters < -5 ||
        yMeters > field.fieldWidthMeters + 5) {
      return null;
    }

    return (
    xMeters.clamp(0, field.fieldLengthMeters).toDouble(),
    yMeters.clamp(0, field.fieldWidthMeters).toDouble(),
    );
  }

  static (double, double) _toLocalMeters({
    required double originLat,
    required double originLng,
    required double lat,
    required double lng,
  }) {
    const earthRadius = 6378137.0;

    final dLat = _degToRad(lat - originLat);
    final dLng = _degToRad(lng - originLng);
    final meanLat = _degToRad((originLat + lat) / 2.0);

    final x = dLng * earthRadius * cos(meanLat);
    final y = dLat * earthRadius;

    return (x, y);
  }

  static (double, double) _normalize(double x, double y) {
    final len = sqrt(x * x + y * y);
    if (len == 0) return (0, 0);
    return (x / len, y / len);
  }

  static double _dot(double ax, double ay, double bx, double by) {
    return ax * bx + ay * by;
  }

  static List<TimelinePoint> buildTimelinePoints({
    required String trackerId,
    required List<TrackerRaw> allSamples,
  }) {
    final samples = allSamples.where((s) {
      if (s.trackerId == null || s.trackerId!.isEmpty) return true;
      return s.trackerId == trackerId;
    }).toList()
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));

    if (samples.isEmpty) return const [];

    final startMs = samples.first.timeMs;
    final points = <TimelinePoint>[];

    bool inSprint = false;

    for (int i = 0; i < samples.length; i++) {
      final current = samples[i];

      double acceleration = 0.0;
      bool isSprint = false;

      if (i > 0) {
        final prev = samples[i - 1];
        final dtMs = current.timeMs - prev.timeMs;

        if (dtMs > 0) {
          final dtSec = dtMs / 1000.0;
          acceleration = (current.speedMps - prev.speedMps) / dtSec;

          final sprintNow = current.speedMps >= sprintThresholdMps &&
              acceleration >= minSprintAccelerationMps2;

          if (sprintNow && !inSprint) {
            inSprint = true;
          } else if (current.speedMps < sprintThresholdMps * 0.9) {
            inSprint = false;
          }

          isSprint = inSprint;
        }
      }

      points.add(
        TimelinePoint(
          timeSec: (current.timeMs - startMs) / 1000.0,
          speedKmh: current.speedMps * 3.6,
          accelerationMps2: acceleration,
          isSprint: isSprint,
        ),
      );
    }

    return points;
  }
}