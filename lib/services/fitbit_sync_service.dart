import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/fitbit_config.dart';
import 'package:grinta/model/fitbit_sync_config.dart';
import 'package:grinta/services/fitbit_sync_repository.dart';
import 'package:url_launcher/url_launcher.dart';

enum FitbitConnectResult {
  success,
  cancelled,
  launchFailed,
  unauthenticated,
  failed,
}

class FitbitSyncService {
  FitbitSyncService._();

  static final FitbitSyncService instance = FitbitSyncService._();

  final FitbitSyncRepository _repository = FitbitSyncRepository();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: kFitbitFunctionsRegion);

  FitbitSyncRepository get repository => _repository;

  Future<FitbitConnectResult> startOAuth({
    required String playerId,
    required String initiatedBy,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return FitbitConnectResult.unauthenticated;
    }

    try {
      final callable = _functions.httpsCallable(kFitbitOAuthStartFunctionName);
      final result = await callable.call(<String, dynamic>{
        'playerId': playerId,
        'initiatedBy': initiatedBy,
      });

      final data = result.data;
      if (data is! Map) {
        return FitbitConnectResult.failed;
      }

      final authUrl = data['authUrl']?.toString().trim();
      if (authUrl == null || authUrl.isEmpty) {
        return FitbitConnectResult.failed;
      }

      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );
      return launched
          ? FitbitConnectResult.success
          : FitbitConnectResult.launchFailed;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('fitbitOAuthStart failed: ${e.code} ${e.message}\n$st');
      return FitbitConnectResult.failed;
    } catch (e, st) {
      debugPrint('fitbitOAuthStart error: $e\n$st');
      return FitbitConnectResult.failed;
    }
  }

  Future<bool> disconnect({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final callable = _functions.httpsCallable(kFitbitDisconnectFunctionName);
      await callable.call(<String, dynamic>{'playerId': playerId});
      return true;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('fitbitDisconnect failed: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('fitbitDisconnect error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateCoachVisibility({
    required String uid,
    required String playerId,
    required FitbitCoachVisibility visibility,
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

  /// Resolves the Firestore owner uid for a fitbitSync document.
  String syncOwnerUidForPlayer({
    required String uid,
    required String playerId,
  }) {
    return uid;
  }
}
