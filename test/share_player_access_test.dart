import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/share_player_access.dart';

void main() {
  group('canSharePlayerCard', () {
    test('manager of the team can share any player', () {
      expect(
        canSharePlayerCard(
          managedTeamIds: const ['team-a'],
          teamId: 'team-a',
          viewerMemberIds: const {'coach-1'},
          viewedMemberIds: const {'player-9'},
        ),
        isTrue,
      );
    });

    test('explicit isManager can share without team id', () {
      expect(
        canSharePlayerCard(
          managedTeamIds: const [],
          viewerMemberIds: const {'coach-1'},
          viewedMemberIds: const {'player-9'},
          isManager: true,
        ),
        isTrue,
      );
    });

    test('non-manager can share only their own profile', () {
      expect(
        canSharePlayerCard(
          managedTeamIds: const ['team-a'],
          teamId: 'team-b',
          viewerMemberIds: const {'player-1', 'legacy-1'},
          viewedMemberIds: const {'legacy-1'},
        ),
        isTrue,
      );
      expect(
        canSharePlayerCard(
          managedTeamIds: const ['team-a'],
          teamId: 'team-b',
          viewerMemberIds: const {'player-1'},
          viewedMemberIds: const {'player-9'},
        ),
        isFalse,
      );
    });

    test('empty identities cannot share', () {
      expect(
        canSharePlayerCard(
          managedTeamIds: const [],
          viewerMemberIds: const {},
          viewedMemberIds: const {'player-1'},
        ),
        isFalse,
      );
    });
  });
}
