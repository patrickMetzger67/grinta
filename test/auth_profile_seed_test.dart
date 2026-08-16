import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/apple_identity_store.dart';
import 'package:grinta/util/auth_profile_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('profileSeedFromAuthIdentity', () {
    test('splits Apple displayName and keeps email', () {
      final seed = profileSeedFromAuthIdentity(
        displayName: 'Christiano MBAPPE',
        email: 'relay@privaterelay.appleid.com',
      );
      expect(seed, isNotNull);
      expect(seed!.firstName, 'Christiano');
      expect(seed.lastName, 'MBAPPE');
      expect(seed.email, 'relay@privaterelay.appleid.com');
    });

    test('prefers Authentication Services givenName/familyName', () {
      final seed = profileSeedFromAuthIdentity(
        givenName: 'Jean',
        familyName: 'Dupont',
        displayName: 'Firebase leftover',
        email: 'jean@privaterelay.appleid.com',
      );
      expect(seed!.firstName, 'Jean');
      expect(seed.lastName, 'Dupont');
    });

    test('uses displayName remainder when only givenName is present', () {
      final seed = profileSeedFromAuthIdentity(
        givenName: 'Jean Pierre',
        displayName: 'Jean Pierre Dupont',
      );
      expect(seed!.firstName, 'Jean Pierre');
      expect(seed.lastName, 'Dupont');
    });

    test('returns null when Auth has no identity fields', () {
      expect(profileSeedFromAuthIdentity(), isNull);
      expect(profileSeedFromAuthIdentity(displayName: '  '), isNull);
    });

    test('keeps email-only seed for Hide My Email without name', () {
      final seed = profileSeedFromAuthIdentity(
        email: 'a@privaterelay.appleid.com',
      );
      expect(seed, isNotNull);
      expect(seed!.email, 'a@privaterelay.appleid.com');
      expect(seed.firstName, '');
      expect(seed.lastName, '');
    });

    test('applyFallbacks never leaves names empty after Apple auth', () {
      final seed = profileSeedFromAuthIdentity(
        email: 'n6vqs8x2k4@privaterelay.appleid.com',
        applyFallbacks: true,
      );
      expect(seed, isNotNull);
      expect(seed!.firstName, 'n6vqs8x2k4');
      expect(seed.lastName, 'n6vqs8x2k4');
      expect(seed.email, 'n6vqs8x2k4@privaterelay.appleid.com');
    });

    test('applyFallbacks uses Player when Apple sent nothing', () {
      final seed = profileSeedFromAuthIdentity(applyFallbacks: true);
      expect(seed, isNotNull);
      expect(seed!.firstName, 'Player');
      expect(seed.lastName, 'Player');
      expect(seed.email, isNull);
    });
  });

  group('mergeAppleIdentity', () {
    test('keeps cached name when a later Apple sign-in omits it', () {
      const cached = AppleIdentityRecord(
        givenName: 'Ada',
        familyName: 'Lovelace',
        email: 'ada@privaterelay.appleid.com',
      );
      final merged = mergeAppleIdentity(
        incoming: const AppleIdentityRecord(),
        cached: cached,
      );
      expect(merged.givenName, 'Ada');
      expect(merged.familyName, 'Lovelace');
      expect(merged.email, 'ada@privaterelay.appleid.com');
    });

    test('incoming non-empty fields win', () {
      const cached = AppleIdentityRecord(
        givenName: 'Old',
        familyName: 'Name',
        email: 'old@example.com',
      );
      final merged = mergeAppleIdentity(
        incoming: const AppleIdentityRecord(
          givenName: 'New',
          email: 'new@example.com',
        ),
        cached: cached,
      );
      expect(merged.givenName, 'New');
      expect(merged.familyName, 'Name');
      expect(merged.email, 'new@example.com');
    });
  });

  test('store keeps Apple name across a second authorization', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppleIdentityStore();
    await store.save(
      userIdentifier: 'user-1',
      incoming: const AppleIdentityRecord(
        givenName: 'Ada',
        familyName: 'Lovelace',
        email: 'ada@privaterelay.appleid.com',
      ),
    );
    final second = await store.save(
      userIdentifier: 'user-1',
      incoming: const AppleIdentityRecord(),
    );
    expect(second.givenName, 'Ada');
    expect(second.familyName, 'Lovelace');
    expect(second.email, 'ada@privaterelay.appleid.com');
  });
}
