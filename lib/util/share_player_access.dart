import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/util/player_photo_resolver.dart';

/// Manager of [teamId] via [AppSession.managedTeamsIdsForSelectedSeason],
/// or an explicit [isManager] flag already resolved with [canManageTeam] /
/// [canManageMatch] / [canManageTraining].
bool isShareManagerOfTeam({
  required Iterable<String> managedTeamIds,
  String? teamId,
  bool isManager = false,
}) {
  if (isManager) return true;
  final id = teamId?.trim() ?? '';
  if (id.isEmpty) return false;
  return managedTeamIds.contains(id);
}

/// True when the viewed player is the signed-in profile
/// ([AppSession.selectedPlayerId] ∩ [playerMemberLookupIds]).
bool isViewingOwnPlayerProfile({
  required Set<String> viewerMemberIds,
  required Set<String> viewedMemberIds,
}) {
  if (viewerMemberIds.isEmpty || viewedMemberIds.isEmpty) return false;
  return viewerMemberIds.intersection(viewedMemberIds).isNotEmpty;
}

Set<String> viewerShareMemberIds(AppSession session) {
  final ids = <String>{};
  final selectedId = session.selectedPlayerId?.trim() ?? '';
  if (selectedId.isNotEmpty) ids.add(selectedId);
  final selected = session.selectedPlayer;
  if (selected != null) ids.addAll(playerMemberLookupIds(selected));
  return ids;
}

Set<String> viewedShareMemberIds({
  Player? player,
  String? playerId,
}) {
  final ids = <String>{};
  if (player != null) ids.addAll(playerMemberLookupIds(player));
  final id = playerId?.trim() ?? '';
  if (id.isNotEmpty) ids.add(id);
  return ids;
}

/// Managers share any player on a team they manage.
/// Everyone else shares only their own synthèse / fiche.
bool canSharePlayerCard({
  required Iterable<String> managedTeamIds,
  String? teamId,
  required Set<String> viewerMemberIds,
  required Set<String> viewedMemberIds,
  bool isManager = false,
}) {
  if (isShareManagerOfTeam(
    managedTeamIds: managedTeamIds,
    teamId: teamId,
    isManager: isManager,
  )) {
    return true;
  }
  return isViewingOwnPlayerProfile(
    viewerMemberIds: viewerMemberIds,
    viewedMemberIds: viewedMemberIds,
  );
}

bool canSharePlayerCardFromSession({
  required AppSession session,
  String? teamId,
  Player? viewedPlayer,
  String? viewedPlayerId,
  bool isManager = false,
}) {
  return canSharePlayerCard(
    managedTeamIds: session.managedTeamsIdsForSelectedSeason,
    teamId: teamId,
    viewerMemberIds: viewerShareMemberIds(session),
    viewedMemberIds: viewedShareMemberIds(
      player: viewedPlayer,
      playerId: viewedPlayerId,
    ),
    isManager: isManager,
  );
}
