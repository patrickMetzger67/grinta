import 'package:grinta/model/player.dart';

/// After Sign in with Apple / Google, prefer IdP name/email on an invitation
/// member profile so the signup form can lock those fields (Guideline 4).
Player mergeAuthIdentityOntoMemberProfile({
  required Player member,
  Player? authSeed,
}) {
  if (authSeed == null) return member;

  final seedFirst = authSeed.firstName?.trim() ?? '';
  final seedLast = authSeed.lastName?.trim() ?? '';
  final seedEmail = authSeed.email?.trim() ?? '';

  return member.copyWith(
    firstName: seedFirst.isNotEmpty ? seedFirst : member.firstName,
    lastName: seedLast.isNotEmpty ? seedLast : member.lastName,
    email: seedEmail.isNotEmpty ? seedEmail : member.email,
  );
}

/// Builds a [Player] seed from Sign in with Apple / Google identity so the
/// signup profile form does not re-ask for name/email (App Store Guideline 4).
///
/// Prefer [givenName] / [familyName] from Authentication Services over splitting
/// [displayName]. When [applyFallbacks] is true, missing names are filled from
/// email / a generic label so the user is never required to type them.
Player? profileSeedFromAuthIdentity({
  String? givenName,
  String? familyName,
  String? displayName,
  String? email,
  bool applyFallbacks = false,
}) {
  final trimmedEmail = email?.trim();
  final hasEmail = trimmedEmail != null && trimmedEmail.isNotEmpty;

  var firstName = givenName?.trim() ?? '';
  var lastName = familyName?.trim() ?? '';
  _fillNamesFromDisplayName(
    displayName: displayName,
    firstName: firstName,
    lastName: lastName,
    onResolved: (first, last) {
      firstName = first;
      lastName = last;
    },
  );

  if (applyFallbacks) {
    if (firstName.isEmpty && hasEmail) {
      firstName = emailLocalPartAsName(trimmedEmail!);
    }
    if (firstName.isEmpty) {
      firstName = 'Player';
    }
    if (lastName.isEmpty) {
      lastName = firstName;
    }
    return Player(
      firstName: firstName,
      lastName: lastName,
      email: hasEmail ? trimmedEmail : null,
    );
  }

  if (firstName.isEmpty && lastName.isEmpty && !hasEmail) {
    return null;
  }

  return Player(
    firstName: firstName,
    lastName: lastName,
    email: hasEmail ? trimmedEmail : null,
  );
}

/// Local-part of an email as a display name fallback (Hide My Email, etc.).
String emailLocalPartAsName(String email) {
  final trimmed = email.trim();
  final at = trimmed.indexOf('@');
  final local = at <= 0 ? trimmed : trimmed.substring(0, at);
  final cleaned = local.replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ').trim();
  if (cleaned.isEmpty) return 'Player';
  return cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).first;
}

void _fillNamesFromDisplayName({
  required String? displayName,
  required String firstName,
  required String lastName,
  required void Function(String firstName, String lastName) onResolved,
}) {
  final name = displayName?.trim() ?? '';
  if (name.isEmpty) {
    onResolved(firstName, lastName);
    return;
  }

  if (firstName.isEmpty && lastName.isEmpty) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      onResolved(firstName, lastName);
      return;
    }
    onResolved(
      parts.first,
      parts.length > 1 ? parts.sublist(1).join(' ') : '',
    );
    return;
  }

  if (lastName.isEmpty && firstName.isNotEmpty) {
    if (name.toLowerCase().startsWith(firstName.toLowerCase())) {
      onResolved(firstName, name.substring(firstName.length).trim());
      return;
    }
  }

  if (firstName.isEmpty && lastName.isNotEmpty) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      onResolved(parts.first, lastName);
      return;
    }
  }

  onResolved(firstName, lastName);
}
