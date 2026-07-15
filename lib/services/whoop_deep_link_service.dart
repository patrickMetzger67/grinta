import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/whoop_config.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/util/app_snackbar.dart';

/// Handles `grinta://whoop/callback?success=1&playerId=...` after OAuth.
class WhoopDeepLinkService {
  WhoopDeepLinkService._();

  static final WhoopDeepLinkService instance = WhoopDeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  final ValueNotifier<WhoopOAuthCallbackResult?> lastCallbackResult =
      ValueNotifier(null);

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      await _capturePlatformLinks(source: 'init');

      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) => _handleUri(uri, source: 'uriLinkStream'),
        onError: (Object error, StackTrace stackTrace) {
          _log('stream error: $error\n$stackTrace');
        },
      );
    } catch (e, st) {
      _log('init error: $e\n$st');
    }
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
  }

  Future<void> _capturePlatformLinks({required String source}) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      final latestUri = await _appLinks.getLatestLink();

      for (final uri in <Uri?>[initialUri, latestUri]) {
        if (uri != null) {
          _handleUri(uri, source: source);
        }
      }
    } catch (e, st) {
      _log('_capturePlatformLinks($source) error: $e\n$st');
    }
  }

  void _handleUri(Uri uri, {required String source}) {
    if (!_isWhoopCallback(uri)) {
      return;
    }

    _log('received from $source: $uri');

    final success = uri.queryParameters['success'] == '1';
    final error = uri.queryParameters['error'];
    final playerId = uri.queryParameters['playerId'];

    final result = WhoopOAuthCallbackResult(
      success: success,
      error: error,
      playerId: playerId,
    );
    lastCallbackResult.value = result;

    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    if (success) {
      AppSnackbar.show(
        context,
        context.l10n.whoopConnectSuccess,
        isError: false,
      );
    } else {
      AppSnackbar.show(
        context,
        context.l10n.whoopConnectFailed,
        isError: true,
      );
    }
  }

  static bool _isWhoopCallback(Uri uri) {
    if (uri.scheme != 'grinta') return false;
    if (uri.host == kWhoopOAuthDeepLinkHost) return true;
    if (uri.path == kWhoopOAuthDeepLinkPath ||
        uri.path == '$kWhoopOAuthDeepLinkPath/') {
      return true;
    }
    return false;
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[WhoopDeepLink] $message');
  }
}

class WhoopOAuthCallbackResult {
  const WhoopOAuthCallbackResult({
    required this.success,
    this.error,
    this.playerId,
  });

  final bool success;
  final String? error;
  final String? playerId;
}
