/// Builds the Firebase Auth / Stream Chat searchable display name.
class ResolvedAuthDisplayName {
  const ResolvedAuthDisplayName({
    required this.name,
    this.firstName = '',
    this.lastName = '',
    this.email,
  });

  /// Value stored as Auth `displayName` and Stream `extraData.name`.
  final String name;
  final String firstName;
  final String lastName;
  final String? email;
}

String composeAuthDisplayName({
  String? firstName,
  String? lastName,
}) {
  final first = firstName?.trim() ?? '';
  final last = lastName?.trim() ?? '';
  return '$first $last'.trim();
}

bool looksLikeEmailDisplayName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return false;
  return trimmed.contains('@');
}

bool isUsablePersonDisplayName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return false;
  if (looksLikeEmailDisplayName(trimmed)) return false;
  final lower = trimmed.toLowerCase();
  return lower != 'utilisateur' && lower != 'player';
}

/// Write [next] onto Auth when it is a real person name and better than [current].
bool shouldWriteAuthDisplayName(String? current, String next) {
  if (!isUsablePersonDisplayName(next)) return false;
  final trimmedCurrent = current?.trim() ?? '';
  if (trimmedCurrent.isEmpty) return true;
  if (looksLikeEmailDisplayName(trimmedCurrent)) return true;
  if (!isUsablePersonDisplayName(trimmedCurrent)) return true;
  return trimmedCurrent != next.trim();
}

String? firstNonEmptyName(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

/// Prefer the Grinta member / `users` names so Stream search matches "2", not
/// only the Auth email or the Google/Apple display name.
ResolvedAuthDisplayName resolveAuthDisplayName({
  String? memberFirstName,
  String? memberLastName,
  String? accountFirstName,
  String? accountLastName,
  String? authDisplayName,
  String? email,
  String fallbackName = 'Utilisateur',
}) {
  final memberName = composeAuthDisplayName(
    firstName: memberFirstName,
    lastName: memberLastName,
  );
  final accountName = composeAuthDisplayName(
    firstName: accountFirstName,
    lastName: accountLastName,
  );

  late final String firstName;
  late final String lastName;
  if (memberName.isNotEmpty) {
    firstName = memberFirstName?.trim() ?? '';
    lastName = memberLastName?.trim() ?? '';
  } else if (accountName.isNotEmpty) {
    firstName = accountFirstName?.trim() ?? '';
    lastName = accountLastName?.trim() ?? '';
  } else {
    firstName = '';
    lastName = '';
  }

  final composed = composeAuthDisplayName(
    firstName: firstName,
    lastName: lastName,
  );
  late final String name;
  if (composed.isNotEmpty) {
    name = composed;
  } else if (isUsablePersonDisplayName(authDisplayName)) {
    name = authDisplayName!.trim();
  } else {
    final mail = email?.trim() ?? '';
    name = mail.isNotEmpty ? mail : fallbackName;
  }

  final resolvedEmail = firstNonEmptyName([email]);
  return ResolvedAuthDisplayName(
    name: name,
    firstName: firstName,
    lastName: lastName,
    email: resolvedEmail,
  );
}
