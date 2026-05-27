import '../model/player.dart';
import 'playerService.dart';
import 'teamService.dart';

/// Charge les joueurs d'une équipe (effectif), avec repli optionnel sur une liste d'ids.
class TeamPlayersService {
  final PlayerService _playerService;
  final TeamService _teamService;

  TeamPlayersService({
    PlayerService? playerService,
    TeamService? teamService,
  })  : _playerService = playerService ?? PlayerService(),
        _teamService = teamService ?? TeamService();

  Future<List<Player>> loadPlayers({
    required String teamId,
    List<String> fallbackPlayerIds = const [],
  }) async {
    final normalizedTeamId = teamId.trim();
    if (normalizedTeamId.isEmpty) {
      return <Player>[];
    }

    final playerIds = <String>{};

    final team = await _teamService.getTeamById(normalizedTeamId);
    if (team?.players != null) {
      for (final rawId in team!.players!) {
        final id = rawId?.toString().trim() ?? '';
        if (id.isNotEmpty) {
          playerIds.add(id);
        }
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

    final players = <Player>[];
    for (final id in playerIds) {
      final player = await _playerService.getPlayerById(id);
      if (player != null) {
        players.add(player);
      }
    }

    players.sort(_comparePlayersByName);
    return players;
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
