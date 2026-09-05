import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:grinta/model/google_health_importable_activity.dart';
import 'package:grinta/services/grinta_health_connect_platform.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Why Health Connect authorization failed on Android.
enum GoogleHealthPlatformFailure {
  androidOnly,
  denied,
  /// Health Connect app/SDK missing — Play Store install was prompted when possible.
  unavailable,
}

/// Result of a local Health Connect authorization attempt.
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

/// Minimum Health Connect read types for declared Android features.
///
/// Keep aligned with `AndroidManifest.xml` health permissions. Play rejects
/// "excessive access" for unused scopes — do not request HEART_RATE,
/// TOTAL_CALORIES_BURNED, ACTIVE_ENERGY, SLEEP, or STEPS here. Imported
/// Google Health workouts may have null HR / calories; wearables remain
/// the source for those metrics.
const List<HealthDataType> _kGoogleHealthReadTypes = [
  HealthDataType.WORKOUT,
  HealthDataType.DISTANCE_DELTA,
];

const List<HealthDataType> _kGoogleHealthWorkoutEnrichmentTypes = [
  HealthDataType.WORKOUT,
  HealthDataType.DISTANCE_DELTA,
];

bool get isGoogleHealthConnectSupported => Platform.isAndroid;

Future<void> _requestRuntimePermissions() async {
  // Fitness / exercise types require Activity Recognition on Android.
  // Distance on workouts also needs location (dangerous permission).
  try {
    await Permission.activityRecognition.request();
  } catch (e, st) {
    debugPrint('Activity recognition permission request failed: $e\n$st');
  }
  try {
    await Permission.locationWhenInUse.request();
  } catch (e, st) {
    debugPrint('Location permission request failed: $e\n$st');
  }
}

Future<bool> _ensureHealthConnectAvailable(Health health) async {
  try {
    final available = await health.isHealthConnectAvailable();
    if (available) return true;

    final status = await health.getHealthConnectSdkStatus();
    debugPrint('Health Connect SDK status: $status');
    // Opens Play Store / provider update flow when HC is missing.
    await health.installHealthConnect();
    return false;
  } catch (e, st) {
    debugPrint('Health Connect availability check failed: $e\n$st');
    try {
      await health.installHealthConnect();
    } catch (_) {}
    return false;
  }
}

Future<bool> _ensureAuthorized(Health health) async {
  final permissions = List<HealthDataAccess>.filled(
    _kGoogleHealthReadTypes.length,
    HealthDataAccess.READ,
  );
  try {
    await _requestRuntimePermissions();

    // Always show the Health Connect permission sheet. `hasPermissions` is
    // unreliable on Android and skipping the request leaves Grinta invisible
    // under Health Connect → App permissions.
    final granted = await health.requestAuthorization(
      _kGoogleHealthReadTypes,
      permissions: permissions,
    );
    debugPrint('Google Health Connect requestAuthorization => $granted');
    if (!granted) return false;

    try {
      if (await health.isHealthDataHistoryAvailable()) {
        final historyOk = await health.isHealthDataHistoryAuthorized();
        if (!historyOk) {
          await health.requestHealthDataHistoryAuthorization();
        }
      }
    } catch (e, st) {
      debugPrint('Health Connect history authorization failed: $e\n$st');
    }

    // Plugin returns true if *any* type was granted. Log enrichment coverage
    // (hasPermissions is imperfect on Android — do not hard-fail here).
    try {
      final workoutOk = await health.hasPermissions(
        _kGoogleHealthWorkoutEnrichmentTypes,
        permissions: List<HealthDataAccess>.filled(
          _kGoogleHealthWorkoutEnrichmentTypes.length,
          HealthDataAccess.READ,
        ),
      );
      debugPrint(
        'Google Health Connect hasPermissions(WORKOUT+DISTANCE)='
        '$workoutOk',
      );
      if (workoutOk == false) {
        debugPrint(
          'Google Health Connect: Exercise/Distance may be '
          'incomplete — enable them in Health Connect → App permissions → Grinta',
        );
      }
    } catch (e, st) {
      debugPrint('Google Health Connect hasPermissions check failed: $e\n$st');
    }

    return true;
  } catch (e, st) {
    debugPrint('Google Health Connect authorization failed: $e\n$st');
    return false;
  }
}

