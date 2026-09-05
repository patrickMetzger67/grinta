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

    test(
      '56174440: 500554 opens Analyse for Erstein, 504006 opens Adversaires',
      () {
        final match = _match56174440();
        final erstein = Team(
          keyTeam: 'LXLDol20qmaJzeAoh4Ha',
          clubId: '500554',
          name: 'ERSTEIN A.S 2',
        );

        expect(
          destinationForMatchSide(
            match: match,
            team: erstein,
            side: MatchSide.team1,
            ownClubId: '500554',
          ),
          MatchTeamStatsDestination.opponents,
        );
        expect(
          destinationForMatchSide(
            match: match,
            team: erstein,
            side: MatchSide.team2,
            ownClubId: '500554',
          ),
          MatchTeamStatsDestination.analysis,
        );
      },
    );
  });

  group('resolveTeamForMatchStats', () {
    test(
      '56174440 prefers the session team of club 500554 over home teamID',
      () {
        final match = _match56174440();
        final erstein = Team(
          keyTeam: 'LXLDol20qmaJzeAoh4Ha',
          clubId: '500554',
          name: 'ERSTEIN A.S 2',
        );
        final rosheim = Team(
          keyTeam: 'vvh0lhAstYbgZFeCTrsN',
          clubId: '504006',
          name: 'ROSHEIM F.C',
        );

        expect(
          resolveTeamForMatchStats(
            candidates: [rosheim, erstein],
            match: match,
            preferClubId: '500554',
          )?.keyTeam,
          'LXLDol20qmaJzeAoh4Ha',
        );
        expect(
          resolveTeamForMatchStats(
            candidates: [rosheim, erstein],
            match: match,
            preferClubId: '500554',
          )?.clubId,
          '500554',
        );
      },
    );

    test(
      '56174440 uses the agenda team of club 500554 when teamID is absent from session',
      () {
        final match = _match56174440();
        final erstein = Team(
          keyTeam: 'other-erstein-id',
          clubId: '500554',
          name: 'ERSTEIN A.S 2',
        );

        expect(
          resolveTeamForMatchStats(
            candidates: [erstein],
            match: match,
          )?.keyTeam,
          'other-erstein-id',
        );
        expect(
          ownClubIdOnMatch(candidates: [erstein], match: match),
          '500554',
        );
      },
    );

    test(
      '56174440 does not return the 504006 team when 500554 is in session',
      () {
        final match = Match(
          id: '56174440',
          team1: 'ROSHEIM F.C',
          team2: 'ERSTEIN A.S 2',
          affiliationTeam1: '504006',
          affiliationTeam2: '500554',
          clubs: const ['504006', '500554'],
          teamID: 'vvh0lhAstYbgZFeCTrsN',
          teams: const ['vvh0lhAstYbgZFeCTrsN', 'LXLDol20qmaJzeAoh4Ha'],
          isOwnClub: false,
        );
        final erstein = Team(
          keyTeam: 'LXLDol20qmaJzeAoh4Ha',
          clubId: '500554',
        );
        final rosheim = Team(
          keyTeam: 'vvh0lhAstYbgZFeCTrsN',
          clubId: '504006',
        );

        expect(
          resolveTeamForMatchStats(
            candidates: [rosheim, erstein],
            match: match,
            preferClubId: '500554',
          )?.clubId,
          '500554',
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

Match _match56174440() {
  return Match(
    id: '56174440',
    team1: 'ROSHEIM F.C',
    team2: 'ERSTEIN A.S 2',
    affiliationTeam1: '504006',
    affiliationTeam2: '500554',
    clubs: const ['504006', '500554'],
    competitionID: '450652',
    poule: '3',
    stage: '1',
    teamID: 'LXLDol20qmaJzeAoh4Ha',
    teams: const ['vvh0lhAstYbgZFeCTrsN', 'LXLDol20qmaJzeAoh4Ha'],
    isOwnClub: false,
    url:
        'https://alsace.fff.fr/competitions?competition_id=450652&poule=1&match_id=56174440',
    whereIsPlayed: '504006',
  );
}
