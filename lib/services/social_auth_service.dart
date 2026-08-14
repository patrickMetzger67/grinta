import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/social_auth_config.dart';
import 'apple_identity_store.dart';

enum SocialAuthProvider { google, apple }

class SocialAuthCancelledException implements Exception {
  const SocialAuthCancelledException();
}

/// Firebase credential plus identity Apple/Google already supplied.
class SocialAuthResult {
  const SocialAuthResult({
    required this.credential,
    this.givenName,
    this.familyName,
    this.email,
    this.displayName,
  });

  final UserCredential credential;
  final String? givenName;
  final String? familyName;
  final String? email;
  final String? displayName;
}

class SocialAuthService {
  SocialAuthService._({AppleIdentityStore? appleIdentityStore})
      : _appleIdentityStore = appleIdentityStore ?? AppleIdentityStore();

  static final SocialAuthService instance = SocialAuthService._();

  static const List<String> _googleScopes = ['email', 'profile'];

  final AppleIdentityStore _appleIdentityStore;
  bool _googleInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleInitialized) {
      return;
    }

    final webClientId = SocialAuthConfig.webGoogleClientId;
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? webClientId : null,
      serverClientId: !kIsWeb && Platform.isAndroid ? webClientId : null,
    );
    _googleInitialized = true;
  }

  Future<SocialAuthResult> signIn(SocialAuthProvider provider) {
    switch (provider) {
      case SocialAuthProvider.google:
        return _signInWithGoogle();
      case SocialAuthProvider.apple:
        return _signInWithApple();
    }
  }

  Future<SocialAuthResult> _signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final credential = await FirebaseAuth.instance.signInWithPopup(provider);
      return SocialAuthResult(
        credential: credential,
        email: _nonEmpty(credential.user?.email),
        displayName: _nonEmpty(credential.user?.displayName),
      );
    }

    await _ensureGoogleSignInInitialized();

    try {
      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: _googleScopes,
      );

      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      return SocialAuthResult(
        credential: userCredential,
        email: _nonEmpty(googleUser.email) ??
            _nonEmpty(userCredential.user?.email),
        displayName: _nonEmpty(googleUser.displayName) ??
            _nonEmpty(userCredential.user?.displayName),
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialAuthCancelledException();
      }
      rethrow;
    }
  }

  Future<SocialAuthResult> _signInWithApple() async {
    if (!kIsWeb && !Platform.isIOS && !Platform.isMacOS && !Platform.isAndroid) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Connexion Apple non disponible sur cette plateforme.',
      );
    }

    final AuthorizationCredentialAppleID appleCredential;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: kIsWeb
            ? WebAuthenticationOptions(
                clientId: SocialAuthConfig.bundleId,
                redirectUri: Uri.parse(
                  'https://${SocialAuthConfig.firebaseProjectId}.firebaseapp.com/__/auth/handler',
                ),
              )
            : null,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const SocialAuthCancelledException();
      }
      rethrow;
    }

    final incoming = AppleIdentityRecord(
      givenName: appleCredential.givenName,
      familyName: appleCredential.familyName,
      email: appleCredential.email,
    );
    final identity = await _appleIdentityStore.save(
      userIdentifier: appleCredential.userIdentifier,
      incoming: incoming,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);

    final firebaseNames = _namesFromAdditionalUserInfo(
      userCredential.additionalUserInfo,
    );
    final givenName = _nonEmpty(identity.givenName) ?? firebaseNames.$1;
    final familyName = _nonEmpty(identity.familyName) ?? firebaseNames.$2;
    final displayName = [
      givenName,
      familyName,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

    final user = userCredential.user;
    if (displayName.isNotEmpty &&
        user != null &&
        (user.displayName == null || user.displayName!.trim().isEmpty)) {
      try {
        await user.updateDisplayName(displayName);
        await user.reload();
      } catch (e) {
        debugPrint('social auth: failed to persist Apple displayName: $e');
      }
    }

    final resolvedUser = FirebaseAuth.instance.currentUser ?? user;
    final email = _nonEmpty(identity.email) ??
        _nonEmpty(resolvedUser?.email) ??
        _nonEmpty(user?.email);

    debugPrint(
      'social auth: apple identity given=${givenName != null} '
      'family=${familyName != null} email=${email != null}',
    );

    return SocialAuthResult(
      credential: userCredential,
      givenName: givenName,
      familyName: familyName,
      email: email,
      displayName: displayName.isNotEmpty
          ? displayName
          : _nonEmpty(resolvedUser?.displayName),
    );
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

(String? givenName, String? familyName) _namesFromAdditionalUserInfo(
  AdditionalUserInfo? info,
) {
  final profile = info?.profile;
  if (profile == null || profile.isEmpty) return (null, null);

  String? read(dynamic value) {
    if (value is String) return _nonEmpty(value);
    return null;
  }

  final nestedName = profile['name'];
  if (nestedName is Map) {
    return (
      read(nestedName['firstName']) ?? read(nestedName['givenName']),
      read(nestedName['lastName']) ?? read(nestedName['familyName']),
    );
  }

  return (
    read(profile['given_name']) ??
        read(profile['givenName']) ??
        read(profile['firstName']),
    read(profile['family_name']) ??
        read(profile['familyName']) ??
        read(profile['lastName']),
  );
}
