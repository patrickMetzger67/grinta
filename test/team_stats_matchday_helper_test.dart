import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/util/team_stats_matchday_helper.dart';

void main() {
  group('defaultMatchdayIndex', () {
    Match datedMatch({required String id, required int day, required DateTime date}) {
      return Match(
        id: id,
        day: day,
        timestamp: Timestamp.fromDate(date),
      );
    }

    test('selects matchday whose date range contains reference date', () {
      final reference = DateTime(2026, 3, 15);
      final groups = groupMatchesByMatchday([
        datedMatch(id: '1', day: 1, date: DateTime(2026, 3, 1)),
        datedMatch(id: '2a', day: 2, date: DateTime(2026, 3, 14)),
        datedMatch(id: '2b', day: 2, date: DateTime(2026, 3, 16)),
        datedMatch(id: '3', day: 3, date: DateTime(2026, 3, 25)),
      ]);

      expect(
        defaultMatchdayIndex(groups, referenceDate: reference),
        1,
      );
    });

    test('prefers upcoming matchday when equally distant', () {
      final reference = DateTime(2026, 3, 15);
      final groups = groupMatchesByMatchday([
        datedMatch(id: '1', day: 1, date: DateTime(2026, 3, 10)),
        datedMatch(id: '2', day: 2, date: DateTime(2026, 3, 20)),
      ]);

      expect(
        defaultMatchdayIndex(groups, referenceDate: reference),
        1,
      );
    });

    test('selects closest past matchday when all are in the past', () {
      final reference = DateTime(2026, 4, 1);
      final groups = groupMatchesByMatchday([
        datedMatch(id: '1', day: 1, date: DateTime(2026, 3, 1)),
        datedMatch(id: '2', day: 2, date: DateTime(2026, 3, 20)),
      ]);

      expect(
        defaultMatchdayIndex(groups, referenceDate: reference),
        1,
      );
    });

    test('selects closest future matchday when all are in the future', () {
      final reference = DateTime(2026, 3, 1);
      final groups = groupMatchesByMatchday([
        datedMatch(id: '1', day: 1, date: DateTime(2026, 3, 10)),
        datedMatch(id: '2', day: 2, date: DateTime(2026, 3, 25)),
      ]);

      expect(
        defaultMatchdayIndex(groups, referenceDate: reference),
        0,
      );
    });

    test('returns zero for empty groups', () {
      expect(defaultMatchdayIndex(const []), 0);
    });
  });

  group('groupMatchesByMatchday', () {
    test('groups league matches by day', () {
      final matches = [
        Match(id: '1', day: 2, tour: ''),
        Match(id: '2', day: 1, tour: ''),
      ];

      final groups = groupMatchesByMatchday(matches, teamId: 'team-a');

      expect(groups, hasLength(2));
      expect(groups[0].kind, TeamStatsMatchdayGroupKind.day);
      expect(groups[0].day, 1);
      expect(groups[1].day, 2);
    });

    test('groups cup matches by tour when day is zero', () {
      final matches = [
        Match(
          id: '1',
          day: 0,
          tour: '1/32 de finale',
          teams: ['team-a'],
        ),
        Match(
          id: '2',
          day: 0,
          tour: '1/16 de finale',
          teams: ['team-a'],
        ),
      ];

      final groups = groupMatchesByMatchday(matches, teamId: 'team-a');

      expect(groups, hasLength(2));
      expect(groups.every((g) => g.kind == TeamStatsMatchdayGroupKind.tour),
          isTrue);
      expect(
        groups.map((g) => g.tour).toSet(),
        {'1/32 de finale', '1/16 de finale'},
      );
    });

    test('includes cup matches linked via teamID when teams array is empty', () {
      final matches = [
        Match(
          id: '1',
          day: 0,
          tour: '1/8 de finale',
          teamID: 'team-a',
        ),
      ];

      final groups = groupMatchesByMatchday(matches, teamId: 'team-a');

      expect(groups, hasLength(1));
      expect(groups.first.tour, '1/8 de finale');
      expect(groups.first.matches, hasLength(1));
    });

    test('includes cup matches linked via clubs when teams is empty', () {
      final matches = [
        Match(
          id: '1',
          day: 0,
          tour: 'Finale',
          clubs: ['club-123'],
        ),
        Match(
          id: '2',
          day: 0,
          tour: 'Finale',
          clubs: ['other-club'],
        ),
      ];

      final groups = groupMatchesByMatchday(
        matches,
        teamId: '',
        clubId: 'club-123',
      );

      expect(groups, hasLength(1));
      expect(groups.first.matches, hasLength(1));
      expect(groups.first.matches.first.id, '1');
    });

    test('omits cup tours with no team involvement', () {
      final matches = [
        Match(
          id: '1',
          day: 0,
          tour: '1/32 de finale',
          teams: ['other-team'],
        ),
      ];

      final groups = groupMatchesByMatchday(matches, teamId: 'team-a');

      expect(groups, isEmpty);
    });
  });
}
