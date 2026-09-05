import 'package:grinta/model/team.dart' show removeDiacritics;

/// Lowercase + strip accents so `Raëd` / `Jérou` hit ASCII `searchOptions`.
String normalizeSearchToken(String token) {
  return removeDiacritics(token.trim().toLowerCase());
}

/// Case variants used for Firestore prefix / array-contains lookups.
///
/// Firestore string comparisons are case-sensitive; legacy member documents may
/// store uppercase names or search tokens (e.g. `ETIENNE`).
///
/// [token] should already be passed through [normalizeSearchToken] so accented
/// input (`Raëd`) still queries `raed` / `Raed`.
Iterable<String> searchTokenCaseVariants(String token) sync* {
  final trimmed = normalizeSearchToken(token);
  if (trimmed.isEmpty) {
    return;
  }

  final variants = <String>{
    trimmed,
    trimmed.toUpperCase(),
  };

  if (trimmed.length == 1) {
    yield* variants;
    return;
  }

  variants.add('${trimmed[0].toUpperCase()}${trimmed.substring(1)}');

  yield* variants;
}

/// E.164 values to probe on `member.phoneE164` for a typed phone query.
///
/// Covers `06…`, `+33…`, and the legacy `+3306…` form stored on some docs.
Iterable<String> phoneSearchE164Variants(String query) {
  final digits = query.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 6) {
    return const <String>[];
  }

  final variants = <String>{
    '+$digits',
    digits,
  };

  if (digits.startsWith('0')) {
    variants.add('+33${digits.substring(1)}');
    variants.add('+330${digits.substring(1)}');
  }
  if (digits.startsWith('33') && digits.length > 2) {
    variants.add('+33${digits.substring(2)}');
    variants.add('+330${digits.substring(2)}');
    variants.add('+$digits');
  }

  return variants;
}

List<String> generateSearchOptions(String? value) {
  final searchOptions = <String>{};
  if (value == null || value.trim().isEmpty) {
    return const <String>[];
  }

  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty);

  for (final part in parts) {
    for (final normalized in <String>{
      part.toLowerCase(),
      normalizeSearchToken(part),
    }) {
      if (normalized.isEmpty) continue;
      for (var y = 1; y < normalized.length; y++) {
        searchOptions.add(normalized.substring(0, y));
      }
      searchOptions.add(normalized);
    }
  }

  return searchOptions.toList(growable: false);
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
