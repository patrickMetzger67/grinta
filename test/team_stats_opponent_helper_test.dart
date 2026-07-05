import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';

void main() {
  group('isChampionshipCompetitionPool', () {
    test('returns true when any match has a positive day', () {
      final matches = [
        Match(id: '1', day: 3, tour: ''),
        Match(id: '2', day: 0, tour: '1/8 de finale'),
      ];

      expect(
        isChampionshipCompetitionPool(matches: matches),
        isTrue,
      );
    });

    test('returns false for cup-only pool with no ranking', () {
      final matches = [
        Match(
          id: '1',
          day: 0,
          tour: '1/32 de finale',
          team1: 'Team A',
          team2: 'Team B',
        ),
        Match(
          id: '2',
          day: 0,
          tour: '1/16 de finale',
          team1: 'Team C',
          team2: 'Team D',
        ),
      ];

      expect(
        isChampionshipCompetitionPool(matches: matches),
        isFalse,
      );
    });
  });

  group('buildCompetitionClubList', () {
    test('lists all pool clubs for championship', () {
      final matches = [
        Match(id: '1', day: 1, team1: 'Alpha FC', team2: 'Beta FC'),
        Match(id: '2', day: 2, team1: 'Gamma FC', team2: 'Delta FC'),
      ];

      final clubs = buildCompetitionClubList(matches: matches);

      expect(clubs.map((c) => c.displayName).toSet(), {
        'Alpha FC',
        'Beta FC',
        'Gamma FC',
        'Delta FC',
      });
    });

    test('lists only faced opponents for cup', () {
      final matches = [
        Match(
          id: '1',
          day: 0,
          tour: '1/32 de finale',
          team1: 'My Team',
          team2: 'Opponent A',
          teams: ['team-my'],
        ),
        Match(
          id: '2',
          day: 0,
          tour: '1/32 de finale',
          team1: 'Other X',
          team2: 'Other Y',
          teams: ['team-x', 'team-y'],
        ),
        Match(
          id: '3',
          day: 0,
          tour: '1/16 de finale',
          team1: 'My Team',
          team2: 'Opponent B',
          teams: ['team-my', 'team-b'],
        ),
      ];

      final clubs = buildCompetitionClubList(
        matches: matches,
        teamId: 'team-my',
      );

      expect(clubs.map((c) => c.displayName).toList(), [
        'Opponent A',
        'Opponent B',
      ]);
    });

    test('cup list excludes opponents from tours without team involvement', () {
      final matches = [
        Match(
          id: '1',
          day: 0,
          tour: '1/32 de finale',
          team1: 'Unrelated A',
          team2: 'Unrelated B',
          teams: ['team-a', 'team-b'],
        ),
      ];

      final clubs = buildCompetitionClubList(
        matches: matches,
        teamId: 'team-my',
      );

      expect(clubs, isEmpty);
    });
  });
}
