import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';

void main() {
  group('UserProfile admin list label', () {
    const uid = 'mQ208H8YnfWK5IQCJg3nAls2';
    const noEmail = 'Sans email';

    UserProfile user({
      String firstName = '',
      String lastName = '',
      String email = '',
    }) {
      return UserProfile(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
    }

    test('prefers person name over email', () {
      final profile = user(
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@example.com',
      );
      expect(profile.adminListLabel(noEmailLabel: noEmail), 'Ada Lovelace');
      expect(profile.adminEmailSubtitle, 'ada@example.com');
      expect(profile.displayName, 'Ada Lovelace');
    });

    test('falls back to email when there is no name', () {
      final profile = user(email: 'ghost@example.com');
      expect(profile.adminListLabel(noEmailLabel: noEmail), 'ghost@example.com');
      expect(profile.adminEmailSubtitle, isNull);
      expect(profile.displayName, 'ghost@example.com');
    });

    test('never uses the raw uid as the title', () {
      final empty = user();
      expect(empty.adminListLabel(noEmailLabel: noEmail), noEmail);
      expect(empty.displayName, isEmpty);
      expect(empty.adminEmailSubtitle, isNull);
      expect(empty.initials, '?');

      final uidAsName = user(firstName: uid, email: 'real@example.com');
      expect(
        uidAsName.adminListLabel(noEmailLabel: noEmail),
        'real@example.com',
      );
      expect(uidAsName.displayName, isNot(uid));

      final uidAsEmail = user(email: uid);
      expect(uidAsEmail.adminListLabel(noEmailLabel: noEmail), noEmail);
      expect(uidAsEmail.usableEmail, isEmpty);
    });
  });

  group('adminPlayerListLabel', () {
    const noEmail = 'Sans email';

    test('uses the player email when there is no name and no linked user', () {
      final player = Player(
        firstName: '',
        lastName: '',
        email: 'roster@example.com',
        keyMember: 'p-orphan',
        userID: '',
        users: const <dynamic>[],
      );
      expect(collectMemberLinkedUserIds(player), isEmpty);
      expect(
        adminPlayerListLabel(player, noEmailLabel: noEmail),
        'roster@example.com',
      );
    });

    test('keeps the person name when present', () {
      final player = Player(
        firstName: 'Hugo',
        lastName: 'Danguel',
        email: 'hugo@example.com',
      );
      expect(
        adminPlayerListLabel(player, noEmailLabel: noEmail),
        'Hugo Danguel',
      );
    });

    test('uses the localized fallback when name and email are missing', () {
      final player = Player(firstName: '', lastName: '', email: '');
      expect(adminPlayerListLabel(player, noEmailLabel: noEmail), noEmail);
    });
  });
}
