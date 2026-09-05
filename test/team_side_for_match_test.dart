import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';

void main() {
  group('teamSideForMatch with single linked team id', () {
    test('home: only our id in teams → team1, opponent is away club', () {
      final match = Match(
        id: 'm1',
        team1: 'A.S. ERSTEIN',
        team2: 'F.C. ILLHAEUSERN',
        teams: const ['team-erstein'],
        teamID: 'team-erstein',
        isOwnClub: true,
      );

      expect(
        teamSideForMatch(match: match, teamId: 'team-erstein'),
        MatchSide.team1,
      );
      expect(
        opponentForMatch(match: match, teamId: 'team-erstein')?.displayName,
        'F.C. ILLHAEUSERN',
      );
    });

    test('away: only our id in teams → team2, opponent is home club', () {
      final match = Match(
        id: 'm2',
        team1: 'F.C. ILLHAEUSERN',
        team2: 'A.S. ERSTEIN',
        teams: const ['team-erstein'],
        teamID: 'team-erstein',
        isOwnClub: false,
      );

      expect(
        teamSideForMatch(match: match, teamId: 'team-erstein'),
        MatchSide.team2,
      );
      expect(
        opponentForMatch(match: match, teamId: 'team-erstein')?.displayName,
        'F.C. ILLHAEUSERN',
      );
    });

    test('two linked ids still use array index', () {
      final match = Match(
        id: 'm3',
        team1: 'Home FC',
        team2: 'Away FC',
        teams: const ['team-home', 'team-away'],
        teamID: 'team-away',
        isOwnClub: false,
      );

      expect(
        teamSideForMatch(match: match, teamId: 'team-away'),
        MatchSide.team2,
      );
      expect(
        opponentForMatch(match: match, teamId: 'team-away')?.displayName,
        'Home FC',
      );
    });

    test(
      '56174440: affiliation 500554 is away even if teamId is the home Grinta id',
      () {
        final match = Match(
          id: '56174440',
          team1: 'ROSHEIM F.C',
          team2: 'ERSTEIN A.S 2',
          affiliationTeam1: '504006',
          affiliationTeam2: '500554',
          clubs: const ['504006', '500554'],
          teams: const ['vvh0lhAstYbgZFeCTrsN', 'LXLDol20qmaJzeAoh4Ha'],
          teamID: 'LXLDol20qmaJzeAoh4Ha',
          isOwnClub: false,
        );

        expect(
          teamSideForMatch(
            match: match,
            teamId: 'vvh0lhAstYbgZFeCTrsN',
            clubId: '500554',
          ),
          MatchSide.team2,
        );
        expect(
          teamSideForMatch(
            match: match,
            teamId: 'LXLDol20qmaJzeAoh4Ha',
            clubId: '500554',
          ),
          MatchSide.team2,
        );
      },
    );
  });
}
