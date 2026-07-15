import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/strava_config.dart';
import 'package:grinta/model/strava_sync_config.dart';
import 'package:grinta/services/strava_sync_repository.dart';
import 'package:url_launcher/url_launcher.dart';

enum StravaConnectResult {
  success,
  cancelled,
  launchFailed,
  unauthenticated,
  failed,
}

class StravaSyncService {
  StravaSyncService._();

  static final StravaSyncService instance = StravaSyncService._();

  final StravaSyncRepository _repository = StravaSyncRepository();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: kStravaFunctionsRegion);

  StravaSyncRepository get repository => _repository;

  Future<StravaConnectResult> startOAuth({
    required String playerId,
    required String initiatedBy,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return StravaConnectResult.unauthenticated;
    }

    try {
      final callable = _functions.httpsCallable(kStravaOAuthStartFunctionName);
      final result = await callable.call(<String, dynamic>{
        'playerId': playerId,
        'initiatedBy': initiatedBy,
      });

      final data = result.data;
      if (data is! Map) {
        return StravaConnectResult.failed;
      }

      final authUrl = data['authUrl']?.toString().trim();
      if (authUrl == null || authUrl.isEmpty) {
        return StravaConnectResult.failed;
      }

      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );
      return launched
          ? StravaConnectResult.success
          : StravaConnectResult.launchFailed;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('stravaOAuthStart failed: ${e.code} ${e.message}\n$st');
      return StravaConnectResult.failed;
    } catch (e, st) {
      debugPrint('stravaOAuthStart error: $e\n$st');
      return StravaConnectResult.failed;
    }
  }

  Future<bool> disconnect({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final callable = _functions.httpsCallable(kStravaDisconnectFunctionName);
      await callable.call(<String, dynamic>{'playerId': playerId});
      return true;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('stravaDisconnect failed: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('stravaDisconnect error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateCoachVisibility({
    required String uid,
    required String playerId,
    required StravaCoachVisibility visibility,
  }) async {
    try {
      await _repository.updateCoachVisibility(
        uid: uid,
        playerId: playerId,
        visibility: visibility,
      );
      return true;
    } catch (e, st) {
      debugPrint('updateCoachVisibility error: $e\n$st');
      return false;
    }
  }

  /// Resolves the Firestore owner uid for a stravaSync document.
  String syncOwnerUidForPlayer({
    required String uid,
    required String playerId,
  }) {
    return uid;
  }
}
