import 'package:grinta/model/player_cards.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/player_cards_helper.dart';

/// Whether the personal (player) cards entry should appear.
///
/// Mirrors Dashboard’s managed-vs-player team split: pure managers/coaches
/// (managed teams only) do not see the player-only button. Users who also have
/// at least one non-managed member team keep the player entry (dual role).
bool shouldShowPlayerCardsEntry({
  required Iterable<String> managedTeamIds,
  required Iterable<String> memberTeamIds,
}) {
  final managed = managedTeamIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
  if (managed.isEmpty) {
    return true;
  }

  return memberTeamIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .any((id) => !managed.contains(id));
}

/// Manager/coach cartons entry is relevant when there is at least one managed
/// team for the selected season (badge still requires non-purged count > 0).
bool shouldShowManagerCardsEntry({
  required Iterable<String> managedTeamIds,
}) {
  return managedTeamIds.any((id) => id.trim().isNotEmpty);
}

/// Total non-purged cards across a map of member → cards docs.
int countNonPurgedCardsAcrossMembers(
  Map<String, PlayerCards?> cardsByMemberId,
) {
  var total = 0;
  for (final cards in cardsByMemberId.values) {
    total += countNonPurgedPlayerCards(
      cards?.entries ?? const <PlayerCardEntry>[],
    );
  }
  return total;
}

/// How to open coach restitution after tapping the manager cards entry.
enum ManagerCardsOpenMode {
  /// No managed team with a usable id.
  none,

  /// Exactly one managed team → open its cards list directly.
  singleTeam,

  /// Several managed teams → pick a team first.
  pickTeam,
}

class ManagerCardsOpenPlan {
  const ManagerCardsOpenPlan._({
    required this.mode,
    required this.teams,
    this.singleTeam,
  });

  factory ManagerCardsOpenPlan.fromManagedTeams(Iterable<Team> managedTeams) {
    final teams = <Team>[];
    final seen = <String>{};
    for (final team in managedTeams) {
      final id = team.keyTeam?.trim() ?? '';
      if (id.isEmpty || !seen.add(id)) continue;
      teams.add(team);
    }

    if (teams.isEmpty) {
      return const ManagerCardsOpenPlan._(
        mode: ManagerCardsOpenMode.none,
        teams: <Team>[],
      );
    }
    if (teams.length == 1) {
      return ManagerCardsOpenPlan._(
        mode: ManagerCardsOpenMode.singleTeam,
        teams: teams,
        singleTeam: teams.first,
      );
    }
    return ManagerCardsOpenPlan._(
      mode: ManagerCardsOpenMode.pickTeam,
      teams: teams,
    );
  }

  final ManagerCardsOpenMode mode;
  final List<Team> teams;
  final Team? singleTeam;
}

String managerTeamDisplayName(Team team, {String fallback = ''}) {
  final name = (team.name ?? '').trim();
  if (name.isNotEmpty) return name;
  final id = team.keyTeam?.trim() ?? '';
  if (id.isNotEmpty) return id;
  return fallback;
}
