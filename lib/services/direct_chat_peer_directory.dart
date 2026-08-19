import 'package:flutter/foundation.dart';

import '../services/playerService.dart';
import '../services/userService.dart';
import '../util/direct_chat_identity.dart';

/// Grinta names/email for a Stream peer (Firebase Auth uid).
class DirectChatPeerProfile {
  const DirectChatPeerProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  const DirectChatPeerProfile.empty()
      : firstName = '',
        lastName = '',
        email = '';

  final String firstName;
  final String lastName;
  final String email;

  bool get hasName => composePersonName(
        firstName: firstName,
        lastName: lastName,
      ).isNotEmpty;
}

/// Caches `users/{uid}` (and member fallback) so the channel list can show
/// first + last name instead of a Stream email title.
class DirectChatPeerDirectory {
  DirectChatPeerDirectory({
    UserService? userService,
    PlayerService? playerService,
  })  : _userService = userService ?? UserService(),
        _playerService = playerService ?? PlayerService();

  static DirectChatPeerDirectory instance = DirectChatPeerDirectory();

  final UserService _userService;
  final PlayerService _playerService;
  final Map<String, DirectChatPeerProfile> _cache = {};
  final Map<String, Future<DirectChatPeerProfile>> _inflight = {};

  @visibleForTesting
  static void resetInstanceForTest([DirectChatPeerDirectory? directory]) {
    instance = directory ?? DirectChatPeerDirectory();
  }

  DirectChatPeerProfile? cached(String uid) {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return null;
    return _cache[trimmed];
  }

  Future<DirectChatPeerProfile> load(String uid) {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) {
      return Future.value(const DirectChatPeerProfile.empty());
    }

    final cachedProfile = _cache[trimmed];
    if (cachedProfile != null) return Future.value(cachedProfile);

    return _inflight.putIfAbsent(trimmed, () async {
      try {
        final profile = await _fetch(trimmed);
        _cache[trimmed] = profile;
        return profile;
      } finally {
        _inflight.remove(trimmed);
      }
    });
  }

  Future<DirectChatPeerProfile> _fetch(String uid) async {
    try {
      final user = await _userService.getById(uid);
      if (user != null) {
        var firstName = user.firstName.trim();
        var lastName = user.lastName.trim();
        var email = user.email.trim();
        if (firstName.isEmpty && lastName.isEmpty) {
          final fromMember = await _fromFirstNamedMember(uid);
          firstName = fromMember.firstName;
          lastName = fromMember.lastName;
          if (email.isEmpty) email = fromMember.email;
        }
        return DirectChatPeerProfile(
          firstName: firstName,
          lastName: lastName,
          email: email,
        );
      }
    } catch (e, st) {
      debugPrint('DirectChatPeerDirectory users/$uid: $e\n$st');
    }

    return _fromFirstNamedMember(uid);
  }

  Future<DirectChatPeerProfile> _fromFirstNamedMember(String uid) async {
    try {
      final members = await _playerService.getPlayersByUserId(uid);
      for (final member in members) {
        final firstName = member.firstName?.trim() ?? '';
        final lastName = member.lastName?.trim() ?? '';
        if (firstName.isEmpty && lastName.isEmpty) continue;
        return DirectChatPeerProfile(
          firstName: firstName,
          lastName: lastName,
          email: member.email?.trim() ?? '',
        );
      }
    } catch (e, st) {
      debugPrint('DirectChatPeerDirectory members for $uid: $e\n$st');
    }
    return const DirectChatPeerProfile.empty();
  }
}
