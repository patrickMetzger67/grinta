import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/manager_cards_helper.dart';

Team _team(String id, {String? name}) {
  return Team(keyTeam: id, name: name);
}

void main() {
  group('shouldShowPlayerCardsEntry', () {
    test('shows for players with no managed teams', () {
      expect(
        shouldShowPlayerCardsEntry(
          managedTeamIds: const [],
          memberTeamIds: const ['player-team'],
        ),
        isTrue,
      );
    });

    test('hides for pure managers (managed only)', () {
      expect(
        shouldShowPlayerCardsEntry(
          managedTeamIds: const ['managed-a'],
          memberTeamIds: const [],
        ),
        isFalse,
      );
      expect(
        shouldShowPlayerCardsEntry(
          managedTeamIds: const ['managed-a'],
          memberTeamIds: const ['managed-a'],
        ),
        isFalse,
      );
    });

    test('shows for dual-role users with a non-managed member team', () {
      expect(
        shouldShowPlayerCardsEntry(
          managedTeamIds: const ['managed-a'],
          memberTeamIds: const ['managed-a', 'player-b'],
        ),
        isTrue,
      );
    });
  });

  group('shouldShowManagerCardsEntry', () {
    test('requires at least one managed team id', () {
      expect(
        shouldShowManagerCardsEntry(managedTeamIds: const []),
        isFalse,
      );
      expect(
        shouldShowManagerCardsEntry(managedTeamIds: const ['  ']),
        isFalse,
      );
      expect(
        shouldShowManagerCardsEntry(managedTeamIds: const ['team-1']),
        isTrue,
      );
    });

    test('shows for multi-team managers regardless of card count', () {
      expect(
        shouldShowManagerCardsEntry(
          managedTeamIds: const ['team-a', 'team-b', 'team-c'],
        ),
        isTrue,
      );
      // Entry visibility is independent of non-purged count (badge only).
      expect(shouldShowManagerCardsBadge(nonPurgedCount: 0), isFalse);
      expect(shouldShowManagerCardsBadge(nonPurgedCount: 4), isTrue);
    });
  });

  group('shouldShowManagerCardsBadge', () {
    test('only when non-purged count is positive', () {
      expect(shouldShowManagerCardsBadge(nonPurgedCount: 0), isFalse);
      expect(shouldShowManagerCardsBadge(nonPurgedCount: -1), isFalse);
      expect(shouldShowManagerCardsBadge(nonPurgedCount: 1), isTrue);
    });
  });

  group('countNonPurgedCardsAcrossMembers', () {
    test('sums non-purged entries across members and ignores purged', () {
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
              type: playerCardTypeRed,
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
              type: playerCardTypeYellow,
            ),
            PlayerCardEntry(
              matchId: 'm4',
              time: 15,
              type: playerCardTypeYellow,
            ),
          ],
        ),
        'c': null,
        'd': const PlayerCards(
          memberId: 'd',
          entries: [
            PlayerCardEntry(
              matchId: 'm5',
              time: 40,
              type: playerCardTypeRed,
              isPurged: true,
            ),
          ],
        ),
      };

      expect(countNonPurgedCardsAcrossMembers(cardsByMemberId), 3);
    });
  });

  group('ManagerCardsOpenPlan', () {
    test('none when no usable teams', () {
      final plan = ManagerCardsOpenPlan.fromManagedTeams(const []);
      expect(plan.mode, ManagerCardsOpenMode.none);
      expect(plan.singleTeam, isNull);
    });

    test('singleTeam when exactly one managed team', () {
      final plan = ManagerCardsOpenPlan.fromManagedTeams([
        _team('t1', name: 'U18'),
      ]);
      expect(plan.mode, ManagerCardsOpenMode.singleTeam);
      expect(plan.singleTeam?.keyTeam, 't1');
      expect(plan.teams, hasLength(1));
    });

    test('pickTeam when several managed teams (deduped)', () {
      final plan = ManagerCardsOpenPlan.fromManagedTeams([
        _team('t1', name: 'A'),
        _team('t2', name: 'B'),
        _team('t1', name: 'A again'),
        _team('  ', name: 'empty'),
      ]);
      expect(plan.mode, ManagerCardsOpenMode.pickTeam);
      expect(plan.singleTeam, isNull);
      expect(plan.teams.map((t) => t.keyTeam).toList(), ['t1', 't2']);
    });
  });

  group('managerTeamDisplayName', () {
    test('prefers name then id then fallback', () {
      expect(
        managerTeamDisplayName(_team('t1', name: ' Seniors ')),
        'Seniors',
      );
      expect(managerTeamDisplayName(_team('t1')), 't1');
      expect(
        managerTeamDisplayName(_team(''), fallback: 'Équipe'),
        'Équipe',
      );
    });
  });
}
