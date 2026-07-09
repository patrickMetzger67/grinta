import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/grinta_player.dart';
import '../model/player.dart';
import '../model/team.dart';
import '../util/player_photo_resolver.dart';
import '../util/player_positions.dart';
import 'engagement_service.dart';
import 'stream_channel_service.dart';
import 'subscription_limits_service.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'team';

  /// One roster-index migration scan per member id set per app session.
  static final Set<String> _grintaMemberIndexMigrationScanned =
      <String>{};

  /// Roster-scan matches kept for the session so later indexed-only resolves
  /// (e.g. watch stream re-fetch) do not drop teams missing from the index.
  static final Map<String, List<Team>> _grintaRosterScanCache =
      <String, List<Team>>{};

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  void _logFirestoreReadError({
    required String method,
    required String queryContext,
    required Object error,
  }) {
    if (error is FirebaseException) {
      debugPrint(
        'Firestore error in $method: collection=$collectionName '
        'filters=[$queryContext] ${error.code} - ${error.message}',
      );
    } else {
      debugPrint(
        'Unexpected error in $method: collection=$collectionName '
        'filters=[$queryContext] $error',
      );
    }
  }

  Stream<T> _withReadErrorLogging<T>({
    required Stream<T> stream,
    required String method,
    required String queryContext,
  }) {
    return stream.handleError((Object error) {
      _logFirestoreReadError(
        method: method,
        queryContext: queryContext,
        error: error,
      );
    });
  }

  /// CREATE
  Future<String> createTeam(Team team) async {
    try {
      final docRef = (team.keyTeam != null && team.keyTeam!.isNotEmpty)
          ? _collection.doc(team.keyTeam)
          : _collection.doc();

      if (team.keyTeam == null || team.keyTeam!.isEmpty) {
        team.keyTeam = docRef.id;
      }

      await docRef.set(team.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// GET BY SEASON ID + MANAGER USER ID
  Future<List<Team>> getTeamsBySeasonIdAndManager({
    required String seasonId,
    required String userId,
  }) async {
    const method = 'getTeamsBySeasonIdAndManager';
    final queryContext =
        '$keyTeamIsGrinta==true, $keyTeamSeasonID==$seasonId, '
        '$keyTeamManagers arrayContains $userId';
    try {
      final query = await _collection
          .where(keyTeamIsGrinta, isEqualTo: true)
          .where(keyTeamSeasonID, isEqualTo: seasonId)
          .where(keyTeamManagers, arrayContains: userId)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      _logFirestoreReadError(
        method: method,
        queryContext: queryContext,
        error: e,
      );
      rethrow;
    }
  }

  /// STREAM BY SEASON ID + MANAGER USER ID
  Stream<List<Team>> streamTeamsBySeasonIdAndManager({
    required String seasonId,
    required String userId,
  }) {
    const method = 'streamTeamsBySeasonIdAndManager';
    final queryContext =
        '$keyTeamIsGrinta==true, $keyTeamSeasonID==$seasonId, '
        '$keyTeamManagers arrayContains $userId';
    return _withReadErrorLogging(
      method: method,
      queryContext: queryContext,
      stream: _collection
          .where(keyTeamIsGrinta, isEqualTo: true)
          .where(keyTeamSeasonID, isEqualTo: seasonId)
          .where(keyTeamManagers, arrayContains: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Team.fromDocumentSnapshot(doc))
              .toList()),
    );
  }

  /// STREAM BY SEASON ID + MANAGER USER ID
  Stream<List<Team>> streamTeamsBySeasonIdPlayerId({
    required String seasonId,
    required String playerId,
  }) {
    const method = 'streamTeamsBySeasonIdPlayerId';
    final queryContext =
        '$keyTeamIsGrinta==true, $keyTeamSeasonID==$seasonId, '
        '$keyTeamPlayers arrayContains $playerId';
    return _withReadErrorLogging(
      method: method,
      queryContext: queryContext,
      stream: _collection
          .where(keyTeamIsGrinta, isEqualTo: true)
          .where(keyTeamSeasonID, isEqualTo: seasonId)
          .where(keyTeamPlayers, arrayContains: playerId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Team.fromDocumentSnapshot(doc))
              .toList()),
    );
  }

  /// WATCH BY SEASON ID + MANAGER USER ID
  Stream<List<Team>> watchTeamsBySeasonIdAndManager({
    required String seasonId,
    required String userId,
  }) =>
      streamTeamsBySeasonIdAndManager(
        seasonId: seasonId,
        userId: userId,
      );

  /// SET / UPSERT
  Future<void> setTeam(Team team) async {
    try {
      final docRef = (team.keyTeam != null && team.keyTeam!.isNotEmpty)
          ? _collection.doc(team.keyTeam)
          : _collection.doc();

      if (team.keyTeam == null || team.keyTeam!.isEmpty) {
        team.keyTeam = docRef.id;
      }

      await docRef.set(team.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// READ ONE
  Future<Team?> getTeamById(String teamId) async {
    try {
      final doc = await _collection.doc(teamId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final Map<String, dynamic> data = doc.data()!;
      final Team team = Team.fromDocumentSnapshot(doc);
      await backfillGrintaPlayerMemberIdsIfMissing(
        team,
        rawMemberIds: data[keyTeamGrintaPlayerMemberIds],
      );
      return team;
    } catch (e) {
      rethrow;
    }
  }

  /// Reads the team document from Firestore.
  ///
  /// When [preferCache] is true, uses [Source.serverAndCache] so a read right
  /// after a local roster write sees the updated document (pure [Source.server]
  /// can briefly return stale data and hide newly added players).
  Future<DocumentSnapshot<Map<String, dynamic>>?> getTeamSnapshotFromServer(
    String teamId, {
    bool preferCache = false,
  }) async {
    final doc = await _collection.doc(teamId).get(
      GetOptions(
        source: preferCache ? Source.serverAndCache : Source.server,
      ),
    );

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return doc;
  }

  /// Reads the team document from the Firestore server (not local cache).
  Future<Team?> getTeamByIdFromServer(String teamId) async {
    try {
      final doc = await getTeamSnapshotFromServer(teamId);
      if (doc == null) {
        return null;
      }

      return Team.fromDocumentSnapshot(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ONE
  Stream<Team?> streamTeamById(String teamId) {
    return _collection.doc(teamId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Team.fromDocumentSnapshot(doc);
    });
  }

  /// WATCH ONE
  Stream<Team?> watchTeamById(String teamId) => streamTeamById(teamId);

  /// READ ALL
  Future<List<Team>> getAllTeams() async {
    try {
      final query = await _collection.get();
      return query.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => Team.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ALL
  Stream<List<Team>> streamAllTeams() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => Team.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// WATCH ALL
  Stream<List<Team>> watchAllTeams() => streamAllTeams();

  /// UPDATE
  Future<void> updateTeam(Team team) async {
    try {
      if (team.keyTeam == null || team.keyTeam!.isEmpty) {
        throw Exception('keyTeam null ou vide');
      }

      await _collection.doc(team.keyTeam).update(team.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Appends a [GrintaPlayer] to [keyTeamGrintaPlayers] (read-modify-write).
  ///
  /// Uses a targeted Firestore update so roster writes are not lost when the
  /// in-memory [Team] is stale or a full [updateTeam] would overwrite fields.
  ///
  /// The same [memberId] may appear twice on a roster (once as field player,
  /// once as staff). Duplicate adds for the same role are ignored.
  Future<void> addGrintaPlayer({
    required String teamId,
    required GrintaPlayer player,
    String? firebaseUserId,
    bool staffEntry = false,
  }) async {
    final trimmedTeamId = teamId.trim();
    final trimmedPlayerId = player.playerId.trim();
    if (trimmedTeamId.isEmpty) {
      throw Exception('keyTeam null ou vide');
    }
    if (trimmedPlayerId.isEmpty) {
      throw Exception('playerId null ou vide');
    }

    final team = await getTeamById(trimmedTeamId);
    if (team == null) {
      throw Exception('Team introuvable');
    }

    final Set<String> managerIds = _managerIdsFromTeam(team);
    final bool isStaff = staffEntry ||
        isGrintaRosterStaff(
          positions: player.positions,
          fonction: player.fonction,
          listedInManagers: managerIds.contains(trimmedPlayerId),
        );
    if (!isStaff) {
      await SubscriptionLimitsService.instance.assertCanAddPlayer(
        teamId: trimmedTeamId,
        memberId: trimmedPlayerId,
        firebaseUserId: firebaseUserId,
      );
    }

    final List<GrintaPlayer> grintaPlayers =
        List<GrintaPlayer>.from(team.grintaPlayers ?? const <GrintaPlayer>[]);

    final bool alreadySameRole = grintaPlayers.any(
      (GrintaPlayer entry) =>
          entry.playerId.trim() == trimmedPlayerId &&
          _isGrintaStaffEntry(entry, managerIds) == isStaff,
    );
    if (alreadySameRole) {
      return;
    }

    grintaPlayers.add(player);

    final List<Map<String, dynamic>> grintaPlayerMaps =
        grintaPlayers.map((GrintaPlayer entry) => entry.toMap()).toList();
    final List<String> memberIds =
        grintaPlayerMemberIdsFromGrintaPlayers(grintaPlayers);
    debugPrint(
      'TeamService.addGrintaPlayer teamId=$trimmedTeamId playerId=$trimmedPlayerId '
      'staffEntry=$staffEntry invitationId=${player.invitationId} '
      'grintaPlayersPayload=$grintaPlayerMaps',
    );

    await _collection.doc(trimmedTeamId).update(<String, dynamic>{
      keyTeamGrintaPlayers: grintaPlayerMaps,
      keyTeamGrintaPlayerMemberIds: memberIds,
    });
  }

  /// Updates one field-player or staff [GrintaPlayer] entry in
  /// [keyTeamGrintaPlayers] (read-modify-write).
  Future<void> updateGrintaPlayer({
    required String teamId,
    required String playerId,
    required GrintaPlayer player,
    required bool staffEntry,
  }) async {
    final trimmedTeamId = teamId.trim();
    final trimmedPlayerId = playerId.trim();
    if (trimmedTeamId.isEmpty) {
      throw Exception('keyTeam null ou vide');
    }
    if (trimmedPlayerId.isEmpty) {
      throw Exception('playerId null ou vide');
    }

    final team = await getTeamById(trimmedTeamId);
    if (team == null) {
      throw Exception('Team introuvable');
    }

    final Set<String> managerIds = _managerIdsFromTeam(team);
    final List<GrintaPlayer> grintaPlayers =
        List<GrintaPlayer>.from(team.grintaPlayers ?? const <GrintaPlayer>[]);

    final int index = _indexOfGrintaEntry(
      grintaPlayers,
      trimmedPlayerId,
      staffEntry: staffEntry,
      managerIds: managerIds,
    );
    if (index < 0) {
      throw Exception('Joueur introuvable sur le roster Grinta');
    }

    grintaPlayers[index] = player;

    await _collection.doc(trimmedTeamId).update(<String, dynamic>{
      keyTeamGrintaPlayers:
          grintaPlayers.map((GrintaPlayer entry) => entry.toMap()).toList(),
      keyTeamGrintaPlayerMemberIds:
          grintaPlayerMemberIdsFromGrintaPlayers(grintaPlayers),
    });
  }

  /// Removes one field-player entry from [keyTeamGrintaPlayers].
  Future<void> removeGrintaPlayer({
    required String teamId,
    required String playerId,
  }) async {
    await _removeGrintaEntry(
      teamId: teamId,
      playerId: playerId,
      staffEntry: false,
      removeFromManagers: false,
    );
  }

  /// Removes one staff entry from [keyTeamGrintaPlayers] and [keyTeamManagers].
  Future<void> removeGrintaStaff({
    required String teamId,
    required String playerId,
    Iterable<String> extraManagerIds = const <String>[],
  }) async {
    await _removeGrintaEntry(
      teamId: teamId,
      playerId: playerId,
      staffEntry: true,
      removeFromManagers: true,
      extraManagerIds: extraManagerIds,
    );
  }

  Future<void> _removeGrintaEntry({
    required String teamId,
    required String playerId,
    required bool staffEntry,
    required bool removeFromManagers,
    Iterable<String> extraManagerIds = const <String>[],
  }) async {
    final trimmedTeamId = teamId.trim();
    final trimmedPlayerId = playerId.trim();
    if (trimmedTeamId.isEmpty) {
      throw Exception('keyTeam null ou vide');
    }
    if (trimmedPlayerId.isEmpty) {
      throw Exception('playerId null ou vide');
    }

    final team = await getTeamById(trimmedTeamId);
    if (team == null) {
      throw Exception('Team introuvable');
    }

    final Set<String> managerIds = _managerIdsFromTeam(team);
    final List<GrintaPlayer> grintaPlayers =
        List<GrintaPlayer>.from(team.grintaPlayers ?? const <GrintaPlayer>[]);

    // When removing staff, include the target id in the managers snapshot used
    // for roster classification. Educator/executive codes (1/2) overlap pitch
    // codes 1–23 and require listedInManagers; callers must not clear managers
    // before this read-modify-write, but this keeps lookup correct if they do.
    final Set<String> classificationManagerIds = <String>{...managerIds};
    if (staffEntry) {
      classificationManagerIds.add(trimmedPlayerId);
      for (final String extraId in extraManagerIds) {
        final String trimmed = extraId.trim();
        if (trimmed.isNotEmpty) {
          classificationManagerIds.add(trimmed);
        }
      }
    }

    int index = _indexOfGrintaEntry(
      grintaPlayers,
      trimmedPlayerId,
      staffEntry: staffEntry,
      managerIds: classificationManagerIds,
    );
    if (index < 0 && staffEntry) {
      index = grintaPlayers.indexWhere(
        (GrintaPlayer entry) =>
            entry.playerId.trim() == trimmedPlayerId &&
            isGrintaRosterStaff(
              positions: entry.positions,
              fonction: entry.fonction,
              listedInManagers:
                  classificationManagerIds.contains(trimmedPlayerId),
            ),
      );
    }

    final Map<String, dynamic> update = <String, dynamic>{};

    if (index >= 0) {
      grintaPlayers.removeAt(index);
      update[keyTeamGrintaPlayers] =
          grintaPlayers.map((GrintaPlayer entry) => entry.toMap()).toList();
      update[keyTeamGrintaPlayerMemberIds] =
          grintaPlayerMemberIdsFromGrintaPlayers(grintaPlayers);
    }

    if (removeFromManagers) {
      final List<dynamic> managers =
          List<dynamic>.from(team.managers ?? const <dynamic>[]);
      for (final String managerUserId in extraManagerIds) {
        final String trimmed = managerUserId.trim();
        if (trimmed.isNotEmpty) {
          managers.remove(trimmed);
        }
      }
      update[keyTeamManagers] = managers;
    }

    if (update.isEmpty) {
      return;
    }

    await _collection.doc(trimmedTeamId).update(update);
  }

  /// Roster read-modify-write slot for staff vs field player (same memberId
  /// may appear twice). Display lists use [isGrintaRosterStaff] instead.
  static bool _isGrintaStaffEntry(
    GrintaPlayer entry,
    Set<String> managerIds,
  ) {
    return isGrintaStaffCrudEntry(
      positions: entry.positions,
      fonction: entry.fonction,
      playerId: entry.playerId,
      managerIds: managerIds,
    );
  }

  static int _indexOfGrintaEntry(
    List<GrintaPlayer> grintaPlayers,
    String playerId, {
    required bool staffEntry,
    required Set<String> managerIds,
  }) {
    for (int index = 0; index < grintaPlayers.length; index++) {
      final GrintaPlayer entry = grintaPlayers[index];
      if (entry.playerId.trim() != playerId) {
        continue;
      }
      if (_isGrintaStaffEntry(entry, managerIds) == staffEntry) {
        return index;
      }
    }
    return -1;
  }

  /// Replaces [keyTeamGrintaPlayers] on the team document.
  Future<void> updateGrintaPlayers({
    required String teamId,
    required List<GrintaPlayer> grintaPlayers,
  }) async {
    final trimmedTeamId = teamId.trim();
    if (trimmedTeamId.isEmpty) {
      throw Exception('keyTeam null ou vide');
    }

    await _collection.doc(trimmedTeamId).update(<String, dynamic>{
      keyTeamGrintaPlayers:
          grintaPlayers.map((GrintaPlayer entry) => entry.toMap()).toList(),
      keyTeamGrintaPlayerMemberIds:
          grintaPlayerMemberIdsFromGrintaPlayers(grintaPlayers),
    });
  }

  /// DELETE (document only).
  Future<void> deleteTeam(String teamId) async {
    try {
      await _collection.doc(teamId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE as owner: engagement cleanup then team document removal.
  ///
  /// Client-side only: [currentUserUid] must match [team.uid].
  Future<void> deleteTeamAsOwner({
    required Team team,
    required String currentUserUid,
    EngagementService? engagementService,
  }) async {
    final teamId = team.keyTeam?.trim() ?? '';
    if (teamId.isEmpty) {
      throw Exception('keyTeam null ou vide');
    }

    final ownerUid = team.uid?.trim() ?? '';
    if (ownerUid.isEmpty || ownerUid != currentUserUid.trim()) {
      throw Exception('Seul le créateur de l\'équipe peut la supprimer');
    }

    final engagements = engagementService ?? EngagementService();

    try {
      await engagements.removeTeamIdFromAllEngagements(teamId);

      if (team.isGrinta == true) {
        try {
          await StreamChannelService.instance.deleteTeamStreamChannel(
            teamId: teamId,
          );
        } catch (e, stackTrace) {
          StreamChannelService.log(
            'deleteTeamStreamChannel failed during team delete (continuing):'
            ' teamId=$teamId',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      await _collection.doc(teamId).delete();
    } catch (e, stackTrace) {
      debugPrint('deleteTeamAsOwner failed for teamId=$teamId: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// GET TEAMS FOR A PLAYER (legacy [keyTeamPlayers] membership).
  Future<List<Team>> getTeamsByPlayerId(String playerId) async {
    const method = 'getTeamsByPlayerId';
    final queryContext =
        '$keyTeamPlayers arrayContains $playerId, $keyTeamIsVisible==true';
    try {
      final query = await _collection
          .where(keyTeamPlayers, arrayContains: playerId)
          .where(keyTeamIsVisible, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      _logFirestoreReadError(
        method: method,
        queryContext: queryContext,
        error: e,
      );
      rethrow;
    }
  }

  /// STREAM TEAMS FOR A PLAYER (legacy [keyTeamPlayers] membership).
  Stream<List<Team>> streamTeamsByPlayerId(String playerId) {
    const method = 'streamTeamsByPlayerId';
    final queryContext =
        '$keyTeamPlayers arrayContains $playerId, $keyTeamIsVisible==true';
    return _withReadErrorLogging(
      method: method,
      queryContext: queryContext,
      stream: _collection
          .where(keyTeamPlayers, arrayContains: playerId)
          .where(keyTeamIsVisible, isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Team.fromDocumentSnapshot(doc))
              .toList()),
    );
  }

  /// WATCH TEAMS FOR A PLAYER
  Stream<List<Team>> watchTeamsByPlayerId(String playerId) =>
      streamTeamsByPlayerId(playerId);

  /// GET TEAMS WHERE [keyTeamGrintaPlayerMemberIds] CONTAINS MEMBER ID
  Future<List<Team>> getTeamsByGrintaPlayerMemberId(String memberId) async {
    const method = 'getTeamsByGrintaPlayerMemberId';
    final trimmedMemberId = memberId.trim();
    if (trimmedMemberId.isEmpty) {
      return const <Team>[];
    }

    try {
      return await _resolveGrintaMemberTeams(<String>{trimmedMemberId});
    } catch (e) {
      final queryContext =
          '$keyTeamIsGrinta==true, $keyTeamGrintaPlayerMemberIds '
          'arrayContains $trimmedMemberId, $keyTeamIsVisible==true';
      _logFirestoreReadError(
        method: method,
        queryContext: queryContext,
        error: e,
      );
      rethrow;
    }
  }

  /// Grinta roster teams for [player] (canonical member id + legacy aliases).
  Future<List<Team>> getTeamsForPlayerGrintaMembership(Player player) async {
    final Set<String> lookupIds = playerMemberLookupIds(player);
    if (lookupIds.isEmpty) {
      return const <Team>[];
    }
    return _resolveGrintaMemberTeams(lookupIds);
  }

  /// STREAM TEAMS WHERE [keyTeamGrintaPlayerMemberIds] CONTAINS MEMBER ID
  Stream<List<Team>> streamTeamsByGrintaPlayerMemberId(String memberId) {
    const method = 'streamTeamsByGrintaPlayerMemberId';
    final trimmedMemberId = memberId.trim();
    if (trimmedMemberId.isEmpty) {
      return Stream<List<Team>>.value(const <Team>[]);
    }

    final queryContext =
        '$keyTeamIsGrinta==true, $keyTeamGrintaPlayerMemberIds '
        'arrayContains $trimmedMemberId, $keyTeamIsVisible==true';
    return _withReadErrorLogging(
      method: method,
      queryContext: queryContext,
      stream: Stream.fromFuture(
        _resolveGrintaMemberTeams(<String>{trimmedMemberId}),
      ).asyncExpand((List<Team> initialTeams) {
        return _streamTeamsByGrintaPlayerMemberIdIndexed(trimmedMemberId).map(
          (List<Team> indexedTeams) =>
              _mergeTeamsByKey(<Team>[...initialTeams, ...indexedTeams]),
        );
      }),
    );
  }

  Future<List<Team>> _resolveGrintaMemberTeams(Set<String> memberIds) async {
    final Set<String> trimmedMemberIds = memberIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
    if (trimmedMemberIds.isEmpty) {
      return const <Team>[];
    }

    final String cacheKey = trimmedMemberIds.join('|');
    final List<Team> indexedTeams = _mergeTeamsByKey(
      await Future.wait(
        trimmedMemberIds.map(_queryTeamsByGrintaPlayerMemberIdIndexed),
      ).then(
        (List<List<Team>> results) =>
            results.expand((List<Team> teams) => teams),
      ),
    );

    final List<Team> rosterTeams = await _rosterScanTeamsForMemberIds(
      cacheKey: cacheKey,
      memberIds: trimmedMemberIds,
    );

    return _mergeTeamsByKey(<Team>[...indexedTeams, ...rosterTeams]);
  }

  Future<List<Team>> _rosterScanTeamsForMemberIds({
    required String cacheKey,
    required Set<String> memberIds,
  }) async {
    final List<Team>? cached = _grintaRosterScanCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    if (_grintaMemberIndexMigrationScanned.contains(cacheKey)) {
      return const <Team>[];
    }

    final List<Team> rosterTeams =
        await _findGrintaTeamsViaRosterScan(memberIds);
    _grintaMemberIndexMigrationScanned.add(cacheKey);
    _grintaRosterScanCache[cacheKey] = rosterTeams;
    return rosterTeams;
  }

  Future<List<Team>> _queryTeamsByGrintaPlayerMemberIdIndexed(
    String memberId,
  ) async {
    final query = await _collection
        .where(keyTeamIsGrinta, isEqualTo: true)
        .where(keyTeamGrintaPlayerMemberIds, arrayContains: memberId)
        .where(keyTeamIsVisible, isEqualTo: true)
        .get();

    return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
  }

  Stream<List<Team>> _streamTeamsByGrintaPlayerMemberIdIndexed(
    String memberId,
  ) {
    return _collection
        .where(keyTeamIsGrinta, isEqualTo: true)
        .where(keyTeamGrintaPlayerMemberIds, arrayContains: memberId)
        .where(keyTeamIsVisible, isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Team.fromDocumentSnapshot(doc))
              .toList(),
        );
  }

  /// Teams whose [grintaPlayers] roster includes a member id but predate or
  /// bypass the denormalized [keyTeamGrintaPlayerMemberIds] index field.
  ///
  /// Does not filter on [keyTeamIsGrinta] so teams with a [grintaPlayers]
  /// roster but a missing/false flag are still discovered client-side.
  Future<List<Team>> _findGrintaTeamsViaRosterScan(
    Set<String> memberIds,
  ) async {
    final query = await _collection
        .where(keyTeamIsVisible, isEqualTo: true)
        .get();

    final List<Team> matches = <Team>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in query.docs) {
      final Map<String, dynamic> data = doc.data();
      final Team team = Team.fromDocumentSnapshot(doc);
      final bool onRoster = memberIds.any(
        (String memberId) => teamContainsGrintaMember(team, memberId),
      );
      if (!onRoster) {
        continue;
      }

      matches.add(team);
      await backfillGrintaPlayerMemberIdsIfMissing(
        team,
        rawMemberIds: data[keyTeamGrintaPlayerMemberIds],
      );
    }
    return matches;
  }

  /// Persists [keyTeamGrintaPlayerMemberIds] when missing or stale in Firestore.
  Future<void> backfillGrintaPlayerMemberIdsIfMissing(
    Team team, {
    dynamic rawMemberIds,
  }) async {
    final String teamId = team.keyTeam?.trim() ?? '';
    if (teamId.isEmpty) {
      return;
    }

    if (!grintaPlayerMemberIdsNeedBackfill(
      rawMemberIds: rawMemberIds ?? team.grintaPlayerMemberIds,
      grintaPlayers: team.grintaPlayers,
    )) {
      return;
    }

    final List<String> memberIds =
        grintaPlayerMemberIdsFromGrintaPlayers(team.grintaPlayers);
    if (memberIds.isEmpty) {
      return;
    }

    await _collection.doc(teamId).update(<String, dynamic>{
      keyTeamGrintaPlayerMemberIds: memberIds,
    });
    team.grintaPlayerMemberIds = memberIds;
  }

  static List<Team> _mergeTeamsByKey(Iterable<Team> teams) {
    final Map<String, Team> byKey = <String, Team>{};
    for (final Team team in teams) {
      final String teamId = team.keyTeam?.trim() ?? '';
      if (teamId.isEmpty) {
        continue;
      }
      byKey[teamId] = team;
    }
    return byKey.values.toList();
  }

  /// WATCH TEAMS WHERE [keyTeamGrintaPlayerMemberIds] CONTAINS MEMBER ID
  Stream<List<Team>> watchTeamsByGrintaPlayerMemberId(String memberId) =>
      streamTeamsByGrintaPlayerMemberId(memberId);

  /// WATCH grinta roster teams for [player] (indexed query + one-time roster scan).
  Stream<List<Team>> watchTeamsForPlayerGrintaMembership(Player player) {
    final Set<String> lookupIds = playerMemberLookupIds(player);
    if (lookupIds.isEmpty) {
      return Stream<List<Team>>.value(const <Team>[]);
    }

    const method = 'watchTeamsForPlayerGrintaMembership';
    final queryContext =
        '$keyTeamGrintaPlayerMemberIds arrayContainsAnyOf '
        '${lookupIds.join('|')}, $keyTeamIsVisible==true';

    return _withReadErrorLogging(
      method: method,
      queryContext: queryContext,
      stream: Stream.fromFuture(_resolveGrintaMemberTeams(lookupIds))
          .asyncExpand((List<Team> initialTeams) {
        return _streamTeamsByGrintaPlayerMemberIds(lookupIds).map(
          (List<Team> indexedTeams) =>
              _mergeTeamsByKey(<Team>[...initialTeams, ...indexedTeams]),
        );
      }),
    );
  }

  /// Live updates for every candidate member id (canonical + legacy aliases).
  Stream<List<Team>> _streamTeamsByGrintaPlayerMemberIds(Set<String> memberIds) {
    final List<String> trimmedIds = memberIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toList();
    if (trimmedIds.isEmpty) {
      return Stream<List<Team>>.value(const <Team>[]);
    }
    if (trimmedIds.length == 1) {
      return _streamTeamsByGrintaPlayerMemberIdIndexed(trimmedIds.first);
    }

    final StreamController<List<Team>> controller =
        StreamController<List<Team>>.broadcast();
    final Map<String, List<Team>> latestByMemberId = <String, List<Team>>{};
    final List<StreamSubscription<List<Team>>> subscriptions =
        <StreamSubscription<List<Team>>>[];

    void emitMerged() {
      if (controller.isClosed) return;
      controller.add(
        _mergeTeamsByKey(
          latestByMemberId.values.expand((List<Team> teams) => teams),
        ),
      );
    }

    for (final String memberId in trimmedIds) {
      subscriptions.add(
        _streamTeamsByGrintaPlayerMemberIdIndexed(memberId).listen(
          (List<Team> teams) {
            latestByMemberId[memberId] = teams;
            emitMerged();
          },
          onError: controller.addError,
        ),
      );
    }

    controller.onCancel = () async {
      for (final StreamSubscription<List<Team>> sub in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  /// GET TEAMS FOR A MANAGER
  Future<List<Team>> getTeamsForAManger(String uid) async {
    const method = 'getTeamsForAManger';
    final queryContext =
        '$keyTeamIsGrinta==true, $keyTeamManagers arrayContains $uid, '
        '$keyTeamIsVisible==true';
    try {
      final query = await _collection
          .where(keyTeamIsGrinta, isEqualTo: true)
          .where(keyTeamManagers, arrayContains: uid)
          .where(keyTeamIsVisible, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      _logFirestoreReadError(
        method: method,
        queryContext: queryContext,
        error: e,
      );
      rethrow;
    }
  }

  /// STREAM TEAMS FOR A MANAGER
  Stream<List<Team>> streamTeamsForAManger(String uid) {
    const method = 'streamTeamsForAManger';
    final queryContext =
        '$keyTeamIsGrinta==true, $keyTeamManagers arrayContains $uid, '
        '$keyTeamIsVisible==true';
    return _withReadErrorLogging(
      method: method,
      queryContext: queryContext,
      stream: _collection
          .where(keyTeamIsGrinta, isEqualTo: true)
          .where(keyTeamManagers, arrayContains: uid)
          .where(keyTeamIsVisible, isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Team.fromDocumentSnapshot(doc))
              .toList()),
    );
  }

  /// WATCH TEAMS FOR A MANAGER
  Stream<List<Team>> watchTeamsForAManger(String uid) =>
      streamTeamsForAManger(uid);

  /// GET TEAMS FOR AN OWNER (creator uid)
  Future<List<Team>> getTeamsByOwnerUid(String userId) async {
    const method = 'getTeamsByOwnerUid';
    final queryContext =
        '$keyTeamIsGrinta==true, $keyTeamUid==$userId, '
        '$keyTeamIsVisible==true';
    try {
      final query = await _collection
          .where(keyTeamIsGrinta, isEqualTo: true)
          .where(keyTeamUid, isEqualTo: userId)
          .where(keyTeamIsVisible, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      _logFirestoreReadError(
        method: method,
        queryContext: queryContext,
        error: e,
      );
      rethrow;
    }
  }

  /// STREAM TEAMS FOR AN OWNER (creator uid)
  Stream<List<Team>> streamTeamsByOwnerUid(String userId) {
    const method = 'streamTeamsByOwnerUid';
    final queryContext =
        '$keyTeamIsGrinta==true, $keyTeamUid==$userId, '
        '$keyTeamIsVisible==true';
    return _withReadErrorLogging(
      method: method,
      queryContext: queryContext,
      stream: _collection
          .where(keyTeamIsGrinta, isEqualTo: true)
          .where(keyTeamUid, isEqualTo: userId)
          .where(keyTeamIsVisible, isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Team.fromDocumentSnapshot(doc))
              .toList()),
    );
  }

  /// WATCH TEAMS FOR AN OWNER (creator uid)
  Stream<List<Team>> watchTeamsByOwnerUid(String userId) =>
      streamTeamsByOwnerUid(userId);

  /// GET BY CLUB ID
  Future<List<Team>> getTeamsByClubId(String clubId) async {
    try {
      final query = await _collection
          .where(keyTeamClubId, isEqualTo: clubId)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamTeamsByClubId(String clubId) {
    return _collection
        .where(keyTeamClubId, isEqualTo: clubId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchTeamsByClubId(String clubId) =>
      streamTeamsByClubId(clubId);

  /// GET BY SEASON ID
  Future<List<Team>> getTeamsBySeasonId(String seasonId) async {
    try {
      final query = await _collection
          .where(keyTeamSeasonID, isEqualTo: seasonId)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamTeamsBySeasonId(String seasonId) {
    return _collection
        .where(keyTeamSeasonID, isEqualTo: seasonId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchTeamsBySeasonId(String seasonId) =>
      streamTeamsBySeasonId(seasonId);

  /// GET BY CATEGORY
  Future<List<Team>> getTeamsByCategory(String category) async {
    try {
      final query = await _collection
          .where(keyTeamCategory, isEqualTo: category)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamTeamsByCategory(String category) {
    return _collection
        .where(keyTeamCategory, isEqualTo: category)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchTeamsByCategory(String category) =>
      streamTeamsByCategory(category);

  /// GET BY SUBCATEGORY
  Future<List<Team>> getTeamsBySubCategory(String subCategory) async {
    try {
      final query = await _collection
          .where(keyTeamSubCategory, isEqualTo: subCategory)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamTeamsBySubCategory(String subCategory) {
    return _collection
        .where(keyTeamSubCategory, isEqualTo: subCategory)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchTeamsBySubCategory(String subCategory) =>
      streamTeamsBySubCategory(subCategory);

  /// GET BY CHAMPIONSHIP TYPE
  Future<List<Team>> getTeamsByChType(String chType) async {
    try {
      final query = await _collection
          .where(keyTeamChType, isEqualTo: chType)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamTeamsByChType(String chType) {
    return _collection
        .where(keyTeamChType, isEqualTo: chType)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchTeamsByChType(String chType) =>
      streamTeamsByChType(chType);

  /// GET BY SOCCER TYPE
  Future<List<Team>> getTeamsBySoccerType(int soccerType) async {
    try {
      final query = await _collection
          .where(keyTeamSoccerType, isEqualTo: soccerType)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamTeamsBySoccerType(int soccerType) {
    return _collection
        .where(keyTeamSoccerType, isEqualTo: soccerType)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchTeamsBySoccerType(int soccerType) =>
      streamTeamsBySoccerType(soccerType);

  /// GET VISIBLE TEAMS
  Future<List<Team>> getVisibleTeams() async {
    try {
      final query = await _collection
          .where(keyTeamIsVisible, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamVisibleTeams() {
    return _collection
        .where(keyTeamIsVisible, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchVisibleTeams() => streamVisibleTeams();

  /// GET COMPETITION TEAMS
  Future<List<Team>> getCompetitionTeams() async {
    try {
      final query = await _collection
          .where(keyTeamIsCompetition, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamCompetitionTeams() {
    return _collection
        .where(keyTeamIsCompetition, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchCompetitionTeams() => streamCompetitionTeams();

  /// GET TRACKER TEAMS
  Future<List<Team>> getTeamsWithTracker() async {
    try {
      final query = await _collection
          .where('withTracker', isEqualTo: true)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamTeamsWithTracker() {
    return _collection
        .where('withTracker', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchTeamsWithTracker() => streamTeamsWithTracker();

  /// GET BY CLUB + SEASON
  Future<List<Team>> getTeamsByClubAndSeason({
    required String clubId,
    required String seasonId,
  }) async {
    try {
      final query = await _collection
          .where(keyTeamClubId, isEqualTo: clubId)
          .where(keyTeamSeasonID, isEqualTo: seasonId)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamTeamsByClubAndSeason({
    required String clubId,
    required String seasonId,
  }) {
    return _collection
        .where(keyTeamClubId, isEqualTo: clubId)
        .where(keyTeamSeasonID, isEqualTo: seasonId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchTeamsByClubAndSeason({
    required String clubId,
    required String seasonId,
  }) =>
      streamTeamsByClubAndSeason(clubId: clubId, seasonId: seasonId);

  /// GET BY CLUB + CATEGORY
  Future<List<Team>> getTeamsByClubAndCategory({
    required String clubId,
    required String category,
  }) async {
    try {
      final query = await _collection
          .where(keyTeamClubId, isEqualTo: clubId)
          .where(keyTeamCategory, isEqualTo: category)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamTeamsByClubAndCategory({
    required String clubId,
    required String category,
  }) {
    return _collection
        .where(keyTeamClubId, isEqualTo: clubId)
        .where(keyTeamCategory, isEqualTo: category)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchTeamsByClubAndCategory({
    required String clubId,
    required String category,
  }) =>
      streamTeamsByClubAndCategory(clubId: clubId, category: category);

  /// GET ONE TEAM BY NAME
  Future<List<Team>> getTeamsByName(String name) async {
    try {
      final query = await _collection
          .where(keyTeamName, isEqualTo: name)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Team>> streamTeamsByName(String name) {
    return _collection
        .where(keyTeamName, isEqualTo: name)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<Team>> watchTeamsByName(String name) => streamTeamsByName(name);

  /// UPDATE VISIBILITY
  Future<void> updateVisibility({
    required String teamId,
    required bool isVisible,
  }) async {
    try {
      await _collection.doc(teamId).update({
        keyTeamIsVisible: isVisible,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE TRACKER
  Future<void> updateWithTracker({
    required String teamId,
    required bool withTracker,
  }) async {
    try {
      await _collection.doc(teamId).update({
        'withTracker': withTracker,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE PLAYERS
  Future<void> updatePlayers({
    required String teamId,
    required List<dynamic> players,
  }) async {
    try {
      await _collection.doc(teamId).update({
        keyTeamPlayers: players,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// ADD PLAYER
  Future<void> addPlayer({
    required String teamId,
    required dynamic playerId,
  }) async {
    try {
      final memberId = playerId?.toString().trim() ?? '';
      if (memberId.isNotEmpty) {
        await SubscriptionLimitsService.instance.assertCanAddPlayer(
          teamId: teamId,
          memberId: memberId,
        );
      }

      await _collection.doc(teamId).update({
        keyTeamPlayers: FieldValue.arrayUnion([playerId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// REMOVE PLAYER
  Future<void> removePlayer({
    required String teamId,
    required dynamic playerId,
  }) async {
    try {
      await _collection.doc(teamId).update({
        keyTeamPlayers: FieldValue.arrayRemove([playerId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE USERS
  Future<void> updateUsers({
    required String teamId,
    required List<dynamic> users,
  }) async {
    try {
      await _collection.doc(teamId).update({
        keyTeamUsers: users,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// ADD USER
  Future<void> addUser({
    required String teamId,
    required dynamic userId,
  }) async {
    try {
      await _collection.doc(teamId).update({
        keyTeamUsers: FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// REMOVE USER
  Future<void> removeUser({
    required String teamId,
    required dynamic userId,
  }) async {
    try {
      await _collection.doc(teamId).update({
        keyTeamUsers: FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE MANAGERS
  Future<void> updateManagers({
    required String teamId,
    required List<dynamic> managers,
  }) async {
    try {
      await _collection.doc(teamId).update({
        keyTeamManagers: managers,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// ADD MANAGER
  Future<void> addManager({
    required String teamId,
    required dynamic managerId,
  }) async {
    try {
      await _collection.doc(teamId).update({
        keyTeamManagers: FieldValue.arrayUnion([managerId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// REMOVE MANAGER
  Future<void> removeManager({
    required String teamId,
    required dynamic managerId,
  }) async {
    try {
      await _collection.doc(teamId).update({
        keyTeamManagers: FieldValue.arrayRemove([managerId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE OWNERS
  Future<void> updateOwners({
    required String teamId,
    required List<dynamic> owners,
  }) async {
    try {
      await _collection.doc(teamId).update({
        'owners': owners,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// ADD OWNER
  Future<void> addOwner({
    required String teamId,
    required dynamic ownerId,
  }) async {
    try {
      await _collection.doc(teamId).update({
        'owners': FieldValue.arrayUnion([ownerId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// REMOVE OWNER
  Future<void> removeOwner({
    required String teamId,
    required dynamic ownerId,
  }) async {
    try {
      await _collection.doc(teamId).update({
        'owners': FieldValue.arrayRemove([ownerId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE COMPETITIONS
  Future<void> updateCompetitions({
    required String teamId,
    required List<Competition> competitions,
  }) async {
    try {
      await _collection.doc(teamId).update({
        keyTeamCompetitions: competitions.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// ADD COMPETITION
  Future<void> addCompetition({
    required String teamId,
    required Competition competition,
  }) async {
    try {
      final team = await getTeamById(teamId);
      if (team == null) {
        throw Exception('Team introuvable');
      }

      final competitions = List<Competition>.from(team.competitions ?? []);
      competitions.add(competition);

      await _collection.doc(teamId).update({
        keyTeamCompetitions: competitions.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// REMOVE COMPETITION BY ID
  Future<void> removeCompetitionById({
    required String teamId,
    required String competitionId,
  }) async {
    try {
      final team = await getTeamById(teamId);
      if (team == null) {
        throw Exception('Team introuvable');
      }

      final competitions = List<Competition>.from(team.competitions ?? [])
        ..removeWhere((e) => e.competitionID == competitionId);

      await _collection.doc(teamId).update({
        keyTeamCompetitions: competitions.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// REPLACE COMPETITION
  Future<void> upsertCompetition({
    required String teamId,
    required Competition competition,
  }) async {
    try {
      final team = await getTeamById(teamId);
      if (team == null) {
        throw Exception('Team introuvable');
      }

      final competitions = List<Competition>.from(team.competitions ?? []);

      final index = competitions.indexWhere(
            (e) => e.competitionID == competition.competitionID,
      );

      if (index >= 0) {
        competitions[index] = competition;
      } else {
        competitions.add(competition);
      }

      await _collection.doc(teamId).update({
        keyTeamCompetitions: competitions.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  static Set<String> _managerIdsFromTeam(Team team) {
    final Set<String> ids = <String>{};
    for (final dynamic raw in team.managers ?? const <dynamic>[]) {
      if (raw is! String) {
        continue;
      }
      final String id = raw.trim();
      if (id.isNotEmpty) {
        ids.add(id);
      }
    }
    return ids;
  }
}