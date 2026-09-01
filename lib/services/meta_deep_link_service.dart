import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/meta_config.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/meta_share_strings.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/util/app_snackbar.dart';

/// Handles `grinta://meta/callback?success=1` after optional Meta OAuth.
class MetaDeepLinkService {
  MetaDeepLinkService._();

  static final MetaDeepLinkService instance = MetaDeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  final ValueNotifier<MetaOAuthCallbackResult?> lastCallbackResult =
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
    if (!_isMetaCallback(uri)) return;

    _log('received from $source: $uri');

    final result = MetaOAuthCallbackResult(
      success: uri.queryParameters['success'] == '1',
      error: uri.queryParameters['error'],
    );
    lastCallbackResult.value = result;

    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final strings = MetaShareStrings.of(context.l10n);
    if (result.success) {
      AppSnackbar.show(context, strings.connectSuccess, isError: false);
    } else {
      AppSnackbar.show(context, strings.connectFailed, isError: true);
    }
  }

  static bool _isMetaCallback(Uri uri) {
    if (uri.scheme != 'grinta') return false;
    if (uri.host == kMetaOAuthDeepLinkHost) return true;
    if (uri.path == kMetaOAuthDeepLinkPath ||
        uri.path == '$kMetaOAuthDeepLinkPath/') {
      return true;
    }
    return false;
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[MetaDeepLink] $message');
  }
}

class MetaOAuthCallbackResult {
  const MetaOAuthCallbackResult({
    required this.success,
    this.error,
  });

  final bool success;
  final String? error;
}
