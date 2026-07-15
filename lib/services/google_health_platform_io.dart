import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Result of a local Health Connect authorization attempt.
class GoogleHealthPlatformConnectResult {
  const GoogleHealthPlatformConnectResult._({
    required this.authorized,
    this.recentWorkoutCount,
    this.mostRecentWorkoutAt,
  });

  final bool authorized;
  final int? recentWorkoutCount;
  final DateTime? mostRecentWorkoutAt;

  static const GoogleHealthPlatformConnectResult androidOnly =
      GoogleHealthPlatformConnectResult._(authorized: false);

  static const GoogleHealthPlatformConnectResult denied =
      GoogleHealthPlatformConnectResult._(authorized: false);

  static GoogleHealthPlatformConnectResult success({
    required int recentWorkoutCount,
    DateTime? mostRecentWorkoutAt,
  }) {
    return GoogleHealthPlatformConnectResult._(
      authorized: true,
      recentWorkoutCount: recentWorkoutCount,
      mostRecentWorkoutAt: mostRecentWorkoutAt,
    );
  }
}

const List<HealthDataType> _kGoogleHealthReadTypes = [
  HealthDataType.WORKOUT,
  HealthDataType.HEART_RATE,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.SLEEP_ASLEEP,
];

bool get isGoogleHealthConnectSupported => Platform.isAndroid;

Future<GoogleHealthPlatformConnectResult> authorizeAndProbeWorkouts() async {
  if (!Platform.isAndroid) {
    return GoogleHealthPlatformConnectResult.androidOnly;
  }

  final health = Health();
  await health.configure();

  final permissions = List<HealthDataAccess>.filled(
    _kGoogleHealthReadTypes.length,
    HealthDataAccess.READ,
  );

  try {
    final hasPermissions = await health.hasPermissions(
      _kGoogleHealthReadTypes,
      permissions: permissions,
    );
    if (hasPermissions != true) {
      final granted = await health.requestAuthorization(
        _kGoogleHealthReadTypes,
        permissions: permissions,
      );
      if (!granted) {
        return GoogleHealthPlatformConnectResult.denied;
      }
    }
  } catch (e, st) {
    debugPrint('Google Health Connect authorization failed: $e\n$st');
    return GoogleHealthPlatformConnectResult.denied;
  }

  var workoutCount = 0;
  DateTime? mostRecentWorkoutAt;
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 30));

  try {
    final workouts = await health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
      types: const [HealthDataType.WORKOUT],
    );
    workoutCount = workouts.length;
    for (final workout in workouts) {
      final date = workout.dateFrom;
      if (mostRecentWorkoutAt == null || date.isAfter(mostRecentWorkoutAt)) {
        mostRecentWorkoutAt = date;
      }
    }
  } catch (e, st) {
    debugPrint('Google Health Connect workout probe failed: $e\n$st');
  }

  return GoogleHealthPlatformConnectResult.success(
    recentWorkoutCount: workoutCount,
    mostRecentWorkoutAt: mostRecentWorkoutAt,
  );
}
