import '../model/player.dart';
import '../model/team.dart' show removeDiacritics;

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

/// Normalizes a player-name query (trim, case, accents) for contains-matching.
String normalizePlayerNameQuery(String? value) {
  return removeDiacritics((value ?? '').trim().toLowerCase());
}

/// Whether [player] matches a "Filtrer par nom" query.
///
/// Compares first/last/display names after lowercasing and stripping accents
/// so mobile keyboards (autocorrect, no-accent input) still hit the roster.
bool playerMatchesNameQuery(Player player, String query) {
  final String normalizedQuery = normalizePlayerNameQuery(query);
  if (normalizedQuery.isEmpty) return true;

  final List<String> candidates = <String>[
    playerDisplayName(player, unknownLabel: ''),
    formatPlayerShortName(player, unknownLabel: ''),
    player.firstName ?? '',
    player.lastName ?? '',
    '${player.firstName ?? ''} ${player.lastName ?? ''}',
    '${player.lastName ?? ''} ${player.firstName ?? ''}',
  ];
  for (final String candidate in candidates) {
    if (normalizePlayerNameQuery(candidate).contains(normalizedQuery)) {
      return true;
    }
  }
  return false;
}