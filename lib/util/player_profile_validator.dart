import '../model/player.dart';

final RegExp _emailPattern = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

final RegExp _e164Pattern = RegExp(r'^\+[1-9]\d{1,14}$');

bool isValidEmailFormat(String? email) {
  final trimmed = email?.trim();
  if (trimmed == null || trimmed.isEmpty) return true;
  return _emailPattern.hasMatch(trimmed);
}

bool isValidE164Phone(String? phoneE164) {
  final trimmed = phoneE164?.trim();
  if (trimmed == null || trimmed.isEmpty) return true;
  return _e164Pattern.hasMatch(trimmed);
}

/// First + last name required on every signup / invite completion path.
bool hasRequiredGivenNames(String? firstName, String? lastName) {
  return (firstName?.trim().isNotEmpty ?? false) &&
      (lastName?.trim().isNotEmpty ?? false);
}

bool isProfileComplete(Player profile) {
  return hasRequiredGivenNames(profile.firstName, profile.lastName) &&
      (profile.nationality?.trim().isNotEmpty ?? false) &&
      (profile.birthDay?.trim().isNotEmpty ?? false);
}

bool hasContactInfo(Player profile) {
  return (profile.email?.trim().isNotEmpty ?? false) ||
      (profile.phoneE164?.trim().isNotEmpty ?? false);
}

bool isProfileAndContactValid(Player profile) {
  return isProfileComplete(profile) &&
      hasContactInfo(profile) &&
      isValidEmailFormat(profile.email) &&
      isValidE164Phone(profile.phoneE164);
}
