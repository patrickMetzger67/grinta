import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/google_health_importable_activity.dart';
import 'package:grinta/model/google_health_sync_config.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/services/google_health_platform.dart';
import 'package:grinta/services/google_health_sync_repository.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';

enum GoogleHealthConnectResult {
  success,
  androidOnly,
  denied,
  unauthenticated,
  failed,
}

class GoogleHealthListActivitiesResult {
  const GoogleHealthListActivitiesResult({
    required this.activities,
    this.errorCode,
    this.errorMessage,
  });

  final List<GoogleHealthImportableActivity> activities;
  final String? errorCode;
  final String? errorMessage;

  bool get hasError => errorCode != null && errorCode!.isNotEmpty;
}

class GoogleHealthSyncService {
  GoogleHealthSyncService._();

  static final GoogleHealthSyncService instance = GoogleHealthSyncService._();

  final GoogleHealthSyncRepository _repository = GoogleHealthSyncRepository();
  final PersonalSportActivityService _activities =
      PersonalSportActivityService();

  GoogleHealthSyncRepository get repository => _repository;

  static const String externalSource = 'googleHealth';

  /// Requests Health Connect authorization on Android and stores connection metadata.
  Future<GoogleHealthConnectResult> connect({
    required String playerId,
    required String initiatedBy,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return GoogleHealthConnectResult.unauthenticated;
    }

    if (!isGoogleHealthConnectSupported) {
      return GoogleHealthConnectResult.androidOnly;
    }

    try {
      final platformResult = await authorizeAndProbeWorkouts();
      if (!platformResult.authorized) {
        return GoogleHealthConnectResult.denied;
      }

      await _repository.markConnected(
        uid: uid,
        playerId: playerId,
        initiatedBy: initiatedBy,
        recentWorkoutCount: platformResult.recentWorkoutCount,
        mostRecentWorkoutAt: platformResult.mostRecentWorkoutAt,
      );
      return GoogleHealthConnectResult.success;
    } catch (e, st) {
      debugPrint('Google Health Connect error: $e\n$st');
      return GoogleHealthConnectResult.failed;
    }
  }

  /// Clears Grinta connection state. User must revoke Health Connect access in Android Settings.
  Future<bool> disconnect({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      await _repository.markDisconnected(uid: uid, playerId: playerId);
      return true;
    } catch (e, st) {
      debugPrint('Google Health Connect disconnect error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateCoachVisibility({
    required String uid,
    required String playerId,
    required GoogleHealthCoachVisibility visibility,
  }) async {
    try {
      await _repository.updateCoachVisibility(
        uid: uid,
        playerId: playerId,
        visibility: visibility,
      );
      return true;
    } catch (e, st) {
      debugPrint('Google Health Connect updateCoachVisibility error: $e\n$st');
      return false;
    }
  }

  String syncOwnerUidForPlayer({
    required String uid,
    required String playerId,
  }) {
    return uid;
  }

  /// Lists Health Connect workouts not yet imported into Grinta (Android only).
  Future<GoogleHealthListActivitiesResult> listImportableActivities({
    required String playerId,
    int lookbackDays = 90,
  }) async {
    if (!isGoogleHealthConnectSupported) {
      return const GoogleHealthListActivitiesResult(
        activities: [],
        errorCode: 'android-only',
      );
    }

    try {
      final workouts = await listGoogleHealthWorkouts(
        lookbackDays: lookbackDays,
      );
      final imported = await _activities.importedExternalIds(
        memberId: playerId,
        externalSource: externalSource,
      );
      final activities = [
        for (final workout in workouts)
          if (!imported.contains(workout.externalId)) workout,
      ];
      return GoogleHealthListActivitiesResult(activities: activities);
    } catch (e, st) {
      debugPrint('Google Health Connect listImportableActivities error: $e\n$st');
      return GoogleHealthListActivitiesResult(
        activities: const [],
        errorCode: 'unknown',
        errorMessage: e.toString(),
      );
    }
  }

  /// Imports one Health Connect workout into `personalSportActivities`.
  Future<PersonalSportActivity?> importActivity({
    required String playerId,
    required GoogleHealthImportableActivity workout,
    String visibility = 'private',
    int? feeling,
    String? notes,
    String? typeId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    if (!isGoogleHealthConnectSupported) return null;

    final externalId = workout.externalId.trim();
    if (externalId.isEmpty) return null;

    try {
      final already = await _activities.hasExternalActivity(
        memberId: playerId,
        externalSource: externalSource,
        externalId: externalId,
      );
      if (already) return null;

      final avgHr = workout.averageHeartRateBpm ??
          await averageHeartRateForWorkout(
            start: workout.startDate,
            end: workout.endDate,
          );

      final visibilityEnum = PersonalSportVisibilityX.fromFirestore(visibility);
      final activity = PersonalSportActivity(
        memberId: playerId,
        createdByUserId: uid,
        startAt: workout.startDate,
        endAt: workout.endDate,
        typeId: (typeId != null && typeId.trim().isNotEmpty)
            ? typeId.trim()
            : workout.typeId,
        title: workout.name,
        visibility: visibilityEnum,
        entryMode: PersonalSportEntryMode.import,
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        feeling: feeling,
        durationSeconds: workout.durationSeconds,
        distanceMeters: workout.distanceMeters,
        paceSecondsPerKm: workout.paceSecondsPerKm,
        caloriesKcal: workout.caloriesKcal,
        averageHeartRateBpm: avgHr,
        distanceUnit: 'km',
        paceUnit: '/km',
        externalSource: externalSource,
        externalId: externalId,
        accessMemberIds: [playerId],
      );

      final saved = await _activities.create(activity);
      return saved;
    } catch (e, st) {
      debugPrint('Google Health Connect importActivity error: $e\n$st');
      return null;
    }
  }
}
