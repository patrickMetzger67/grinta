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

bool isProfileComplete(Player profile) {
  return (profile.firstName?.trim().isNotEmpty ?? false) &&
      (profile.lastName?.trim().isNotEmpty ?? false) &&
      (profile.nationality?.trim().isNotEmpty ?? false);
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
