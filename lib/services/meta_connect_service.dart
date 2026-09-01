import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/meta_config.dart';
import 'package:grinta/model/meta_sync_config.dart';
import 'package:grinta/services/meta_sync_repository.dart';
import 'package:url_launcher/url_launcher.dart';

enum MetaConnectResult {
  success,
  cancelled,
  launchFailed,
  unauthenticated,
  failed,
}

class MetaConnectService {
  MetaConnectService._();

  static final MetaConnectService instance = MetaConnectService._();

  final MetaSyncRepository repository = MetaSyncRepository();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: kMetaFunctionsRegion);

  Future<MetaSyncConfig?> readStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return null;
    return repository.getConfig(uid);
  }

  Future<MetaConnectResult> startOAuth() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return MetaConnectResult.unauthenticated;
    }

    try {
      final callable = _functions.httpsCallable(kMetaOAuthStartFunctionName);
      final result = await callable.call(<String, dynamic>{});
      final data = result.data;
      if (data is! Map) return MetaConnectResult.failed;

      final authUrl = data['authUrl']?.toString().trim();
      if (authUrl == null || authUrl.isEmpty) {
        return MetaConnectResult.failed;
      }

      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_self' : null,
      );
      return launched
          ? MetaConnectResult.success
          : MetaConnectResult.launchFailed;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('metaOAuthStart failed: ${e.code} ${e.message}\n$st');
      return MetaConnectResult.failed;
    } catch (e, st) {
      debugPrint('metaOAuthStart error: $e\n$st');
      return MetaConnectResult.failed;
    }
  }

  Future<bool> disconnect() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final callable = _functions.httpsCallable(kMetaDisconnectFunctionName);
      await callable.call(<String, dynamic>{});
      return true;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('metaDisconnect failed: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('metaDisconnect error: $e\n$st');
      return false;
    }
  }
}
