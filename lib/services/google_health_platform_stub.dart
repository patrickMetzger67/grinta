import 'package:grinta/model/google_health_importable_activity.dart';

/// Why Health Connect authorization failed.
enum GoogleHealthPlatformFailure {
  androidOnly,
  denied,
  unavailable,
}

/// Result of a local Health Connect authorization attempt (non-Android platforms).
class GoogleHealthPlatformConnectResult {
  const GoogleHealthPlatformConnectResult._({
    required this.authorized,
    this.failure,
    this.recentWorkoutCount,
    this.mostRecentWorkoutAt,
  });

  final bool authorized;
  final GoogleHealthPlatformFailure? failure;
  final int? recentWorkoutCount;
  final DateTime? mostRecentWorkoutAt;

  static const GoogleHealthPlatformConnectResult androidOnly =
      GoogleHealthPlatformConnectResult._(
    authorized: false,
    failure: GoogleHealthPlatformFailure.androidOnly,
  );

  static const GoogleHealthPlatformConnectResult denied =
      GoogleHealthPlatformConnectResult._(
    authorized: false,
    failure: GoogleHealthPlatformFailure.denied,
  );

  static const GoogleHealthPlatformConnectResult unavailable =
      GoogleHealthPlatformConnectResult._(
    authorized: false,
    failure: GoogleHealthPlatformFailure.unavailable,
  );

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

/// Whether Google Health (Health Connect) can be connected on this platform.
bool get isGoogleHealthConnectSupported => false;

/// Requests Health Connect read access and optionally probes recent workouts.
Future<GoogleHealthPlatformConnectResult> authorizeAndProbeWorkouts() async {
  return GoogleHealthPlatformConnectResult.androidOnly;
}

/// Lists recent workouts from Health Connect (empty off Android).
Future<List<GoogleHealthImportableActivity>> listGoogleHealthWorkouts({
  int lookbackDays = 90,
  bool skipAuthorization = false,
}) async {
  return const [];
}

/// Average heart rate (bpm) for a workout window — unsupported off Android.
Future<int?> averageHeartRateForWorkout({
  required DateTime start,
  required DateTime end,
}) async {
  return null;
}

Future<bool> ensureGoogleWorkoutWriteAuthorized() async => false;

Future<bool> writeGoogleHealthWorkout({
  required String activityTypeName,
  required DateTime start,
  required DateTime end,
  int? distanceMeters,
  String? title,
}) async {
  return false;
}
