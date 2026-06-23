import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/social_auth_config.dart';

enum SocialAuthProvider { google, apple }

class SocialAuthCancelledException implements Exception {
  const SocialAuthCancelledException();
}

class SocialAuthService {
  SocialAuthService._();

  static final SocialAuthService instance = SocialAuthService._();

  static const List<String> _googleScopes = ['email', 'profile'];

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

  Future<UserCredential> signIn(SocialAuthProvider provider) {
    switch (provider) {
      case SocialAuthProvider.google:
        return _signInWithGoogle();
      case SocialAuthProvider.apple:
        return _signInWithApple();
    }
  }

  Future<UserCredential> _signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return FirebaseAuth.instance.signInWithPopup(provider);
    }

    await _ensureGoogleSignInInitialized();

    try {
      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: _googleScopes,
      );

      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
      );

      return FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialAuthCancelledException();
      }
      rethrow;
    }
  }

  Future<UserCredential> _signInWithApple() async {
    if (!kIsWeb && !Platform.isIOS && !Platform.isMacOS && !Platform.isAndroid) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Connexion Apple non disponible sur cette plateforme.',
      );
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
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

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);

    final displayName = [
      appleCredential.givenName,
      appleCredential.familyName,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

    if (displayName.isNotEmpty &&
        userCredential.user != null &&
        (userCredential.user!.displayName == null ||
            userCredential.user!.displayName!.isEmpty)) {
      await userCredential.user!.updateDisplayName(displayName);
    }

    return userCredential;
  }
}
