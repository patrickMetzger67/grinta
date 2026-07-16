import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/non_sport_event.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/non_sport_event_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:provider/provider.dart';

bool canManageNonSportEvent(NonSportEvent event, AppSession session) {
  final String? uid = session.user?.uid?.trim();
  final String? createdBy = event.createdByUserId?.trim();
  if (uid != null &&
      uid.isNotEmpty &&
      createdBy != null &&
      createdBy.isNotEmpty &&
      uid == createdBy) {
    return true;
  }

  final String? memberId = session.selectedPlayerId?.trim();
  final String? createdByMember = event.createdByMemberId?.trim();
  return memberId != null &&
      memberId.isNotEmpty &&
      createdByMember != null &&
      createdByMember.isNotEmpty &&
      memberId == createdByMember;
}

Future<bool> confirmDeleteNonSportEvent(
  BuildContext context, {
  required NonSportEvent event,
}) async {
  final colors = context.appColors;
  final l10n = context.l10n;

  final bool? confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.deleteNonSportEventConfirmTitle),
        content: Text(l10n.deleteNonSportEventConfirmMessage(event.title)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(true),
            child: Text(
              l10n.actionDelete,
              style: TextStyle(
                color: colors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

Future<bool> deleteManagedNonSportEvent(
  BuildContext context, {
  required NonSportEvent event,
  VoidCallback? onDeleted,
}) async {
  final AppSession session = context.read<AppSession>();
  if (!canManageNonSportEvent(event, session)) {
    return false;
  }

  final bool confirmed = await confirmDeleteNonSportEvent(
    context,
    event: event,
  );
  if (!confirmed || !context.mounted) {
    return false;
  }

  final String successMessage = context.l10n.deleteNonSportEventDeleted;
  final String errorMessage = context.l10n.deleteNonSportEventError;

  try {
    await NonSportEventService().deleteEvent(event);
    onDeleted?.call();

    final BuildContext? rootContext = appNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      AppSnackbar.show(rootContext, successMessage, isError: false);
    }
    return true;
  } catch (error, stackTrace) {
    debugPrint('deleteManagedNonSportEvent failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (context.mounted) {
      AppSnackbar.show(context, errorMessage, isError: true);
    }
    return false;
  }
}
