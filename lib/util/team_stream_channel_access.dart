import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/stream_channel_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_deletion_access.dart';
import 'package:provider/provider.dart';

String _teamDisplayName(BuildContext context, Team team) {
  final name = team.name?.trim() ?? '';
  if (name.isNotEmpty) {
    return name;
  }
  return context.l10n.entityTeam;
}

/// Handles tap on the pending Stream group indicator (managers only).
Future<void> onPendingStreamChannelIndicatorTap(
  BuildContext context, {
  required Team team,
  required bool isManager,
}) async {
  if (team.isGrinta != true || !team.isStreamChannelPending) {
    StreamChannelService.log(
      'indicator tap ignored: isGrinta=${team.isGrinta}'
      ' pending=${team.isStreamChannelPending}'
      ' teamId=${team.keyTeam}',
    );
    return;
  }

  final appSession = context.read<AppSession>();
  final String? currentUserUid =
      appSession.user?.uid ?? FirebaseAuth.instance.currentUser?.uid;

  if (!canManageTeam(team, currentUserUid, isManager: isManager)) {
    StreamChannelService.log(
      'indicator tap rejected: user is not manager'
      ' teamId=${team.keyTeam}',
    );
    AppSnackbar.show(context, context.l10n.teamStreamChannelCreateNotManager);
    return;
  }

  final teamId = team.keyTeam?.trim() ?? '';
  if (teamId.isEmpty) {
    StreamChannelService.log(
      'createTeamStreamChannel skipped: missing teamId'
      ' teamName="${_teamDisplayName(context, team)}"',
    );
    return;
  }

  final teamName = _teamDisplayName(context, team);
  final l10n = context.l10n;
  final colors = context.appColors;

  StreamChannelService.log(
    'indicator tap accepted: teamId=$teamId teamName="$teamName"',
  );

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.teamStreamChannelCreateTitle),
        content: Text(l10n.teamStreamChannelCreateMessage(teamName)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.teamStreamChannelCreateConfirm),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    StreamChannelService.log(
      'createTeamStreamChannel cancelled: teamId=$teamId confirmed=$confirmed',
    );
    return;
  }

  AppSnackbar.show(
    context,
    l10n.teamStreamChannelCreateLoading,
    isError: false,
  );

  try {
    StreamChannelService.log(
      'UI invoking createTeamStreamChannel:'
      ' teamId=$teamId teamName="$teamName"'
      ' function=$kCreateTeamStreamChannelFunctionName'
      ' region=$kStreamFunctionsRegion',
    );

    final response =
        await StreamChannelService.instance.createTeamStreamChannel(
      teamId: teamId,
      teamName: teamName,
    );

    StreamChannelService.log(
      'UI createTeamStreamChannel completed:'
      ' teamId=$teamId response=${StreamChannelService.encodeForLog(response)}',
    );

    if (!context.mounted) {
      return;
    }

    AppSnackbar.show(
      context,
      l10n.teamStreamChannelCreateSuccess(teamName),
      isError: false,
    );
  } on FirebaseFunctionsException catch (e, st) {
    StreamChannelService.log(
      'UI FirebaseFunctionsException:'
      ' teamId=$teamId code=${e.code}'
      ' message=${e.message ?? "(null)"}'
      ' details=${StreamChannelService.encodeForLog(e.details)}',
      error: e,
      stackTrace: st,
    );

    if (!context.mounted) {
      return;
    }

    if (e.code == 'permission-denied') {
      AppSnackbar.show(context, l10n.teamStreamChannelCreateNotManager);
      return;
    }

    final parsed = StreamChannelService.instance.parseCallableError(e);
    StreamChannelService.log(
      'UI showing snackbar: userMessage="${parsed.userMessage}"',
    );
    AppSnackbar.show(context, parsed.userMessage);
  } catch (e, st) {
    StreamChannelService.log(
      'UI unexpected error: teamId=$teamId error=${e.toString()}',
      error: e,
      stackTrace: st,
    );

    if (!context.mounted) {
      return;
    }

    AppSnackbar.show(
      context,
      'Erreur lors de la création du groupe Stream',
    );
  }
}
