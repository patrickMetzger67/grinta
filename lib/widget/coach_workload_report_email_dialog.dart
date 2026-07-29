import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/screen/coach_workload_analysis/coach_workload_analysis_models.dart';
import 'package:grinta/services/coach_workload_report_sender_service.dart';
import 'package:grinta/services/session_report_manager_recipients_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/player_profile_validator.dart';
import 'package:grinta/widget/playerPhoto.dart';

/// Asks for manager emails then queues the coach workload PDF report.
Future<void> showCoachWorkloadReportEmailDialog({
  required BuildContext context,
  required CoachTeamWorkloadReport report,
  required String teamName,
  required String teamId,
  required DateTime rangeStart,
  required DateTime rangeEndInclusive,
  String? clubId,
}) async {
  final l10n = context.l10n;
  final colors = context.appColors;
  final messenger = ScaffoldMessenger.of(context);

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _CoachWorkloadReportEmailDialog(
        report: report,
        teamName: teamName,
        teamId: teamId,
        rangeStart: rangeStart,
        rangeEndInclusive: rangeEndInclusive,
        clubId: clubId,
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
}

class _CoachWorkloadReportEmailDialog extends StatefulWidget {
  const _CoachWorkloadReportEmailDialog({
    required this.report,
    required this.teamName,
    required this.teamId,
    required this.rangeStart,
    required this.rangeEndInclusive,
    required this.colors,
    required this.onSuccess,
    this.clubId,
  });

  final CoachTeamWorkloadReport report;
  final String teamName;
  final String teamId;
  final DateTime rangeStart;
  final DateTime rangeEndInclusive;
  final String? clubId;
  final AppColors colors;
  final void Function(List<String> emails) onSuccess;

  @override
  State<_CoachWorkloadReportEmailDialog> createState() =>
      _CoachWorkloadReportEmailDialogState();
}

class _CoachWorkloadReportEmailDialogState
    extends State<_CoachWorkloadReportEmailDialog> {
  final SessionReportManagerRecipientsService _recipientsService =
      SessionReportManagerRecipientsService();
  late final TextEditingController _manualEmailsController;

  List<SessionReportManagerRecipient> _managers =
      const <SessionReportManagerRecipient>[];
  final Set<String> _selectedKeys = <String>{};
  var _loading = true;
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
    _manualEmailsController = TextEditingController(text: initialEmail);
    _loadManagers();
  }

  @override
  void dispose() {
    _manualEmailsController.dispose();
    super.dispose();
  }

  Future<void> _loadManagers() async {
    final managers = await _recipientsService.loadManagers(
      teamId: widget.teamId,
    );
    if (!mounted) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final currentEmail =
        (FirebaseAuth.instance.currentUser?.email ?? '').trim().toLowerCase();

    final Set<String> initial = <String>{};
    for (final manager in managers) {
      final bool matchesUid = currentUid.isNotEmpty &&
          playerFirebaseUserIds(manager.player).contains(currentUid);
      final bool matchesEmail = currentEmail.isNotEmpty &&
          manager.email.toLowerCase() == currentEmail;
      if (matchesUid || matchesEmail) {
        initial.add(manager.selectionKey);
      }
    }

    setState(() {
      _managers = managers;
      _selectedKeys
        ..clear()
        ..addAll(initial);
      if (initial.isNotEmpty && currentEmail.isNotEmpty) {
        final alreadySelected = managers.any(
          (m) =>
              initial.contains(m.selectionKey) &&
              m.email.toLowerCase() == currentEmail,
        );
        if (alreadySelected) {
          _manualEmailsController.clear();
        }
      }
      _loading = false;
    });
  }

  static List<String> parseManualEmails(String raw) {
    final Set<String> out = <String>{};
    for (final part in raw.split(RegExp(r'[;,\n]+'))) {
      final email = part.trim();
      if (email.isNotEmpty) out.add(email);
    }
    return out.toList(growable: false);
  }

  List<String>? _collectRecipients() {
    final l10n = context.l10n;
    final selectedManagerEmails = _managers
        .where((m) => _selectedKeys.contains(m.selectionKey))
        .map((m) => m.email.trim())
        .where((e) => e.isNotEmpty);

    final manual = parseManualEmails(_manualEmailsController.text);
    for (final email in manual) {
      if (!isValidEmailFormat(email) || !_emailRegex.hasMatch(email)) {
        setState(() => _errorText = l10n.sessionReportEmailInvalid);
        return null;
      }
    }

    final emails = <String>{
      ...selectedManagerEmails,
      ...manual,
    }.toList(growable: false);

    if (emails.isEmpty) {
      setState(() => _errorText = l10n.sessionReportEmailNoSelection);
      return null;
    }
    return emails;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final emails = _collectRecipients();
    if (emails == null) return;

    setState(() {
      _sending = true;
      _errorText = null;
    });

    final localeCode = Localizations.localeOf(context).languageCode;
    final result = await CoachWorkloadReportSenderService.instance.sendReport(
      l10n: l10n,
      toEmails: emails,
      report: widget.report,
      teamName: widget.teamName,
      teamId: widget.teamId,
      rangeStart: widget.rangeStart,
      rangeEndInclusive: widget.rangeEndInclusive,
      localeCode: localeCode,
      clubId: widget.clubId,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pop();
      widget.onSuccess(emails);
      return;
    }

    final error = result.error ?? '';
    final message = error == 'noStats'
        ? l10n.coachWorkloadReportEmpty
        : error == 'invalidEmail' || error == 'emptyEmail'
            ? l10n.sessionReportEmailInvalid
            : l10n.sessionReportEmailFailed;

    setState(() {
      _sending = false;
      _errorText = message;
    });
  }

  void _toggleAll(bool select) {
    setState(() {
      _selectedKeys.clear();
      if (select) {
        _selectedKeys.addAll(_managers.map((m) => m.selectionKey));
      }
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = widget.colors;
    final allSelected =
        _managers.isNotEmpty && _selectedKeys.length == _managers.length;

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(l10n.coachWorkloadReportEmailDialogTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _managers.isEmpty && !_loading
                  ? l10n.sessionReportEmailManualOnlyMessage
                  : l10n.sessionReportEmailDialogMessage,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_managers.isNotEmpty) ...[
                    Row(
                  children: [
                    Text(
                      l10n.sessionReportEmailSelectedCount(_selectedKeys.length),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _toggleAll(!allSelected),
                      child: Text(
                        allSelected
                            ? l10n.sessionReportEmailDeselectAll
                            : l10n.sessionReportEmailSelectAll,
                      ),
                    ),
                  ],
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _managers.length,
                    itemBuilder: (context, index) {
                      final manager = _managers[index];
                      final selected =
                          _selectedKeys.contains(manager.selectionKey);
                      return CheckboxListTile(
                        value: selected,
                        contentPadding: EdgeInsets.zero,
                        secondary: PlayerPhoto(
                          player: manager.player,
                          radius: 16,
                        ),
                        title: Text(manager.displayName),
                        subtitle: Text(manager.email),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedKeys.add(manager.selectionKey);
                            } else {
                              _selectedKeys.remove(manager.selectionKey);
                            }
                            _errorText = null;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _manualEmailsController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.sessionReportEmailAdditionalLabel,
                  hintText: l10n.sessionReportEmailManualHint,
                  helperText: l10n.sessionReportEmailManualHelper,
                ),
                onChanged: (_) => setState(() => _errorText = null),
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: TextStyle(color: colors.danger, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.sessionReportEmailDialogCancel),
        ),
        FilledButton(
          onPressed: _sending || _loading ? null : _submit,
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
