import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/biometric_unlock_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/settings_menu_style.dart';
import 'package:local_auth/local_auth.dart';

/// Gates [child] behind biometric unlock when enabled on iOS/Android.
class BiometricLockGate extends StatefulWidget {
  const BiometricLockGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends State<BiometricLockGate> {
  final BiometricUnlockService _service = BiometricUnlockService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(_service.bindUser(uid));
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.isSupportedPlatform || !_service.isEnabled || !_service.isLocked) {
      return widget.child;
    }
    return const BiometricLockScreen();
  }
}

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final BiometricUnlockService _service = BiometricUnlockService.instance;
  bool _busy = false;
  bool _autoPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoPrompted && mounted) {
        _autoPrompted = true;
        unawaited(_unlock());
      }
    });
  }

  Future<void> _unlock() async {
    if (_busy || !_service.isLocked) return;
    setState(() => _busy = true);
    try {
      await _service.unlock(
        localizedReason: context.l10n.biometricUnlockPromptReason,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _usePasswordInstead() async {
    // Drop vaulted email/password so LoginScreen does not offer the old account.
    await _service.disableForAnotherAccount();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 64,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.biometricUnlockTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.biometricUnlockSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _busy ? null : _unlock,
                    icon: _busy
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.surface,
                            ),
                          )
                        : const Icon(Icons.lock_open_rounded),
                    label: Text(l10n.biometricUnlockAction),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : _usePasswordInstead,
                    child: Text(l10n.biometricUnlockUsePassword),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings row to enable/disable biometric unlock on mobile.
class BiometricUnlockSettingsTile extends StatefulWidget {
  const BiometricUnlockSettingsTile({
    super.key,
    this.contentPadding,
  });

  final EdgeInsetsGeometry? contentPadding;

  @override
  State<BiometricUnlockSettingsTile> createState() =>
      _BiometricUnlockSettingsTileState();
}

class _BiometricUnlockSettingsTileState
    extends State<BiometricUnlockSettingsTile> {
  final BiometricUnlockService _service = BiometricUnlockService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    unawaited(_service.refreshAvailability().then((_) {
      if (mounted) setState(() {});
    }));
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onChangedSwitch(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid.trim() ?? '';
    if (uid.isEmpty || _busy) return;

    setState(() => _busy = true);
    try {
      String? email;
      String? password;
      if (value) {
        final hasPasswordProvider = user!.providerData.any(
          (info) => info.providerId == 'password',
        );
        if (hasPasswordProvider) {
          final vaultPassword = await _promptPasswordToVaultCredentials(
            context,
            emailHint: user.email,
          );
          if (vaultPassword == null) {
            // User cancelled password entry — keep toggle off.
            return;
          }
          email = user.email;
          password = vaultPassword;
        }
      }

      final ok = await _service.setEnabled(
        value,
        uid: uid,
        email: email,
        password: password,
      );
      if (!ok && value && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.biometricUnlockUnavailable)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Asks for the account password so it can be vaulted for biometric login.
  Future<String?> _promptPasswordToVaultCredentials(
    BuildContext context, {
    String? emailHint,
  }) async {
    final colors = context.appColors;
    final l10n = context.l10n;
    final controller = TextEditingController();
    var obscure = true;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: AlertDialog(
              backgroundColor: colors.card,
              title: Text(l10n.biometricLoginSavePasswordTitle),
              content: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.biometricLoginSavePasswordMessage,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (emailHint != null && emailHint.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      emailHint.trim(),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isEmpty) return;
                      Navigator.of(dialogContext).pop(value);
                    },
                  ),
                ],
              ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.biometricUnlockEnableLater),
                ),
                FilledButton(
                  onPressed: () {
                    final value = controller.text;
                    if (value.isEmpty) return;
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: Text(l10n.biometricUnlockEnableConfirm),
                ),
              ],
            ),
            );
          },
        );
      },
    );

    controller.dispose();
    final trimmed = result?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final l10n = context.l10n;
    final available = _service.isHardwareAvailable;

    return Padding(
      padding: widget.contentPadding ?? EdgeInsets.zero,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          _leadingIcon(_service.availableBiometrics),
          color: colors.primary,
        ),
        title: Text(
          l10n.biometricUnlockSettingsTitle,
          style: settingsMenuTitleStyle(context),
        ),
        subtitle: Text(
          available
              ? l10n.biometricUnlockSettingsSubtitle
              : l10n.biometricUnlockUnavailable,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            height: 1.3,
          ),
        ),
        trailing: _busy
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: colors.primary,
                ),
              )
            : Switch(
                value: _service.isEnabled,
                onChanged: available ? _onChangedSwitch : null,
                activeThumbColor: Colors.white,
                activeTrackColor: colors.primary,
                inactiveThumbColor: colors.textSecondary,
                inactiveTrackColor: colors.border,
              ),
      ),
    );
  }
}

IconData _leadingIcon(List<BiometricType> types) {
  if (types.contains(BiometricType.face)) {
    return Icons.face_rounded;
  }
  if (types.contains(BiometricType.fingerprint)) {
    return Icons.fingerprint_rounded;
  }
  return Icons.lock_rounded;
}

/// Post-signup / first-login opt-in dialog.
///
/// When [email] + [password] are provided (email auth), enabling also vaults
/// credentials for biometric sign-in on the login screen after logout.
Future<void> maybePromptBiometricUnlock(
  BuildContext context, {
  String? email,
  String? password,
}) async {
  if (kIsWeb) return;

  final service = BiometricUnlockService.instance;
  await service.ensureInitialized();
  await service.refreshAvailability();

  final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  if (uid.isEmpty || !context.mounted) return;

  final trimmedEmail = email?.trim() ?? '';
  final passwordValue = password;
  final hasPassword = passwordValue != null && passwordValue.isNotEmpty;

  // Already enabled: refresh vaulted password after a successful email login.
  if (service.isEnabled &&
      service.enabledUid == uid &&
      trimmedEmail.isNotEmpty &&
      hasPassword) {
    await service.saveLoginCredentials(
      uid: uid,
      email: trimmedEmail,
      password: passwordValue,
    );
    return;
  }

  if (!service.shouldPromptAfterAccountReady(uid: uid)) return;

  final colors = context.appColors;
  final l10n = context.l10n;

  final enable = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: colors.card,
        title: Text(l10n.biometricUnlockEnableTitle),
        content: Text(
          l10n.biometricUnlockEnableMessage,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.biometricUnlockEnableLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.biometricUnlockEnableConfirm),
          ),
        ],
      );
    },
  );

  await service.markPrompted();
  if (enable != true || !context.mounted) return;

  final ok = await service.setEnabled(
    true,
    uid: uid,
    email: trimmedEmail.isNotEmpty ? trimmedEmail : null,
    password: hasPassword ? passwordValue : null,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.biometricUnlockUnavailable)),
    );
  }
}
