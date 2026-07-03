import '../model/effectives.dart';
import '../model/player.dart';
import '../model/grinta_player.dart';
import '../model/team.dart';
import '../util/player_photo_resolver.dart';
import '../util/player_positions.dart';
import 'effectivesService.dart';
import 'playerService.dart';
import 'teamService.dart';

/// Charge les joueurs d'une équipe (effectif), avec repli optionnel sur une liste d'ids.
///
/// Seuls les membres dont l'effectif a [Effectives.type] == 0 (joueur) sont inclus.
class TeamPlayersService {
  final PlayerService _playerService;
  final TeamService _teamService;
  final EffectivesService _effectivesService;

  TeamPlayersService({
    PlayerService? playerService,
    TeamService? teamService,
    EffectivesService? effectivesService,
  })  : _playerService = playerService ?? PlayerService(),
        _teamService = teamService ?? TeamService(),
        _effectivesService = effectivesService ?? EffectivesService();

  Future<List<Player>> loadPlayers({
    required String teamId,
    List<String> fallbackPlayerIds = const [],
  }) async {
    final normalizedTeamId = teamId.trim();
    if (normalizedTeamId.isEmpty) {
      return <Player>[];
    }

    final playerIds = <String>{};
    var usesGrintaRoster = false;

    final team = await _teamService.getTeamById(normalizedTeamId);
    if (team != null) {
      if (_teamHasLegacyPlayers(team)) {
        for (final rawId in team.players!) {
          final id = rawId?.toString().trim() ?? '';
          if (id.isNotEmpty) {
            playerIds.add(id);
          }
        }
      } else if (_teamUsesGrintaRoster(team)) {
        usesGrintaRoster = true;
        playerIds.addAll(_grintaFieldPlayerIds(team));
      }
    }

    if (playerIds.isEmpty) {
      for (final id in fallbackPlayerIds) {
        final normalized = id.trim();
        if (normalized.isNotEmpty) {
          playerIds.add(normalized);
        }
      }
    }

    final rosterPlayerIds = usesGrintaRoster
        ? playerIds
        : await _rosterPlayerMemberIds(normalizedTeamId);

    final players = <Player>[];
    for (final id in playerIds) {
      if (!rosterPlayerIds.contains(id)) continue;

      final player = await _playerService.getPlayerById(id);
      if (player != null) {
        players.add(player);
      }
    }

    players.sort(comparePlayersByName);
    return dedupePlayersByMemberId(players);
  }

  /// One roster entry per member ([effectiveMemberId]).
  static List<Player> dedupePlayersByMemberId(List<Player> players) {
    final seenMemberIds = <String>{};
    final deduped = <Player>[];

    for (final player in players) {
      final memberId = effectiveMemberId(player);
      if (memberId == null) {
        deduped.add(player);
        continue;
      }
      if (seenMemberIds.add(memberId)) {
        deduped.add(player);
      }
    }

    return deduped;
  }

  static int comparePlayersByName(Player a, Player b) {
    return _comparePlayersByName(a, b);
  }

  bool _teamHasLegacyPlayers(Team team) {
    for (final dynamic rawId in team.players ?? const <dynamic>[]) {
      if (rawId?.toString().trim().isNotEmpty == true) {
        return true;
      }
    }
    return false;
  }

  bool _teamUsesGrintaRoster(Team team) {
    if (_teamHasLegacyPlayers(team)) {
      return false;
    }
    if (team.isGrinta == true) {
      return true;
    }
    for (final GrintaPlayer entry in team.grintaPlayers ?? const <GrintaPlayer>[]) {
      if (entry.playerId.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Iterable<String> _grintaFieldPlayerIds(Team team) sync* {
    for (final GrintaPlayer entry in team.grintaPlayers ?? const <GrintaPlayer>[]) {
      final String id = entry.playerId.trim();
      if (id.isEmpty) {
        continue;
      }
      if (isGrintaRosterStaff(
        positions: entry.positions,
        fonction: entry.fonction,
        listedInManagers: false,
      )) {
        continue;
      }
      yield id;
    }
  }

  /// Membres de l'équipe avec effectif joueur ([Effectives.type] == 0).
  Future<Set<String>> _rosterPlayerMemberIds(String teamId) async {
    final effectives = await _effectivesService.getEffectivesByTeamId(teamId);
    return effectives
        .where((e) => e.type == 0)
        .map((e) => e.memberID?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  static int _comparePlayersByName(Player a, Player b) {
    final last = (a.lastName ?? '').toLowerCase().compareTo(
      (b.lastName ?? '').toLowerCase(),
    );
    if (last != 0) return last;
    return (a.firstName ?? '').toLowerCase().compareTo(
      (b.firstName ?? '').toLowerCase(),
    );
  }
}
