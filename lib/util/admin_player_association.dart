import '../model/player.dart';
import 'player_photo_resolver.dart';

/// Merges two member lists by canonical member id (`keyMember` / doc id).
List<Player> mergePlayersByMemberId(
  Iterable<Player> primary,
  Iterable<Player> secondary,
) {
  final byId = <String, Player>{};
  for (final player in primary) {
    final id = effectiveMemberId(player) ?? player.keyMember?.trim();
    if (id != null && id.isNotEmpty) {
      byId[id] = player;
    }
  }
  for (final player in secondary) {
    final id = effectiveMemberId(player) ?? player.keyMember?.trim();
    if (id != null && id.isNotEmpty) {
      byId.putIfAbsent(id, () => player);
    }
  }
  return byId.values.toList(growable: false);
}

/// Linked-player counts per Firebase uid from an already-loaded member list.
Map<String, int> adminPlayerCountsByUserId(Iterable<Player> members) {
  final counts = <String, int>{};
  for (final player in members) {
    for (final uid in collectMemberLinkedUserIds(player)) {
      counts[uid] = (counts[uid] ?? 0) + 1;
    }
  }
  return counts;
}

/// Members already linked to [uid], from an in-memory [members] snapshot.
List<Player> adminPlayersLinkedToUser(Iterable<Player> members, String uid) {
  final trimmed = uid.trim();
  if (trimmed.isEmpty) return const <Player>[];
  return members
      .where((player) => collectMemberLinkedUserIds(player).contains(trimmed))
      .toList(growable: false);
}

/// Count shown on Admin → Utilisateurs.
///
/// `null` means the association query has not emitted yet — never treat that
/// as zero, which flashes « Aucun joueur » / "No players".
int? adminAssociationPlayerCount({
  required bool hasData,
  List<Player>? players,
}) {
  if (!hasData) return null;
  return players?.length ?? 0;
}
