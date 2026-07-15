import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/google_health_sync_config.dart';
import 'package:grinta/services/google_health_platform.dart';
import 'package:grinta/services/google_health_sync_repository.dart';

enum GoogleHealthConnectResult {
  success,
  androidOnly,
  denied,
  unauthenticated,
  failed,
}

class GoogleHealthSyncService {
  GoogleHealthSyncService._();

  static final GoogleHealthSyncService instance = GoogleHealthSyncService._();

  final GoogleHealthSyncRepository _repository = GoogleHealthSyncRepository();

  GoogleHealthSyncRepository get repository => _repository;

  /// Requests Health Connect authorization on Android and stores connection metadata.
  ///
  /// Full workout sync to Firestore is Phase 2 — see docs/google-health-connect-integration.md.
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
}
