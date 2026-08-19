/// Identity shown on a 1:1 Messagerie row: person name, then email.
class DirectChatIdentity {
  const DirectChatIdentity({
    required this.title,
    this.email,
  });

  /// First name + last name, or a non-email Stream name, or the email.
  final String title;

  /// Email shown under [title]. Null when missing or identical to [title].
  final String? email;
}

/// Team / group channels have a Stream [channelName] (e.g. "myTeam 1") or
/// more than one other member. Direct messages have neither.
bool isDirectMessageChannel({
  required int? memberCount,
  required String? channelName,
  required int otherMemberCount,
}) {
  final trimmedName = channelName?.trim() ?? '';
  if (trimmedName.isNotEmpty) return false;
  if ((memberCount ?? 0) > 2) return false;
  if (otherMemberCount > 1) return false;
  return otherMemberCount == 1 || memberCount == 2;
}

String composePersonName({
  String? firstName,
  String? lastName,
}) {
  final first = firstName?.trim() ?? '';
  final last = lastName?.trim() ?? '';
  return '$first $last'.trim();
}

bool looksLikeEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return false;
  return trimmed.contains('@');
}

String? firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

/// Prefers Grinta profile names over a Stream `name` that is often the email.
DirectChatIdentity resolveDirectChatIdentity({
  String? firstName,
  String? lastName,
  String? email,
  String? streamName,
  String fallbackTitle = 'Utilisateur',
}) {
  final composed = composePersonName(firstName: firstName, lastName: lastName);
  final mail = firstNonEmpty([email]);
  final name = streamName?.trim() ?? '';

  late final String title;
  if (composed.isNotEmpty) {
    title = composed;
  } else if (name.isNotEmpty && !looksLikeEmail(name)) {
    title = name;
  } else if (mail != null) {
    title = mail;
  } else if (name.isNotEmpty) {
    title = name;
  } else {
    title = fallbackTitle;
  }

  String? subtitleEmail = mail;
  if (subtitleEmail == null && looksLikeEmail(name)) {
    subtitleEmail = name;
  }
  if (subtitleEmail != null &&
      title.toLowerCase() == subtitleEmail.toLowerCase()) {
    subtitleEmail = null;
  }

  return DirectChatIdentity(title: title, email: subtitleEmail);
}

/// Overlay a Grinta `users` / member profile onto the Stream identity.
DirectChatIdentity mergeDirectChatIdentity({
  required DirectChatIdentity streamIdentity,
  String? profileFirstName,
  String? profileLastName,
  String? profileEmail,
}) {
  final hasProfileName = composePersonName(
        firstName: profileFirstName,
        lastName: profileLastName,
      ).isNotEmpty;
  if (!hasProfileName && firstNonEmpty([profileEmail]) == null) {
    return streamIdentity;
  }

  return resolveDirectChatIdentity(
    firstName: firstNonEmpty([profileFirstName]),
    lastName: firstNonEmpty([profileLastName]),
    email: firstNonEmpty([profileEmail, streamIdentity.email]),
    streamName: streamIdentity.title,
  );
}
