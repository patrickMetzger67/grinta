import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:grinta/services/biometric_login_credentials_store.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional biometric app unlock + email login (Face ID / Touch ID / Android).
///
/// Unlock gates the UI while a Firebase session is already on device.
/// When email/password credentials are saved in secure storage, biometrics can
/// also sign the user back in from [LoginScreen] after logout.
class BiometricUnlockService extends ChangeNotifier
    with WidgetsBindingObserver {
  BiometricUnlockService._({BiometricLoginCredentialsStore? credentialsStore})
      : _credentialsStore =
            credentialsStore ?? BiometricLoginCredentialsStore();

  static final BiometricUnlockService instance = BiometricUnlockService._();

  @visibleForTesting
  factory BiometricUnlockService.forTesting({
    BiometricLoginCredentialsStore? credentialsStore,
  }) {
    return BiometricUnlockService._(credentialsStore: credentialsStore);
  }

  static const String _prefsEnabledKey = 'biometric_unlock_enabled_v1';
  static const String _prefsUidKey = 'biometric_unlock_uid_v1';
  static const String _prefsPromptedKey = 'biometric_unlock_prompted_v1';

  final LocalAuthentication _auth = LocalAuthentication();
  final BiometricLoginCredentialsStore _credentialsStore;

  bool _initialized = false;
  bool _enabled = false;
  String? _enabledUid;
  bool _prompted = false;
  bool _unlockedThisSession = false;
  bool _authInProgress = false;
  bool _hardwareAvailable = false;
  bool _hasSavedLoginCredentials = false;
  String? _savedLoginEmailHint;
  List<BiometricType> _availableBiometrics = const <BiometricType>[];

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  bool get isInitialized => _initialized;
  bool get isEnabled => _enabled;
  String? get enabledUid => _enabledUid;
  bool get hasPrompted => _prompted;
  bool get isHardwareAvailable => _hardwareAvailable;
  bool get isLocked =>
      isSupportedPlatform && _enabled && !_unlockedThisSession;
  bool get authInProgress => _authInProgress;
  bool get hasSavedLoginCredentials =>
      isSupportedPlatform && _hasSavedLoginCredentials;
  String? get savedLoginEmailHint => _savedLoginEmailHint;
  bool get canOfferBiometricLogin =>
      hasSavedLoginCredentials && _hardwareAvailable && !_authInProgress;
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  Future<void> ensureInitialized() async {
    if (_initialized || !isSupportedPlatform) {
      _initialized = true;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsEnabledKey) ?? false;
    _enabledUid = prefs.getString(_prefsUidKey);
    _prompted = prefs.getBool(_prefsPromptedKey) ?? false;

    await refreshAvailability();
    await _refreshSavedLoginCredentialsState();

    WidgetsBinding.instance.addObserver(this);
    _initialized = true;
    notifyListeners();
  }

  Future<void> refreshAvailability() async {
    if (!isSupportedPlatform) {
      _hardwareAvailable = false;
      _availableBiometrics = const <BiometricType>[];
      return;
    }

    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool supported = await _auth.isDeviceSupported();
      _availableBiometrics = await _auth.getAvailableBiometrics();
      _hardwareAvailable =
          (canCheck || supported) && _availableBiometrics.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('biometric availability failed: $e');
      _hardwareAvailable = false;
      _availableBiometrics = const <BiometricType>[];
    }
  }

  /// Call when Firebase auth emits a restored/signed-in user.
  Future<void> bindUser(String uid) async {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return;

    if (_enabled &&
        (_enabledUid == null || _enabledUid!.isEmpty || _enabledUid != trimmed)) {
      // Preference belonged to another account — disable quietly.
      await setEnabled(false, uid: trimmed);
      return;
    }

    if (_enabled && _enabledUid == trimmed && !_unlockedThisSession) {
      notifyListeners();
    }
  }

  void markUnlocked() {
    if (!_unlockedThisSession) {
      _unlockedThisSession = true;
      notifyListeners();
    }
  }

  void onSignedOut() {
    _unlockedThisSession = false;
    notifyListeners();
  }

  Future<void> markPrompted() async {
    _prompted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsPromptedKey, true);
  }

  Future<bool> setEnabled(
    bool enabled, {
    required String uid,
    String? email,
    String? password,
  }) async {
    if (!isSupportedPlatform) return false;

    final trimmed = uid.trim();
    if (trimmed.isEmpty) return false;

    if (enabled) {
      await refreshAvailability();
      if (!_hardwareAvailable) return false;

      final ok = await authenticate(
        reasonFallback: 'Authenticate to enable biometric unlock',
      );
      if (!ok) return false;

      _enabled = true;
      _enabledUid = trimmed;
      _unlockedThisSession = true;
      _prompted = true;

      final trimmedEmail = email?.trim() ?? '';
      final passwordValue = password;
      if (trimmedEmail.isNotEmpty &&
          passwordValue != null &&
          passwordValue.isNotEmpty) {
        await saveLoginCredentials(
          uid: trimmed,
          email: trimmedEmail,
          password: passwordValue,
        );
      }
    } else {
      _enabled = false;
      _enabledUid = null;
      await clearSavedLoginCredentials();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabledKey, _enabled);
    if (_enabledUid == null) {
      await prefs.remove(_prefsUidKey);
    } else {
      await prefs.setString(_prefsUidKey, _enabledUid!);
    }
    await prefs.setBool(_prefsPromptedKey, _prompted);
    notifyListeners();
    return true;
  }

  /// Persists email/password for biometric re-login (Keychain / Keystore).
  Future<void> saveLoginCredentials({
    required String uid,
    required String email,
    required String password,
  }) async {
    if (!isSupportedPlatform) return;
    await _credentialsStore.save(
      uid: uid,
      email: email,
      password: password,
    );
    await _refreshSavedLoginCredentialsState();
    notifyListeners();
  }

  Future<void> clearSavedLoginCredentials() async {
    await _credentialsStore.clear();
    _hasSavedLoginCredentials = false;
    _savedLoginEmailHint = null;
    notifyListeners();
  }

  /// Disables unlock + clears vault (e.g. "use another account").
  Future<void> disableForAnotherAccount() async {
    final uid = _enabledUid?.trim().isNotEmpty == true
        ? _enabledUid!.trim()
        : 'unknown';
    await setEnabled(false, uid: uid);
  }

  /// Biometric challenge then read vaulted email/password.
  Future<StoredBiometricLoginCredentials?> authenticateAndReadLoginCredentials({
    required String localizedReason,
  }) async {
    if (!canOfferBiometricLogin && !hasSavedLoginCredentials) return null;

    final ok = await authenticate(localizedReason: localizedReason);
    if (!ok) return null;

    final credentials = await _credentialsStore.read();
    if (credentials == null) {
      await clearSavedLoginCredentials();
      return null;
    }
    return credentials;
  }

  Future<bool> authenticate({String? localizedReason, String? reasonFallback}) async {
    if (!isSupportedPlatform) return false;
    if (_authInProgress) return false;

    await refreshAvailability();
    if (!_hardwareAvailable) return false;

    _authInProgress = true;
    notifyListeners();
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason ??
            reasonFallback ??
            'Authenticate to unlock Grinta',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('biometric authenticate failed: $e');
      return false;
    } finally {
      _authInProgress = false;
      notifyListeners();
    }
  }

  Future<bool> unlock({required String localizedReason}) async {
    final ok = await authenticate(localizedReason: localizedReason);
    if (ok) {
      markUnlocked();
    }
    return ok;
  }

  bool shouldOfferEnable({required String uid}) {
    if (!isSupportedPlatform || !_hardwareAvailable) return false;
    if (_enabled && _enabledUid == uid.trim()) return false;
    return true;
  }

  bool shouldPromptAfterAccountReady({required String uid}) {
    if (!shouldOfferEnable(uid: uid)) return false;
    return !_prompted;
  }

  Future<void> _refreshSavedLoginCredentialsState() async {
    if (!isSupportedPlatform) {
      _hasSavedLoginCredentials = false;
      _savedLoginEmailHint = null;
      return;
    }
    _hasSavedLoginCredentials = await _credentialsStore.hasCredentials();
    _savedLoginEmailHint =
        _hasSavedLoginCredentials ? await _credentialsStore.peekEmail() : null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isSupportedPlatform || !_enabled || _authInProgress) return;

    // Relock when the app leaves the foreground so the next resume requires
    // biometrics (while Firebase session may still be valid).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_unlockedThisSession) {
        _unlockedThisSession = false;
        notifyListeners();
      }
    }
  }
}
