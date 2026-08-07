import 'package:grinta/model/player.dart';
import 'package:grinta/util/player_age.dart';

/// Minimum age to use Grinta at all (COPPA / store policy floor).
const int kMinGrintaAgeYears = 13;

/// Minimum age to self-register without parental consent.
const int kSelfServeAccountAgeYears = 15;

enum AccountAgeGateResult {
  /// Age < 13 — must not create / must delete the account.
  blockedUnderage,

  /// Age 13–14 — parental consent required before app access.
  parentalConsentRequired,

  /// Age >= 15 — standard self-serve account.
  selfServeAllowed,

  /// Birth date missing or unparsable.
  birthDateRequired,
}

/// Classifies [ageYears] for signup / AuthGate.
AccountAgeGateResult classifyAccountAge(int? ageYears) {
  if (ageYears == null) return AccountAgeGateResult.birthDateRequired;
  if (ageYears < kMinGrintaAgeYears) {
    return AccountAgeGateResult.blockedUnderage;
  }
  if (ageYears < kSelfServeAccountAgeYears) {
    return AccountAgeGateResult.parentalConsentRequired;
  }
  return AccountAgeGateResult.selfServeAllowed;
}

AccountAgeGateResult classifyPlayerAccountAge(Player profile) {
  return classifyAccountAge(playerAgeYears(profile));
}

/// Age in full years from a calendar birth date.
int ageYearsFromBirthDate(DateTime birthDate, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  var age = clock.year - birthDate.year;
  if (clock.month < birthDate.month ||
      (clock.month == birthDate.month && clock.day < birthDate.day)) {
    age--;
  }
  return age;
}

/// Latest birth date allowed by the picker (exactly [kMinGrintaAgeYears] old).
DateTime maxBirthDateForMinAge({DateTime? now}) {
  final clock = now ?? DateTime.now();
  return DateTime(clock.year - kMinGrintaAgeYears, clock.month, clock.day);
}
