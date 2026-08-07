import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/util/account_age_gate.dart';

void main() {
  group('classifyAccountAge', () {
    test('blocks under 13', () {
      expect(classifyAccountAge(12), AccountAgeGateResult.blockedUnderage);
      expect(classifyAccountAge(0), AccountAgeGateResult.blockedUnderage);
    });

    test('requires parental consent for 13–14', () {
      expect(
        classifyAccountAge(13),
        AccountAgeGateResult.parentalConsentRequired,
      );
      expect(
        classifyAccountAge(14),
        AccountAgeGateResult.parentalConsentRequired,
      );
    });

    test('allows self-serve from 15', () {
      expect(classifyAccountAge(15), AccountAgeGateResult.selfServeAllowed);
      expect(classifyAccountAge(30), AccountAgeGateResult.selfServeAllowed);
    });

    test('requires birth date when age unknown', () {
      expect(classifyAccountAge(null), AccountAgeGateResult.birthDateRequired);
    });
  });

  group('ageYearsFromBirthDate', () {
    test('handles birthday not yet reached this year', () {
      final birth = DateTime(2012, 12, 31);
      final now = DateTime(2026, 8, 7);
      expect(ageYearsFromBirthDate(birth, now: now), 13);
    });

    test('handles birthday already passed', () {
      final birth = DateTime(2011, 1, 1);
      final now = DateTime(2026, 8, 7);
      expect(ageYearsFromBirthDate(birth, now: now), 15);
    });
  });

  group('classifyPlayerAccountAge', () {
    test('uses player birthDay string', () {
      final player = Player(birthDay: '01/01/2012');
      // Age depends on "today" — just ensure it doesn't crash / returns a gate.
      expect(
        classifyPlayerAccountAge(player),
        isNot(AccountAgeGateResult.birthDateRequired),
      );
    });
  });
}
