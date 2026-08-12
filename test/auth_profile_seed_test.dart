import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/auth_profile_seed.dart';

void main() {
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
}
