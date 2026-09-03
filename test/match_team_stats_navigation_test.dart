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

    test(
      'affiliation identifies own club even when isOwnClub/teams[] are inverted',
      () {
        // Home match: ERSTEIN vs RACING. FFF import stored only our id at
        // index 0 but left isOwnClub=false (defaults to away). Affiliation
        // under the logo is the source of truth.
        final match = Match(
          id: 'm4',
          team1: 'ERSTEIN AS',
          team2: 'RACING HW 96',
          teamID: 'team-erstein',
          isOwnClub: false,
          teams: const ['team-erstein'],
          affiliationTeam1: '500554',
          affiliationTeam2: '546491',
        );
        final team = Team(keyTeam: 'team-erstein', clubId: '500554');

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
      },
    );

    test(
      'away affiliation still opens analysis for the users club logo',
      () {
        final match = Match(
          id: 'm5',
          team1: 'RACING HW 96',
          team2: 'ERSTEIN AS',
          teamID: 'team-erstein',
          isOwnClub: true,
          teams: const ['team-erstein'],
          affiliationTeam1: '546491',
          affiliationTeam2: '500554',
        );
        final team = Team(keyTeam: 'team-erstein', clubId: '500554');

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
      },
    );
  });

  group('isUsersClubMatchSide', () {
    test('prefers the affiliation printed under the logo', () {
      final match = Match(
        id: 'm6',
        team1: 'ERSTEIN AS',
        team2: 'RACING HW 96',
        teamID: 'team-erstein',
        isOwnClub: false,
        teams: const ['team-erstein'],
        affiliationTeam1: '500554',
        affiliationTeam2: '546491',
      );
      final team = Team(keyTeam: 'team-erstein', clubId: '500554');

      expect(
        isUsersClubMatchSide(
          match: match,
          team: team,
          side: MatchSide.team1,
        ),
        isTrue,
      );
      expect(
        isUsersClubMatchSide(
          match: match,
          team: team,
          side: MatchSide.team2,
        ),
        isFalse,
      );
    });
  });
}
