import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/services/session_report_manager_recipients_service.dart';
import 'package:grinta/services/session_report_sender_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/playerPhoto.dart';

/// Shows managers of the team; selected ones receive the branded PDF report.
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

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _SessionReportEmailDialog(
        eventId: eventId,
        isMatch: isMatch,
        summary: summary,
        title: title,
        subtitle: subtitle,
        teamName: teamName,
        teamId: teamId,
        eventDate: eventDate,
        match: match,
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

class _SessionReportEmailDialog extends StatefulWidget {
  const _SessionReportEmailDialog({
    required this.eventId,
    required this.isMatch,
    required this.colors,
    required this.onSuccess,
    this.summary,
    this.title,
    this.subtitle,
    this.teamName,
    this.teamId,
    this.eventDate,
    this.match,
  });

  final String eventId;
  final bool isMatch;
  final TeamWorkloadSummary? summary;
  final String? title;
  final String? subtitle;
  final String? teamName;
  final String? teamId;
  final DateTime? eventDate;
  final grinta_match.Match? match;
  final AppColors colors;
  final void Function(List<String> emails) onSuccess;

  @override
  State<_SessionReportEmailDialog> createState() =>
      _SessionReportEmailDialogState();
}

class _SessionReportEmailDialogState extends State<_SessionReportEmailDialog> {
  final SessionReportManagerRecipientsService _recipientsService =
      SessionReportManagerRecipientsService();

  List<SessionReportManagerRecipient> _managers =
      const <SessionReportManagerRecipient>[];
  final Set<String> _selectedKeys = <String>{};
  var _loading = true;
  var _sending = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadManagers();
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
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final selected = _managers
        .where((m) => _selectedKeys.contains(m.selectionKey))
        .toList(growable: false);

    if (selected.isEmpty) {
      setState(() => _errorText = l10n.sessionReportEmailNoSelection);
      return;
    }

    setState(() {
      _sending = true;
      _errorText = null;
    });

    final localeCode = Localizations.localeOf(context).languageCode;
    final emails = selected.map((m) => m.email).toList(growable: false);
    final result = await SessionReportSenderService.instance.sendReport(
      l10n: l10n,
      toEmails: emails,
      eventId: widget.eventId,
      isMatch: widget.isMatch,
      title: widget.title,
      subtitle: widget.subtitle,
      teamName: widget.teamName,
      teamId: widget.teamId,
      eventDate: widget.eventDate,
      localeCode: localeCode,
      summary: widget.summary,
      match: widget.match,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pop();
      widget.onSuccess(emails);
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
      title: Text(l10n.sessionReportEmailDialogTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sessionReportEmailDialogMessage,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_managers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.sessionReportEmailNoManagers,
                  style: TextStyle(color: colors.textSecondary),
                ),
              )
            else ...[
              Row(
                children: [
                  TextButton(
                    onPressed: _sending
                        ? null
                        : () => _toggleAll(!allSelected),
                    child: Text(
                      allSelected
                          ? l10n.sessionReportEmailDeselectAll
                          : l10n.sessionReportEmailSelectAll,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.sessionReportEmailSelectedCount(_selectedKeys.length),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _managers.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: colors.border.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final manager = _managers[index];
                    final selected =
                        _selectedKeys.contains(manager.selectionKey);
                    return CheckboxListTile(
                      value: selected,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: _sending
                          ? null
                          : (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedKeys.add(manager.selectionKey);
                                } else {
                                  _selectedKeys.remove(manager.selectionKey);
                                }
                                _errorText = null;
                              });
                            },
                      title: Row(
                        children: [
                          PlayerPhoto(
                            player: manager.player,
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  manager.displayName,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  manager.email,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
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
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.sessionReportEmailDialogCancel),
        ),
        FilledButton(
          onPressed: (_sending || _loading || _managers.isEmpty) ? null : _submit,
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
