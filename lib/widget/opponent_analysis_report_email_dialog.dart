import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/opponent_analysis_report_data_service.dart';
import 'package:grinta/services/opponent_analysis_report_sender_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_profile_validator.dart';

/// Asks for recipient emails then sends the opponent analysis PDF.
Future<bool> showOpponentAnalysisReportEmailDialog({
  required BuildContext context,
  required OpponentAnalysisReportData data,
}) async {
  final l10n = context.l10n;
  final colors = context.appColors;
  final messenger = ScaffoldMessenger.of(context);

  final sent = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _OpponentAnalysisReportEmailDialog(
        data: data,
        colors: colors,
        onSuccess: (emails) {
          final label = emails.length == 1
              ? emails.first
              : l10n.sessionReportEmailSuccessCount(emails.length);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                emails.length == 1
                    ? l10n.sessionReportEmailSuccess(emails.first)
                    : label,
              ),
            ),
          );
        },
      );
    },
  );
  return sent == true;
}

class _OpponentAnalysisReportEmailDialog extends StatefulWidget {
  const _OpponentAnalysisReportEmailDialog({
    required this.data,
    required this.colors,
    required this.onSuccess,
  });

  final OpponentAnalysisReportData data;
  final AppColors colors;
  final void Function(List<String> emails) onSuccess;

  @override
  State<_OpponentAnalysisReportEmailDialog> createState() =>
      _OpponentAnalysisReportEmailDialogState();
}

class _OpponentAnalysisReportEmailDialogState
    extends State<_OpponentAnalysisReportEmailDialog> {
  late final TextEditingController _emailsController;
  var _sending = false;
  String? _errorText;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    final initialEmail =
        (FirebaseAuth.instance.currentUser?.email ?? '').trim();
    _emailsController = TextEditingController(text: initialEmail);
  }

  @override
  void dispose() {
    _emailsController.dispose();
    super.dispose();
  }

  List<String> _parseEmails(String raw) {
    return raw
        .split(RegExp(r'[;,\n]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final emails = _parseEmails(_emailsController.text);
    if (emails.isEmpty) {
      setState(() => _errorText = l10n.sessionReportEmailNoSelection);
      return;
    }
    for (final email in emails) {
      if (!isValidEmailFormat(email) || !_emailRegex.hasMatch(email)) {
        setState(() => _errorText = l10n.sessionReportEmailInvalid);
        return;
      }
    }

    setState(() {
      _sending = true;
      _errorText = null;
    });

    final result = await OpponentAnalysisReportSenderService.instance.sendReport(
      l10n: l10n,
      toEmails: emails,
      data: widget.data,
      localeCode: Localizations.localeOf(context).languageCode,
    );

    if (!mounted) return;
    setState(() => _sending = false);

    if (!result.success) {
      setState(() {
        _errorText = switch (result.error) {
          'invalidEmail' => l10n.sessionReportEmailInvalid,
          'emptyEmail' => l10n.sessionReportEmailNoSelection,
          _ => l10n.opponentAnalysisReportSendFailed,
        };
      });
      return;
    }

    widget.onSuccess(emails);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = widget.colors;

    return AlertDialog(
      backgroundColor: colors.card,
      title: Text(l10n.opponentAnalysisReportEmailDialogTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.opponentAnalysisReportEmailDialogMessage(
                widget.data.opponent.displayName,
              ),
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailsController,
              enabled: !_sending,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.opponentAnalysisReportEmailRecipientsLabel,
                hintText: l10n.sessionReportEmailManualHint,
                helperText: l10n.sessionReportEmailManualHelper,
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: TextStyle(color: colors.danger, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.sessionReportEmailDialogCancel),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.sessionReportEmailDialogSend),
        ),
      ],
    );
  }
}
