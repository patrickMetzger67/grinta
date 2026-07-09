import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/player.dart';
import '../model/team.dart';
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

/// Identifiant membre stable pour les maps session (keyMember ou id document).
String? effectiveMemberId(Player player) {
  final fromField = player.keyMember?.trim();
  if (fromField != null && fromField.isNotEmpty) {
    return fromField;
  }

  final docId = player.ref?.id.trim();
  if (docId != null && docId.isNotEmpty) {
    return docId;
  }

  return null;
}

/// Candidate member ids for roster / team membership lookups.
///
/// [effectiveMemberId] ([keyMember] or Firestore doc id) is canonical; linked
/// [Player.userID] is included only to match legacy roster data.
Set<String> playerMemberLookupIds(Player player) {
  final Set<String> ids = <String>{};

  void add(String? raw) {
    final String trimmed = raw?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      ids.add(trimmed);
    }
  }

  add(effectiveMemberId(player));
  add(player.keyMember);
  add(player.ref?.id);
  add(player.userID);
  return ids;
}

/// Firebase Auth user ids linked to [player] ([Player.userID] and [users]).
Set<String> playerFirebaseUserIds(Player player) {
  final Set<String> ids = <String>{};

  void add(String? raw) {
    final String trimmed = raw?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      ids.add(trimmed);
    }
  }

  add(player.userID);
  for (final dynamic raw in player.users ?? const <dynamic>[]) {
    add(raw?.toString());
  }
  return ids;
}

/// True when [team.grintaPlayers] references any [playerMemberLookupIds] entry.
bool teamContainsGrintaMemberForPlayer(Team team, Player player) {
  for (final String id in playerMemberLookupIds(player)) {
    if (teamContainsGrintaMember(team, id)) {
      return true;
    }
  }
  return false;
}

/// Assure [player.keyMember] non vide quand l'id document est connu.
void normalizePlayerMemberId(Player player) {
  final effectiveId = effectiveMemberId(player);
  if (effectiveId == null) return;
  if (player.keyMember?.trim().isNotEmpty ?? false) return;
  player.keyMember = effectiveId;
}

/// UID Auth le plus à jour ([FirebaseAuth.currentUser] toujours prioritaire).
String? liveAuthUid({User? sessionUser}) {
  final User? current = FirebaseAuth.instance.currentUser;
  final String? currentUid = current?.uid.trim();
  if (currentUid != null && currentUid.isNotEmpty) {
    return currentUid;
  }

  final String? sessionUid = sessionUser?.uid.trim();
  if (sessionUid != null && sessionUid.isNotEmpty) {
    return sessionUid;
  }
  return null;
}

/// photoURL Auth live : [FirebaseAuth.currentUser] d'abord, puis snapshot session.
String? liveAuthPhotoUrl({User? sessionUser}) {
  final String? authUid = liveAuthUid(sessionUser: sessionUser);
  if (authUid == null || authUid.isEmpty) return null;

  final User? current = FirebaseAuth.instance.currentUser;
  if (current != null && current.uid.trim() == authUid) {
    final currentPhoto = _readAuthPhotoUrl(current);
    if (currentPhoto != null) return currentPhoto;
  }

  if (sessionUser != null && sessionUser.uid.trim() == authUid) {
    final sessionPhoto = _readAuthPhotoUrl(sessionUser);
    if (sessionPhoto != null) return sessionPhoto;
  }

  return null;
}

