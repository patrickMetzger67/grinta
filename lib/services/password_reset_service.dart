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
/// Preferred path: Cloud Function `sendPasswordResetMail` (europe-west1), which
/// verifies the Auth user, generates a reset link, and queues a Grinta-branded
/// email via the `mail` collection.
///
/// Fallback: Firebase Auth `sendPasswordResetEmail` when the callable fails
/// with a transport/internal error (missing deploy, unauthorized continue URL, …).
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

    try {
      final callable = _functions.httpsCallable('sendPasswordResetMail');
      await callable.call(<String, dynamic>{
        'email': trimmed,
        'locale': locale,
      });
      return PasswordResetResult.sent;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint(
        'PasswordResetService.sendResetEmail CF failed: '
        'code=${e.code} message=${e.message} details=${e.details}\n$st',
      );

      // Business errors from our CF — do not fall back.
      if (e.message == 'invalid-email' || e.code == 'invalid-argument') {
        return PasswordResetResult.invalidEmail;
      }
      if (e.message == 'user-not-found') {
        return PasswordResetResult.userNotFound;
      }

      // link-failed / missing deploy / IAM / transport → Auth fallback.
      if (_shouldFallbackToAuth(e)) {
        return _sendViaFirebaseAuth(trimmed);
      }

      return PasswordResetResult.failed;
    } catch (e, st) {
      debugPrint('PasswordResetService.sendResetEmail unexpected: $e\n$st');
      return _sendViaFirebaseAuth(trimmed);
    }
  }

  Future<PasswordResetResult> _sendViaFirebaseAuth(String email) async {
    try {
      debugPrint(
        'PasswordResetService: falling back to FirebaseAuth.sendPasswordResetEmail',
      );
      // No ActionCodeSettings: avoids unauthorized-continue-uri when
      // https://grinta.io is not in Auth authorized domains.
      await _auth.sendPasswordResetEmail(email: email);
      return PasswordResetResult.sent;
    } on FirebaseAuthException catch (e, st) {
      debugPrint(
        'PasswordResetService Auth fallback failed: '
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
      debugPrint('PasswordResetService Auth fallback unexpected: $e\n$st');
      return PasswordResetResult.failed;
    }
  }

  static bool _shouldFallbackToAuth(FirebaseFunctionsException e) {
    if (e.message == 'link-failed' || e.message == 'mail-queue-failed') {
      return true;
    }
    const fallbackCodes = <String>{
      'internal',
      'not-found',
      'unavailable',
      'deadline-exceeded',
      'unknown',
    };
    return fallbackCodes.contains(e.code);
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }
}