Future<GoogleHealthPlatformConnectResult> authorizeAndProbeWorkouts() async {
  if (!Platform.isAndroid) {
    return GoogleHealthPlatformConnectResult.androidOnly;
  }

  final health = Health();
  await health.configure();

  final available = await _ensureHealthConnectAvailable(health);
  if (!available) {
    return GoogleHealthPlatformConnectResult.unavailable;
  }

  final granted = await _ensureAuthorized(health);
  if (!granted) {
    return GoogleHealthPlatformConnectResult.denied;
  }

  final workouts = await listGoogleHealthWorkouts(
    lookbackDays: 90,
    skipAuthorization: true,
  );
  DateTime? mostRecentWorkoutAt;
  for (final workout in workouts) {
    if (mostRecentWorkoutAt == null ||
        workout.startDate.isAfter(mostRecentWorkoutAt)) {
      mostRecentWorkoutAt = workout.startDate;
    }
  }

  return GoogleHealthPlatformConnectResult.success(
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
  return distance.toDouble();
}

double? _caloriesFromWorkout(WorkoutHealthValue value) {
  final energy = value.totalEnergyBurned;
  if (energy == null || energy <= 0) return null;
  final unit = value.totalEnergyBurnedUnit;
  if (unit == HealthDataUnit.JOULE) {
    return energy / 4184.0;
  }
  return energy.toDouble();
}

GoogleHealthImportableActivity? _mapWorkoutPoint(HealthDataPoint point) {
  final value = point.value;
  if (value is! WorkoutHealthValue) return null;

  final start = point.dateFrom;
  final end = point.dateTo;
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

  return GoogleHealthImportableActivity(
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

/// Lists recent workouts from Health Connect (newest first).
Future<List<GoogleHealthImportableActivity>> listGoogleHealthWorkouts({
  int lookbackDays = 90,
  bool skipAuthorization = false,
}) async {
  if (!Platform.isAndroid) return const [];

  final health = Health();
  await health.configure();
  if (!skipAuthorization) {
    final available = await health.isHealthConnectAvailable();
    if (!available) return const [];
    final granted = await _ensureAuthorized(health);
    if (!granted) return const [];
  }

  // Prefer the native reader: the health plugin's WORKOUT path may enrich
  // with extra types and return [] on any SecurityException.
  final native = await GrintaHealthConnectPlatform.listExerciseSessions(
    lookbackDays: lookbackDays,
  );
  if (native.ok && native.workouts.isNotEmpty) {
    return native.workouts;
  }
  if (native.ok && native.sessionCount == 0) {
    debugPrint(
      'Google Health Connect native found 0 Exercise sessions '
      '(lookbackDays=$lookbackDays warnings=${native.warnings})',
    );
    return const [];
  }
  if (!native.ok) {
    debugPrint(
      'Google Health Connect native list unavailable '
      '(reason=${native.reason}); falling back to health plugin',
    );
  } else if (native.workouts.isEmpty && native.sessionCount > 0) {
    debugPrint(
      'Google Health Connect native mapped 0 of ${native.sessionCount} '
      'sessions; falling back to health plugin',
    );
  }

  final now = DateTime.now();
  final start = now.subtract(Duration(days: lookbackDays.clamp(1, 365)));

  try {
    final points = await health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
      types: const [HealthDataType.WORKOUT],
    );
    debugPrint(
      'Google Health Connect WORKOUT points=${points.length} '
      'lookbackDays=$lookbackDays',
    );
    final activities = <GoogleHealthImportableActivity>[];
    final seen = <String>{};
    for (final point in points) {
      final mapped = _mapWorkoutPoint(point);
      if (mapped == null) continue;
      if (!seen.add(mapped.externalId)) continue;
      activities.add(mapped);
    }
    activities.sort((a, b) => b.startDate.compareTo(a.startDate));
    debugPrint(
      'Google Health Connect mapped activities=${activities.length}',
    );
    return activities;
  } catch (e, st) {
    debugPrint('Google Health Connect list workouts failed: $e\n$st');
    // If the plugin path failed but native had sessions that failed mapping,
    // still return whatever native produced (possibly empty).
    return native.workouts;
  }
}

/// Health Connect HEART_RATE is not requested (Play minimal-scope policy).
/// Imported Google Health workouts therefore have no HC-derived HR.
/// Wearables (Polar / Whoop / …) remain the source for heart rate.
Future<int?> averageHeartRateForWorkout({
  required DateTime start,
  required DateTime end,
}) async {
  return null;
}

/// Requests Health Connect write access for workouts.
Future<bool> ensureGoogleWorkoutWriteAuthorized() async {
  if (!Platform.isAndroid) return false;

  final health = Health();
  await health.configure();
  if (!await health.isHealthConnectAvailable()) return false;

  await _requestRuntimePermissions();

  // Write only what session export uses: Exercise + Distance.
  final types = <HealthDataType>[
    HealthDataType.WORKOUT,
    HealthDataType.DISTANCE_DELTA,
  ];
  final permissions = <HealthDataAccess>[
    HealthDataAccess.READ_WRITE, // WORKOUT
    HealthDataAccess.READ_WRITE, // DISTANCE_DELTA
  ];

  try {
    final granted = await health.requestAuthorization(
      types,
      permissions: permissions,
    );
    return granted;
  } catch (e, st) {
    debugPrint('Google Health Connect write authorization failed: $e\n$st');
    return false;
  }
}

HealthWorkoutActivityType _activityTypeFromName(String name) {
  for (final value in HealthWorkoutActivityType.values) {
    if (value.name == name) return value;
  }
  return HealthWorkoutActivityType.OTHER;
}

/// Writes a session workout (distance + time window) into Health Connect.
Future<bool> writeGoogleHealthWorkout({
  required String activityTypeName,
  required DateTime start,
  required DateTime end,
  int? distanceMeters,
  String? title,
}) async {
  if (!Platform.isAndroid) return false;
  if (!end.isAfter(start)) return false;

  final authorized = await ensureGoogleWorkoutWriteAuthorized();
  if (!authorized) return false;

  // SOCCER is iOS-only in the health package; force OTHER on Android.
  final rawName =
      activityTypeName == 'SOCCER' ? 'OTHER' : activityTypeName;
  final activityType = _activityTypeFromName(rawName);
  final health = Health();
  await health.configure();
  try {
    return await health.writeWorkoutData(
      activityType: activityType,
      start: start,
      end: end,
      totalDistance: distanceMeters != null && distanceMeters > 0
          ? distanceMeters
          : null,
      totalDistanceUnit: HealthDataUnit.METER,
      title: title,
      recordingMethod: RecordingMethod.manual,
    );
  } catch (e, st) {
    debugPrint('Google Health Connect writeWorkout failed: $e\n$st');
    return false;
  }
}
