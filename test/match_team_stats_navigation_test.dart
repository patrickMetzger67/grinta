import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_team_stats_navigation.dart';

void main() {
  group('destinationForMatchSide', () {
    test('home own club opens analysis for team1 and opponents for team2', () {
      final match = Match(
        id: 'm1',
        team1: 'My Team',
        team2: 'Opponent',
        teamID: 'team-my',
        isOwnClub: true,
        teams: ['team-my'],
      );
      final team = Team(keyTeam: 'team-my', clubId: 'club-my');

      expect(
        destinationForMatchSide(
          match: match,
          team: team,
          side: MatchSide.team1,
        ),
        MatchTeamStatsDestination.analysis,
      );
      expect(
        destinationForMatchSide(
          match: match,
          team: team,
          side: MatchSide.team2,
        ),
        MatchTeamStatsDestination.opponents,
      );
    });

    test('away own club opens opponents for team1 and analysis for team2', () {
      final match = Match(
        id: 'm2',
        team1: 'Opponent',
        team2: 'My Team',
        teamID: 'team-my',
        isOwnClub: false,
        teams: ['team-my'],
      );
      final team = Team(keyTeam: 'team-my', clubId: 'club-my');

      expect(
        destinationForMatchSide(
          match: match,
          team: team,
          side: MatchSide.team1,
        ),
        MatchTeamStatsDestination.opponents,
      );
      expect(
        destinationForMatchSide(
          match: match,
          team: team,
          side: MatchSide.team2,
        ),
        MatchTeamStatsDestination.analysis,
      );
    });

    test('returns null when own side cannot be resolved', () {
      final match = Match(
        id: 'm3',
        team1: 'A',
        team2: 'B',
      );
      final team = Team(keyTeam: 'unknown', clubId: 'unknown');

      expect(
        destinationForMatchSide(
          match: match,
          team: team,
          side: MatchSide.team1,
        ),
        isNull,
      );
    });
  });
}