/// URLs à afficher : photo Auth live en tête si lié, puis override, puis session.
List<String> buildDisplayAvatarUrls({
  required Player player,
  List<String>? sessionUrls,
  List<String>? overrideUrls,
  User? authUser,
}) {
  final urls = <String>[];

  void add(String? source) {
    if (source == null) return;
    final trimmed = source.trim();
    if (trimmed.isEmpty) return;
    if (!urls.contains(trimmed)) {
      urls.add(trimmed);
    }
  }

  final User? resolvedAuthUser =
      FirebaseAuth.instance.currentUser ?? authUser;
  final authUid = liveAuthUid(sessionUser: resolvedAuthUser) ?? '';
  if (authUid.isNotEmpty && isPlayerLinkedToAuthUser(player, authUid)) {
    add(liveAuthPhotoUrl(sessionUser: resolvedAuthUser));
  }

  for (final url in overrideUrls ?? const <String>[]) {
    add(url);
  }
  for (final url in sessionUrls ?? const <String>[]) {
    add(url);
  }

  if (kDebugMode && urls.isEmpty) {
    debugPrint(
      'buildDisplayAvatarUrls empty player=${effectiveMemberId(player)} '
      'linked=${authUid.isNotEmpty && isPlayerLinkedToAuthUser(player, authUid)} '
      'sessionUrls=$sessionUrls overrideUrls=$overrideUrls '
      'authPhoto=${liveAuthPhotoUrl(sessionUser: authUser)}',
    );
  }

  if (urls.isEmpty) return urls;

  final authUrls = urls
      .where(UserAvatarService.isExternalAuthPhotoUrl)
      .toList(growable: false);
  if (authUrls.isEmpty) return urls;

  final defaults = urls
      .where((url) => !UserAvatarService.isExternalAuthPhotoUrl(url))
      .toList(growable: false);
  return [...authUrls, ...defaults];
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

  if (entry is DocumentReference) {
    final pathUid = entry.path.split('/').last.trim();
    return pathUid.isNotEmpty ? pathUid : null;
  }

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

/// True when [player] belongs to the logged-in user (explicit link or session map).
bool isAuthUsersSessionPlayer(
  Player player,
  String authUid, {
  Map<String, Player>? sessionPlayers,
}) {
  if (authUid.isEmpty) return false;
  if (isPlayerLinkedToAuthUser(player, authUid)) return true;

  final memberId = effectiveMemberId(player);
  if (memberId == null || memberId.isEmpty) return false;
  return sessionPlayers?[memberId] != null;
}

/// All Firebase Auth uids linked to [player] via [Player.userID] and [Player.users].
///
/// Normalizes, trims, deduplicates, and drops empty values.
Set<String> collectMemberLinkedUserIds(Player player) {
  final ids = <String>{};
  final memberId = effectiveMemberId(player);

  void addUid(String? uid) {
    if (uid == null || uid.isEmpty) return;
    if (memberId != null && uid == memberId) return;
    ids.add(uid);
  }

  addUid(_normalizeLinkedUserId(player.userID));

  final users = player.users;
  if (users != null) {
    for (final entry in users) {
      addUid(_normalizeLinkedUserId(entry));
    }
  }

  return ids;
}

/// True when [player] has at least one linked app account ([Player.userID] or
/// [Player.users]).
bool isMemberLinkedToAppAccount(Player player) {
  return collectMemberLinkedUserIds(player).isNotEmpty;
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

/// Ensures Google profile photo URLs request a displayable thumbnail size.
String normalizeAuthPhotoDisplayUrl(String url, {int size = 96}) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  final host = Uri.tryParse(trimmed)?.host ?? '';
  if (!host.contains('googleusercontent.com')) return trimmed;

  if (RegExp(r'[-=]s\d+').hasMatch(trimmed)) return trimmed;
  return '$trimmed=s$size-c';
}

String? _readAuthPhotoUrl(User? user) => readAuthUserPhotoUrl(user);

/// Auth profile photo: [User.photoURL] then OAuth [UserInfo.photoURL].
String? readAuthUserPhotoUrl(User? user) {
  final direct = user?.photoURL?.trim();
  if (direct != null && direct.isNotEmpty) {
    return normalizeAuthPhotoDisplayUrl(direct);
  }

  for (final info in user?.providerData ?? const <UserInfo>[]) {
    final providerPhoto = info.photoURL?.trim();
    if (providerPhoto != null && providerPhoto.isNotEmpty) {
      return normalizeAuthPhotoDisplayUrl(providerPhoto);
    }
  }
  return null;
}

/// True when [player] should use the live Firebase Auth profile photo.
bool shouldUseDirectAuthPhoto(
  Player player,
  String authUid, {
  Map<String, Player>? sessionPlayers,
}) {
  if (authUid.isEmpty) return false;

  final current = FirebaseAuth.instance.currentUser;
  if (current == null || current.uid.trim() != authUid) return false;

  return isAuthUsersSessionPlayer(
    player,
    authUid,
    sessionPlayers: sessionPlayers,
  );
}

Future<String?> _currentAuthPhotoUrl(User? user) async {
  if (user == null) return null;

  final direct = liveAuthPhotoUrl(sessionUser: user);
  if (direct != null) return direct;

  try {
    await user.reload().timeout(_kAuthPhotoReloadTimeout);
    return liveAuthPhotoUrl(
      sessionUser: FirebaseAuth.instance.currentUser ?? user,
    );
  } catch (_) {}

  return null;
}

/// ImageProvider réseau (web : img HTML via [NetworkImage] + widget dédié).
ImageProvider playerPhotoImageProvider(String url) {
  return NetworkImage(url);
}
