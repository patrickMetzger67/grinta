/// Case variants used for Firestore prefix / array-contains lookups.
///
/// Firestore string comparisons are case-sensitive; legacy member documents may
/// store uppercase names or search tokens (e.g. `ETIENNE`).
Iterable<String> searchTokenCaseVariants(String token) sync* {
  final trimmed = token.trim();
  if (trimmed.isEmpty) {
    return;
  }

  final variants = <String>{
    trimmed,
    trimmed.toLowerCase(),
    trimmed.toUpperCase(),
  };

  if (trimmed.length == 1) {
    yield* variants;
    return;
  }

  final lower = trimmed.toLowerCase();
  variants.add('${lower[0].toUpperCase()}${lower.substring(1)}');

  yield* variants;
}

List<String> generateSearchOptions(String? value) {
  final searchOptions = <String>[];
  if (value == null || value.trim().isEmpty) {
    return searchOptions;
  }

  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty);

  for (final part in parts) {
    for (var y = 1; y < part.length; y++) {
      searchOptions.add(part.substring(0, y).toLowerCase());
    }
    searchOptions.add(part.toLowerCase());
  }

  return searchOptions;
}

/// Builds Firestore `searchOptions` tokens for member lookup.
///
/// Includes lowercase prefixes for [firstName], [lastName], and [email]
/// (full address + local-part before `@`) so coaches can search by any of them.
List<String> buildPlayerSearchOptions({
  required String firstName,
  required String lastName,
  String email = '',
}) {
  final options = <String>{
    ...generateSearchOptions(firstName),
    ...generateSearchOptions(lastName),
  };

  final trimmedEmail = email.trim().toLowerCase();
  if (trimmedEmail.isNotEmpty) {
    options.addAll(generateSearchOptions(trimmedEmail));
    final atIndex = trimmedEmail.indexOf('@');
    if (atIndex > 0) {
      options.addAll(generateSearchOptions(trimmedEmail.substring(0, atIndex)));
    }
  }

  return options.toList(growable: false);
}
