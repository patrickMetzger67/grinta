import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../model/teamParam.dart';
import '../model/tracker/trackerData.dart';
import '../util/gps_distance_smoothing.dart';


class SensorAnalysisService {
  /// Si la fréquence est irrégulière on utilise le delta temps réel
  static TrackerAnalysisResult analyzeSensorData({
    required String trackerId,
    required String playerId,
    required String eventId,
    required List<TrackerRaw> allSamples,
    required bool isMatch,
    FootballFieldGps? fieldGps,
    TeamParam? teamParam,
    double minMeaningfulStepDistanceMeters = 0,
  }) {
    final params = teamParam ?? TeamParam.defaultConfig();

    final samples = allSamples.where((s) {
      final id = s.trackerId?.trim();
      return id == trackerId.trim();
    }).toList()
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));

    if (samples.isEmpty) {
      return TrackerAnalysisResult(
        trackerId: trackerId,
        playerId: playerId,
        eventId: eventId,
        distanceKm: 0,
        duration: Duration.zero,
        averageSpeedKmh: 0,
        maxSpeedKmh: 0,
        maxValidatedSpeedKmh: 0,
        samplesCount: 0,
        heatmapPoints: const [],
        sprintCount: 0,
        highAccelerationCount: 0,
        highSpeedDuration: Duration.zero,
        maxAccelerationMps2: 0,
        distanceByZones: const [],
        speedZones: const [],
        halfStats: const [],
        workloadScore: 0,
        workloadScorePerMinute: 0,
        playerProfile: 'Inconnu',
        fatigueIndex: 1.0,
        firstHalfDistanceKm: 0,
        secondHalfDistanceKm: 0,
        distanceTimeline: const [],
      );
    }

    final List<HeatmapPoint> heatmapPoints = [];
    final Map<String, double> zoneDistanceMeters = {};
    final Map<String, int> zoneSamples = {};

    double totalDistanceMeters = 0.0;
    double maxSpeedMps = 0.0;
    double maxValidatedSpeedMps = 0.0;
    double maxAccelerationMps2 = 0.0;

    int sprintCount = 0;
    int highAccelerationCount = 0;
    int timeAboveSprintThresholdMs = 0;

    double firstHalfDistanceMeters = 0.0;
    double secondHalfDistanceMeters = 0.0;

    final startMs = samples.first.timeMs;
    final endMs = samples.last.timeMs;
    final totalDurationMs = max(0, endMs - startMs);
    final midTimeMs = startMs + (totalDurationMs ~/ 2);

    // Real pitch heatmap whenever field GPS corners are available (match or
    // training). [isMatch] remains available for callers that specialize logic.
    final bool canBuildRealFieldHeatmap = fieldGps != null;
    final bool shouldBuildRelativeHeatmap = fieldGps == null;

    final double sprintThresholdMps = params.sprintThresholdMps;
    final int sprintMinDurationMs = params.sprintMinDurationMs;

    final double highAccelerationThresholdMps2 =
        params.highAccelerationThresholdMps2;
    final int highAccelerationMinDurationMs =
        params.highAccelerationMinDurationMs;

    final double maxPlausibleSpeedMps = params.maxPlausibleSpeedMps;
    final double maxPlausibleAccelerationMps2 =
        params.maxPlausibleAccelerationMps2;

    final int minDtMs = params.minDtMs;
    final int maxDtMs = params.maxDtMs;
    final int smoothingWindow = params.smoothingWindow;
    final int validatedSpeedMinDurationMs =
        params.validatedSpeedMinDurationMs;

    final List<double> recentSpeeds = [];

    bool inSprint = false;
    int sprintAccumulatedMs = 0;

    int highAccelerationAccumulatedMs = 0;
    bool inHighAcceleration = false;

    int validatedSpeedAccumulatedMs = 0;

    double? previousRetainedSpeedMps;

    final globalMaxRawSensorSpeed = samples
        .map((e) => e.speedMps)
        .fold<double>(0.0, (p, e) => e > p ? e : p);

    final bool sensorLooksLikeKmh = globalMaxRawSensorSpeed > 15.0;

    final Map<String, int> speedZoneTimeMs = {
      for (final zone in params.orderedSpeedZones) zone.zoneId: 0,
    };

    final int timelineBucketMs = params.timelineBucketMs;
    final Map<int, Map<String, double>> distanceTimelineBuckets = {};

    // EMA + min-speed gate — shared by Live, training finish, match, personal.
    final distanceSmoother = GpsDistanceSmoother();

    for (int i = 0; i < samples.length; i++) {
      final current = samples[i];

      if (canBuildRealFieldHeatmap) {
        final projectedCurrent = _projectGpsToField(
          latitude: current.latitude,
          longitude: current.longitude,
          field: fieldGps!,
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

      if (i == 0) {
        distanceSmoother.ingest(
          timeMs: current.timeMs,
          latitude: current.latitude,
          longitude: current.longitude,
          minDtMs: minDtMs,
          maxDtMs: maxDtMs,
          maxPlausibleSpeedMps: maxPlausibleSpeedMps,
          minMeaningfulStepDistanceMeters: minMeaningfulStepDistanceMeters,
        );
        continue;
      }

      final prev = samples[i - 1];
      final dtMs = current.timeMs - prev.timeMs;

      if (dtMs <= 0) continue;

      // Always feed the smoother so EMA stays continuous across short gaps.
      final stepDistance = distanceSmoother.ingest(
        timeMs: current.timeMs,
        latitude: current.latitude,
        longitude: current.longitude,
        minDtMs: minDtMs,
        maxDtMs: maxDtMs,
        maxPlausibleSpeedMps: maxPlausibleSpeedMps,
        minMeaningfulStepDistanceMeters: minMeaningfulStepDistanceMeters,
      );

      if (dtMs < minDtMs) continue;

      if (dtMs > maxDtMs) {
        recentSpeeds.clear();
        previousRetainedSpeedMps = null;
        sprintAccumulatedMs = 0;
        inSprint = false;
        highAccelerationAccumulatedMs = 0;
        inHighAcceleration = false;
        validatedSpeedAccumulatedMs = 0;
        continue;
      }

      final dtSec = dtMs / 1000.0;

      // Raw haversine still gates "isGpsStepValid" for speed retention fallback.
      final rawDistance = _haversineMeters(
        prev.latitude,
        prev.longitude,
        current.latitude,
        current.longitude,
      );

      final maxStepDistance = maxPlausibleSpeedMps * dtSec * 1.5;
      final isGpsStepValid = rawDistance >= 0 && rawDistance <= maxStepDistance;

      totalDistanceMeters += stepDistance;

      if (current.timeMs <= midTimeMs) {
        firstHalfDistanceMeters += stepDistance;
      } else {
        secondHalfDistanceMeters += stepDistance;
      }

      // Speed / sprints keep the high-rate raw step (capped). Distance alone
      // uses [GpsDistanceSmoother] so jitter does not inflate km.
      final gpsSpeedMps =
          isGpsStepValid && dtSec > 0 ? rawDistance / dtSec : 0.0;

      recentSpeeds.add(gpsSpeedMps);
      if (recentSpeeds.length > smoothingWindow) {
        recentSpeeds.removeAt(0);
      }

      final smoothedGpsSpeedMps = recentSpeeds.isEmpty
          ? 0.0
          : recentSpeeds.reduce((a, b) => a + b) / recentSpeeds.length;

      double sensorSpeedMps = 0.0;
      if (current.speedMps.isFinite && current.speedMps >= 0) {
        sensorSpeedMps = sensorLooksLikeKmh
            ? current.speedMps / 3.6
            : current.speedMps;
      }

      double retainedSpeedMps;
      if (isGpsStepValid) {
        if (smoothedGpsSpeedMps > maxPlausibleSpeedMps &&
            sensorSpeedMps > 0 &&
            sensorSpeedMps <= maxPlausibleSpeedMps) {
          retainedSpeedMps = sensorSpeedMps;
        } else {
          retainedSpeedMps = smoothedGpsSpeedMps;
        }
      } else {
        retainedSpeedMps = sensorSpeedMps;
      }

      if (!retainedSpeedMps.isFinite || retainedSpeedMps < 0) {
        retainedSpeedMps = 0.0;
      }

      if (retainedSpeedMps > maxSpeedMps) {
        maxSpeedMps = retainedSpeedMps;
      }

      if (retainedSpeedMps >= maxValidatedSpeedMps) {
        validatedSpeedAccumulatedMs += dtMs;
        if (validatedSpeedAccumulatedMs >= validatedSpeedMinDurationMs) {
          maxValidatedSpeedMps = retainedSpeedMps;
        }
      } else {
        validatedSpeedAccumulatedMs = 0;
      }

      final speedKmh = retainedSpeedMps * 3.6;

      final resolvedZone = params.resolveSpeedZone(speedKmh);
      final speedZoneId = resolvedZone.zoneId;
      speedZoneTimeMs[speedZoneId] = (speedZoneTimeMs[speedZoneId] ?? 0) + dtMs;

      final relativeStartMs = prev.timeMs - startMs;
      final bucketIndex = relativeStartMs ~/ timelineBucketMs;

      final bucket = distanceTimelineBuckets.putIfAbsent(bucketIndex, () {
        return {
          'walkingMeters': 0.0,
          'joggingMeters': 0.0,
          'runningMeters': 0.0,
          'highIntensityMeters': 0.0,
        };
      });

      if (speedKmh < params.walkingMaxKmh) {
        bucket['walkingMeters'] =
            (bucket['walkingMeters'] ?? 0.0) + stepDistance;
      } else if (speedKmh < params.joggingMaxKmh) {
        bucket['joggingMeters'] =
            (bucket['joggingMeters'] ?? 0.0) + stepDistance;
      } else if (speedKmh < params.runningMaxKmh) {
        bucket['runningMeters'] =
            (bucket['runningMeters'] ?? 0.0) + stepDistance;
      } else {
        bucket['highIntensityMeters'] =
            (bucket['highIntensityMeters'] ?? 0.0) + stepDistance;
      }

      if (retainedSpeedMps >= sprintThresholdMps) {
        timeAboveSprintThresholdMs += dtMs;
        sprintAccumulatedMs += dtMs;

        if (!inSprint && sprintAccumulatedMs >= sprintMinDurationMs) {
          sprintCount++;
          inSprint = true;
        }
      } else {
        sprintAccumulatedMs = 0;
        inSprint = false;
      }

      if (previousRetainedSpeedMps != null) {
        final acc = (retainedSpeedMps - previousRetainedSpeedMps!) / dtSec;

        if (acc.isFinite &&
            acc > 0 &&
            acc <= maxPlausibleAccelerationMps2 &&
            acc > maxAccelerationMps2) {
          maxAccelerationMps2 = acc;
        }

        if (acc.isFinite && acc >= highAccelerationThresholdMps2) {
          highAccelerationAccumulatedMs += dtMs;
          if (!inHighAcceleration &&
              highAccelerationAccumulatedMs >= highAccelerationMinDurationMs) {
            highAccelerationCount++;
            inHighAcceleration = true;
          }
        } else {
          highAccelerationAccumulatedMs = 0;
          inHighAcceleration = false;
        }
      }

      previousRetainedSpeedMps = retainedSpeedMps;

      if (canBuildRealFieldHeatmap) {
        final projectedCurrent = _projectGpsToField(
          latitude: current.latitude,
          longitude: current.longitude,
          field: fieldGps!,
        );

        if (projectedCurrent != null) {
          final zoneId = _computeZoneId(
            xMeters: projectedCurrent.$1,
            yMeters: projectedCurrent.$2,
            fieldLengthMeters: fieldGps.fieldLengthMeters,
            fieldWidthMeters: fieldGps.fieldWidthMeters,
          );

          zoneDistanceMeters[zoneId] =
              (zoneDistanceMeters[zoneId] ?? 0.0) + stepDistance;

          if (heatmapPoints.isNotEmpty) {
            final last = heatmapPoints.removeLast();
            heatmapPoints.add(
              HeatmapPoint(
                xMeters: last.xMeters,
                yMeters: last.yMeters,
                timeMs: last.timeMs,
                intensity: max(0.2, retainedSpeedMps),
              ),
            );
          }
        }
      }
    }

    if (shouldBuildRelativeHeatmap) {
      heatmapPoints.addAll(_buildRelativeHeatmapPoints(samples));
    }

    final averageSpeedMps = totalDurationMs > 0
        ? totalDistanceMeters / (totalDurationMs / 1000.0)
        : 0.0;

    final halfStats = _computeHalfStats(samples, params);

    final allZoneIds = <String>{
      ...zoneSamples.keys,
      ...zoneDistanceMeters.keys,
    };

    final distanceByZones = allZoneIds.map((zoneId) {
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

    final speedZones = speedZoneTimeMs.entries.map((e) {
      final percent =
      totalDurationMs > 0 ? (e.value / totalDurationMs) * 100.0 : 0.0;
      return SpeedZoneStat(
        zoneId: e.key,
        duration: Duration(milliseconds: e.value),
        percentOfSession: percent,
      );
    }).toList()
      ..sort((a, b) => a.zoneId.compareTo(b.zoneId));

    final distanceTimeline = distanceTimelineBuckets.entries.map((entry) {
      final bucketIndex = entry.key;
      final values = entry.value;

      final bucketStartMs = bucketIndex * timelineBucketMs;
      final bucketEndMs = bucketStartMs + timelineBucketMs;

      return DistanceTimelineStat(
        bucketStartMs: bucketStartMs,
        bucketEndMs: bucketEndMs,
        label: '${bucketStartMs ~/ 60000}-${bucketEndMs ~/ 60000} min',
        walkingMeters: values['walkingMeters'] ?? 0.0,
        joggingMeters: values['joggingMeters'] ?? 0.0,
        runningMeters: values['runningMeters'] ?? 0.0,
        highIntensityMeters: values['highIntensityMeters'] ?? 0.0,
      );
    }).toList()
      ..sort((a, b) => a.bucketStartMs.compareTo(b.bucketStartMs));

    final workloadScore = _computeWorkloadScore(
      distanceMeters: totalDistanceMeters,
      timeAbove20Ms: timeAboveSprintThresholdMs,
      sprintCount: sprintCount,
      maxAccelerationMps2: maxAccelerationMps2,
    );

    final durationMinutes = totalDurationMs / 60000.0;

    final workloadScorePerMinute = durationMinutes > 0
        ? workloadScore / durationMinutes
        : 0.0;

    final fatigueIndex = firstHalfDistanceMeters > 0
        ? secondHalfDistanceMeters / firstHalfDistanceMeters
        : 1.0;

    final String playerProfile;
    if (sprintCount > 25 && timeAboveSprintThresholdMs > 60000) {
      playerProfile = 'Explosif / Ailier';
    } else if (totalDistanceMeters > 10000 && sprintCount > 15) {
      playerProfile = 'Box-to-box';
    } else if (totalDistanceMeters < 7000 && sprintCount < 10) {
      playerProfile = 'Défensif';
    } else if (highAccelerationCount >= 15 && sprintCount >= 15) {
      playerProfile = 'Polyvalent dynamique';
    } else {
      playerProfile = 'Polyvalent';
    }

    return TrackerAnalysisResult(
      trackerId: trackerId,
      playerId: playerId,
      eventId: eventId,
      distanceKm: totalDistanceMeters / 1000.0,
      duration: Duration(milliseconds: totalDurationMs),
      averageSpeedKmh: averageSpeedMps * 3.6,
      maxSpeedKmh: maxSpeedMps * 3.6,
      maxValidatedSpeedKmh: maxValidatedSpeedMps * 3.6,
      samplesCount: samples.length,
      heatmapPoints: heatmapPoints,
      fieldGps: fieldGps,
      sprintCount: sprintCount,
      highAccelerationCount: highAccelerationCount,
      highSpeedDuration: Duration(milliseconds: timeAboveSprintThresholdMs),
      maxAccelerationMps2: maxAccelerationMps2,
      distanceByZones: distanceByZones,
      speedZones: speedZones,
      halfStats: halfStats,
      workloadScore: workloadScore,
      workloadScorePerMinute: workloadScorePerMinute,
      playerProfile: playerProfile,
      fatigueIndex: fatigueIndex,
      firstHalfDistanceKm: firstHalfDistanceMeters / 1000.0,
      secondHalfDistanceKm: secondHalfDistanceMeters / 1000.0,
      distanceTimeline: distanceTimeline,
    );
  }

  static List<HeatmapPoint> _buildRelativeHeatmapPoints(
      List<TrackerRaw> samples, {
        double targetWidthMeters = 105.0,
        double targetHeightMeters = 68.0,
      }) {
    if (samples.isEmpty) return const [];

    final origin = samples.first;

    final localPoints = <({double x, double y, int timeMs, double intensity})>[];

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final sample in samples) {
      final local = _toLocalMeters(
        originLat: origin.latitude,
        originLng: origin.longitude,
        lat: sample.latitude,
        lng: sample.longitude,
      );

      final x = local.$1;
      final y = local.$2;

      minX = min(minX, x);
      maxX = max(maxX, x);
      minY = min(minY, y);
      maxY = max(maxY, y);

      localPoints.add((
      x: x,
      y: y,
      timeMs: sample.timeMs,
      intensity: max(0.2, sample.speedMps),
      ));
    }

    final width = max(1.0, maxX - minX);
    final height = max(1.0, maxY - minY);

    final scale = min(targetWidthMeters / width, targetHeightMeters / height);

    final scaledWidth = width * scale;
    final scaledHeight = height * scale;

    final offsetX = (targetWidthMeters - scaledWidth) / 2.0;
    final offsetY = (targetHeightMeters - scaledHeight) / 2.0;

    return localPoints.map((p) {
      final normalizedX = ((p.x - minX) * scale) + offsetX;
      final normalizedY = ((p.y - minY) * scale) + offsetY;

      return HeatmapPoint(
        xMeters: normalizedX.clamp(0, targetWidthMeters).toDouble(),
        yMeters: normalizedY.clamp(0, targetHeightMeters).toDouble(),
        timeMs: p.timeMs,
        intensity: p.intensity,
      );
    }).toList();
  }

  static List<HalfStats> _computeHalfStats(
      List<TrackerRaw> samples,
      TeamParam params,
      ) {
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
      result.add(_buildHalfStats(1, firstHalf, params));
    }
    if (secondHalf.length >= 2) {
      result.add(_buildHalfStats(2, secondHalf, params));
    }

    return result;
  }

  static HalfStats _buildHalfStats(
      int halfIndex,
      List<TrackerRaw> samples,
      TeamParam params,
      ) {
    double speedSumMps = 0;
    double distanceMeters = 0;
    final smoother = GpsDistanceSmoother();

    final globalMaxRawSensorSpeed = samples
        .map((e) => e.speedMps)
        .fold<double>(0.0, (p, e) => e > p ? e : p);

    final bool sensorLooksLikeKmh = globalMaxRawSensorSpeed > 15.0;

    for (int i = 0; i < samples.length; i++) {
      final speedMps = sensorLooksLikeKmh
          ? samples[i].speedMps / 3.6
          : samples[i].speedMps;
      speedSumMps += speedMps;

      final d = smoother.ingest(
        timeMs: samples[i].timeMs,
        latitude: samples[i].latitude,
        longitude: samples[i].longitude,
        minDtMs: params.minDtMs,
        maxDtMs: params.maxDtMs,
        maxPlausibleSpeedMps: params.maxPlausibleSpeedMps,
      );
      // Keep the legacy absolute cap as a last-resort guard.
      if (d > 0 && d <= params.maxAcceptedStepDistanceMeters) {
        distanceMeters += d;
      }
    }

    final averageSpeedMps = samples.isNotEmpty ? speedSumMps / samples.length : 0;
    final durationMs = samples.last.timeMs - samples.first.timeMs;

    return HalfStats(
      halfIndex: halfIndex,
      averageSpeedKmh: averageSpeedMps * 3.6,
      distanceKm: distanceMeters / 1000.0,
      duration: Duration(milliseconds: durationMs),
    );
  }

  /// Charge de travail simplifiée
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

    final a = sin(dLat / 2) * sin(dLat / 2) +
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
      originLat: field.topLeft.latitude,
      originLng: field.topLeft.longitude,
      lat: latitude,
      lng: longitude,
    );

    final right = _toLocalMeters(
      originLat: field.topLeft.latitude,
      originLng: field.topLeft.longitude,
      lat: field.topRight.latitude,
      lng: field.topRight.longitude,
    );

    final down = _toLocalMeters(
      originLat: field.topLeft.latitude,
      originLng: field.topLeft.longitude,
      lat: field.bottomLeft.latitude,
      lng: field.bottomLeft.longitude,
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
    TeamParam? teamParam,
  }) {
    final params = teamParam ?? TeamParam.defaultConfig();

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

          final sprintNow = current.speedMps >= params.sprintThresholdMps &&
              acceleration >= params.minSprintAccelerationMps2;

          if (sprintNow && !inSprint) {
            inSprint = true;
          } else if (current.speedMps < params.sprintThresholdMps * 0.9) {
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

  static Future<String> heatmapToCsv({
    required String deviceId,
    required String eventId,
    required List<HeatmapPoint> heatmapPoints,
  }) async {
    final buffer = StringBuffer();

    buffer.writeln('xMeters,yMeters,timeMs,intensity');

    for (final p in heatmapPoints) {
      buffer.writeln(
        '${p.xMeters},${p.yMeters},${p.timeMs},${p.intensity}',
      );
    }

    final csvString = buffer.toString();
    final csvBytes = Uint8List.fromList(utf8.encode(csvString));

    final gzipBytes =
    Uint8List.fromList(GZipEncoder().encode(csvBytes) ?? csvBytes);

    final filePath = 'tracker/heatmapPoints_${deviceId}_$eventId.csv.gz';

    final ref = FirebaseStorage.instance.ref().child(filePath);

    await ref.putData(
      gzipBytes,
      SettableMetadata(
        contentType: 'application/gzip',
        contentEncoding: 'gzip',
        customMetadata: {
          'deviceId': deviceId,
          'eventId': eventId,
          'originalContentType': 'text/csv',
        },
      ),
    );

    return await ref.getDownloadURL();
  }
}