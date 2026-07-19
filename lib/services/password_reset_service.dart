import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

enum PasswordResetResult {
  sent,
  invalidEmail,
  userNotFound,
  failed,
}

/// Calls Cloud Function `sendPasswordResetMail` (europe-west1).
///
/// Verifies the Auth user exists server-side, generates a reset link, and queues
/// a Grinta-branded email via the `mail` collection.
class PasswordResetService {
  PasswordResetService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

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
        'PasswordResetService.sendResetEmail failed: '
        'code=${e.code} message=${e.message}\n$st',
      );
      if (e.code == 'invalid-argument' || e.message == 'invalid-email') {
        return PasswordResetResult.invalidEmail;
      }
      if (e.code == 'not-found' || e.message == 'user-not-found') {
        return PasswordResetResult.userNotFound;
      }
      return PasswordResetResult.failed;
    } catch (e, st) {
      debugPrint('PasswordResetService.sendResetEmail unexpected: $e\n$st');
      return PasswordResetResult.failed;
    }
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }
}
