import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:grinta/model/apple_health_importable_activity.dart';
import 'package:health/health.dart';

/// Result of a local HealthKit authorization attempt.
class AppleHealthPlatformConnectResult {
  const AppleHealthPlatformConnectResult._({
    required this.authorized,
    this.recentWorkoutCount,
    this.mostRecentWorkoutAt,
  });

  final bool authorized;
  final int? recentWorkoutCount;
  final DateTime? mostRecentWorkoutAt;

  static const AppleHealthPlatformConnectResult iosOnly =
      AppleHealthPlatformConnectResult._(authorized: false);

  static const AppleHealthPlatformConnectResult denied =
      AppleHealthPlatformConnectResult._(authorized: false);

  static AppleHealthPlatformConnectResult success({
    required int recentWorkoutCount,
    DateTime? mostRecentWorkoutAt,
  }) {
    return AppleHealthPlatformConnectResult._(
      authorized: true,
      recentWorkoutCount: recentWorkoutCount,
      mostRecentWorkoutAt: mostRecentWorkoutAt,
    );
  }
}

const List<HealthDataType> _kAppleHealthReadTypes = [
  HealthDataType.WORKOUT,
  HealthDataType.HEART_RATE,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.SLEEP_ASLEEP,
];

bool get isAppleHealthSupported => Platform.isIOS;

Future<bool> _ensureAuthorized(Health health) async {
  final permissions = List<HealthDataAccess>.filled(
    _kAppleHealthReadTypes.length,
    HealthDataAccess.READ,
  );
  try {
    final hasPermissions = await health.hasPermissions(
      _kAppleHealthReadTypes,
      permissions: permissions,
    );
    if (hasPermissions == true) return true;
    return health.requestAuthorization(
      _kAppleHealthReadTypes,
      permissions: permissions,
    );
  } catch (e, st) {
    debugPrint('Apple Health authorization failed: $e\n$st');
    return false;
  }
}

Future<AppleHealthPlatformConnectResult> authorizeAndProbeWorkouts() async {
  if (!Platform.isIOS) {
    return AppleHealthPlatformConnectResult.iosOnly;
  }

  final health = Health();
  await health.configure();
  final granted = await _ensureAuthorized(health);
  if (!granted) {
    return AppleHealthPlatformConnectResult.denied;
  }

  final workouts = await listAppleHealthWorkouts(lookbackDays: 30);
  DateTime? mostRecentWorkoutAt;
  for (final workout in workouts) {
    if (mostRecentWorkoutAt == null ||
        workout.startDate.isAfter(mostRecentWorkoutAt)) {
      mostRecentWorkoutAt = workout.startDate;
    }
  }

  return AppleHealthPlatformConnectResult.success(
    recentWorkoutCount: workouts.length,
    mostRecentWorkoutAt: mostRecentWorkoutAt,
  );
}

String _mapWorkoutTypeId(HealthWorkoutActivityType type) {
  switch (type) {
    case HealthWorkoutActivityType.SWIMMING:
    case HealthWorkoutActivityType.SWIMMING_OPEN_WATER:
    case HealthWorkoutActivityType.SWIMMING_POOL:
    case HealthWorkoutActivityType.WATER_FITNESS:
      return 'natation';
    case HealthWorkoutActivityType.BIKING:
    case HealthWorkoutActivityType.BIKING_STATIONARY:
    case HealthWorkoutActivityType.HAND_CYCLING:
      return 'velo';
    case HealthWorkoutActivityType.WALKING:
    case HealthWorkoutActivityType.WALKING_TREADMILL:
    case HealthWorkoutActivityType.HIKING:
    case HealthWorkoutActivityType.SNOWSHOEING:
      return 'sortie_longue';
    case HealthWorkoutActivityType.RUNNING:
    case HealthWorkoutActivityType.RUNNING_TREADMILL:
    case HealthWorkoutActivityType.TRACK_AND_FIELD:
      return 'course';
    case HealthWorkoutActivityType.YOGA:
    case HealthWorkoutActivityType.PILATES:
    case HealthWorkoutActivityType.COOLDOWN:
    case HealthWorkoutActivityType.FLEXIBILITY:
    case HealthWorkoutActivityType.PREPARATION_AND_RECOVERY:
    case HealthWorkoutActivityType.MIND_AND_BODY:
    case HealthWorkoutActivityType.GUIDED_BREATHING:
    case HealthWorkoutActivityType.TAI_CHI:
      return 'recuperation';
    default:
      return 'entrainement';
  }
}

