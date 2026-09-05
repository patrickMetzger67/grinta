import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/util/player_cards_helper.dart';

void main() {
  group('PlayerCardEntry toMap / fromMap', () {
    test('round-trips required fields and defaults isPurged to false', () {
      const original = PlayerCardEntry(
        matchId: '56174440',
        time: 67,
        extraTime: 2,
        type: playerCardTypeYellow,
      );

      final parsed = PlayerCardEntry.fromMap(original.toMap());

      expect(parsed.matchId, '56174440');
      expect(parsed.time, 67);
      expect(parsed.extraTime, 2);
      expect(parsed.type, playerCardTypeYellow);
      expect(parsed.isPurged, isFalse);
      expect(parsed, original);
    });

    test('reads isPurged true and missing extraTime as 0', () {
      final parsed = PlayerCardEntry.fromMap(<String, dynamic>{
        keyPlayerCardMatchId: 'm1',
        keyPlayerCardTime: 12,
        keyPlayerCardType: playerCardTypeRed,
        keyPlayerCardIsPurged: true,
      });

      expect(parsed.extraTime, 0);
      expect(parsed.isPurged, isTrue);
      expect(parsed.type, playerCardTypeRed);
    });
  });

  group('PlayerCards toMap / fromMap', () {
    test('round-trips the Firestore document shape', () {
      const original = PlayerCards(
        memberId: 'member-42',
        entries: [
          PlayerCardEntry(
            matchId: 'm1',
            time: 33,
            type: playerCardTypeYellow,
          ),
          PlayerCardEntry(
            matchId: 'm2',
            time: 90,
            extraTime: 1,
            type: playerCardTypeRed,
            isPurged: true,
          ),
        ],
      );

      final parsed = PlayerCards.fromMap(
        original.toMap(),
        fallbackMemberId: 'ignored',
      );

      expect(parsed.memberId, 'member-42');
      expect(parsed.documentId, 'member-42');
      expect(parsed.entries, hasLength(2));
      expect(parsed.entries[0].matchId, 'm1');
      expect(parsed.entries[1].isPurged, isTrue);
      expect(parsed.entries[1].extraTime, 1);
    });

    test('uses snapshot id when memberId is missing', () {
      final parsed = PlayerCards.fromMap(
        <String, dynamic>{
          keyPlayerCardsEntries: [
            <String, dynamic>{
              keyPlayerCardMatchId: 'm1',
              keyPlayerCardTime: 8,
              keyPlayerCardType: playerCardTypeYellow,
            },
          ],
        },
        fallbackMemberId: 'doc-id',
      );

      expect(parsed.memberId, 'doc-id');
      expect(parsed.entries.single.time, 8);
    });
  });

  group('upsertPlayerCardEntry', () {
    const incoming = PlayerCardEntry(
      matchId: 'm1',
      time: 40,
      type: playerCardTypeYellow,
    );

    test('appends a new identity', () {
      const existing = [
        PlayerCardEntry(
          matchId: 'm1',
          time: 12,
          type: playerCardTypeYellow,
        ),
      ];

      final updated = upsertPlayerCardEntry(existing, incoming);

      expect(updated, hasLength(2));
      expect(updated.last, incoming);
      expect(identical(updated, existing), isFalse);
    });

    test('skips duplicate match+time+extraTime+type and keeps isPurged', () {
      const existing = [
        PlayerCardEntry(
          matchId: 'm1',
          time: 40,
          type: playerCardTypeYellow,
          isPurged: true,
        ),
      ];
      const duplicate = PlayerCardEntry(
        matchId: 'm1',
        time: 40,
        type: playerCardTypeYellow,
      );

      final updated = upsertPlayerCardEntry(existing, duplicate);

      expect(updated, hasLength(1));
      expect(updated.single.isPurged, isTrue);
      expect(playerCardEntryExists(existing, duplicate), isTrue);
    });

    test('treats extraTime as part of the identity', () {
      const firstHalfStoppage = PlayerCardEntry(
        matchId: 'm1',
        time: 45,
        extraTime: 1,
        type: playerCardTypeYellow,
      );
      const laterStoppage = PlayerCardEntry(
        matchId: 'm1',
        time: 45,
        extraTime: 3,
        type: playerCardTypeYellow,
      );

      final updated = upsertPlayerCardEntry(
        [firstHalfStoppage],
        laterStoppage,
      );

      expect(updated, hasLength(2));
    });
  });

  group('parsePlayerCardType', () {
    test('maps Grinta and FMI yellow / red aliases', () {
      expect(parsePlayerCardType('CardType.yellow'), playerCardTypeYellow);
      expect(parsePlayerCardType('ActionType.yellowCard'), playerCardTypeYellow);
      expect(parsePlayerCardType('yellow_card'), playerCardTypeYellow);
      expect(parsePlayerCardType('carton_jaune'), playerCardTypeYellow);
      expect(parsePlayerCardType('CardType.red'), playerCardTypeRed);
      expect(parsePlayerCardType('redcard'), playerCardTypeRed);
      expect(parsePlayerCardType('carton rouge'), playerCardTypeRed);
      expect(parsePlayerCardType('second_yellow'), playerCardTypeRed);
      expect(parsePlayerCardType('goal'), isNull);
    });
  });

  group('playerCardEntryFromGrintaHighlight', () {
    test('builds an unpurged entry from a yellow highlight with player id', () {
      final entry = playerCardEntryFromGrintaHighlight(
        matchId: 'm1',
        actionType: ActionType.yellowCard,
        playerId: 'member-7',
        minute: 22,
        extraTime: 0,
      );

      expect(entry, isNotNull);
      expect(entry!.matchId, 'm1');
      expect(entry.time, 22);
      expect(entry.type, playerCardTypeYellow);
      expect(entry.isPurged, isFalse);
    });

    test('skips opponent cards without a member id', () {
      expect(
        playerCardEntryFromGrintaHighlight(
          matchId: 'm1',
          actionType: ActionType.redCard,
          playerId: '  ',
          minute: 70,
        ),
        isNull,
      );
    });

    test('skips non-card actions', () {
      expect(
        playerCardEntryFromGrintaHighlight(
          matchId: 'm1',
          actionType: ActionType.goal,
          playerId: 'member-7',
        ),
        isNull,
      );
    });
  });

  group('FMI highlight mapping', () {
    test('detects card types and builds an entry', () {
      final highlight = MatchStatHighLight(
        player: 'Dupont',
        time: 55,
        type: 'carton_jaune',
      );

      expect(isFmiCardHighlight(highlight), isTrue);
      expect(isFmiCardHighlight(MatchStatHighLight(type: 'goal')), isFalse);

      final entry = playerCardEntryFromFmiHighlight(
        matchId: 'm9',
        highlight: highlight,
        memberId: 'member-3',
      );

      expect(entry?.matchId, 'm9');
      expect(entry?.time, 55);
      expect(entry?.type, playerCardTypeYellow);
      expect(entry?.isPurged, isFalse);
    });
  });
}
