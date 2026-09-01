import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captures invite deep links (`grinta://invite?code=GT1234` or
/// `https://grinta.io/invite?code=…`) and holds the code for signup.
class InvitationDeepLinkService {
  InvitationDeepLinkService._();

  static final InvitationDeepLinkService instance =
      InvitationDeepLinkService._();

  static const String _prefsKey = 'pending_invitation_code';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  String? _pendingCode;

  /// Latest invite code from a deep link / landing page, if any.
  String? get pendingCode => _pendingCode;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey)?.trim();
      if (stored != null && stored.isNotEmpty) {
        _pendingCode = stored;
      }

      if (kIsWeb) {
        _captureWebUri(Uri.base);
      } else {
        final initial = await _appLinks.getInitialLink();
        if (initial != null) {
          _captureUri(initial);
        }
        _linkSubscription = _appLinks.uriLinkStream.listen(
          _captureUri,
          onError: (Object error, StackTrace st) {
            debugPrint('InvitationDeepLinkService stream error: $error\n$st');
          },
        );
      }
    } catch (e, st) {
      debugPrint('InvitationDeepLinkService.init failed: $e\n$st');
    }
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
  }

  /// Stores [code] for the next signup invitation step.
  Future<void> setPendingCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;
    _pendingCode = normalized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, normalized);
    } catch (e, st) {
      debugPrint('InvitationDeepLinkService.setPendingCode failed: $e\n$st');
    }
  }

  /// Returns and clears the pending code (once).
  Future<String?> takePendingCode() async {
    final code = _pendingCode?.trim();
    _pendingCode = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
    if (code == null || code.isEmpty) return null;
    return code;
  }

  void _captureWebUri(Uri uri) {
    final hostPath = '${uri.host}${uri.path}'.toLowerCase();
    final looksLikeInvite = uri.path.toLowerCase().contains('/invite') ||
        hostPath.contains('invite');
    final code = uri.queryParameters['code']?.trim() ??
        uri.queryParameters['invite']?.trim();
    if ((looksLikeInvite || (code != null && code.isNotEmpty)) &&
        code != null &&
        code.isNotEmpty) {
      unawaited(setPendingCode(code));
    }
  }

  void _captureUri(Uri uri) {
    if (!_isInviteLink(uri)) return;
    final code = uri.queryParameters['code']?.trim() ??
        uri.queryParameters['invite']?.trim();
    if (code == null || code.isEmpty) return;
    unawaited(setPendingCode(code));
  }

  static bool _isInviteLink(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'grinta' && uri.host.toLowerCase() == 'invite') {
      return true;
    }
    if ((scheme == 'https' || scheme == 'http') &&
        uri.path.toLowerCase().contains('/invite')) {
      return true;
    }
    return false;
  }

  @visibleForTesting
  static bool isInviteLinkForTest(Uri uri) => _isInviteLink(uri);
}
