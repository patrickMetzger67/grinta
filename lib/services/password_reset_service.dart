import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum PasswordResetResult {
  sent,
  invalidEmail,
  userNotFound,
  failed,
}

/// Sends a password-reset email.
///
/// 1) Cloud Function `sendPasswordResetMail` → Grinta-branded mail via `mail`
/// 2) On any CF failure (except invalid email / user-not-found) → Firebase Auth
///    `sendPasswordResetEmail` so the login flow is never blocked.
class PasswordResetService {
  PasswordResetService({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'europe-west1'),
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Future<PasswordResetResult> sendResetEmail({
    required String email,
    String locale = 'fr',
  }) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty || !_looksLikeEmail(trimmed)) {
      return PasswordResetResult.invalidEmail;
    }

    final branded = await _tryBrandedCloudFunction(
      email: trimmed,
      locale: locale,
    );
    if (branded != null) {
      return branded;
    }

    return _sendViaFirebaseAuth(trimmed);
  }

  /// Returns a result when CF handled the request, or null to fall back to Auth.
  Future<PasswordResetResult?> _tryBrandedCloudFunction({
    required String email,
    required String locale,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendPasswordResetMail');
      await callable.call(<String, dynamic>{
        'email': email,
        'locale': locale,
      });
      debugPrint('PasswordResetService: branded CF mail queued');
      return PasswordResetResult.sent;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint(
        'PasswordResetService: branded CF failed '
        'code=${e.code} message=${e.message} details=${e.details}\n$st',
      );

      if (e.message == 'invalid-email' || e.code == 'invalid-argument') {
        return PasswordResetResult.invalidEmail;
      }
      if (e.message == 'user-not-found') {
        return PasswordResetResult.userNotFound;
      }

      // link-failed, deploy/IAM/transport, etc. → Auth fallback.
      return null;
    } catch (e, st) {
      debugPrint('PasswordResetService: branded CF unexpected: $e\n$st');
      return null;
    }
  }

  Future<PasswordResetResult> _sendViaFirebaseAuth(String email) async {
    try {
      debugPrint(
        'PasswordResetService: Auth fallback sendPasswordResetEmail',
      );
      await _auth.sendPasswordResetEmail(email: email);
      return PasswordResetResult.sent;
    } on FirebaseAuthException catch (e, st) {
      debugPrint(
        'PasswordResetService: Auth fallback failed '
        'code=${e.code} message=${e.message}\n$st',
      );
      if (e.code == 'invalid-email') {
        return PasswordResetResult.invalidEmail;
      }
      if (e.code == 'user-not-found') {
        return PasswordResetResult.userNotFound;
      }
      return PasswordResetResult.failed;
    } catch (e, st) {
      debugPrint('PasswordResetService: Auth fallback unexpected: $e\n$st');
      return PasswordResetResult.failed;
    }
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }
}
