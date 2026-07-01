import '../model/player.dart';

/// Roster-style label: first initial + "." + uppercased last name (e.g. L.METZGER).
String formatPlayerShortName(Player player, {String unknownLabel = 'Joueur'}) {
  final firstName = (player.firstName ?? '').trim();
  final lastName = (player.lastName ?? '').trim();

  if (firstName.isNotEmpty && lastName.isNotEmpty) {
    return '${firstName[0].toUpperCase()}.${lastName.toUpperCase()}';
  }

  if (lastName.isNotEmpty) {
    return lastName.toUpperCase();
  }

  if (firstName.isNotEmpty) {
    return firstName;
  }

  return unknownLabel;
}

String playerDisplayName(Player player, {String unknownLabel = 'Joueur'}) {
  final firstName = (player.firstName ?? '').trim();
  final lastName = (player.lastName ?? '').trim();

  if (firstName.isNotEmpty && lastName.isNotEmpty) {
    return '$firstName $lastName';
  }

  if (firstName.isNotEmpty) {
    return firstName;
  }

  if (lastName.isNotEmpty) {
    return lastName;
  }

  return unknownLabel;
}