import '../model/effectives.dart';
import '../model/player.dart';
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

    final rosterPlayerIds = await _rosterPlayerMemberIds(normalizedTeamId);

    final players = <Player>[];
    for (final id in playerIds) {
      if (!rosterPlayerIds.contains(id)) continue;

      final player = await _playerService.getPlayerById(id);
      if (player != null) {
        players.add(player);
      }
    }

    players.sort(_comparePlayersByName);
    return players;
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
