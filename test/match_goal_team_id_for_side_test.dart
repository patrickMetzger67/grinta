import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/match_goal_helper.dart';

void main() {
  const ersteinClubId = 'club-erstein';
  const holtzClubId = 'club-holtz';

  final clubIdByTeamId = clubIdByTeamIdFromTeams([
    Team(keyTeam: 'team-erstein', clubId: ersteinClubId),
    Team(keyTeam: 'team-holtz', clubId: holtzClubId),
  ]);

  group('clubIdByTeamIdFromTeams', () {
    test('maps keyTeam to clubId', () {
      expect(clubIdByTeamId['team-erstein'], ersteinClubId);
      expect(clubIdByTeamId['team-holtz'], holtzClubId);
    });
  });

  group('teamIdForSide via Team.clubId', () {
    test('home: linked id with clubId matching affiliationTeam1', () {
      final match = Match(
        id: 'm1',
        team1: 'A.S. ERSTEIN',
        team2: 'RACING HOLTZWIR',
        teams: const ['team-erstein'],
        teamID: 'team-erstein',
        affiliationTeam1: ersteinClubId,
        affiliationTeam2: holtzClubId,
        // isOwnClub must be ignored — deliberately wrong here.
        isOwnClub: false,
      );

      expect(
        teamIdForSide(match, MatchSide.team1, clubIdByTeamId: clubIdByTeamId),
        'team-erstein',
      );
      expect(
        teamIdForSide(match, MatchSide.team2, clubIdByTeamId: clubIdByTeamId),
        isNull,
      );
      expect(
        isManagedSide(
          match,
          MatchSide.team1,
          ['team-erstein'],
          clubIdByTeamId: clubIdByTeamId,
        ),
        isTrue,
      );
      expect(
        isManagedSide(
          match,
          MatchSide.team2,
          ['team-erstein'],
          clubIdByTeamId: clubIdByTeamId,
        ),
        isFalse,
      );
    });

    test(
      'away: linked id with clubId matching affiliationTeam2 — '
      'opponent must not get our roster',
      () {
        // Erstein away at Racing Holtzwhir: teams[] holds only Erstein.
        final match = Match(
          id: 'm2',
          team1: 'RACING HOLTZWIR',
          team2: 'A.S. ERSTEIN',
          teams: const ['team-erstein'],
          teamID: 'team-erstein',
          affiliationTeam1: holtzClubId,
          affiliationTeam2: ersteinClubId,
          isOwnClub: true, // wrong on purpose — must not drive placement
        );

        expect(
          teamIdForSide(match, MatchSide.team1, clubIdByTeamId: clubIdByTeamId),
          isNull,
        );
        expect(
          teamIdForSide(match, MatchSide.team2, clubIdByTeamId: clubIdByTeamId),
          'team-erstein',
        );
        expect(
          isManagedSide(
            match,
            MatchSide.team1,
            ['team-erstein'],
            clubIdByTeamId: clubIdByTeamId,
          ),
          isFalse,
        );
        expect(
          isManagedSide(
            match,
            MatchSide.team2,
            ['team-erstein'],
            clubIdByTeamId: clubIdByTeamId,
          ),
          isTrue,
        );
      },
    );

    test('places via match.clubs when affiliations are empty', () {
      final match = Match(
        id: 'm3',
        team1: 'RACING HOLTZWIR',
        team2: 'A.S. ERSTEIN',
        teams: const ['team-erstein'],
        clubs: const [holtzClubId, ersteinClubId],
      );

      expect(
        teamIdForSide(match, MatchSide.team1, clubIdByTeamId: clubIdByTeamId),
        isNull,
      );
      expect(
        teamIdForSide(match, MatchSide.team2, clubIdByTeamId: clubIdByTeamId),
        'team-erstein',
      );
    });

    test('without clubId map, does not use isOwnClub for single linked id', () {
      final away = Match(
        id: 'm4',
        team1: 'RACING HOLTZWIR',
        team2: 'A.S. ERSTEIN',
        teams: const ['team-erstein'],
        isOwnClub: false,
      );

      expect(teamIdForSide(away, MatchSide.team1), isNull);
      expect(teamIdForSide(away, MatchSide.team2), isNull);
    });

    test('two linked ids without clubIds still use home/away array index', () {
      final match = Match(
        id: 'm5',
        team1: 'Home FC',
        team2: 'Away FC',
        teams: const ['team-home', 'team-away'],
        teamID: 'team-away',
        isOwnClub: false,
      );

      expect(teamIdForSide(match, MatchSide.team1), 'team-home');
      expect(teamIdForSide(match, MatchSide.team2), 'team-away');
    });

    test('two linked ids prefer clubId over array index', () {
      final match = Match(
        id: 'm6',
        team1: 'RACING HOLTZWIR',
        team2: 'A.S. ERSTEIN',
        // Deliberately reversed vs home/away order.
        teams: const ['team-erstein', 'team-holtz'],
        affiliationTeam1: holtzClubId,
        affiliationTeam2: ersteinClubId,
      );

      expect(
        teamIdForSide(match, MatchSide.team1, clubIdByTeamId: clubIdByTeamId),
        'team-holtz',
      );
      expect(
        teamIdForSide(match, MatchSide.team2, clubIdByTeamId: clubIdByTeamId),
        'team-erstein',
      );
    });
  });
}
