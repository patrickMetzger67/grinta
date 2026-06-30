import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/screen/teamDetailScreen.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_positions.dart';
import 'package:grinta/util/team_deletion_access.dart';
import 'package:grinta/widget/subscription_paywall.dart';
import 'package:provider/provider.dart';

/// Free member-profile field players cannot open team detail for teams they own.
bool isTeamDetailBlockedForUser(
  Team team,
  String? currentUserUid, {
  Player? memberProfile,
}) {
  if (!isTeamOwner(team, currentUserUid)) {
    return false;
  }
  if (UserTrialService.instance.hasPremiumAccess) {
    return false;
  }
  final Iterable<int> positionCodes =
      memberProfile?.positionCodes ?? const <int>[];
  if (hasStaffProfilePositionCodes(positionCodes)) {
    return false;
  }
  return hasMemberProfileFieldPlayerRole(positionCodes);
}

/// Blocks navigation and prompts upgrade when a free player taps their team.
Future<bool> ensureCanOpenTeamDetail(
  BuildContext context, {
  required Team team,
}) async {
  final appSession = context.read<AppSession>();
  final String? currentUserUid =
      appSession.user?.uid ?? FirebaseAuth.instance.currentUser?.uid;

  if (!isTeamDetailBlockedForUser(
    team,
    currentUserUid,
    memberProfile: appSession.selectedPlayer,
  )) {
    return true;
  }

  if (!context.mounted) return false;

  final l10n = context.l10n;
  final colors = context.appColors;

  final upgrade = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.subscriptionLimitTeamDetailBlockedTitle),
        content: Text(l10n.subscriptionLimitTeamDetailBlockedMessage),
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
            child: Text(l10n.subscriptionSubscribe),
          ),
        ],
      );
    },
  );

  if (upgrade != true || !context.mounted) return false;

  await SubscriptionPaywall.show(
    context,
    allowSkip: true,
    initialKind: SubscriptionOfferingKind.player,
  );
  return false;
}

/// Navigates to [TeamDetailScreen] when the current user may open it.
Future<void> openTeamDetailScreen(
  BuildContext context, {
  required Team team,
  required String? seasonId,
  required bool isManager,
}) async {
  final allowed = await ensureCanOpenTeamDetail(context, team: team);
  if (!allowed || !context.mounted) return;

  await Navigator.of(context).push(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.teamDetail,
      builder: (_) => TeamDetailScreen(
        team: team,
        seasonId: seasonId,
        isManager: isManager,
      ),
    ),
  );
}
