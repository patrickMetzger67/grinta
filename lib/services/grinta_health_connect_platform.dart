import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:grinta/model/google_health_importable_activity.dart';

/// Native Health Connect exercise reader (Android).
///
/// Bypasses the Flutter `health` plugin's workout enrichment path, which returns
/// an empty list when Distance / Total calories / Steps reads throw.
class GrintaHealthConnectListResult {
  const GrintaHealthConnectListResult({
    required this.ok,
    required this.workouts,
    this.reason,
    this.sessionCount = 0,
    this.warnings = const [],
    this.hasDistance,
    this.hasTotalCalories,
    this.hasSteps,
  });

  final bool ok;
  final String? reason;
  final int sessionCount;
  final List<GoogleHealthImportableActivity> workouts;
  final List<String> warnings;
  final bool? hasDistance;
  final bool? hasTotalCalories;
  final bool? hasSteps;

  static const GrintaHealthConnectListResult unsupported =
      GrintaHealthConnectListResult(
    ok: false,
    reason: 'unsupported',
    workouts: [],
  );
}

class GrintaHealthConnectPlatform {
  GrintaHealthConnectPlatform._();

  static const MethodChannel _channel =
      MethodChannel('io.grinta.app/health_connect');

  static Future<GrintaHealthConnectListResult> listExerciseSessions({
    int lookbackDays = 90,
  }) async {
    if (!Platform.isAndroid) {
      return GrintaHealthConnectListResult.unsupported;
    }

    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'listExerciseSessions',
        <String, Object?>{'lookbackDays': lookbackDays.clamp(1, 365)},
      );
      if (raw == null) {
        return const GrintaHealthConnectListResult(
          ok: false,
          reason: 'null_response',
          workouts: [],
        );
      }

      final map = Map<String, dynamic>.from(raw);
      final workoutMaps = (map['workouts'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final workouts = <GoogleHealthImportableActivity>[];
      final seen = <String>{};
      for (final item in workoutMaps) {
        final mapped = _mapNativeWorkout(item);
        if (mapped == null) continue;
        if (!seen.add(mapped.externalId)) continue;
        workouts.add(mapped);
      }
      workouts.sort((a, b) => b.startDate.compareTo(a.startDate));

      final warnings = (map['warnings'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();

      debugPrint(
        'GrintaHealthConnect native sessions=${map['sessionCount']} '
        'mapped=${workouts.length} ok=${map['ok']} reason=${map['reason']} '
        'warnings=$warnings '
        'hasDistance=${map['hasDistance']} '
        'hasTotalCalories=${map['hasTotalCalories']} '
        'hasSteps=${map['hasSteps']}',
      );

      return GrintaHealthConnectListResult(
        ok: map['ok'] == true,
        reason: map['reason']?.toString(),
        sessionCount: (map['sessionCount'] as num?)?.toInt() ?? workouts.length,
        workouts: workouts,
        warnings: warnings,
        hasDistance: map['hasDistance'] as bool?,
        hasTotalCalories: map['hasTotalCalories'] as bool?,
        hasSteps: map['hasSteps'] as bool?,
      );
    } on PlatformException catch (e, st) {
      debugPrint('GrintaHealthConnect list failed: ${e.message}\n$st');
      return GrintaHealthConnectListResult(
        ok: false,
        reason: e.code,
        workouts: const [],
        warnings: [e.message ?? e.code],
      );
    } catch (e, st) {
      debugPrint('GrintaHealthConnect list failed: $e\n$st');
      return const GrintaHealthConnectListResult(
        ok: false,
        reason: 'exception',
        workouts: [],
      );
    }
  }
}

GoogleHealthImportableActivity? _mapNativeWorkout(Map<String, dynamic> raw) {
  final fromMs = (raw['dateFromMs'] as num?)?.toInt();
  final toMs = (raw['dateToMs'] as num?)?.toInt();
  if (fromMs == null || toMs == null) return null;

  final start = DateTime.fromMillisecondsSinceEpoch(fromMs, isUtc: false);
  final end = DateTime.fromMillisecondsSinceEpoch(toMs, isUtc: false);
  final durationSeconds = end.difference(start).inSeconds;
  final activityType = (raw['workoutActivityType'] as String?)?.trim();
  final typeName =
      (activityType == null || activityType.isEmpty) ? 'OTHER' : activityType;
  final title = (raw['title'] as String?)?.trim();
  final uuid = (raw['uuid'] as String?)?.trim() ?? '';
  final externalId = uuid.isNotEmpty
      ? uuid
      : '${start.toUtc().millisecondsSinceEpoch}_$typeName';

  final distanceMeters = (raw['totalDistance'] as num?)?.toDouble();
  final caloriesKcal = (raw['totalEnergyBurned'] as num?)?.toDouble();
  final pace = distanceMeters != null &&
          distanceMeters > 0 &&
          durationSeconds > 0
      ? (durationSeconds / (distanceMeters / 1000)).round()
      : null;

  return GoogleHealthImportableActivity(
    externalId: externalId,
    name: (title != null && title.isNotEmpty)
        ? title
        : _humanizeWorkoutType(typeName),
    typeId: _mapWorkoutTypeId(typeName),
    startDate: start,
    endDate: end.isBefore(start) ? start : end,
    durationSeconds: durationSeconds > 0 ? durationSeconds : null,
    distanceMeters: distanceMeters != null && distanceMeters > 0
        ? distanceMeters
        : null,
    paceSecondsPerKm: pace,
    caloriesKcal:
        caloriesKcal != null && caloriesKcal > 0 ? caloriesKcal : null,
    workoutActivityType: typeName,
  );
}

String _mapWorkoutTypeId(String type) {
  switch (type) {
    case 'SWIMMING':
    case 'SWIMMING_OPEN_WATER':
    case 'SWIMMING_POOL':
    case 'WATER_FITNESS':
      return 'natation';
    case 'BIKING':
    case 'BIKING_STATIONARY':
    case 'HAND_CYCLING':
      return 'velo';
    case 'WALKING':
    case 'WALKING_TREADMILL':
    case 'HIKING':
    case 'SNOWSHOEING':
      return 'sortie_longue';
    case 'RUNNING':
    case 'RUNNING_TREADMILL':
    case 'TRACK_AND_FIELD':
      return 'course';
    case 'SOCCER':
    case 'FOOTBALL_SOCCER':
      return 'entrainement';
    case 'YOGA':
    case 'PILATES':
    case 'COOLDOWN':
    case 'FLEXIBILITY':
    case 'PREPARATION_AND_RECOVERY':
    case 'MIND_AND_BODY':
    case 'GUIDED_BREATHING':
    case 'TAI_CHI':
      return 'recuperation';
    default:
      return 'entrainement';
  }
}

String _humanizeWorkoutType(String type) {
  final raw = type.replaceAll('_', ' ').toLowerCase();
  return raw.replaceAllMapped(
    RegExp(r'\b\w'),
    (match) => match.group(0)!.toUpperCase(),
  );
}
