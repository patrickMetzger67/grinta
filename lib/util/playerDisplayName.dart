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

String playerSearchDigits(String? value) {
  return (value ?? '').replaceAll(RegExp(r'\D'), '');
}

/// Tokens for member / roster search (trim, lowercase, accents stripped).
List<String> playerSearchQueryTokens(String query) {
  return normalizePlayerNameQuery(query)
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}

/// Whether a roster / convocation display [label] matches a name filter.
///
/// Same normalization as [playerMatchesNameQuery] (trim, case, accents).
/// An empty query matches everyone. Multi-word queries require every token
/// (first / last name) to appear in the label, in any order.
bool playerLabelMatchesNameQuery(String label, String query) {
  final String normalizedQuery = normalizePlayerNameQuery(query);
  if (normalizedQuery.isEmpty) {
    return true;
  }

  final String normalizedLabel = normalizePlayerNameQuery(label);
  if (normalizedLabel.contains(normalizedQuery)) {
    return true;
  }

  final List<String> tokens = playerSearchQueryTokens(query);
  if (tokens.isEmpty) {
    return true;
  }
  return tokens.every(normalizedLabel.contains);
}

/// Whether [player] matches a "Filtrer par nom" / "Ajouter un joueur" query.
///
/// Compares first/last/display/short names, e-mail, `searchOptions` and phone
/// digits after lowercasing and stripping accents so mobile keyboards
/// (autocorrect, Raëd/Jérou, no-accent input) still hit the member.
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
    player.email ?? '',
    for (final dynamic option in player.searchOptions ?? const <dynamic>[])
      option.toString(),
  ];
  for (final String candidate in candidates) {
    if (normalizePlayerNameQuery(candidate).contains(normalizedQuery)) {
      return true;
    }
  }

  final String queryDigits = playerSearchDigits(query);
  if (queryDigits.length >= 6) {
    final String phoneDigits = playerSearchDigits(player.phoneE164);
    if (phoneDigits.isNotEmpty &&
        (phoneDigits.contains(queryDigits) ||
            queryDigits.contains(phoneDigits))) {
      return true;
    }
  }
  return false;
}

/// True when every query token matches [player] (add-player sheet).
bool playerMatchesMemberSearchQuery(Player player, String query) {
  final List<String> tokens = playerSearchQueryTokens(query);
  if (tokens.isEmpty) return false;
  return tokens.every((token) => playerMatchesNameQuery(player, token));
}