import 'package:grinta/model/player_task.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/util/team_deletion_access.dart';

/// True when the signed-in manager/owner created [task] or still manages
/// its team, so they may edit or delete it.
bool canManagePlayerTask(PlayerTask task, AppSession session) {
  final String uid = session.user?.uid.trim() ?? '';
  final String createdBy = task.createdByUserId.trim();
  if (uid.isNotEmpty && createdBy.isNotEmpty && uid == createdBy) {
    return true;
  }

  final String memberId = session.selectedPlayerId?.trim() ?? '';
  final String createdByMember = task.createdByMemberId?.trim() ?? '';
  if (memberId.isNotEmpty &&
      createdByMember.isNotEmpty &&
      memberId == createdByMember) {
    return true;
  }

  final String teamId = task.teamId.trim();
  if (teamId.isEmpty) {
    return false;
  }
  if (session.managedTeamsIdsForSelectedSeason.contains(teamId)) {
    return true;
  }

  for (final team in session.managerTeamsForSelectedSeason) {
    if ((team.keyTeam?.trim() ?? '') == teamId &&
        canManageTeam(team, uid, isManager: true)) {
      return true;
    }
  }
  return false;
}

/// Display name of [task]'s team from the session cache, or empty if unknown.
String playerTaskTeamDisplayName(PlayerTask task, AppSession session) {
  return playerTaskTeamNameFromTeams(
    task.teamId,
    session.teamsForAgendaSelectedSeason,
  );
}

/// Resolves [teamId] against [teams] via [Team.keyTeam].
String playerTaskTeamNameFromTeams(String teamId, Iterable<Team> teams) {
  final String id = teamId.trim();
  if (id.isEmpty) {
    return '';
  }
  for (final Team team in teams) {
    if ((team.keyTeam?.trim() ?? '') == id) {
      return (team.name ?? '').trim();
    }
  }
  return '';
}

/// Filters [tasks] to those assigned to [memberId] or created by them.
List<PlayerTask> playerTasksVisibleToMember(
  Iterable<PlayerTask> tasks,
  String? memberId,
) {
  final String trimmed = memberId?.trim() ?? '';
  if (trimmed.isEmpty) {
    return const <PlayerTask>[];
  }
  return [
    for (final PlayerTask task in tasks)
      if (task.accessMemberIds.contains(trimmed) ||
          task.assigneeMemberIds.contains(trimmed) ||
          (task.createdByMemberId?.trim() ?? '') == trimmed)
        task,
  ];
}

List<PlayerTask> applyPlayerTaskTeamFilter(
  Iterable<PlayerTask> tasks,
  Set<String> teamIds,
) {
  if (teamIds.isEmpty) {
    return List<PlayerTask>.from(tasks);
  }
  return [
    for (final PlayerTask task in tasks)
      if (task.teamId.isEmpty || teamIds.contains(task.teamId)) task,
  ];
}
