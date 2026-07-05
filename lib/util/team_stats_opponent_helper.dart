import 'package:grinta/model/match.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/ranking.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';
import 'package:grinta/util/team_stats_matchday_helper.dart';

/// Opponent identified from competition matches (stable [key] for filtering).
class TeamStatsOpponent {
  const TeamStatsOpponent({
    required this.key,
    required this.displayName,
    this.affiliation,
    this.clubId,
  });

  final String key;
  final String displayName;
  final String? affiliation;
  final String? clubId;
}

String normalizeOpponentDisplayName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '';
  }
  if (trimmed.contains('Exempt')) {
    return '';
  }
  return trimmed;
}

String opponentStableKey({
  String? affiliation,
  String? clubId,
  required String displayName,
}) {
  final aff = affiliation?.trim() ?? '';
  if (aff.isNotEmpty) {
    return 'aff:$aff';
  }

  final club = clubId?.trim() ?? '';
  if (club.isNotEmpty) {
    return 'club:$club';
  }

  return 'name:${displayName.trim().toLowerCase()}';
}

String? clubIdForMatchSide({
  required Match match,
  required MatchSide side,
}) {
  final clubs = match.clubs ?? const <dynamic>[];
  if (clubs.isEmpty) {
    return null;
  }

  final index = side == MatchSide.team1 ? 0 : 1;
  if (index >= clubs.length) {
    return null;
  }

  final club = clubs[index]?.toString().trim() ?? '';
  return club.isEmpty ? null : club;
}

/// Builds a [TeamStatsOpponent] for one side of [match].
TeamStatsOpponent? opponentFromMatchSide({
  required Match match,
  required MatchSide side,
}) {
  final rawName = side == MatchSide.team1 ? match.team1 : match.team2;
  final affiliation = side == MatchSide.team1
      ? match.affiliationTeam1
      : match.affiliationTeam2;
  final displayName = normalizeOpponentDisplayName(rawName);
  if (displayName.isEmpty) {
    return null;
  }

  final clubId = clubIdForMatchSide(match: match, side: side);
  final trimmedAffiliation = affiliation?.trim() ?? '';

  return TeamStatsOpponent(
    key: opponentStableKey(
      affiliation: affiliation,
      clubId: clubId,
      displayName: displayName,
    ),
    displayName: displayName,
    affiliation: trimmedAffiliation.isEmpty ? null : trimmedAffiliation,
    clubId: clubId,
  );
}

/// Returns the opponent side for [match] from the user's team perspective.
TeamStatsOpponent? opponentForMatch({
  required Match match,
  required String teamId,
  String? clubId,
  String? clubAffiliation,
}) {
  final side = teamSideForMatch(
    match: match,
    teamId: teamId,
    clubId: clubId,
    clubAffiliation: clubAffiliation,
  );
  if (side == null) {
    return null;
  }

  final opponentSide =
      side == MatchSide.team1 ? MatchSide.team2 : MatchSide.team1;
  return opponentFromMatchSide(match: match, side: opponentSide);
}

/// Which side [opponent] occupies in [match], if any.
MatchSide? teamSideForOpponent({
  required Match match,
  required TeamStatsOpponent opponent,
}) {
  return teamSideForMatch(
    match: match,
    teamId: '',
    clubId: opponent.clubId,
    clubAffiliation: opponent.affiliation,
    displayName: opponent.displayName,
  );
}

/// Grinta team id for [opponent] in [match], when linked in [match.teams].
String? teamIdForOpponentInMatch({
  required Match match,
  required TeamStatsOpponent opponent,
}) {
  final side = teamSideForOpponent(match: match, opponent: opponent);
  if (side == null) {
    return null;
  }
  return teamIdForSide(match, side);
}

/// Display name of [opponent] on their side of [match].
String? opponentTeamDisplayNameForMatch({
  required Match match,
  required TeamStatsOpponent opponent,
}) {
  final side = teamSideForOpponent(match: match, opponent: opponent);
  if (side == null) {
    return null;
  }

  final rawName = side == MatchSide.team1 ? match.team1 : match.team2;
  final displayName = normalizeOpponentDisplayName(rawName);
  return displayName.isEmpty ? null : displayName;
}

bool matchIncludesOpponent({
  required Match match,
  required TeamStatsOpponent opponent,
}) {
  return teamSideForOpponent(match: match, opponent: opponent) != null;
}

/// Played matches in [matches] where [opponent] participates (either side).
List<Match> filterMatchesByOpponent({
  required List<Match> matches,
  required TeamStatsOpponent opponent,
}) {
  return matches
      .where(
        (match) => matchIncludesOpponent(match: match, opponent: opponent),
      )
      .toList();
}

