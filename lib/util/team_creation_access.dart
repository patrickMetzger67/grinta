import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/feature_discovery/shell_navigation_scope.dart';
import 'package:grinta/model/feature_discovery_ids.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/teams_per_club.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/subscription_limits_service.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/model/subscription_tier_limits.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/engagement_sync.dart';
import 'package:grinta/util/subscription_limits_access.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/player_positions.dart';
import 'package:grinta/util/team_detail_access.dart';
import 'package:grinta/widget/team_basics_form_dialog.dart';
import 'package:provider/provider.dart';

/// Opens the gated team creation flow (limits, dialog, create, optional detail nav).
Future<void> openTeamCreationFlow(BuildContext context) async {
  final appSession = context.read<AppSession>();
  final seasonId = appSession.selectedSeason?.ref?.id.trim();
  if (seasonId == null || seasonId.isEmpty) {
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      context.l10n.emptyNoCurrentSeason,
      isError: true,
    );
    return;
  }

  final String? userId =
      appSession.user?.uid ?? FirebaseAuth.instance.currentUser?.uid;
  if (userId == null || userId.isEmpty) {
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      context.l10n.infoUserNotConnected,
      isError: true,
    );
    return;
  }

  await SubscriptionLimitsService.instance.ensureInitialized();
  await SubscriptionService.instance.refreshForActiveSession();
  await UserTrialService.instance.ensureInitialized();

  final Player? player = appSession.selectedPlayer;
  final String? playerId = player?.keyMember ?? appSession.selectedPlayerId;

  final teamCount = await SubscriptionLimitsService.instance.countTeamsForUser(
    userId: userId,
    seasonId: seasonId,
    playerId: playerId,
    player: player,
  );
  final gate = SubscriptionLimitsService.instance.resolveTeamCreationGate(
    teamCount,
  );

  switch (gate) {
    case TeamCreationGate.allowed:
      break;
    case TeamCreationGate.needsUpgrade:
      if (!context.mounted) return;
      final maxTeams =
          await SubscriptionLimitsService.instance.maxTeamsForUser();
      if (!context.mounted) return;
      await SubscriptionLimitsAccess.showTeamLimitExceeded(
        context,
        SubscriptionLimitExceeded(
          violation: SubscriptionLimitViolation.maxTeams,
          tier: SubscriptionLimitsService.instance.resolveEffectiveTier(),
          limit: maxTeams,
          requiresUpgrade: true,
        ),
      );
      return;
    case TeamCreationGate.atMaxLimit:
      if (!context.mounted) return;
      final max = await SubscriptionLimitsService.instance.maxTeamsForUser();
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.subscriptionLimitMaxTeamsReached(max),
        isError: true,
      );
      return;
  }

  if (!context.mounted) return;

  final draft = await showTeamBasicsFormDialog(
    context,
    title: context.l10n.actionCreateTeam,
    submitLabel: context.l10n.actionCreateTeam,
  );
  if (draft == null || !context.mounted) return;

  if (draft.name.trim().isEmpty) {
    AppSnackbar.show(
      context,
      context.l10n.hintRequiredField,
      isError: true,
    );
    return;
  }

  if (playerId == null || playerId.isEmpty) {
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      context.l10n.infoUserNotConnected,
      isError: true,
    );
    return;
  }

  try {
    final bool autoAddCreatorToRoster =
        shouldAutoAddMemberProfileToTeamRoster(player?.positionCodes ?? const []);

    final GrintaPlayer? creatorGrintaPlayer = autoAddCreatorToRoster
        ? _grintaPlayerFromProfile(
            playerId: playerId,
            player: player,
          )
        : null;

    final Set<String> creatorManagerUserIds = <String>{userId};
    if (player != null) {
      creatorManagerUserIds.addAll(playerFirebaseUserIds(player));
    }

    final team = Team(
      name: draft.name,
      seasonID: seasonId,
      players: autoAddCreatorToRoster ? <dynamic>[playerId] : <dynamic>[],
      users: <dynamic>[userId],
      order: 1,
      soccerType: draft.soccerType,
      teamIdInTeamsPerClub: _firstSelectedEquipeId(draft.selectedEquipes),
      category: player?.category,
      clubId: draft.clubAffiliation,
      country: draft.country,
      isGrinta: true,
      uid: userId,
      grintaPlayers: creatorGrintaPlayer == null
          ? <GrintaPlayer>[]
          : <GrintaPlayer>[creatorGrintaPlayer],
    )
      ..isVisible = true
      ..managers = creatorManagerUserIds.toList();

    final String teamId = await TeamService().createTeam(team);
    team.keyTeam = teamId;

    if (draft.clubAffiliation != null &&
        draft.clubAffiliation!.isNotEmpty &&
        draft.selectedEquipes.isNotEmpty) {
      await syncEngagementsForEquipes(
        grintaTeamId: teamId,
        clubId: draft.clubAffiliation!,
        seasonId: seasonId,
        equipes: draft.selectedEquipes,
      );
    }

    await appSession.init();

    final BuildContext? rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) return;

    if (isTeamDetailBlockedForUser(
      team,
      userId,
      memberProfile: player,
    )) {
      AppSnackbar.show(
        rootContext,
        rootContext.l10n.subscriptionLimitTeamCreatedFreePlayer,
      );
      return;
    }

    ShellNavigationScope.tryNavigateToTab(
      rootContext,
      FeatureDiscoveryIds.tabTeams,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? navContext = appNavigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      unawaited(
        openTeamDetailScreen(
          navContext,
          team: team,
          seasonId: seasonId,
          isManager: true,
        ),
      );
    });
  } catch (e, stackTrace) {
    debugPrint('openTeamCreationFlow failed: $e');
    debugPrint('$stackTrace');
    final BuildContext? snackContext =
        appNavigatorKey.currentContext ?? (context.mounted ? context : null);
    if (snackContext == null || !snackContext.mounted) return;
    if (e is SubscriptionLimitExceeded) {
      SubscriptionLimitsAccess.showLimitExceeded(snackContext, e);
      return;
    }
    AppSnackbar.show(
      snackContext,
      snackContext.l10n.errorGeneric(e.toString()),
      isError: true,
    );
  }
}

String? _firstSelectedEquipeId(List<Equipe> equipes) {
  if (equipes.isEmpty) return null;
  final equipeId = equipes.first.id?.trim() ?? '';
  return equipeId.isEmpty ? null : equipeId;
}

GrintaPlayer _grintaPlayerFromProfile({
  required String playerId,
  required Player? player,
}) {
  return GrintaPlayer(
    playerId: playerId,
    positions: List<int>.from(player?.positionCodes ?? const <int>[]),
    email: player?.email,
    phoneE164: player?.phoneE164,
    birthday: Player.parseBirthDay(player?.birthDay),
  );
}
