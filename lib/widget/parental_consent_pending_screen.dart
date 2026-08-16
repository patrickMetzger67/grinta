import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/parental_consent_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_profile_validator.dart';

/// Shown while a 13–14 account waits for legal-guardian approval.
class ParentalConsentPendingScreen extends StatefulWidget {
  const ParentalConsentPendingScreen({
    super.key,
    required this.uid,
    this.childDisplayName,
    this.parentEmail,
  });

  final String uid;
  final String? childDisplayName;
  final String? parentEmail;

  @override
  State<ParentalConsentPendingScreen> createState() =>
      _ParentalConsentPendingScreenState();
}

class _ParentalConsentPendingScreenState
    extends State<ParentalConsentPendingScreen> {
  final ParentalConsentService _consentService = ParentalConsentService();
  bool _resending = false;

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      final name = (widget.childDisplayName?.trim().isNotEmpty ?? false)
          ? widget.childDisplayName!.trim()
          : 'votre enfant';
      final error = await _consentService.resendParentalConsentEmail(
        uid: widget.uid,
        childDisplayName: name,
      );
      if (!mounted) return;
      if (error != null) {
        AppSnackbar.show(
          context,
          context.l10n.parentalConsentResendError,
          isError: true,
        );
      } else {
        AppSnackbar.show(
          context,
          context.l10n.parentalConsentResendSuccess,
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final parent = widget.parentEmail?.trim();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.family_restroom_rounded,
                    size: 56,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.parentalConsentPendingTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    parent != null && parent.isNotEmpty
                        ? l10n.parentalConsentPendingMessage(parent)
                        : l10n.parentalConsentPendingMessageGeneric,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _resending ? null : _resend,
                      child: _resending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.parentalConsentResend),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _signOut,
                    child: Text(l10n.actionLogout),
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

/// Asks for the legal guardian email during 13–14 signup.
Future<String?> promptParentalConsentEmail(BuildContext context) async {
  final l10n = context.l10n;
  final colors = context.appColors;
  final controller = TextEditingController();

  final result = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.parentalConsentEmailTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.parentalConsentEmailMessage,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.parentalConsentEmailLabel,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              final email = controller.text.trim();
              if (email.isEmpty || !isValidEmailFormat(email)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(l10n.memberEmailInvalid)),
                );
                return;
              }
              Navigator.of(dialogContext).pop(email);
            },
            child: Text(l10n.actionValidate),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
      );
    },
  );

  controller.dispose();
  return result?.trim();
}
