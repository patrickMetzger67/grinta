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

/// Assignees plus the creator. Team managers are **not** stored here: they
/// reach tasks via a `teamId` query so access stays current when staff changes.
Set<String> playerTaskAccessMemberIds({
  required Iterable<String> assigneeMemberIds,
  String? createdByMemberId,
}) {
  return <String>{
    for (final String id in assigneeMemberIds)
      if (id.trim().isNotEmpty) id.trim(),
    if ((createdByMemberId ?? '').trim().isNotEmpty) createdByMemberId!.trim(),
  };
}

/// Stable key for the agenda player-task subscription (member + managed teams).
String playerTasksAgendaQueryKey(
  String? memberId,
  Iterable<String> managedTeamIds,
) {
  final String member = memberId?.trim() ?? '';
  final List<String> teams = normalizedPlayerTaskTeamIds(managedTeamIds);
  return '$member|${teams.join(',')}';
}

List<String> normalizedPlayerTaskTeamIds(Iterable<String> teamIds) {
  final Set<String> unique = <String>{
    for (final String id in teamIds)
      if (id.trim().isNotEmpty) id.trim(),
  };
  final List<String> sorted = unique.toList()..sort();
  return sorted;
}

bool playerTaskIsVisibleToMember(
  PlayerTask task, {
  required String memberId,
  Iterable<String> managedTeamIds = const <String>[],
}) {
  final String trimmed = memberId.trim();
  if (trimmed.isNotEmpty) {
    if (task.accessMemberIds.contains(trimmed) ||
        task.assigneeMemberIds.contains(trimmed) ||
        (task.createdByMemberId?.trim() ?? '') == trimmed) {
      return true;
    }
  }
  final String teamId = task.teamId.trim();
  if (teamId.isEmpty) {
    return false;
  }
  for (final String id in managedTeamIds) {
    if (id.trim() == teamId) {
      return true;
    }
  }
  return false;
}

/// Tasks assigned to [memberId], created by them, or belonging to a team
/// they currently manage.
///
/// Unassigned players and managers of other teams are excluded. A manager
/// added to the team later still matches via [managedTeamIds], even when
/// they are missing from the stored [PlayerTask.accessMemberIds].
List<PlayerTask> playerTasksVisibleToMember(
  Iterable<PlayerTask> tasks,
  String? memberId, {
  Iterable<String> managedTeamIds = const <String>[],
}) {
  final String trimmed = memberId?.trim() ?? '';
  final List<String> managed = normalizedPlayerTaskTeamIds(managedTeamIds);
  if (trimmed.isEmpty && managed.isEmpty) {
    return const <PlayerTask>[];
  }
  return [
    for (final PlayerTask task in tasks)
      if (playerTaskIsVisibleToMember(
        task,
        memberId: trimmed,
        managedTeamIds: managed,
      ))
        task,
  ];
}

int comparePlayerTasksForAgenda(PlayerTask a, PlayerTask b) {
  final int startCmp = a.startAt.compareTo(b.startAt);
  if (startCmp != 0) {
    return startCmp;
  }
  return a.barLabel.toLowerCase().compareTo(b.barLabel.toLowerCase());
}

/// Dedupes overlapping access / team-id query results by document id.
List<PlayerTask> mergePlayerTasksById(Iterable<Iterable<PlayerTask>> batches) {
  final Map<String, PlayerTask> byId = <String, PlayerTask>{};
  final List<PlayerTask> withoutId = <PlayerTask>[];
  for (final Iterable<PlayerTask> batch in batches) {
    for (final PlayerTask task in batch) {
      final String id = task.id?.trim() ?? '';
      if (id.isEmpty) {
        withoutId.add(task);
        continue;
      }
      byId[id] = task;
    }
  }
  return <PlayerTask>[...byId.values, ...withoutId]
    ..sort(comparePlayerTasksForAgenda);
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
