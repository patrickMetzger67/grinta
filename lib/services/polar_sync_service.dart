import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/polar_config.dart';
import 'package:grinta/model/polar_sync_config.dart';
import 'package:grinta/services/polar_sync_repository.dart';
import 'package:url_launcher/url_launcher.dart';

enum PolarConnectResult {
  success,
  cancelled,
  launchFailed,
  unauthenticated,
  failed,
}

class PolarSyncService {
  PolarSyncService._();

  static final PolarSyncService instance = PolarSyncService._();

  final PolarSyncRepository _repository = PolarSyncRepository();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: kPolarFunctionsRegion);

  PolarSyncRepository get repository => _repository;

  Future<PolarConnectResult> startOAuth({
    required String playerId,
    required String initiatedBy,
    String? polarAccountHint,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return PolarConnectResult.unauthenticated;
    }

    final hint = polarAccountHint?.trim() ?? '';
    if (hint.isEmpty) {
      return PolarConnectResult.failed;
    }

    try {
      final callable = _functions.httpsCallable(kPolarOAuthStartFunctionName);
      final payload = <String, dynamic>{
        'playerId': playerId,
        'initiatedBy': initiatedBy,
        'polarAccountHint': hint,
      };
      if (kIsWeb) {
        // Cloud Function redirects back here after OAuth (grinta:// is mobile-only).
        payload['returnTo'] = Uri.base.origin;
      }
      final result = await callable.call(payload);

      final data = result.data;
      if (data is! Map) {
        return PolarConnectResult.failed;
      }

      final authUrl = data['authUrl']?.toString().trim();
      if (authUrl == null || authUrl.isEmpty) {
        return PolarConnectResult.failed;
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
      return launched
          ? PolarConnectResult.success
          : PolarConnectResult.launchFailed;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('polarOAuthStart failed: ${e.code} ${e.message}\n$st');
      return PolarConnectResult.failed;
    } catch (e, st) {
      debugPrint('polarOAuthStart error: $e\n$st');
      return PolarConnectResult.failed;
    }
  }

  Future<bool> disconnect({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final callable = _functions.httpsCallable(kPolarDisconnectFunctionName);
      await callable.call(<String, dynamic>{'playerId': playerId});
      return true;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('polarDisconnect failed: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('polarDisconnect error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateCoachVisibility({
    required String uid,
    required String playerId,
    required PolarCoachVisibility visibility,
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
