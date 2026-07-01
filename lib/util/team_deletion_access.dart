import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:provider/provider.dart';

/// True when [team.uid] matches the signed-in Firebase user.
bool isTeamOwner(Team team, String? currentUserUid) {
  final userId = currentUserUid?.trim() ?? '';
  if (userId.isEmpty) {
    return false;
  }
  final ownerUid = team.uid?.trim() ?? '';
  return ownerUid.isNotEmpty && ownerUid == userId;
}

/// True when [team.managers] contains the signed-in Firebase user id.
bool isTeamManager(Team team, String? currentUserUid) {
  final userId = currentUserUid?.trim() ?? '';
  if (userId.isEmpty) {
    return false;
  }

  for (final dynamic raw in team.managers ?? const <dynamic>[]) {
    if (raw?.toString().trim() == userId) {
      return true;
    }
  }
  return false;
}

/// True when the signed-in user may manage roster/staff for [team].
bool canManageTeam(Team team, String? currentUserUid, {bool isManager = false}) {
  if (isManager) {
    return true;
  }
  return isTeamOwner(team, currentUserUid) ||
      isTeamManager(team, currentUserUid);
}

String _teamDisplayName(BuildContext context, Team team) {
  final name = team.name?.trim() ?? '';
  if (name.isNotEmpty) {
    return name;
  }
  return context.l10n.entityTeam;
}

/// Shows a confirmation dialog before deleting a team.
Future<bool> confirmDeleteTeam(
  BuildContext context, {
  required Team team,
}) async {
  final colors = context.appColors;
  final l10n = context.l10n;
  final teamName = _teamDisplayName(context, team);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.teamDeleteConfirmTitle),
        content: Text(l10n.teamDeleteConfirmMessage(teamName)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
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

/// Owner-only delete: confirmation, Firestore cleanup, session refresh, pop.
Future<bool> deleteOwnedTeam(
  BuildContext context, {
  required Team team,
  bool popAfterDelete = true,
}) async {
  final appSession = context.read<AppSession>();
  final String? currentUserUid =
      appSession.user?.uid ?? FirebaseAuth.instance.currentUser?.uid;

  if (!isTeamOwner(team, currentUserUid)) {
    return false;
  }

  final confirmed = await confirmDeleteTeam(context, team: team);
  if (!confirmed || !context.mounted) {
    return false;
  }

  try {
    await TeamService().deleteTeamAsOwner(
      team: team,
      currentUserUid: currentUserUid!,
    );

    final String teamId = team.keyTeam?.trim() ?? '';
    if (teamId.isNotEmpty) {
      appSession.removeTeamFromSession(teamId);
    }
    if (!context.mounted) {
      return true;
    }

    AppSnackbar.show(
      context,
      context.l10n.teamDeleteSuccess(_teamDisplayName(context, team)),
      isError: false,
    );

    if (popAfterDelete) {
      Navigator.of(context).maybePop();
    }

    return true;
  } catch (e, stackTrace) {
    debugPrint('deleteOwnedTeam failed: $e');
    debugPrint('$stackTrace');
    if (!context.mounted) {
      return false;
    }
    AppSnackbar.show(
      context,
      context.l10n.errorGeneric(e.toString()),
      isError: true,
    );
    return false;
  }
}
