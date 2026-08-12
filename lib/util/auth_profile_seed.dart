import 'package:grinta/model/player.dart';

/// Builds a [Player] seed from Firebase Auth identity (Sign in with Apple /
/// Google) so the signup profile form does not re-ask for name/email.
Player? profileSeedFromAuthIdentity({
  String? displayName,
  String? email,
}) {
  final trimmedEmail = email?.trim();
  final name = displayName?.trim() ?? '';
  var firstName = '';
  var lastName = '';
  if (name.isNotEmpty) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      firstName = parts.first;
      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }
  }

  final hasEmail = trimmedEmail != null && trimmedEmail.isNotEmpty;
  if (firstName.isEmpty && lastName.isEmpty && !hasEmail) {
    return null;
  }

  return Player(
    firstName: firstName,
    lastName: lastName,
    email: hasEmail ? trimmedEmail : null,
  );
}
