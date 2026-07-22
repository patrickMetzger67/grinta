import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:provider/provider.dart';

bool canManagePersonalSportActivity(
  PersonalSportActivity activity,
  AppSession session,
) {
  final String? uid = session.user?.uid?.trim();
  final String createdBy = activity.createdByUserId.trim();
  if (uid != null &&
      uid.isNotEmpty &&
      createdBy.isNotEmpty &&
      uid == createdBy) {
    return true;
  }

  final String? memberId = session.selectedPlayerId?.trim();
  final String ownerMemberId = activity.memberId.trim();
  return memberId != null &&
      memberId.isNotEmpty &&
      ownerMemberId.isNotEmpty &&
      memberId == ownerMemberId;
}

Future<bool> confirmDeletePersonalSportActivity(
  BuildContext context, {
  required PersonalSportActivity activity,
}) async {
  final colors = context.appColors;
  final l10n = context.l10n;
  final title = (activity.title?.trim().isNotEmpty == true)
      ? activity.title!.trim()
      : activity.typeId;

  final bool? confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.deletePersonalSportConfirmTitle),
        content: Text(l10n.deletePersonalSportConfirmMessage(title)),
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

Future<bool> deleteManagedPersonalSportActivity(
  BuildContext context, {
  required PersonalSportActivity activity,
  VoidCallback? onDeleted,
}) async {
  final AppSession session = context.read<AppSession>();
  if (!canManagePersonalSportActivity(activity, session)) {
    return false;
  }

  final bool confirmed = await confirmDeletePersonalSportActivity(
    context,
    activity: activity,
  );
  if (!confirmed || !context.mounted) {
    return false;
  }

  final String successMessage = context.l10n.deletePersonalSportDeleted;
  final String errorMessage = context.l10n.deletePersonalSportError;

  try {
    await PersonalSportActivityService().delete(activity);
    onDeleted?.call();

    final BuildContext? rootContext = appNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      AppSnackbar.show(rootContext, successMessage, isError: false);
    }
    return true;
  } catch (error, stackTrace) {
    debugPrint('deleteManagedPersonalSportActivity failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (context.mounted) {
      AppSnackbar.show(context, errorMessage, isError: true);
    }
    return false;
  }
}
