import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
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

Future<AppleHealthPlatformConnectResult> authorizeAndProbeWorkouts() async {
  if (!Platform.isIOS) {
    return AppleHealthPlatformConnectResult.iosOnly;
  }

  final health = Health();
  await health.configure();

  final permissions = List<HealthDataAccess>.filled(
    _kAppleHealthReadTypes.length,
    HealthDataAccess.READ,
  );

  try {
    final hasPermissions = await health.hasPermissions(
      _kAppleHealthReadTypes,
      permissions: permissions,
    );
    if (hasPermissions != true) {
      final granted = await health.requestAuthorization(
        _kAppleHealthReadTypes,
        permissions: permissions,
      );
      if (!granted) {
        return AppleHealthPlatformConnectResult.denied;
      }
    }
  } catch (e, st) {
    debugPrint('Apple Health authorization failed: $e\n$st');
    return AppleHealthPlatformConnectResult.denied;
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
    debugPrint('Apple Health workout probe failed: $e\n$st');
  }

  return AppleHealthPlatformConnectResult.success(
    recentWorkoutCount: workoutCount,
    mostRecentWorkoutAt: mostRecentWorkoutAt,
  );
}