/// Unique opponents from head-to-head [matches] (user's team vs others).
List<TeamStatsOpponent> buildOpponentsFromMatches({
  required List<Match> matches,
  required String teamId,
  String? clubId,
  String? clubAffiliation,
}) {
  final byKey = <String, TeamStatsOpponent>{};
  for (final match in matches) {
    final opponent = opponentForMatch(
      match: match,
      teamId: teamId,
      clubId: clubId,
      clubAffiliation: clubAffiliation,
    );
    if (opponent != null) {
      byKey.putIfAbsent(opponent.key, () => opponent);
    }
  }

  return _sortedOpponents(byKey.values);
}

/// Unique teams from all sides of [matches] (full competition pool).
List<TeamStatsOpponent> buildOpponentsFromCompetitionMatches({
  required List<Match> matches,
}) {
  final byKey = <String, TeamStatsOpponent>{};
  for (final match in matches) {
    for (final side in const [MatchSide.team1, MatchSide.team2]) {
      final opponent = opponentFromMatchSide(match: match, side: side);
      if (opponent != null) {
        byKey.putIfAbsent(opponent.key, () => opponent);
      }
    }
  }

  return _sortedOpponents(byKey.values);
}

TeamStatsOpponent _clubFromDisplayName({
  required String displayName,
  TeamStatsOpponent? fromMatch,
  String? affiliateFromPerDay,
}) {
  if (fromMatch != null) {
    return fromMatch;
  }

  final trimmedAffiliate = affiliateFromPerDay?.trim() ?? '';
  if (trimmedAffiliate.isNotEmpty) {
    return TeamStatsOpponent(
      key: opponentStableKey(
        affiliation: trimmedAffiliate,
        displayName: displayName,
      ),
      displayName: displayName,
      affiliation: trimmedAffiliate,
    );
  }

  return TeamStatsOpponent(
    key: opponentStableKey(displayName: displayName),
    displayName: displayName,
  );
}

Map<String, TeamStatsOpponent> _opponentsByDisplayName(
  Iterable<TeamStatsOpponent> opponents,
) {
  final byName = <String, TeamStatsOpponent>{};
  for (final opponent in opponents) {
    final normalized = opponent.displayName.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    byName.putIfAbsent(normalized, () => opponent);
  }
  return byName;
}

/// True when the pool is a league championship (matchdays or ranking table).
///
/// Cup pools use [Match.tour] with no positive [Match.day] and no ranking.
bool isChampionshipCompetitionPool({
  required List<Match> matches,
  Ranking? ranking,
}) {
  final ranks = ranking?.ranks ?? const <Rank>[];
  if (ranks.isNotEmpty) {
    return true;
  }

  return matches.any((match) => matchdayNumber(match) != null);
}

/// Opponents actually faced by the user's team in a cup pool.
List<TeamStatsOpponent> buildCupOpponentList({
  required List<Match> matches,
  required String teamId,
  String? clubId,
  String? clubAffiliation,
}) {
  final trimmedTeamId = teamId.trim();
  final trimmedClubId = clubId?.trim() ?? '';
  final trimmedAffiliation = clubAffiliation?.trim() ?? '';
  if (trimmedTeamId.isEmpty &&
      trimmedClubId.isEmpty &&
      trimmedAffiliation.isEmpty) {
    return const [];
  }

  final teamMatches = matches
      .where(
        (match) => matchIncludesTeam(
          match,
          trimmedTeamId,
          clubId: trimmedClubId.isEmpty ? null : trimmedClubId,
          clubAffiliation:
              trimmedAffiliation.isEmpty ? null : trimmedAffiliation,
        ),
      )
      .toList();

  return buildOpponentsFromMatches(
    matches: teamMatches,
    teamId: trimmedTeamId,
    clubId: trimmedClubId.isEmpty ? null : trimmedClubId,
    clubAffiliation: trimmedAffiliation.isEmpty ? null : trimmedAffiliation,
  );
}

