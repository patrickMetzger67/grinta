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
