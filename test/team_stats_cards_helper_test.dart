import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/util/team_stats_cards_helper.dart';

Player _player({
  required String id,
  required String firstName,
  required String lastName,
}) {
  return Player(
    keyMember: id,
    firstName: firstName,
    lastName: lastName,
  );
}

void main() {
  group('filterTeamStatsCardEntries', () {
    const entries = <PlayerCardEntry>[
      PlayerCardEntry(
        matchId: 'm1',
        time: 10,
        type: playerCardTypeYellow,
      ),
      PlayerCardEntry(
        matchId: 'm2',
        time: 20,
        type: playerCardTypeRed,
        isPurged: true,
      ),
      PlayerCardEntry(
        matchId: 'm3',
        time: 30,
        type: playerCardTypeYellow,
        isPurged: false,
      ),
    ];

    test('default excludes purged (isPurged != true)', () {
      final filtered = filterTeamStatsCardEntries(
        entries,
        includePurged: false,
      );
      expect(filtered, [entries[0], entries[2]]);
    });

    test('includePurged keeps all entries', () {
      final filtered = filterTeamStatsCardEntries(
        entries,
        includePurged: true,
      );
      expect(filtered, entries);
    });
  });

  group('buildTeamStatsCardsRows', () {
    test('aggregates, filters, and sorts by count desc then name', () {
      final alice = _player(id: 'a', firstName: 'Alice', lastName: 'Martin');
      final bob = _player(id: 'b', firstName: 'Bob', lastName: 'Durand');
      final claire = _player(id: 'c', firstName: 'Claire', lastName: 'Bernard');

      final cardsByMemberId = <String, PlayerCards?>{
        'a': const PlayerCards(
          memberId: 'a',
          entries: [
            PlayerCardEntry(
              matchId: 'm1',
              time: 10,
              type: playerCardTypeYellow,
            ),
            PlayerCardEntry(
              matchId: 'm2',
              time: 20,
              type: playerCardTypeYellow,
              isPurged: true,
            ),
          ],
        ),
        'b': const PlayerCards(
          memberId: 'b',
          entries: [
            PlayerCardEntry(
              matchId: 'm3',
              time: 5,
              type: playerCardTypeRed,
            ),
            PlayerCardEntry(
              matchId: 'm4',
              time: 15,
              type: playerCardTypeYellow,
            ),
            PlayerCardEntry(
              matchId: 'm5',
              time: 25,
              type: playerCardTypeYellow,
            ),
          ],
        ),
        'c': const PlayerCards(
          memberId: 'c',
          entries: [
            PlayerCardEntry(
              matchId: 'm6',
              time: 40,
              type: playerCardTypeYellow,
              isPurged: true,
            ),
          ],
        ),
      };

      final rows = buildTeamStatsCardsRows(
        players: [alice, bob, claire],
        cardsByMemberId: cardsByMemberId,
        includePurged: false,
      );

      // Claire only has purged → excluded. Bob (3) before Alice (1).
      expect(rows, hasLength(2));
      expect(rows[0].memberId, 'b');
      expect(rows[0].count, 3);
      expect(rows[1].memberId, 'a');
      expect(rows[1].count, 1);
    });

    test('includePurged adds purged-only players and ties break by name', () {
      final alice = _player(id: 'a', firstName: 'Alice', lastName: 'Martin');
      final bob = _player(id: 'b', firstName: 'Bob', lastName: 'Durand');

      final rows = buildTeamStatsCardsRows(
        players: [bob, alice],
        cardsByMemberId: {
          'a': const PlayerCards(
            memberId: 'a',
            entries: [
              PlayerCardEntry(
                matchId: 'm1',
                time: 10,
                type: playerCardTypeYellow,
              ),
            ],
          ),
          'b': const PlayerCards(
            memberId: 'b',
            entries: [
              PlayerCardEntry(
                matchId: 'm2',
                time: 20,
                type: playerCardTypeRed,
              ),
            ],
          ),
        },
        includePurged: true,
      );

      // Same count → Alice before Bob by display name.
      expect(rows.map((r) => r.memberId).toList(), ['a', 'b']);
    });
  });

  group('setPlayerCardEntryPurged', () {
    const entries = <PlayerCardEntry>[
      PlayerCardEntry(
        matchId: 'm1',
        time: 10,
        type: playerCardTypeYellow,
      ),
      PlayerCardEntry(
        matchId: 'm2',
        time: 20,
        extraTime: 1,
        type: playerCardTypeRed,
        isPurged: true,
      ),
    ];

    test('sets isPurged on the matching identity', () {
      final updated = setPlayerCardEntryPurged(
        entries,
        const PlayerCardEntry(
          matchId: 'm1',
          time: 10,
          type: playerCardTypeYellow,
        ),
        isPurged: true,
      );

      expect(updated[0].isPurged, isTrue);
      expect(updated[1].isPurged, isTrue);
      expect(identical(updated, entries), isFalse);
    });

    test('is idempotent when value already matches', () {
      final updated = setPlayerCardEntryPurged(
        entries,
        const PlayerCardEntry(
          matchId: 'm2',
          time: 20,
          extraTime: 1,
          type: playerCardTypeRed,
        ),
        isPurged: true,
      );

      expect(updated[1].isPurged, isTrue);
      expect(updated, entries);
    });

    test('no-op when identity is missing', () {
      final updated = setPlayerCardEntryPurged(
        entries,
        const PlayerCardEntry(
          matchId: 'missing',
          time: 99,
          type: playerCardTypeYellow,
        ),
        isPurged: true,
      );

      expect(updated, entries);
    });
  });
}
