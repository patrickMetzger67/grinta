import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../model/player.dart';
import '../util/member_unsubscribe.dart';
import '../util/player_photo_resolver.dart';
import '../util/search_options.dart';
import 'user_root_service.dart';

class PlayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'member';

  static final Map<String, List<String>> _avatarUrlCache = {};
  static final Map<String, Future<List<String>>> _avatarUrlPending = {};

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Ajouter un joueur
  Future<DocumentReference<Map<String, dynamic>>> addPlayer(Player player) async {
    return await _collection.add(player.toMap());
  }

  /// Crée un membre (player) sans invitation et lie l'utilisateur courant.
  Future<String> createMember({
    required String userId,
    required Player profile,
  }) async {
    final player = Player.forNewMember(userId: userId, profile: profile);
    return _persistNewMember(player);
  }

  /// Crée un membre sans compte utilisateur lié (ex. ajout à une équipe).
  Future<Player> createInvitedMember({
    required String creatorUserId,
    required Player profile,
  }) async {
    final player = Player.forInvitedMember(
      creatorUserId: creatorUserId,
      profile: profile,
    );
    final memberId = await _persistNewMember(player);
    final created = await getPlayerById(memberId);
    if (created == null) {
      throw StateError('Created member not found: $memberId');
    }
    return created;
  }

  Future<String> _persistNewMember(Player player) async {
    final docRef = await addPlayer(player);
    final playerId = docRef.id;

    await docRef.update({
      keyPlayerKeyMember: playerId,
    });

    return playerId;
  }

  /// Met à jour les champs de profil d'un membre existant.
  Future<void> updateMemberProfile({
    required String memberId,
    required Player profile,
  }) async {
    await updatePlayerFields(memberId, profile.toProfileUpdateMap());
  }

  /// Lie un compte Firebase à un membre invité (userID + users[]).
  Future<void> linkUserToMember({
    required String memberId,
    required String uid,
  }) async {
    final trimmedMemberId = memberId.trim();
    final trimmedUid = uid.trim();
    if (trimmedMemberId.isEmpty) {
      throw ArgumentError.value(memberId, 'memberId', 'must not be empty');
    }
    if (trimmedUid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'must not be empty');
    }

    await _collection.doc(trimmedMemberId).update({
      keyPlayerUserID: trimmedUid,
      keyPlayerUsers: FieldValue.arrayUnion([trimmedUid]),
    });
  }

  /// Detaches [uid] from a member (invitation abort / failed signup cleanup).
  Future<void> unlinkUserFromMember({
    required String memberId,
    required String uid,
  }) async {
    final trimmedMemberId = memberId.trim();
    final trimmedUid = uid.trim();
    if (trimmedMemberId.isEmpty || trimmedUid.isEmpty) return;

    final updates = <String, dynamic>{
      keyPlayerUsers: FieldValue.arrayRemove([trimmedUid]),
    };
    final existing = await getPlayerById(trimmedMemberId);
    if (existing?.userID?.trim() == trimmedUid) {
      updates[keyPlayerUserID] = FieldValue.delete();
    }
    await _collection.doc(trimmedMemberId).update(updates);
  }

  /// Best-effort cleanup of members created/linked during an aborted signup.
  ///
  /// - Sole owner (`creatorUserId` + single `users` entry) → delete member.
  /// - Otherwise → unlink [uid] only (keeps invitation roster members).
  Future<void> cleanupMembersForAbortedSignup(String uid) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) return;

    final linked = await getPlayersByUserId(trimmedUid);
    for (final player in linked) {
      final memberId = player.keyMember?.trim() ?? '';
      if (memberId.isEmpty) continue;

      final users = (player.users ?? const <dynamic>[])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final isSoleOwner = player.creatorUserId?.trim() == trimmedUid &&
          users.length == 1 &&
          users.first == trimmedUid;
      try {
        if (isSoleOwner) {
          await deletePlayer(memberId);
        } else {
          await unlinkUserFromMember(memberId: memberId, uid: trimmedUid);
        }
      } catch (e) {
        debugPrint(
          'PlayerService: cleanup member $memberId for $trimmedUid failed: $e',
        );
      }
    }
  }

  /// Ajouter un joueur avec un id personnalisé
  Future<void> setPlayer(String id, Player player) async {
    await _collection.doc(id).set(player.toMap());
  }

  /// Mettre à jour un joueur
  Future<void> updatePlayer(String id, Player player) async {
    await _collection.doc(id).update(player.toMap());
  }

  /// Mettre à jour partiellement un joueur
  Future<void> updatePlayerFields(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  /// Supprimer un joueur
  Future<void> deletePlayer(String id) async {
    await _collection.doc(id).delete();
  }

  /// Récupérer un joueur par son id
  Future<Player?> getPlayerById(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
    await _collection.doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    return Player.fromDocumentsnapshot(snapshot);
  }

  /// Stream d’un joueur par son id
  Stream<Player?> streamPlayerById(String id) {
    return _collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return Player.fromDocumentsnapshot(snapshot);
    });
  }

  /// Alias watch d’un joueur par son id
  Stream<Player?> watchPlayerById(String id) => streamPlayerById(id);

  /// Récupérer tous les joueurs
  Future<List<Player>> getPlayers() async {
    final QuerySnapshot<Map<String, dynamic>> query = await _collection.get();

    return query.docs.map((doc) => Player.fromDocumentsnapshot(doc)).toList();
  }

  /// Stream de tous les joueurs
  Stream<List<Player>> streamPlayers() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Player.fromDocumentsnapshot(doc))
          .toList();
    });
  }

  /// Alias watch de tous les joueurs
  Stream<List<Player>> watchPlayers() => streamPlayers();

  /// Récupérer les joueurs d’un club
  Future<List<Player>> getPlayersByClubId(String clubId) async {
    final QuerySnapshot<Map<String, dynamic>> query = await _collection
        .where(keyPlayerClubId, isEqualTo: clubId)
        .get();

    return query.docs.map((doc) => Player.fromDocumentsnapshot(doc)).toList();
  }

  /// Stream des joueurs d’un club
  Stream<List<Player>> streamPlayersByClubId(String clubId) {
    return _collection
        .where(keyPlayerClubId, isEqualTo: clubId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Player.fromDocumentsnapshot(doc))
          .toList();
    });
  }

  /// Alias watch des joueurs d’un club
  Stream<List<Player>> watchPlayersByClubId(String clubId) =>
      streamPlayersByClubId(clubId);

  /// Récupérer les joueurs actifs d’un club
  Future<List<Player>> getActivePlayersByClubId(String clubId) async {
    final QuerySnapshot<Map<String, dynamic>> query = await _collection
        .where(keyPlayerClubId, isEqualTo: clubId)
        .where(keyPlayerStatut, isEqualTo: 1)
        .get();

    return query.docs.map((doc) => Player.fromDocumentsnapshot(doc)).toList();
  }

  /// Stream des joueurs actifs d’un club
  Stream<List<Player>> streamActivePlayersByClubId(String clubId) {
    return _collection
        .where(keyPlayerClubId, isEqualTo: clubId)
        .where(keyPlayerStatut, isEqualTo: 1)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Player.fromDocumentsnapshot(doc))
          .toList();
    });
  }

  /// Alias watch des joueurs actifs d’un club
  Stream<List<Player>> watchActivePlayersByClubId(String clubId) =>
      streamActivePlayersByClubId(clubId);

  /// Chercher les joueurs par userID
  Future<List<Player>> getPlayersByUserId(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> query = await _collection
        .where(keyPlayerUsers, arrayContains: userId)
        .get();

    return query.docs.map((doc) => Player.fromDocumentsnapshot(doc)).toList();
  }

  /// Stream des joueurs par userID
  Stream<List<Player>> streamPlayersByUserId(String userId) {
    return _collection
        .where(keyPlayerUsers, arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Player.fromDocumentsnapshot(doc))
          .toList();
    });
  }

  /// Alias watch des joueurs par userID
  Stream<List<Player>> watchPlayersByUserId(String userId) =>
      streamPlayersByUserId(userId);

  /// Search active members by [searchOptions] token (lowercase prefix).
  ///
  /// Firestore `array-contains` matches one indexed token; multi-word queries
  /// should pass the first token and filter client-side on name/email.
  ///
  /// When [query] looks like an e-mail (contains `@`), also matches the
  /// `email` field so existing members without e-mail tokens in
  /// [searchOptions] remain findable.
  Future<List<Player>> searchMembersBySearchOptions(String query) async {
    final String trimmedQuery = query.trim();
    final String normalizedQuery = trimmedQuery.toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const <Player>[];
    }

    final String firstToken = normalizeSearchToken(
      normalizedQuery
          .split(RegExp(r'\s+'))
          .firstWhere((token) => token.isNotEmpty, orElse: () => ''),
    );
    if (firstToken.isEmpty) {
      return const <Player>[];
    }

    final byOptions = await _searchMembersBySearchOptionsToken(firstToken);
    final byName = await _searchMembersByNamePrefix(firstToken);
    var merged = _mergePlayersByDocId(byOptions, byName);

    if (normalizedQuery.contains('@')) {
      final byEmail = await _getActiveMembersByEmailQuery(
        normalizedEmail: normalizedQuery,
        rawEmail: trimmedQuery,
      );
      merged = _mergePlayersByDocId(merged, byEmail);
    }

    final phoneVariants = phoneSearchE164Variants(trimmedQuery);
    if (phoneVariants.isNotEmpty) {
      final byPhone = await _searchMembersByPhoneVariants(phoneVariants);
      merged = _mergePlayersByDocId(merged, byPhone);
    }

    return merged;
  }

  /// Stream variant of [searchMembersBySearchOptions].
  Stream<List<Player>> streamMembersBySearchOptions(String query) {
    return Stream.fromFuture(searchMembersBySearchOptions(query));
  }

  Future<List<Player>> _searchMembersBySearchOptionsToken(String token) async {
    final Map<String, Player> byId = <String, Player>{};

    for (final variant in searchTokenCaseVariants(token)) {
      try {
        final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
            .where(keyPlayerSearchOptions, arrayContains: variant)
            .limit(100)
            .get();

        for (final player in _mapActivePlayers(snapshot)) {
          final id = effectiveMemberId(player) ?? player.keyMember?.trim();
          if (id != null && id.isNotEmpty) {
            byId[id] = player;
          }
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            '[MemberSearch] searchOptions token=$variant failed: $e\n$st',
          );
        }
      }
    }

    return byId.values.toList(growable: false);
  }

  Future<List<Player>> _searchMembersByNamePrefix(String token) async {
    final Map<String, Player> byId = <String, Player>{};

    for (final variant in searchTokenCaseVariants(token)) {
      for (final field in <String>[keyPlayerFirstName, keyPlayerLastName]) {
        try {
          final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
              .where(field, isGreaterThanOrEqualTo: variant)
              .where(field, isLessThanOrEqualTo: '$variant\uf8ff')
              .limit(50)
              .get();

          for (final player in _mapActivePlayers(snapshot)) {
            final id = effectiveMemberId(player) ?? player.keyMember?.trim();
            if (id != null && id.isNotEmpty) {
              byId[id] = player;
            }
          }
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              '[MemberSearch] name prefix field=$field token=$variant '
              'failed: $e\n$st',
            );
          }
        }
      }
    }

    return byId.values.toList(growable: false);
  }

  Future<List<Player>> _searchMembersByPhoneVariants(
    Iterable<String> variants,
  ) async {
    final Map<String, Player> byId = <String, Player>{};

    for (final variant in variants) {
      try {
        final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
            .where(keyPlayerPhoneE164, isEqualTo: variant)
            .limit(20)
            .get();

        for (final player in _mapActivePlayers(snapshot)) {
          final id = effectiveMemberId(player) ?? player.keyMember?.trim();
          if (id != null && id.isNotEmpty) {
            byId[id] = player;
          }
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            '[MemberSearch] phone variant=$variant failed: $e\n$st',
          );
        }
      }
    }

    return byId.values.toList(growable: false);
  }

  List<Player> _mapActivePlayers(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => Player.fromDocumentsnapshot(doc))
        .where((player) => player.statut == 1)
        .toList();
  }

  Future<List<Player>> _getActiveMembersByEmailQuery({
    required String normalizedEmail,
    required String rawEmail,
  }) async {
    final Map<String, Player> byId = <String, Player>{};

    Future<void> collect(Query<Map<String, dynamic>> query) async {
      final snapshot = await query.limit(30).get();
      for (final doc in snapshot.docs) {
        final player = Player.fromDocumentsnapshot(doc);
        if (player.statut == 1) {
          byId[doc.id] = player;
        }
      }
    }

    final emailVariants = <String>{
      normalizedEmail,
      if (rawEmail.isNotEmpty) rawEmail,
    };

    for (final email in emailVariants) {
      await collect(_collection.where(keyPlayerEmail, isEqualTo: email));
      await collect(
        _collection
            .where(keyPlayerEmail, isGreaterThanOrEqualTo: email)
            .where(keyPlayerEmail, isLessThanOrEqualTo: '$email\uf8ff'),
      );
    }

    return byId.values.toList(growable: false);
  }

  List<Player> _mergePlayersByDocId(
    List<Player> primary,
    List<Player> secondary,
  ) {
    final Map<String, Player> byId = <String, Player>{};
    for (final player in primary) {
      final id = effectiveMemberId(player) ?? player.keyMember?.trim();
      if (id != null && id.isNotEmpty) {
        byId[id] = player;
      }
    }
    for (final player in secondary) {
      final id = effectiveMemberId(player) ?? player.keyMember?.trim();
      if (id != null && id.isNotEmpty) {
        byId.putIfAbsent(id, () => player);
      }
    }
    return byId.values.toList(growable: false);
  }

  /// Chercher un joueur par userID
  Future<Player?> getPlayerByUserId(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> query = await _collection
        .where(keyPlayerUserID, isEqualTo: userId)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return Player.fromDocumentsnapshot(query.docs.first);
  }

  /// Ajouter une indisponibilité
  Future<void> addUnavailability({
    required String playerId,
    required Unavailability unavailability,
  }) async {
    final DocumentReference<Map<String, dynamic>> docRef =
    _collection.doc(playerId);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();

    if (!snapshot.exists) return;

    Player player = Player.fromDocumentsnapshot(snapshot);

    final seasonId = unavailability.seasonId?.trim() ?? legacyUnavailabilitySeasonKey;
    unavailability.seasonId = seasonId;
    player.unavailableMap.putIfAbsent(seasonId, () => <Unavailability>[]);
    player.unavailableMap[seasonId]!.add(unavailability);

    await docRef.update({
      keyPlayerUnavailability:
          _buildUnavailabilityFirestoreMap(player.unavailableMap),
    });
  }

  /// Remplacer complètement les indisponibilités
  Future<void> updateUnavailabilityMap({
    required String playerId,
    required Map<String, List<Unavailability>> unavailableMap,
  }) async {
    await _collection.doc(playerId).update({
      keyPlayerUnavailability:
          _buildUnavailabilityFirestoreMap(unavailableMap),
    });
  }

  /// Supprimer une indisponibilité par id
  Future<void> removeUnavailability({
    required String playerId,
    required String unavailabilityId,
  }) async {
    final DocumentReference<Map<String, dynamic>> docRef =
    _collection.doc(playerId);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();

    if (!snapshot.exists) return;

    Player player = Player.fromDocumentsnapshot(snapshot);

    player.unavailableMap.forEach((seasonId, entries) {
      entries.removeWhere((item) => item.id == unavailabilityId);
    });
    player.unavailableMap.removeWhere((_, entries) => entries.isEmpty);

    await docRef.update({
      keyPlayerUnavailability:
          _buildUnavailabilityFirestoreMap(player.unavailableMap),
    });
  }

  /// Ajouter un user dans le champ users
  Future<void> addUserToPlayer({
    required String playerId,
    required String userId,
  }) async {
    await _collection.doc(playerId).update({
      keyPlayerUsers: FieldValue.arrayUnion([userId]),
    });
  }

  /// Admin: associate [uid] with a member (`users` arrayUnion; set `userID`
  /// when the member has no primary link yet).
  Future<void> adminAssociateUserToMember({
    required String memberId,
    required String uid,
  }) async {
    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }

    final trimmedMemberId = memberId.trim();
    final trimmedUid = uid.trim();
    if (trimmedMemberId.isEmpty) {
      throw ArgumentError.value(memberId, 'memberId', 'must not be empty');
    }
    if (trimmedUid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'must not be empty');
    }

    final existing = await getPlayerById(trimmedMemberId);
    if (existing == null) {
      throw StateError('member-not-found');
    }

    final updates = <String, dynamic>{
      keyPlayerUsers: FieldValue.arrayUnion([trimmedUid]),
    };
    final currentPrimary = existing.userID?.trim() ?? '';
    if (currentPrimary.isEmpty) {
      updates[keyPlayerUserID] = trimmedUid;
    }

    await _collection.doc(trimmedMemberId).update(updates);
  }

  /// Stream of all members (admin tools — client filters / aggregates).
  Stream<List<Player>> streamAllMembers() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Player.fromDocumentsnapshot(doc))
          .toList(growable: false);
    });
  }

  /// Retirer un user du champ users
  Future<void> removeUserFromPlayer({
    required String playerId,
    required String userId,
  }) async {
    await _collection.doc(playerId).update({
      keyPlayerUsers: FieldValue.arrayRemove([userId]),
    });
  }

  /// Unsubscribes [uid] from a member profile (`users` + [userID] if needed).
  ///
  /// No-op when [uid] is not linked. Does not delete the member document.
  Future<void> unsubscribeUserFromMember({
    required String memberId,
    required String uid,
  }) async {
    final trimmedMemberId = memberId.trim();
    final trimmedUid = uid.trim();
    if (trimmedMemberId.isEmpty) {
      throw ArgumentError.value(memberId, 'memberId', 'must not be empty');
    }
    if (trimmedUid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'must not be empty');
    }

    final existing = await getPlayerById(trimmedMemberId);
    if (existing == null) {
      throw StateError('Member not found: $trimmedMemberId');
    }

    final plan = planMemberUnsubscribe(
      users: existing.users,
      userID: existing.userID,
      uid: trimmedUid,
    );
    if (plan == null) return;

    final updates = <String, dynamic>{
      keyPlayerUsers: FieldValue.arrayRemove([trimmedUid]),
    };
    switch (plan.userIdAction) {
      case MemberUserIdUnsubscribeAction.keep:
        break;
      case MemberUserIdUnsubscribeAction.reassign:
        updates[keyPlayerUserID] = plan.nextUserId;
        break;
      case MemberUserIdUnsubscribeAction.clear:
        updates[keyPlayerUserID] = FieldValue.delete();
        break;
    }

    await _collection.doc(trimmedMemberId).update(updates);
  }

  /// Ajouter un like
  Future<void> addLike({
    required String playerId,
    required String userId,
  }) async {
    await _collection.doc(playerId).update({
      keyPlayerLikes: FieldValue.arrayUnion([userId]),
    });
  }

  /// Retirer un like
  Future<void> removeLike({
    required String playerId,
    required String userId,
  }) async {
    await _collection.doc(playerId).update({
      keyPlayerLikes: FieldValue.arrayRemove([userId]),
    });
  }

  /// Incrémenter les vues
  Future<void> incrementViews(String playerId) async {
    await _collection.doc(playerId).update({
      keyPlayerViews: FieldValue.increment(1),
    });
  }

  /// Construire la map Firestore des indisponibilités par saison
  Map<String, dynamic> _buildUnavailabilityFirestoreMap(
    Map<String, List<Unavailability>> unavailableMap,
  ) {
    final map = <String, dynamic>{};
    unavailableMap.forEach((seasonId, entries) {
      if (entries.isEmpty) return;
      map[seasonId] = entries.map((item) => item.toMap()).toList();
    });
    return map;
  }

  /// URLs avatar mises en cache (joueur → utilisateur → défaut).
  Future<List<String>> getCachedPlayerAvatarUrls(
    Player player, {
    String defaultPhotoFileName = defaultPlayerAvatarFilename,
    User? authUser,
  }) {
    final cacheKey = _avatarCacheKey(
      player,
      defaultPhotoFileName,
      authUser: authUser,
    );
    final cached = _avatarUrlCache[cacheKey];
    if (cached != null) {
      return Future<List<String>>.value(cached);
    }

    return _avatarUrlPending.putIfAbsent(cacheKey, () async {
      try {
        final urls = await resolvePlayerAvatarUrls(
          player,
          defaultPhotoFileName: defaultPhotoFileName,
          authUser: authUser,
        );
        _avatarUrlCache[cacheKey] = urls;
        return urls;
      } finally {
        _avatarUrlPending.remove(cacheKey);
      }
    });
  }

  static String _avatarCacheKey(
    Player player,
    String defaultPhotoFileName, {
    User? authUser,
  }) {
    final linkedUserId = linkedUserIdForPlayer(player);
    final photoPart = hasPlayerPhoto(player) ? player.photo!.trim() : '';
    final authPhotoPart = _authPhotoCachePart(player, authUser);
    final id = effectiveMemberId(player);
    if (id != null && id.isNotEmpty) {
      return '$id|$photoPart|user:$linkedUserId|auth:$authPhotoPart|$defaultPhotoFileName';
    }
    return 'photo:$photoPart|user:$linkedUserId|auth:$authPhotoPart|$defaultPhotoFileName';
  }

  static String _authPhotoCachePart(Player player, User? authUser) {
    if (authUser == null) return '';
    final authUid = authUser.uid.trim();
    if (authUid.isEmpty || !isPlayerLinkedToAuthUser(player, authUid)) {
      return '';
    }
    final liveUser = FirebaseAuth.instance.currentUser;
    if (liveUser != null && liveUser.uid.trim() == authUid) {
      return liveUser.photoURL?.trim() ?? '';
    }
    return authUser.photoURL?.trim() ?? '';
  }

  static void clearPlayerPhotoUrlCache() {
    _avatarUrlCache.clear();
    _avatarUrlPending.clear();
  }
}
