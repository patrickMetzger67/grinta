import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/team_deletion_access.dart';

/// True when [selectedPlayerId] (or one of [lookupIds]) is the designated
/// fines manager of [team].
bool isTeamFinesManager(
  Team team, {
  required String? selectedPlayerId,
  Set<String> lookupIds = const <String>{},
}) {
  final String finesId = team.finesManagerMemberId?.trim() ?? '';
  if (finesId.isEmpty) {
    return false;
  }
  final String memberId = selectedPlayerId?.trim() ?? '';
  if (memberId.isNotEmpty && memberId == finesId) {
    return true;
  }
  return lookupIds.contains(finesId);
}

/// Managers of [team], plus the designated fines-manager player.
bool canManageTeamFines({
  required Team team,
  required bool isTeamManager,
  required String? selectedPlayerId,
  Set<String> selectedPlayerLookupIds = const <String>{},
}) {
  if (isTeamManager) {
    return true;
  }
  return isTeamFinesManager(
    team,
    selectedPlayerId: selectedPlayerId,
    lookupIds: selectedPlayerLookupIds,
  );
}

/// Teams the current session may manage fines for (managers + designated player).
List<Team> finesManagedTeamsForSession(AppSession session) {
  final String? uid = session.user?.uid;
  final String? memberId = session.selectedPlayerId;
  final Player? player = session.selectedPlayer;
  final Set<String> lookupIds =
      player == null ? <String>{} : playerMemberLookupIds(player);
  final Set<String> managedIds = session.managedTeamsIdsForSelectedSeason.toSet();

  final Map<String, Team> byId = <String, Team>{};
  for (final Team team in session.teamsForAgendaSelectedSeason) {
    final String teamId = team.keyTeam?.trim() ?? '';
    if (teamId.isEmpty) {
      continue;
    }
    final bool isManager = canManageTeam(
      team,
      uid,
      isManager: managedIds.contains(teamId),
    );
    if (!canManageTeamFines(
      team: team,
      isTeamManager: isManager,
      selectedPlayerId: memberId,
      selectedPlayerLookupIds: lookupIds,
    )) {
      continue;
    }
    byId[teamId] = team;
  }

  final List<Team> teams = byId.values.toList()
    ..sort(
      (Team a, Team b) => (a.name ?? '')
          .toLowerCase()
          .compareTo((b.name ?? '').toLowerCase()),
    );
  return teams;
}

bool hasTeamFinesAccess(AppSession session) {
  return finesManagedTeamsForSession(session).isNotEmpty;
}
