import '../model/player.dart';

DateTime? playerBirthDate(Player player) {
  final raw = player.birthDay?.trim();
  if (raw == null || raw.isEmpty) return null;

  final parts = raw.split('/');
  if (parts.length != 3) return null;

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;

  try {
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

int? playerAgeYears(Player player) {
  final birthDate = playerBirthDate(player);
  if (birthDate == null) return null;

  final now = DateTime.now();
  var age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age;
}
