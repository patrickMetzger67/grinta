import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/player.dart';
import '../services/user_avatar_service.dart';

const defaultPlayerAvatarFilename = 'portrait_1920x1920.jpg';

const memberPhotoSizeSuffix = '_1920x1920.JPG';

/// Nom de fichier Storage pour la photo membre (ex. METZGER-Louis-2007_1920x1920.JPG).
String buildMemberPhotoFilename({
  required String lastName,
  required String firstName,
  String? birthDay,
}) {
  final last = _photoNameSegment(lastName, uppercase: true);
  final first = _photoNameSegment(firstName, uppercase: false);
  if (last.isEmpty || first.isEmpty) {
    throw ArgumentError('lastName and firstName are required for photo filename');
  }

  final birthDate = Player.parseBirthDay(birthDay);
  final year = birthDate?.year.toString() ?? '0000';
  return '$last-$first-$year$memberPhotoSizeSuffix';
}

String _photoNameSegment(String value, {required bool uppercase}) {
  final trimmed = value.trim().replaceAll(RegExp(r'\s+'), '');
  if (trimmed.isEmpty) return '';

  if (uppercase) return trimmed.toUpperCase();
  if (trimmed.length == 1) return trimmed.toUpperCase();
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
}

/// Valeurs du champ [Player.photo] qui ne comptent pas comme photo réelle.
const _invalidPlayerPhotoValues = {'><'};
const Duration _kAuthPhotoReloadTimeout = Duration(seconds: 5);

/// Indique si le joueur a une photo propre (non vide, non placeholder).
bool hasPlayerPhoto(Player player) {
  final photo = player.photo?.trim() ?? '';
  return photo.isNotEmpty && !_invalidPlayerPhotoValues.contains(photo);
}

/// Chaîne d'URL à essayer à l'affichage (max 3) :
/// [0] photo joueur, [1] photo utilisateur lié (Auth), [2] portrait par défaut.
Future<List<String>> resolvePlayerAvatarUrls(
  Player player, {
  String defaultPhotoFileName = defaultPlayerAvatarFilename,
  User? authUser,
}) async {
  final urls = <String>[];

  if (hasPlayerPhoto(player)) {
    await _tryAddUrl(urls, player.photo!.trim());
  }

  final authPhoto = await _linkedAuthPhotoUrl(player, authUser: authUser);
  await _tryAddUrl(urls, authPhoto);

  final defaultUrl = await _defaultAvatarUrl(defaultPhotoFileName);
  if (defaultUrl.isNotEmpty && !urls.contains(defaultUrl)) {
    urls.add(defaultUrl);
  }

  if (kDebugMode) {
    final playerId = player.keyMember ?? '?';
    final authUid = authUser?.uid.trim() ?? '';
    debugPrint(
      'resolvePlayerAvatarUrls player=$playerId '
      'hasMemberPhoto=${hasPlayerPhoto(player)} '
      'memberPhoto=${player.photo?.trim() ?? ''} '
      'linked=${authUid.isNotEmpty && isPlayerLinkedToAuthUser(player, authUid)} '
      'authPhoto=${authPhoto ?? 'null'} urls=$urls',
    );
  }

  return urls;
}

Future<void> _tryAddUrl(List<String> urls, String? source) async {
  if (source == null || source.trim().isEmpty) return;
  try {
    final url = await _sourceToDownloadUrl(source.trim());
    if (url.isNotEmpty && !urls.contains(url)) {
      urls.add(url);
    }
  } catch (_) {}
}

Future<String> _sourceToDownloadUrl(String source) async {
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return source;
  }

  final ref = FirebaseStorage.instance.ref().child('thumbs/$source');
  return ref.getDownloadURL();
}

Future<String> _defaultAvatarUrl(String filename) async {
  try {
    return await _sourceToDownloadUrl(filename);
  } catch (_) {
    return '';
  }
}

