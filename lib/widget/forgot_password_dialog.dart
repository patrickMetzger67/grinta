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
  final service = passwordResetService ?? PasswordResetService();
  final controller = TextEditingController(text: initialEmail?.trim() ?? '');
  var sending = false;

  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) {
      final colors = dialogContext.appColors;
      final l10n = dialogContext.l10n;

      return StatefulBuilder(
        builder: (context, setLocalState) {
          Future<void> submit() async {
            if (sending) return;
            setLocalState(() => sending = true);

            final locale = Localizations.localeOf(context).languageCode;
            final result = await service.sendResetEmail(
              email: controller.text,
              locale: locale,
            );

            if (!dialogContext.mounted) return;

            switch (result) {
              case PasswordResetResult.sent:
                Navigator.of(dialogContext, rootNavigator: true).pop();
                final snackContext = appNavigatorKey.currentContext;
                if (snackContext != null && snackContext.mounted) {
                  AppSnackbar.show(
                    snackContext,
                    l10n.forgotPasswordSent,
                    isError: false,
                  );
                }
                break;
              case PasswordResetResult.invalidEmail:
                setLocalState(() => sending = false);
                AppSnackbar.show(dialogContext, l10n.invalidEmail);
                break;
              case PasswordResetResult.userNotFound:
                setLocalState(() => sending = false);
                AppSnackbar.show(dialogContext, l10n.userNotFound);
                break;
              case PasswordResetResult.failed:
                setLocalState(() => sending = false);
                AppSnackbar.show(dialogContext, l10n.forgotPasswordFailed);
                break;
            }
          }

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
                  controller: controller,
                  enabled: !sending,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: l10n.emailHint,
                  ),
                  onSubmitted: (_) => submit(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: sending
                    ? null
                    : () => Navigator.of(dialogContext, rootNavigator: true)
                        .pop(),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: sending ? null : submit,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                ),
                child: sending
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
        },
      );
    },
  );

  controller.dispose();
}
