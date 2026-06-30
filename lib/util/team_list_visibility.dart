import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/player_positions.dart';

/// True when [team] lists [player] on [Team.grintaPlayers] or [Team.players].
bool teamContainsMemberOnRoster(Team team, Player player) {
  if (teamContainsGrintaMemberForPlayer(team, player)) {
    return true;
  }

  final Set<String> lookupIds = playerMemberLookupIds(player);
  for (final dynamic raw in team.players ?? const <dynamic>[]) {
    final String id = raw?.toString().trim() ?? '';
    if (id.isNotEmpty && lookupIds.contains(id)) {
      return true;
    }
  }
  return false;
}

/// Staff / ambiguous profiles may see owned or managed teams without roster rows.
bool memberProfileShowsNonRosterOwnedTeams(Player player) {
  if (hasStaffProfilePositionCodes(player.positionCodes)) {
    return true;
  }
  if (hasMemberProfileFieldPlayerRole(player.positionCodes)) {
    return false;
  }
  return true;
}

/// Whether a team loaded for [player] should appear in the teams list.
bool shouldIncludeTeamInMemberProfileList(Team team, Player player) {
  if (memberProfileShowsNonRosterOwnedTeams(player)) {
    return true;
  }
  return teamContainsMemberOnRoster(team, player);
}
