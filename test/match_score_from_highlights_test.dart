import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/util/match_goal_helper.dart';

Highlights _goal({
  required String affiliationTeam,
  required int minute,
}) {
  return Highlights(
    matchCalendarId: 'm1',
    teamId: 't1',
    minute: minute,
    actionType: ActionType.goal,
    value: Goal(
      affiliationTeam: affiliationTeam,
      goalType: GoalType.normal,
    ),
    dateTime: Timestamp.fromDate(DateTime(2026, 8, 2, 15, minute)),
  );
}

models.Match _match({
  String affiliationTeam1 = '500554',
  String affiliationTeam2 = '517642',
  int homeScore = 0,
  int outSideScore = 0,
}) {
  return models.Match(
    id: 'PQbBSkHS7g8R7FoxQKx1',
    affiliationTeam1: affiliationTeam1,
    affiliationTeam2: affiliationTeam2,
    homeScore: homeScore,
    outSideScore: outSideScore,
  );
}

void main() {
  group('scoreFromGoalHighlights', () {
    test('counts 3-2 from the Aug 2 match goal affiliations', () {
      final highlights = [
        _goal(affiliationTeam: '500554', minute: 38),
        _goal(affiliationTeam: '517642', minute: 42),
        _goal(affiliationTeam: '500554', minute: 62),
        _goal(affiliationTeam: '500554', minute: 75),
        _goal(affiliationTeam: '517642', minute: 82),
      ];

      final scores = scoreFromGoalHighlights(_match(), highlights);
      expect(scores.homeScore, 3);
      expect(scores.outsideScore, 2);
    });

    test('ignores substitutions and unknown affiliations', () {
      final highlights = [
        _goal(affiliationTeam: '500554', minute: 10),
        Highlights(
          matchCalendarId: 'm1',
          teamId: 't1',
          minute: 20,
          actionType: ActionType.substitution,
          value: Substitution(
            affiliationTeam: '500554',
            enteringPlayerId: 'a',
            outgoingPlayerId: 'b',
          ),
        ),
        _goal(affiliationTeam: 'unknown', minute: 30),
        _goal(affiliationTeam: '517642', minute: 40),
      ];

      final scores = scoreFromGoalHighlights(_match(), highlights);
      expect(scores.homeScore, 1);
      expect(scores.outsideScore, 1);
    });

    test('returns 0-0 when there are no goals', () {
      final scores = scoreFromGoalHighlights(_match(homeScore: 0, outSideScore: 1), const []);
      expect(scores.homeScore, 0);
      expect(scores.outsideScore, 0);
    });

    test('swaps sides when home affiliation is the other club', () {
      final highlights = [
        _goal(affiliationTeam: '500554', minute: 38),
        _goal(affiliationTeam: '517642', minute: 42),
      ];

      final scores = scoreFromGoalHighlights(
        _match(
          affiliationTeam1: '517642',
          affiliationTeam2: '500554',
        ),
        highlights,
      );
      expect(scores.homeScore, 1);
      expect(scores.outsideScore, 1);
    });
  });
}
