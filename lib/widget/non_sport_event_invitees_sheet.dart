import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/non_sport_event.dart';
import 'package:grinta/util/app_theme.dart';

Future<void> showNonSportEventInviteesSheet(
  BuildContext context, {
  required NonSportEvent event,
}) {
  if (kIsWeb) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.appColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.appColors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
          child: _NonSportEventInviteesBody(event: event),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    builder: (_) => _NonSportEventInviteesBody(event: event),
  );
}

class _NonSportEventInviteesBody extends StatelessWidget {
  const _NonSportEventInviteesBody({required this.event});

  final NonSportEvent event;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.nonSportEventInviteesTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              event.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            if (event.invitees.isEmpty)
              Text(
                l10n.createNonSportEventNoInvitees,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: event.invitees.length,
                  separatorBuilder: (_, __) => Divider(color: colors.border),
                  itemBuilder: (context, index) {
                    final NonSportInvitee invitee = event.invitees[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        invitee.displayName.isEmpty
                            ? invitee.memberId
                            : invitee.displayName,
                      ),
                      subtitle: Text(_statusLabel(context, invitee.status)),
                      trailing: Icon(
                        _statusIcon(invitee.status),
                        color: _statusColor(context, invitee.status),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionClose),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, NonSportInviteStatus status) {
    final l10n = context.l10n;
    switch (status) {
      case NonSportInviteStatus.sent:
        return l10n.createNonSportEventInviteStatusSent;
      case NonSportInviteStatus.noAccount:
        return l10n.createNonSportEventInviteStatusNoAccount;
      case NonSportInviteStatus.error:
        return l10n.createNonSportEventInviteStatusError;
      case NonSportInviteStatus.pending:
        return l10n.createNonSportEventInviteStatusPending;
    }
  }

  IconData _statusIcon(NonSportInviteStatus status) {
    switch (status) {
      case NonSportInviteStatus.sent:
        return Icons.mark_email_read_outlined;
      case NonSportInviteStatus.noAccount:
        return Icons.person_off_outlined;
      case NonSportInviteStatus.error:
        return Icons.error_outline;
      case NonSportInviteStatus.pending:
        return Icons.hourglass_empty_rounded;
    }
  }

  Color _statusColor(BuildContext context, NonSportInviteStatus status) {
    final colors = context.appColors;
    switch (status) {
      case NonSportInviteStatus.sent:
        return colors.success;
      case NonSportInviteStatus.noAccount:
        return colors.warning;
      case NonSportInviteStatus.error:
        return colors.danger;
      case NonSportInviteStatus.pending:
        return colors.textSecondary;
    }
  }
}
