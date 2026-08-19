import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../model/player.dart';
import '../util/auth_display_name.dart';

/// Persists the Grinta person name to Firebase Auth and Stream Chat.
class AuthDisplayNameSync {
  AuthDisplayNameSync._();

  static final AuthDisplayNameSync instance = AuthDisplayNameSync._();

  StreamChatClient? _client;

  void bindStreamClient(StreamChatClient? client) {
    _client = client;
  }

  /// Writes Auth `displayName` + Stream `name` / `firstName` / `lastName` / `email`.
  Future<void> persistFromProfile({
    required String firstName,
    required String lastName,
    String? email,
    String? photoUrl,
  }) async {
    final resolved = resolveAuthDisplayName(
      memberFirstName: firstName,
      memberLastName: lastName,
      email: email,
    );
    await persistResolved(resolved, photoUrl: photoUrl);
  }

  Future<void> persistFromMember(
    Player profile, {
    String? email,
    String? photoUrl,
  }) {
    return persistFromProfile(
      firstName: profile.firstName?.trim() ?? '',
      lastName: profile.lastName?.trim() ?? '',
      email: email ?? profile.email,
      photoUrl: photoUrl,
    );
  }

  Future<void> persistResolved(
    ResolvedAuthDisplayName resolved, {
    String? photoUrl,
  }) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (shouldWriteAuthDisplayName(user.displayName, resolved.name)) {
      try {
        await user.updateDisplayName(resolved.name);
        await user.reload();
      } catch (e, st) {
        debugPrint('AuthDisplayNameSync: updateDisplayName failed: $e\n$st');
      }
    }

    await syncStreamUser(
      uid: user.uid,
      resolved: resolved,
      photoUrl: photoUrl ?? user.photoURL,
    );
  }

  Future<void> syncStreamUser({
    required String uid,
    required ResolvedAuthDisplayName resolved,
    String? photoUrl,
  }) async {
    final client = _client;
    if (client == null || client.state.currentUser?.id != uid) return;

    try {
      await client.updateUser(
        User(
          id: uid,
          extraData: {
            'name': resolved.name,
            if (resolved.firstName.isNotEmpty) 'firstName': resolved.firstName,
            if (resolved.lastName.isNotEmpty) 'lastName': resolved.lastName,
            if (resolved.email != null) 'email': resolved.email,
            if (photoUrl != null && photoUrl.trim().isNotEmpty)
              'image': photoUrl.trim(),
          },
        ),
      );
    } catch (e, st) {
      debugPrint('AuthDisplayNameSync: Stream updateUser failed: $e\n$st');
    }
  }

  Map<String, Object?> streamExtraData({
    required ResolvedAuthDisplayName resolved,
    String? photoUrl,
  }) {
    return {
      'name': resolved.name,
      if (resolved.firstName.isNotEmpty) 'firstName': resolved.firstName,
      if (resolved.lastName.isNotEmpty) 'lastName': resolved.lastName,
      if (resolved.email != null) 'email': resolved.email!,
      if (photoUrl != null && photoUrl.trim().isNotEmpty) 'image': photoUrl.trim(),
    };
  }
}