/// Builds the club dropdown for a competition pool.
///
/// For championships, [ranking] ranks are listed first (authoritative poule).
/// Every entry is enriched with affiliation/club id from [affiliatesByTeamName]
/// and/or pool [matches].
///
/// For cups, only opponents faced by [teamId] / club identifiers are listed.
List<TeamStatsOpponent> buildCompetitionClubList({
  required List<Match> matches,
  Ranking? ranking,
  Map<String, String> affiliatesByTeamName = const {},
  String? teamId,
  String? clubId,
  String? clubAffiliation,
}) {
  if (!isChampionshipCompetitionPool(matches: matches, ranking: ranking)) {
    return buildCupOpponentList(
      matches: matches,
      teamId: teamId ?? '',
      clubId: clubId,
      clubAffiliation: clubAffiliation,
    );
  }

  final fromMatches = buildOpponentsFromCompetitionMatches(matches: matches);
  final byDisplayName = _opponentsByDisplayName(fromMatches);
  final byKey = <String, TeamStatsOpponent>{};

  final ranks = ranking?.ranks ?? const <Rank>[];
  if (ranks.isNotEmpty) {
    for (final rank in ranks) {
      final displayName = normalizeOpponentDisplayName(rank.team);
      if (displayName.isEmpty) {
        continue;
      }

      final normalizedName = displayName.toLowerCase();
      final club = _clubFromDisplayName(
        displayName: displayName,
        fromMatch: byDisplayName[normalizedName],
        affiliateFromPerDay: affiliatesByTeamName[normalizedName],
      );
      byKey[club.key] = club;
    }
  }

  for (final club in fromMatches) {
    byKey.putIfAbsent(club.key, () => club);
  }

  return _sortedOpponents(byKey.values);
}

List<TeamStatsOpponent> _sortedOpponents(Iterable<TeamStatsOpponent> opponents) {
  return opponents.toList()
    ..sort(
      (a, b) => a.displayName
          .toLowerCase()
          .compareTo(b.displayName.toLowerCase()),
    );
}

/// Registers minimal [Player] entries from [compo] for opponent stats tables.
void registerPlayersFromCompo(
  Map<String, Player> target,
  MatchCompo? compo,
) {
  if (compo == null) {
    return;
  }

  void add(PlayerCompo playerCompo) {
    final playerId = playerCompo.playerID?.trim() ?? '';
    if (playerId.isEmpty || target.containsKey(playerId)) {
      return;
    }

    final rawName = playerCompo.playerNameDisplayed?.trim() ??
        playerCompo.customName?.trim() ??
        '';
    final parts = rawName.split(RegExp(r'\s+'));
    final firstName = parts.length > 1 ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : rawName;

    target[playerId] = Player(
      keyMember: playerId,
      firstName: firstName.isEmpty ? null : firstName,
      lastName: lastName.isEmpty ? null : lastName,
    );
  }

  void addAll(Iterable<PlayerCompo>? players) {
    for (final playerCompo in players ?? const <PlayerCompo>[]) {
      add(playerCompo);
    }
  }

  addAll(compo.goalkeeper);
  addAll(compo.defender);
  addAll(compo.midfielder);
  addAll(compo.midfielderAttaking);
  addAll(compo.midfielderDefensive);
  addAll(compo.stricker);
  addAll(compo.substitute);
}

/// Registers minimal [Player] entries from [matchStats] for opponent stats tables.
///
/// When [displayNames] is provided, stores the raw FFF [MatchStatPlayer.player]
/// label keyed by [normalizeMatchStatPlayerKey] for UI display.
void registerPlayersFromMatchStats({
  required Map<String, Player> target,
  Map<String, String>? displayNames,
  required MatchStats? matchStats,
  required String opponentTeamName,
}) {
  if (matchStats == null) {
    return;
  }

  final resolvedTeamName = resolveMatchStatTeamName(
    preferredTeamName: opponentTeamName,
    matchStats: matchStats,
  );
  if (resolvedTeamName == null || resolvedTeamName.isEmpty) {
    return;
  }

  void add(MatchStatPlayer player) {
    if (!sameMatchStatTeam(player.team, resolvedTeamName)) {
      return;
    }

    final playerKey = normalizeMatchStatPlayerKey(player.player);
    if (playerKey.isEmpty || target.containsKey(playerKey)) {
      return;
    }

    final rawName = player.player?.trim() ?? '';
    if (displayNames != null && rawName.isNotEmpty) {
      displayNames.putIfAbsent(playerKey, () => rawName);
    }

    final parts = rawName.split(RegExp(r'\s+'));
    final firstName = parts.length > 1 ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : rawName;

    target[playerKey] = Player(
      keyMember: playerKey,
      firstName: firstName.isEmpty ? null : firstName,
      lastName: lastName.isEmpty ? null : lastName,
    );
  }

  for (final player in matchStats.titulars ?? const <MatchStatPlayer>[]) {
    add(player);
  }
  for (final player in matchStats.substitutes ?? const <MatchStatPlayer>[]) {
    add(player);
  }
}
