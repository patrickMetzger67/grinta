import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/config/polar_config.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/services/polar_web_return_cleanup.dart';
import 'package:grinta/util/app_snackbar.dart';

/// Handles Polar OAuth return:
/// - mobile: `grinta://polar/callback?success=1&playerId=...`
/// - web: `https://.../?polarOAuth=1&success=1&playerId=...`
class PolarDeepLinkService {
  PolarDeepLinkService._();

  static final PolarDeepLinkService instance = PolarDeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  final ValueNotifier<PolarOAuthCallbackResult?> lastCallbackResult =
      ValueNotifier(null);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      _handleWebReturn();
      return;
    }

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

  void _handleWebReturn() {
    try {
      final uri = Uri.base;
      if (uri.queryParameters['polarOAuth'] != '1') return;

      _log('web return: $uri');
      _handleUri(uri, source: 'web');
      cleanPolarOAuthQueryParams();
    } catch (e, st) {
      _log('_handleWebReturn error: $e\n$st');
    }
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
    final isWebReturn = kIsWeb && uri.queryParameters['polarOAuth'] == '1';
    if (!isWebReturn && !_isPolarCallback(uri)) {
      return;
    }

    _log('received from $source: $uri');

    final success = uri.queryParameters['success'] == '1';
    final error = uri.queryParameters['error'];
    final playerId = uri.queryParameters['playerId'];

    final result = PolarOAuthCallbackResult(
      success: success,
      error: error,
      playerId: playerId,
    );
    lastCallbackResult.value = result;

    // Defer snackbar until navigator context is available.
    scheduleMicrotask(() => _showResultSnackbar(result));
  }

  void _showResultSnackbar(PolarOAuthCallbackResult result) {
    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        final delayedContext = appNavigatorKey.currentContext;
        if (delayedContext == null || !delayedContext.mounted) return;
        _presentSnackbar(delayedContext, result);
      });
      return;
    }
    _presentSnackbar(context, result);
  }

  void _presentSnackbar(
    BuildContext context,
    PolarOAuthCallbackResult result,
  ) {
    if (result.success) {
      AppSnackbar.show(
        context,
        context.l10n.polarConnectSuccess,
        isError: false,
      );
    } else {
      AppSnackbar.show(
        context,
        context.l10n.polarConnectFailed,
        isError: true,
      );
    }
  }

  static bool _isPolarCallback(Uri uri) {
    if (uri.scheme != 'grinta') return false;
    if (uri.host == kPolarOAuthDeepLinkHost) return true;
    if (uri.path == kPolarOAuthDeepLinkPath ||
        uri.path == '$kPolarOAuthDeepLinkPath/') {
      return true;
    }
    return false;
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[PolarDeepLink] $message');
  }
}

class PolarOAuthCallbackResult {
  const PolarOAuthCallbackResult({
    required this.success,
    this.error,
    this.playerId,
  });

  final bool success;
  final String? error;
  final String? playerId;
}
