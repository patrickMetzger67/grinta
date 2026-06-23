import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/player.dart';
import '../util/player_photo_resolver.dart';

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

    player.unavailable ??= [];
    player.unavailable!.add(unavailability);

    await docRef.update({
      keyPlayerUnavailability:
      _buildUnavailabilityMapList(player.unavailable!),
    });
  }

  /// Remplacer complètement la liste des indisponibilités
  Future<void> updateUnavailabilityList({
    required String playerId,
    required List<dynamic> unavailabilityList,
  }) async {
    await _collection.doc(playerId).update({
      keyPlayerUnavailability:
      _buildUnavailabilityMapList(unavailabilityList),
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

    player.unavailable ??= [];
    player.unavailable!.removeWhere((item) {
      if (item is Unavailability) {
        return item.id == unavailabilityId;
      }
      return false;
    });

    await docRef.update({
      keyPlayerUnavailability:
      _buildUnavailabilityMapList(player.unavailable!),
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

  /// Retirer un user du champ users
  Future<void> removeUserFromPlayer({
    required String playerId,
    required String userId,
  }) async {
    await _collection.doc(playerId).update({
      keyPlayerUsers: FieldValue.arrayRemove([userId]),
    });
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

  /// Construire la liste Firestore des indisponibilités
  List<Map<String, dynamic>> _buildUnavailabilityMapList(
      List<dynamic> unavailable,
      ) {
    List<Map<String, dynamic>> list = [];

    for (int i = 0; i < unavailable.length; i++) {
      if (unavailable[i] is Unavailability) {
        Unavailability item = unavailable[i];

        String? type;
        switch (item.unavailabilityType) {
          case UnavailabilityType.holiday:
            type = 'holiday';
            break;
          case UnavailabilityType.unwell:
            type = 'unwell';
            break;
          case UnavailabilityType.injured:
            type = 'injured';
            break;
          case UnavailabilityType.other:
            type = 'other';
            break;
          default:
            type = 'other';
        }

        list.add({
          'id': item.id,
          'from': item.from,
          'to': item.to,
          'details': item.details,
          'isVisible': item.isVisible ?? true,
          'type': type,
        });
      }
    }

    return list;
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
    final id = player.keyMember?.trim();
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
