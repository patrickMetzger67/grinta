import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';

void main() {
  group('UserProfile admin list label', () {
    const uid = 'mQ208H8YnfWK5IQCJg3nAls2';
    const noName = 'Sans nom';

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

    test('title is person name and email stays on the subtitle', () {
      final profile = user(
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@example.com',
      );
      expect(profile.adminListLabel(noNameLabel: noName), 'Ada Lovelace');
      expect(profile.adminEmailSubtitle, 'ada@example.com');
      expect(profile.displayName, 'Ada Lovelace');
      expect(profile.isListedInAdminUsers, isTrue);
    });

    test('never uses email as the title when there is no name', () {
      final profile = user(email: 'ghost@example.com');
      expect(profile.adminListLabel(noNameLabel: noName), noName);
      expect(profile.adminEmailSubtitle, 'ghost@example.com');
      expect(profile.displayName, 'ghost@example.com');
      expect(profile.isListedInAdminUsers, isTrue);
    });

    test('never hides a named account as anonymous', () {
      expect(
        user(firstName: 'Mohamed-Amine', lastName: 'ABDESSAMAD')
            .isAnonymousAccount,
        isFalse,
      );
      expect(
        user(email: 'ghost@example.com').isAnonymousAccount,
        isFalse,
      );
      expect(
        user(firstName: 'Ada', lastName: 'Lovelace').isAnonymousAccount,
        isFalse,
      );
      expect(
        const UserProfile(
          uid: uid,
          firstName: 'Mohamed-Amine',
          lastName: 'ABDESSAMAD',
          email: '',
          isAnonymous: true,
        ).isAnonymousAccount,
        isFalse,
      );
    });

    test('treats isAnonymous and anonymous providerIds as anonymous', () {
      expect(
        const UserProfile(
          uid: uid,
          firstName: '',
          lastName: '',
          email: '',
          isAnonymous: true,
        ).isAnonymousAccount,
        isTrue,
      );
      expect(
        const UserProfile(
          uid: uid,
          firstName: '',
          lastName: '',
          email: 'ghost@example.com',
          providerIds: ['password', 'anonymous'],
        ).isAnonymousAccount,
        isTrue,
      );
      expect(
        const UserProfile(
          uid: uid,
          firstName: 'Ada',
          lastName: '',
          email: 'ada@example.com',
          providerIds: ['google.com'],
        ).isAnonymousAccount,
        isFalse,
      );
      expect(user().isAnonymousAccount, isFalse);
      expect(user().isListedInAdminUsers, isFalse);
      expect(user(email: 'ghost@example.com').isListedInAdminUsers, isTrue);
    });

    test('detects Google, Apple and password from providerIds', () {
      expect(
        const UserProfile(
          uid: uid,
          firstName: '',
          lastName: '',
          email: 'ghost@example.com',
          providerIds: ['google.com'],
        ).signedInWithGoogle,
        isTrue,
      );
      expect(
        const UserProfile(
          uid: uid,
          firstName: '',
          lastName: '',
          email: 'ghost@example.com',
          providerIds: ['apple.com'],
        ).signedInWithApple,
        isTrue,
      );
      expect(
        const UserProfile(
          uid: uid,
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: 'ada@example.com',
          providerIds: ['password'],
        ).signedInWithPassword,
        isTrue,
      );
      expect(
        const UserProfile(
          uid: uid,
          firstName: '',
          lastName: '',
          email: 'ghost@example.com',
          providerIds: ['google.com', 'password'],
        ).signedInWithGoogle,
        isTrue,
      );
      expect(user(email: 'ghost@example.com').signedInWithGoogle, isFalse);
      expect(user(email: 'ghost@example.com').signedInWithApple, isFalse);
    });

    test('readUserProviderIds uses fields already on the user document', () {
      expect(
        readUserProviderIds({
          UserDocumentFields.providerIds: ['google.com'],
        }),
        ['google.com'],
      );
      expect(
        readUserProviderIds({'signInProvider': 'apple.com'}),
        ['apple.com'],
      );
      expect(
        readUserProviderIds({'providerId': 'password'}),
        ['password'],
      );
      expect(
        readUserProviderIds({
          'providers': [
            {'providerId': 'google.com', 'email': 'ada@example.com'},
          ],
        }),
        ['google.com'],
      );
      expect(
        readUserProviderIds({
          'providers': {'apple.com': true, 'password': true},
        }),
        ['apple.com', 'password'],
      );
      expect(
        readUserProviderIds({
          UserDocumentFields.providerIds: ['Google.com'],
          'signInProvider': 'google.com',
        }),
        ['Google.com'],
      );
    });

    test('matches firstName, lastName, displayName and email', () {
      final profile = user(
        firstName: 'Mohamed-Amine',
        lastName: 'ABDESSAMAD',
        email: 'mohamed@example.com',
      );
      expect(profile.matchesSearch('Mohamed'), isTrue);
      expect(profile.matchesSearch('abdess'), isTrue);
      expect(profile.matchesSearch('mohamed-amine abdessamad'), isTrue);
      expect(profile.matchesSearch('mohamed@example.com'), isTrue);
      expect(profile.matchesSearch('zzz-no-match'), isFalse);
    });

    test('never uses the raw uid or email as the title', () {
      final empty = user();
      expect(empty.adminListLabel(noNameLabel: noName), noName);
      expect(empty.displayName, isEmpty);
      expect(empty.adminEmailSubtitle, isNull);
      expect(empty.initials, '?');
      expect(empty.isListedInAdminUsers, isFalse);

      final uidAsName = user(firstName: uid, email: 'real@example.com');
      expect(uidAsName.adminListLabel(noNameLabel: noName), noName);
      expect(uidAsName.adminEmailSubtitle, 'real@example.com');
      expect(uidAsName.displayName, isNot(uid));

      final uidAsEmail = user(email: uid);
      expect(uidAsEmail.adminListLabel(noNameLabel: noName), noName);
      expect(uidAsEmail.usableEmail, isEmpty);
      expect(uidAsEmail.isListedInAdminUsers, isFalse);
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
