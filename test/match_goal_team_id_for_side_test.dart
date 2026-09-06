import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/util/match_goal_helper.dart';

void main() {
  group('teamIdForSide', () {
    test('home: single linked id maps to team1 only', () {
      final match = Match(
        id: 'm1',
        team1: 'A.S. ERSTEIN',
        team2: 'RACING HOLTZWIR',
        teams: const ['team-erstein'],
        teamID: 'team-erstein',
        isOwnClub: true,
      );

      expect(teamIdForSide(match, MatchSide.team1), 'team-erstein');
      expect(teamIdForSide(match, MatchSide.team2), isNull);
      expect(isManagedSide(match, MatchSide.team1, ['team-erstein']), isTrue);
      expect(isManagedSide(match, MatchSide.team2, ['team-erstein']), isFalse);
    });

    test(
      'away: single linked id maps to team2 — opponent must not get our roster',
      () {
        // Erstein away at Racing Holtzwhir: teams[] holds only Erstein.
        final match = Match(
          id: 'm2',
          team1: 'RACING HOLTZWIR',
          team2: 'A.S. ERSTEIN',
          teams: const ['team-erstein'],
          teamID: 'team-erstein',
          isOwnClub: false,
        );

        expect(teamIdForSide(match, MatchSide.team1), isNull);
        expect(teamIdForSide(match, MatchSide.team2), 'team-erstein');
        expect(
          isManagedSide(match, MatchSide.team1, ['team-erstein']),
          isFalse,
        );
        expect(
          isManagedSide(match, MatchSide.team2, ['team-erstein']),
          isTrue,
        );
      },
    );

    test(
      'away without match.teamID: still places linked id on team2 via isOwnClub',
      () {
        final match = Match(
          id: 'm3',
          team1: 'RACING HOLTZWIR',
          team2: 'A.S. ERSTEIN',
          teams: const ['team-erstein'],
          isOwnClub: false,
        );

        expect(teamIdForSide(match, MatchSide.team1), isNull);
        expect(teamIdForSide(match, MatchSide.team2), 'team-erstein');
      },
    );

    test('two linked ids still use home/away array index', () {
      final match = Match(
        id: 'm4',
        team1: 'Home FC',
        team2: 'Away FC',
        teams: const ['team-home', 'team-away'],
        teamID: 'team-away',
        isOwnClub: false,
      );

      expect(teamIdForSide(match, MatchSide.team1), 'team-home');
      expect(teamIdForSide(match, MatchSide.team2), 'team-away');
    });

    test('falls back to match.teamID when teams is empty', () {
      final home = Match(
        id: 'm5',
        teamID: 'team-erstein',
        isOwnClub: true,
      );
      final away = Match(
        id: 'm6',
        teamID: 'team-erstein',
        isOwnClub: false,
      );

      expect(teamIdForSide(home, MatchSide.team1), 'team-erstein');
      expect(teamIdForSide(home, MatchSide.team2), isNull);
      expect(teamIdForSide(away, MatchSide.team1), isNull);
      expect(teamIdForSide(away, MatchSide.team2), 'team-erstein');
    });
  });
}
