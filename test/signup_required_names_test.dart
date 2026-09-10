import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/util/auth_profile_seed.dart';
import 'package:grinta/util/player_profile_validator.dart';

void main() {
  group('hasRequiredGivenNames', () {
    test('requires both first and last after trim', () {
      expect(hasRequiredGivenNames('Ada', 'Lovelace'), isTrue);
      expect(hasRequiredGivenNames(' Ada ', ' Lovelace '), isTrue);
      expect(hasRequiredGivenNames('', 'Lovelace'), isFalse);
      expect(hasRequiredGivenNames('Ada', ''), isFalse);
      expect(hasRequiredGivenNames('  ', '  '), isFalse);
      expect(hasRequiredGivenNames(null, 'Lovelace'), isFalse);
      expect(hasRequiredGivenNames('Ada', null), isFalse);
    });
  });

  group('shouldLockAuthIdentityField', () {
    test('locks only non-empty fields when identity is from Auth', () {
      expect(
        shouldLockAuthIdentityField(
          lockIdentityFromAuth: true,
          value: 'Ada',
        ),
        isTrue,
      );
      expect(
        shouldLockAuthIdentityField(
          lockIdentityFromAuth: true,
          value: '  ',
        ),
        isFalse,
      );
      expect(
        shouldLockAuthIdentityField(
          lockIdentityFromAuth: true,
          value: null,
        ),
        isFalse,
      );
      expect(
        shouldLockAuthIdentityField(
          lockIdentityFromAuth: false,
          value: 'Ada',
        ),
        isFalse,
      );
    });
  });

  group('social and invitation name completion', () {
    test('email-only Apple seed keeps empty names so the form can require them',
        () {
      final seed = profileSeedFromAuthIdentity(
        email: 'a@privaterelay.appleid.com',
      );
      expect(seed, isNotNull);
      expect(hasRequiredGivenNames(seed!.firstName, seed.lastName), isFalse);
      expect(
        shouldLockAuthIdentityField(
          lockIdentityFromAuth: true,
          value: seed.firstName,
        ),
        isFalse,
      );
      expect(
        shouldLockAuthIdentityField(
          lockIdentityFromAuth: true,
          value: seed.lastName,
        ),
        isFalse,
      );
    });

    test('invitation member without names still requires first and last', () {
      final member = Player(
        firstName: '',
        lastName: '',
        email: 'invite@club.test',
      );
      final merged = mergeAuthIdentityOntoMemberProfile(
        member: member,
        authSeed: profileSeedFromAuthIdentity(
          email: 'a@privaterelay.appleid.com',
        ),
      );
      expect(hasRequiredGivenNames(merged.firstName, merged.lastName), isFalse);
      expect(
        shouldLockAuthIdentityField(
          lockIdentityFromAuth: true,
          value: merged.firstName,
        ),
        isFalse,
      );
    });

    test('IdP name is prefilled and locked; missing last name stays required',
        () {
      final seed = profileSeedFromAuthIdentity(givenName: 'Ada');
      expect(seed!.firstName, 'Ada');
      expect(seed.lastName, '');
      expect(
        shouldLockAuthIdentityField(
          lockIdentityFromAuth: true,
          value: seed.firstName,
        ),
        isTrue,
      );
      expect(
        shouldLockAuthIdentityField(
          lockIdentityFromAuth: true,
          value: seed.lastName,
        ),
        isFalse,
      );
    });

    test('signup without applyFallbacks never invents Player placeholders', () {
      final seed = profileSeedFromAuthIdentity();
      expect(seed, isNull);
    });
  });
}
