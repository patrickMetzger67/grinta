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
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty || _busy) return;

    setState(() => _busy = true);
    try {
      final ok = await _service.setEnabled(
        value,
        uid: uid,
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
Future<void> maybePromptBiometricUnlock(BuildContext context) async {
  if (kIsWeb) return;

  final service = BiometricUnlockService.instance;
  await service.ensureInitialized();
  await service.refreshAvailability();

  final uid = FirebaseAuth.instance.currentUser?.uid?.trim() ?? '';
  if (uid.isEmpty || !context.mounted) return;
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

  final ok = await service.setEnabled(true, uid: uid);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.biometricUnlockUnavailable)),
    );
  }
}
