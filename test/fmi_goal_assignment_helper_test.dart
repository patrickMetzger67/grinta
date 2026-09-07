import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/util/match_goal_helper.dart';

models.Match _match({
  String? id = 'match-1',
  String team1 = 'ERSTEIN AS',
  String team2 = 'NORDHOUSE US',
  String? affiliationTeam1 = 'aff-erstein',
  String? affiliationTeam2 = 'aff-nordhouse',
  List<String>? teams,
  String? teamID,
  bool? isOwnClub = true,
}) {
  return models.Match(
    id: id,
    team1: team1,
    team2: team2,
    affiliationTeam1: affiliationTeam1,
    affiliationTeam2: affiliationTeam2,
    teams: teams ?? const ['team-erstein'],
    teamID: teamID ?? 'team-erstein',
    isOwnClub: isOwnClub,
  );
}

void main() {
  group('isFmiGoal / isFmiGoalHighlight', () {
    test('accepts goal, but, and penalty aliases', () {
      expect(isFmiGoal(MatchStatHighLight(type: 'goal')), isTrue);
      expect(isFmiGoal(MatchStatHighLight(type: 'But')), isTrue);
      expect(isFmiGoal(MatchStatHighLight(type: 'penalty')), isTrue);
      expect(isFmiGoal(MatchStatHighLight(type: 'PENALTY')), isTrue);
      expect(isFmiGoalHighlight(MatchStatHighLight(type: 'goal')), isTrue);
    });

    test('rejects own goals and non-goal events', () {
      expect(isFmiGoal(MatchStatHighLight(type: 'own_goal')), isFalse);
      expect(isFmiGoal(MatchStatHighLight(type: 'owngoal')), isFalse);
      expect(isFmiGoal(MatchStatHighLight(type: 'carton_jaune')), isFalse);
      expect(isFmiGoal(MatchStatHighLight(type: 'changement')), isFalse);
      expect(isFmiGoal(MatchStatHighLight(type: '')), isFalse);
    });
  });

  group('goalTypeFromFmiHighlight', () {
    test('maps penalty and defaults to normal', () {
      expect(
        goalTypeFromFmiHighlight(MatchStatHighLight(type: 'penalty')),
        GoalType.penalty,
      );
      expect(
        goalTypeFromFmiHighlight(MatchStatHighLight(type: 'goal')),
        GoalType.normal,
      );
      expect(
        goalTypeFromFmiHighlight(MatchStatHighLight(type: 'but')),
        GoalType.normal,
      );
    });
  });

  group('sideForFmiHighlightTeam / isManagedTeamFmiGoal', () {
    test('matches highlight.team to team1 / team2 names', () {
      final match = _match();

      expect(
        sideForFmiHighlightTeam(
          match,
          MatchStatHighLight(type: 'goal', team: 'ERSTEIN AS'),
        ),
        MatchSide.team1,
      );
      expect(
        sideForFmiHighlightTeam(
          match,
          MatchStatHighLight(type: 'goal', team: 'Nordhouse US'),
        ),
        MatchSide.team2,
      );
      expect(
        sideForFmiHighlightTeam(
          match,
          MatchStatHighLight(type: 'goal', team: 'Unknown FC'),
        ),
        isNull,
      );
    });

    test('is true only for managed-side FMI goals', () {
      final match = _match(isOwnClub: true);
      const managed = ['team-erstein'];

      expect(
        isManagedTeamFmiGoal(
          match,
          MatchStatHighLight(type: 'goal', team: 'ERSTEIN AS'),
          managed,
        ),
        isTrue,
      );
      expect(
        isManagedTeamFmiGoal(
          match,
          MatchStatHighLight(type: 'penalty', team: 'ERSTEIN AS'),
          managed,
        ),
        isTrue,
      );
      expect(
        isManagedTeamFmiGoal(
          match,
          MatchStatHighLight(type: 'goal', team: 'NORDHOUSE US'),
          managed,
        ),
        isFalse,
      );
      expect(
        isManagedTeamFmiGoal(
          match,
          MatchStatHighLight(type: 'own_goal', team: 'ERSTEIN AS'),
          managed,
        ),
        isFalse,
      );
      expect(
        isManagedTeamFmiGoal(
          match,
          MatchStatHighLight(type: 'carton_jaune', team: 'ERSTEIN AS'),
          managed,
        ),
        isFalse,
      );
    });

    test('uses isOwnClub when only one team id is linked (away)', () {
      final match = _match(
        isOwnClub: false,
        teams: const ['team-erstein'],
        teamID: 'team-erstein',
      );
      const managed = ['team-erstein'];

      expect(
        isManagedTeamFmiGoal(
          match,
          MatchStatHighLight(type: 'but', team: 'NORDHOUSE US'),
          managed,
        ),
        isTrue,
      );
      expect(
        isManagedTeamFmiGoal(
          match,
          MatchStatHighLight(type: 'but', team: 'ERSTEIN AS'),
          managed,
        ),
        isFalse,
      );
    });
  });
}
