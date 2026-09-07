import 'package:grinta/model/player.dart';
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_cards_helper.dart';
import 'package:grinta/util/player_photo_resolver.dart';

/// One row in Team Stats → Analyse → Cartons.
class TeamStatsPlayerCardsRow {
  const TeamStatsPlayerCardsRow({
    required this.memberId,
    required this.player,
    required this.entries,
    required this.displayName,
  });

  final String memberId;
  final Player player;

  /// Entries after applying the purged filter.
  final List<PlayerCardEntry> entries;
  final String displayName;

  int get count => entries.length;
}

/// Filters card entries. Default ([includePurged] false) keeps
/// `isPurged != true` only.
List<PlayerCardEntry> filterTeamStatsCardEntries(
  Iterable<PlayerCardEntry> entries, {
  required bool includePurged,
}) {
  if (includePurged) {
    return List<PlayerCardEntry>.from(entries, growable: false);
  }
  return nonPurgedPlayerCardEntries(entries);
}

/// Builds sorted per-player rows for the team cards tab.
///
/// Only players with at least one matching entry are included.
/// Sort: count descending, then display name ascending.
List<TeamStatsPlayerCardsRow> buildTeamStatsCardsRows({
  required List<Player> players,
  required Map<String, PlayerCards?> cardsByMemberId,
  required bool includePurged,
  String unknownPlayerLabel = 'Joueur',
}) {
  final rows = <TeamStatsPlayerCardsRow>[];

  for (final player in players) {
    final memberId = effectiveMemberId(player)?.trim() ?? '';
    if (memberId.isEmpty) {
      continue;
    }

    final cards = cardsByMemberId[memberId];
    final filtered = filterTeamStatsCardEntries(
      cards?.entries ?? const <PlayerCardEntry>[],
      includePurged: includePurged,
    );
    if (filtered.isEmpty) {
      continue;
    }

    rows.add(
      TeamStatsPlayerCardsRow(
        memberId: memberId,
        player: player,
        entries: filtered,
        displayName: playerDisplayName(
          player,
          unknownLabel: unknownPlayerLabel,
        ),
      ),
    );
  }

  rows.sort(_compareCardsRows);
  return rows;
}

int _compareCardsRows(TeamStatsPlayerCardsRow a, TeamStatsPlayerCardsRow b) {
  final byCount = b.count.compareTo(a.count);
  if (byCount != 0) {
    return byCount;
  }
  return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
}

/// Idempotently sets [isPurged] on the entry matching [identity]
/// (matchId + time + extraTime + type). Returns the original list when
/// nothing changes.
List<PlayerCardEntry> setPlayerCardEntryPurged(
  List<PlayerCardEntry> entries,
  PlayerCardEntry identity, {
  required bool isPurged,
}) {
  final index = entries.indexWhere((entry) => entry.hasSameIdentityAs(identity));
  if (index < 0) {
    return List<PlayerCardEntry>.from(entries);
  }

  final current = entries[index];
  if (current.isPurged == isPurged) {
    return List<PlayerCardEntry>.from(entries);
  }

  final updated = List<PlayerCardEntry>.from(entries);
  updated[index] = PlayerCardEntry(
    matchId: current.matchId,
    time: current.time,
    extraTime: current.extraTime,
    type: current.type,
    isPurged: isPurged,
  );
  return updated;
}
