import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/services/session_report_sender_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_profile_validator.dart';

/// Asks for a recipient email, then queues a branded PDF stats report email.
Future<void> showSessionReportEmailDialog({
  required BuildContext context,
  required String eventId,
  required bool isMatch,
  TeamWorkloadSummary? summary,
  String? title,
  String? subtitle,
  String? teamName,
  String? teamId,
  DateTime? eventDate,
  grinta_match.Match? match,
}) async {
  final l10n = context.l10n;
  final colors = context.appColors;
  final messenger = ScaffoldMessenger.of(context);
  final initialEmail = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
  final controller = TextEditingController(text: initialEmail);
  String? errorText;
  var sending = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: !sending,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            final email = controller.text.trim();
            if (email.isEmpty ||
                !isValidEmailFormat(email) ||
                !RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                ).hasMatch(email)) {
              setState(() => errorText = l10n.sessionReportEmailInvalid);
              return;
            }

            setState(() {
              sending = true;
              errorText = null;
            });

            final localeCode = Localizations.localeOf(context).languageCode;
            final result = await SessionReportSenderService.instance.sendReport(
              l10n: l10n,
              toEmail: email,
              eventId: eventId,
              isMatch: isMatch,
              title: title,
              subtitle: subtitle,
              teamName: teamName,
              teamId: teamId,
              eventDate: eventDate,
              localeCode: localeCode,
              summary: summary,
              match: match,
            );

            if (!dialogContext.mounted) return;

            if (result.success) {
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.sessionReportEmailSuccess(email))),
              );
              return;
            }

            final error = result.error ?? '';
            final message = error == 'noStats'
                ? l10n.sessionReportEmailNoStats
                : error == 'invalidEmail' || error == 'emptyEmail'
                    ? l10n.sessionReportEmailInvalid
                    : error == 'uploadFailed'
                        ? l10n.sessionReportEmailFailed
                        : l10n.sessionReportEmailFailed;

            setState(() {
              sending = false;
              errorText = message;
            });
          }

          return AlertDialog(
            backgroundColor: colors.surface,
            title: Text(l10n.sessionReportEmailDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sessionReportEmailDialogMessage,
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  enabled: !sending,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: l10n.sessionReportEmailDialogHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: errorText,
                  ),
                  onSubmitted: (_) {
                    if (!sending) {
                      submit();
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: sending
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.sessionReportEmailDialogCancel),
              ),
              FilledButton(
                onPressed: sending ? null : submit,
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.sessionReportEmailDialogSend),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
}
