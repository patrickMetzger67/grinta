import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/apple_health_importable_activity.dart';
import 'package:grinta/model/apple_health_sync_config.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/services/apple_health_platform.dart';
import 'package:grinta/services/apple_health_sync_repository.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';

enum AppleHealthConnectResult {
  success,
  iosOnly,
  denied,
  unauthenticated,
  failed,
}

class AppleHealthListActivitiesResult {
  const AppleHealthListActivitiesResult({
    required this.activities,
    this.errorCode,
    this.errorMessage,
  });

  final List<AppleHealthImportableActivity> activities;
  final String? errorCode;
  final String? errorMessage;

  bool get hasError => errorCode != null && errorCode!.isNotEmpty;
}

class AppleHealthSyncService {
  AppleHealthSyncService._();

  static final AppleHealthSyncService instance = AppleHealthSyncService._();

  final AppleHealthSyncRepository _repository = AppleHealthSyncRepository();
  final PersonalSportActivityService _activities =
      PersonalSportActivityService();

  AppleHealthSyncRepository get repository => _repository;

  static const String externalSource = 'appleHealth';

  /// Requests HealthKit authorization on iOS and stores connection metadata.
  Future<AppleHealthConnectResult> connect({
    required String playerId,
    required String initiatedBy,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return AppleHealthConnectResult.unauthenticated;
    }

    if (!isAppleHealthSupported) {
      return AppleHealthConnectResult.iosOnly;
    }

    try {
      final platformResult = await authorizeAndProbeWorkouts();
      if (!platformResult.authorized) {
        return AppleHealthConnectResult.denied;
      }

      await _repository.markConnected(
        uid: uid,
        playerId: playerId,
        initiatedBy: initiatedBy,
        recentWorkoutCount: platformResult.recentWorkoutCount,
        mostRecentWorkoutAt: platformResult.mostRecentWorkoutAt,
      );
      return AppleHealthConnectResult.success;
    } catch (e, st) {
      debugPrint('Apple Health connect error: $e\n$st');
      return AppleHealthConnectResult.failed;
    }
  }

  /// Clears Grinta connection state. User must revoke HealthKit access in iOS Settings.
  Future<bool> disconnect({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      await _repository.markDisconnected(uid: uid, playerId: playerId);
      return true;
    } catch (e, st) {
      debugPrint('Apple Health disconnect error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateCoachVisibility({
    required String uid,
    required String playerId,
    required AppleHealthCoachVisibility visibility,
  }) async {
    try {
      await _repository.updateCoachVisibility(
        uid: uid,
        playerId: playerId,
        visibility: visibility,
      );
      return true;
    } catch (e, st) {
      debugPrint('Apple Health updateCoachVisibility error: $e\n$st');
      return false;
    }
  }

  String syncOwnerUidForPlayer({
    required String uid,
    required String playerId,
  }) {
    return uid;
  }

  /// Lists HealthKit workouts not yet imported into Grinta (iOS only).
  Future<AppleHealthListActivitiesResult> listImportableActivities({
    required String playerId,
    int lookbackDays = 90,
  }) async {
    if (!isAppleHealthSupported) {
      return const AppleHealthListActivitiesResult(
        activities: [],
        errorCode: 'ios-only',
      );
    }

    try {
      final workouts = await listAppleHealthWorkouts(
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
      return AppleHealthListActivitiesResult(activities: activities);
    } catch (e, st) {
      debugPrint('Apple Health listImportableActivities error: $e\n$st');
      return AppleHealthListActivitiesResult(
        activities: const [],
        errorCode: 'unknown',
        errorMessage: e.toString(),
      );
    }
  }

  /// Imports one HealthKit workout into `personalSportActivities`.
  Future<PersonalSportActivity?> importActivity({
    required String playerId,
    required AppleHealthImportableActivity workout,
    String visibility = 'private',
    int? feeling,
    String? notes,
    String? typeId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    if (!isAppleHealthSupported) return null;

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
      debugPrint('Apple Health importActivity error: $e\n$st');
      return null;
    }
  }
}
