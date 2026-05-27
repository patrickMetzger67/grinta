import '../model/player.dart';

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