import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/services/password_reset_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';

/// Asks for an email, verifies the Auth user exists, and queues a reset mail.
Future<void> showForgotPasswordDialog(
  BuildContext context, {
  String? initialEmail,
  PasswordResetService? passwordResetService,
}) async {
  final result = await showDialog<PasswordResetResult>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _ForgotPasswordDialog(
        initialEmail: initialEmail,
        passwordResetService: passwordResetService,
      );
    },
  );

  if (result == PasswordResetResult.sent) {
    final snackContext = appNavigatorKey.currentContext ?? context;
    if (snackContext.mounted) {
      AppSnackbar.show(
        snackContext,
        snackContext.l10n.forgotPasswordSent,
        isError: false,
      );
    }
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({
    this.initialEmail,
    this.passwordResetService,
  });

  final String? initialEmail;
  final PasswordResetService? passwordResetService;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _controller;
  late final PasswordResetService _service;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail?.trim() ?? '');
    _service = widget.passwordResetService ?? PasswordResetService();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close([PasswordResetResult? result]) {
    // Prefer the app root navigator (same pattern as feeling screen).
    final navigator =
        appNavigatorKey.currentState ??
        (mounted ? Navigator.of(context, rootNavigator: true) : null);
    if (navigator != null && navigator.canPop()) {
      navigator.pop(result);
      return;
    }
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(result);
    }
  }

  Future<void> _submit() async {
    if (_sending) return;
    setState(() => _sending = true);

    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    try {
      final result = await _service.sendResetEmail(
        email: _controller.text,
        locale: locale,
      );

      if (!mounted) return;

      if (result == PasswordResetResult.sent) {
        // Close immediately on success — snackbar is shown after dialog returns.
        _close(PasswordResetResult.sent);
        return;
      }

      setState(() => _sending = false);
      switch (result) {
        case PasswordResetResult.invalidEmail:
          AppSnackbar.show(context, l10n.invalidEmail);
        case PasswordResetResult.userNotFound:
          AppSnackbar.show(context, l10n.userNotFound);
        case PasswordResetResult.failed:
          AppSnackbar.show(context, l10n.forgotPasswordFailed);
        case PasswordResetResult.sent:
          break;
      }
    } catch (e, st) {
      debugPrint('ForgotPasswordDialog submit failed: $e\n$st');
      if (!mounted) return;
      setState(() => _sending = false);
      AppSnackbar.show(context, l10n.forgotPasswordFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(l10n.forgotPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.forgotPasswordMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            enabled: !_sending,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: l10n.email,
              hintText: l10n.emailHint,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => _close(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _sending ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
          ),
          child: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.forgotPasswordSendAction),
        ),
      ],
    );
  }
}