String? _normalizeLinkedUserId(dynamic entry) {
  if (entry == null) return null;

  if (entry is String) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains('/')) {
      final segment = trimmed.split('/').last.trim();
      return segment.isNotEmpty ? segment : null;
    }
    return trimmed;
  }

  if (entry is Map) {
    for (final key in const ['uid', 'id', 'userId', 'userID']) {
      final value = entry[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return _normalizeLinkedUserId(value);
      }
    }
  }

  final asString = entry.toString().trim();
  if (asString.isEmpty) return null;
  if (asString.contains('/')) {
    final segment = asString.split('/').last.replaceAll(RegExp(r'[)\]]+$'), '').trim();
    return segment.isNotEmpty ? segment : null;
  }
  return asString;
}

/// Indique si [player] est lié au compte Firebase [authUid].
bool isPlayerLinkedToAuthUser(Player player, String authUid) {
  if (authUid.isEmpty) return false;

  final userId = _normalizeLinkedUserId(player.userID);
  if (userId != null && userId == authUid) {
    return true;
  }

  final users = player.users;
  if (users == null || users.isEmpty) return false;

  return users.any((entry) => _normalizeLinkedUserId(entry) == authUid);
}

/// UID utilisateur lié au joueur (champ [Player.userID] ou entrée [Player.users]).
String linkedUserIdForPlayer(Player player) {
  final userId = _normalizeLinkedUserId(player.userID) ?? '';
  if (userId.isNotEmpty) return userId;

  final users = player.users;
  if (users == null || users.isEmpty) return '';

  for (final entry in users) {
    final uid = _normalizeLinkedUserId(entry);
    if (uid != null && uid.isNotEmpty) return uid;
  }

  return '';
}

/// Photo utilisateur liée au joueur (Auth photoURL uniquement pour l'affichage).
Future<String?> resolveUserPhotoUrlForPlayer(
  Player player, {
  User? authUser,
}) {
  return _linkedAuthPhotoUrl(player, authUser: authUser);
}

/// Photo Auth du compte lié au joueur (Google/Apple/Meta), jamais le cache Storage Firestore.
Future<String?> _linkedAuthPhotoUrl(
  Player player, {
  User? authUser,
}) async {
  final initialAuthUser = authUser ?? FirebaseAuth.instance.currentUser;
  final authUid = initialAuthUser?.uid.trim();

  if (authUid == null ||
      authUid.isEmpty ||
      initialAuthUser == null ||
      !isPlayerLinkedToAuthUser(player, authUid)) {
    if (kDebugMode) {
      debugPrint(
        'linkedAuthPhotoUrl skipped player=${player.keyMember} '
        'authUid=$authUid linked=false',
      );
    }
    return null;
  }

  final liveUser = FirebaseAuth.instance.currentUser;
  final resolvedAuthUser =
      liveUser != null && liveUser.uid.trim() == authUid
          ? liveUser
          : initialAuthUser;

  final authPhoto = await _currentAuthPhotoUrl(resolvedAuthUser);
  if (authPhoto != null && authPhoto.isNotEmpty) {
    unawaited(
      UserAvatarService.instance.ensureCachedAuthPhoto(resolvedAuthUser),
    );
  }
  return authPhoto;
}

String? _readAuthPhotoUrl(User? user) {
  final photo = user?.photoURL?.trim();
  if (photo == null || photo.isEmpty) return null;
  return photo;
}

Future<String?> _currentAuthPhotoUrl(User? user) async {
  if (user == null) return null;

  final uid = user.uid.trim();
  final direct = _readAuthPhotoUrl(user);
  if (direct != null) return direct;

  // The passed [User] can be a stale authStateChanges snapshot; prefer live Auth.
  final liveUser = FirebaseAuth.instance.currentUser;
  if (liveUser != null && liveUser.uid.trim() == uid) {
    final livePhoto = _readAuthPhotoUrl(liveUser);
    if (livePhoto != null) return livePhoto;
  }

  // reload() can hang on web — late photoURL is handled by AppSession polling.
  if (kIsWeb) {
    return null;
  }

  try {
    await user.reload().timeout(_kAuthPhotoReloadTimeout);
    final reloaded = FirebaseAuth.instance.currentUser;
    if (reloaded != null && reloaded.uid.trim() == uid) {
      return _readAuthPhotoUrl(reloaded);
    }
  } catch (_) {}

  return null;
}

/// ImageProvider réseau (web : img HTML via [NetworkImage] + widget dédié).
ImageProvider playerPhotoImageProvider(String url) {
  return NetworkImage(url);
}