String _humanizeWorkoutType(HealthWorkoutActivityType type) {
  final raw = type.name.replaceAll('_', ' ').toLowerCase();
  return raw.replaceAllMapped(
    RegExp(r'\b\w'),
    (match) => match.group(0)!.toUpperCase(),
  );
}

double? _distanceMetersFromWorkout(WorkoutHealthValue value) {
  final distance = value.totalDistance;
  if (distance == null || distance <= 0) return null;
  final unit = value.totalDistanceUnit;
  if (unit == HealthDataUnit.MILE) {
    return distance * 1609.344;
  }
  // Default: meters (HealthKit / package usually expose meters).
  return distance.toDouble();
}

double? _caloriesFromWorkout(WorkoutHealthValue value) {
  final energy = value.totalEnergyBurned;
  if (energy == null || energy <= 0) return null;
  final unit = value.totalEnergyBurnedUnit;
  if (unit == HealthDataUnit.KILOJOULE) {
    return energy / 4.184;
  }
  // Default: kilocalories.
  return energy.toDouble();
}

AppleHealthImportableActivity? _mapWorkoutPoint(HealthDataPoint point) {
  final value = point.value;
  if (value is! WorkoutHealthValue) return null;

  final start = point.dateFrom;
  final end = point.dateTo;
  if (!end.isAfter(start) && end != start) {
    // Allow zero-length edge cases by using start.
  }
  final durationSeconds = end.difference(start).inSeconds;
  final distanceMeters = _distanceMetersFromWorkout(value);
  final caloriesKcal = _caloriesFromWorkout(value);
  final pace = distanceMeters != null &&
          distanceMeters > 0 &&
          durationSeconds > 0
      ? (durationSeconds / (distanceMeters / 1000)).round()
      : null;

  final uuid = point.uuid.trim();
  final externalId = uuid.isNotEmpty
      ? uuid
      : '${start.toUtc().millisecondsSinceEpoch}_'
          '${value.workoutActivityType.name}';

  return AppleHealthImportableActivity(
    externalId: externalId,
    name: _humanizeWorkoutType(value.workoutActivityType),
    typeId: _mapWorkoutTypeId(value.workoutActivityType),
    startDate: start,
    endDate: end.isBefore(start) ? start : end,
    durationSeconds: durationSeconds > 0 ? durationSeconds : null,
    distanceMeters: distanceMeters,
    paceSecondsPerKm: pace,
    caloriesKcal: caloriesKcal,
    workoutActivityType: value.workoutActivityType.name,
  );
}

/// Lists recent workouts from HealthKit (newest first).
Future<List<AppleHealthImportableActivity>> listAppleHealthWorkouts({
  int lookbackDays = 90,
}) async {
  if (!Platform.isIOS) return const [];

  final health = Health();
  await health.configure();
  final granted = await _ensureAuthorized(health);
  if (!granted) return const [];

  final now = DateTime.now();
  final start = now.subtract(Duration(days: lookbackDays.clamp(1, 365)));

  try {
    final points = await health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
      types: const [HealthDataType.WORKOUT],
    );
    final activities = <AppleHealthImportableActivity>[];
    final seen = <String>{};
    for (final point in points) {
      final mapped = _mapWorkoutPoint(point);
      if (mapped == null) continue;
      if (!seen.add(mapped.externalId)) continue;
      activities.add(mapped);
    }
    activities.sort((a, b) => b.startDate.compareTo(a.startDate));
    return activities;
  } catch (e, st) {
    debugPrint('Apple Health list workouts failed: $e\n$st');
    return const [];
  }
}

/// Average heart rate (bpm) across HEART_RATE samples in [start, end].
Future<int?> averageHeartRateForWorkout({
  required DateTime start,
  required DateTime end,
}) async {
  if (!Platform.isIOS) return null;
  if (!end.isAfter(start)) return null;

  final health = Health();
  await health.configure();

  try {
    final samples = await health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: const [HealthDataType.HEART_RATE],
    );
    var sum = 0.0;
    var count = 0;
    for (final sample in samples) {
      final value = sample.value;
      if (value is NumericHealthValue) {
        final numeric = value.numericValue;
        if (numeric > 0) {
          sum += numeric;
          count += 1;
        }
      }
    }
    if (count == 0) return null;
    return (sum / count).round();
  } catch (e, st) {
    debugPrint('Apple Health average HR failed: $e\n$st');
    return null;
  }
}
