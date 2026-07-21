import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/whoop_config.dart';
import 'package:grinta/model/whoop_sync_config.dart';
import 'package:grinta/services/whoop_sync_repository.dart';
import 'package:url_launcher/url_launcher.dart';

enum WhoopConnectResult {
  success,
  cancelled,
  launchFailed,
  unauthenticated,
  failed,
}

class WhoopSyncService {
  WhoopSyncService._();

  static final WhoopSyncService instance = WhoopSyncService._();

  final WhoopSyncRepository _repository = WhoopSyncRepository();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: kWhoopFunctionsRegion);

  WhoopSyncRepository get repository => _repository;

  Future<WhoopConnectResult> startOAuth({
    required String playerId,
    required String initiatedBy,
    String? whoopAccountHint,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return WhoopConnectResult.unauthenticated;
    }

    final hint = whoopAccountHint?.trim() ?? '';
    if (hint.isEmpty) {
      return WhoopConnectResult.failed;
    }

    try {
      final callable = _functions.httpsCallable(kWhoopOAuthStartFunctionName);
      final payload = <String, dynamic>{
        'playerId': playerId,
        'initiatedBy': initiatedBy,
        'whoopAccountHint': hint,
      };
      if (kIsWeb) {
        // Cloud Function redirects back here after OAuth (grinta:// is mobile-only).
        payload['returnTo'] = Uri.base.origin;
      }
      final result = await callable.call(payload);

      final data = result.data;
      if (data is! Map) {
        return WhoopConnectResult.failed;
      }

      final authUrl = data['authUrl']?.toString().trim();
      if (authUrl == null || authUrl.isEmpty) {
        return WhoopConnectResult.failed;
      }

      // Web: stay in the same tab so OAuth returns to this Flutter session.
      // Mobile: open the system browser, then return via grinta:// deep link.
      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_self' : null,
      );
      return launched ? WhoopConnectResult.success : WhoopConnectResult.launchFailed;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('whoopOAuthStart failed: ${e.code} ${e.message}\n$st');
      return WhoopConnectResult.failed;
    } catch (e, st) {
      debugPrint('whoopOAuthStart error: $e\n$st');
      return WhoopConnectResult.failed;
    }
  }

  Future<bool> disconnect({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final callable = _functions.httpsCallable(kWhoopDisconnectFunctionName);
      await callable.call(<String, dynamic>{'playerId': playerId});
      return true;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('whoopDisconnect failed: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('whoopDisconnect error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateCoachVisibility({
    required String uid,
    required String playerId,
    required WhoopCoachVisibility visibility,
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

}
