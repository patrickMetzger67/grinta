import 'package:grinta/model/apple_health_importable_activity.dart';

/// Result of a local HealthKit authorization attempt (non-iOS platforms).
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

/// Whether Apple Health / Forme can be connected on this platform.
bool get isAppleHealthSupported => false;

/// Requests HealthKit read access and optionally probes recent workouts.
Future<AppleHealthPlatformConnectResult> authorizeAndProbeWorkouts() async {
  return AppleHealthPlatformConnectResult.iosOnly;
}

/// Lists recent workouts from HealthKit (empty on non-iOS).
Future<List<AppleHealthImportableActivity>> listAppleHealthWorkouts({
  int lookbackDays = 90,
}) async {
  return const [];
}

/// Average heart rate (bpm) for a workout window — unsupported off iOS.
Future<int?> averageHeartRateForWorkout({
  required DateTime start,
  required DateTime end,
}) async {
  return null;
}
