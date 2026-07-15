import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/apple_health_sync_config.dart';
import 'package:grinta/services/apple_health_platform.dart';
import 'package:grinta/services/apple_health_sync_repository.dart';

enum AppleHealthConnectResult {
  success,
  iosOnly,
  denied,
  unauthenticated,
  failed,
}

class AppleHealthSyncService {
  AppleHealthSyncService._();

  static final AppleHealthSyncService instance = AppleHealthSyncService._();

  final AppleHealthSyncRepository _repository = AppleHealthSyncRepository();

  AppleHealthSyncRepository get repository => _repository;

  /// Requests HealthKit authorization on iOS and stores connection metadata.
  ///
  /// Full workout sync to Firestore is Phase 2 — see docs/apple-health-integration.md.
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
}
