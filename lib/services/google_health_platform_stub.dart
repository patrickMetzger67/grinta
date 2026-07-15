/// Result of a local Health Connect authorization attempt (non-Android platforms).
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

/// Whether Google Fit / Health Connect can be connected on this platform.
bool get isGoogleHealthConnectSupported => false;

/// Requests Health Connect read access and optionally probes recent workouts.
Future<GoogleHealthPlatformConnectResult> authorizeAndProbeWorkouts() async {
  return GoogleHealthPlatformConnectResult.androidOnly;
}
