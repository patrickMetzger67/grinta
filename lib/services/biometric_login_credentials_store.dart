import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Email/password pair kept on-device for biometric sign-in after logout.
class StoredBiometricLoginCredentials {
  const StoredBiometricLoginCredentials({
    required this.email,
    required this.password,
    required this.uid,
  });

  final String email;
  final String password;
  final String uid;
}

/// Keychain / Keystore vault for optional biometric email login (iOS/Android).
///
/// Reads are gated by [BiometricUnlockService.authenticate] before use; this
/// store only persists ciphertext via platform secure storage.
class BiometricLoginCredentialsStore {
  BiometricLoginCredentialsStore({FlutterSecureStorage? storage})
      : _storage = storage ?? createDefaultStorage();

  static const String _emailKey = 'biometric_login_email_v1';
  static const String _passwordKey = 'biometric_login_password_v1';
  static const String _uidKey = 'biometric_login_uid_v1';

  final FlutterSecureStorage _storage;

  static FlutterSecureStorage createDefaultStorage() {
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  Future<bool> hasCredentials() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      return email != null &&
          email.trim().isNotEmpty &&
          password != null &&
          password.isNotEmpty;
    } catch (e) {
      debugPrint('biometric credentials hasCredentials failed: $e');
      return false;
    }
  }

  Future<String?> peekEmail() async {
    try {
      final email = (await _storage.read(key: _emailKey))?.trim();
      if (email == null || email.isEmpty) return null;
      return email;
    } catch (e) {
      debugPrint('biometric credentials peekEmail failed: $e');
      return null;
    }
  }

  Future<void> save({
    required String uid,
    required String email,
    required String password,
  }) async {
    final trimmedUid = uid.trim();
    final trimmedEmail = email.trim();
    if (trimmedUid.isEmpty || trimmedEmail.isEmpty || password.isEmpty) {
      throw ArgumentError('uid, email and password are required');
    }

    await _storage.write(key: _uidKey, value: trimmedUid);
    await _storage.write(key: _emailKey, value: trimmedEmail);
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<StoredBiometricLoginCredentials?> read() async {
    try {
      final email = (await _storage.read(key: _emailKey))?.trim();
      final password = await _storage.read(key: _passwordKey);
      final uid = (await _storage.read(key: _uidKey))?.trim();
      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty ||
          uid == null ||
          uid.isEmpty) {
        return null;
      }
      return StoredBiometricLoginCredentials(
        email: email,
        password: password,
        uid: uid,
      );
    } catch (e) {
      debugPrint('biometric credentials read failed: $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
      await _storage.delete(key: _uidKey);
    } catch (e) {
      debugPrint('biometric credentials clear failed: $e');
    }
  }
}
