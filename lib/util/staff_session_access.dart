import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/util/match_creation_helper.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/player_positions.dart';
import 'package:grinta/util/training_creation_helper.dart';

/// True when [player] has a Grinta roster staff row on [team].
///
/// Staff roles live in [GrintaPlayer.fonction] (educator / executive / medical).
/// Being listed in [Team.managers] alone is not enough — that is a permission
/// flag, not a roster staff classification.
bool isRosterStaffOnTeam(Team team, Player player) {
  final Set<String> lookupIds = playerMemberLookupIds(player);
  if (lookupIds.isEmpty) {
    return false;
  }

  final Set<String> managerIds = <String>{};
  for (final dynamic raw in team.managers ?? const <dynamic>[]) {
    final String id = raw?.toString().trim() ?? '';
    if (id.isNotEmpty) {
      managerIds.add(id);
    }
  }

  for (final GrintaPlayer entry in team.grintaPlayers ?? const <GrintaPlayer>[]) {
    final String entryId = entry.playerId.trim();
    if (entryId.isEmpty || !lookupIds.contains(entryId)) {
      continue;
    }
    if (isGrintaRosterStaff(
      positions: entry.positions,
      fonction: entry.fonction,
      listedInManagers: managerIds.contains(entryId),
    )) {
      return true;
    }
  }

  return false;
}

Team? teamForAgendaId(AppSession session, String? teamId) {
  final String trimmed = teamId?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  for (final Team team in session.teamsForAgendaSelectedSeason) {
    if (team.keyTeam?.trim() == trimmed) {
      return team;
    }
  }
  return null;
}

/// True when the selected profile is roster staff on [teamId].
bool isStaffOnTeamId(AppSession session, String? teamId) {
  final Player? player = session.selectedPlayer;
  if (player == null) {
    return false;
  }
  final Team? team = teamForAgendaId(session, teamId);
  if (team == null) {
    return false;
  }
  return isRosterStaffOnTeam(team, player);
}

/// Manager/owner **or** roster staff may open training/match team details.
bool canAccessTeamSessionDetails(AppSession session, String? teamId) {
  final String trimmed = teamId?.trim() ?? '';
  if (trimmed.isEmpty) {
    return false;
  }
  if (session.managedTeamsIdsForSelectedSeason.contains(trimmed)) {
    return true;
  }
  return isStaffOnTeamId(session, trimmed);
}

/// Training detail access (présences / trackers screen).
bool canAccessTrainingSessionDetails(Training training, AppSession session) {
  return canAccessTeamSessionDetails(session, managedTrainingTeamId(training));
}

/// Match detail team view (compo, convocations, team stats tabs).
bool canAccessMatchSessionDetails(models.Match match, AppSession session) {
  if (canManageMatch(match, session)) {
    return true;
  }

  final Player? player = session.selectedPlayer;
  if (player == null) {
    return false;
  }

  final Set<String> teamIds = <String>{};
  final String? primary = match.teamID?.trim();
  if (primary != null && primary.isNotEmpty) {
    teamIds.add(primary);
  }
  for (final dynamic raw in match.teams ?? const <dynamic>[]) {
    final String id = raw?.toString().trim() ?? '';
    if (id.isNotEmpty) {
      teamIds.add(id);
    }
  }

  for (final String teamId in teamIds) {
    if (canAccessTeamSessionDetails(session, teamId)) {
      return true;
    }
  }
  return false;
}
