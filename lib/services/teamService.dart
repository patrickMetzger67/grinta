import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/team.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'team';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

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
    try {
      final query = await _collection
          .where(keyTeamSeasonID, isEqualTo: seasonId)
          .where(keyTeamManagers, arrayContains: userId)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM BY SEASON ID + MANAGER USER ID
  Stream<List<Team>> streamTeamsBySeasonIdAndManager({
    required String seasonId,
    required String userId,
  }) {
    return _collection
        .where(keyTeamSeasonID, isEqualTo: seasonId)
        .where(keyTeamManagers, arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
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

  /// DELETE
  Future<void> deleteTeam(String teamId) async {
    try {
      await _collection.doc(teamId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// GET TEAMS FOR A PLAYER
  Future<List<Team>> getTeamsByPlayerId(String playerId) async {
    try {
      final query = await _collection
          .where(keyTeamPlayers, arrayContains: playerId)
          .where(keyTeamIsVisible, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM TEAMS FOR A PLAYER
  Stream<List<Team>> streamTeamsByPlayerId(String playerId) {
    return _collection
        .where(keyTeamPlayers, arrayContains: playerId)
        .where(keyTeamIsVisible, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  /// WATCH TEAMS FOR A PLAYER
  Stream<List<Team>> watchTeamsByPlayerId(String playerId) =>
      streamTeamsByPlayerId(playerId);

  /// GET TEAMS FOR A MANAGER
  Future<List<Team>> getTeamsForAManger(String uid) async {
    try {
      final query = await _collection
          .where(keyTeamManagers, arrayContains: uid)
          .where(keyTeamIsVisible, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM TEAMS FOR A MANAGER
  Stream<List<Team>> streamTeamsForAManger(String uid) {
    return _collection
        .where(keyTeamManagers, arrayContains: uid)
        .where(keyTeamIsVisible, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromDocumentSnapshot(doc)).toList());
  }

  /// WATCH TEAMS FOR A MANAGER
  Stream<List<Team>> watchTeamsForAManger(String uid) =>
      streamTeamsForAManger(uid);

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
}