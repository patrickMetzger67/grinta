import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/training.dart';

class TrainingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'training';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// CREATE
  Future<String> createTraining(Training training) async {
    try {
      final docRef = (training.trainingId != null && training.trainingId!.isNotEmpty)
          ? _collection.doc(training.trainingId)
          : _collection.doc();

      training.trainingId = docRef.id;

      await docRef.set(training.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// SET / UPSERT
  Future<void> setTraining(Training training) async {
    try {
      final docRef = (training.trainingId != null && training.trainingId!.isNotEmpty)
          ? _collection.doc(training.trainingId)
          : _collection.doc();

      training.trainingId = docRef.id;

      await docRef.set(training.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// READ ONE
  Future<Training?> getTrainingById(String trainingId) async {
    try {
      final doc = await _collection.doc(trainingId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return Training.fromDocumentSnapshot(doc);
    } catch (e) {
      rethrow;
    }
  }

  Future<Training?> getTrainingByDocId(String docId) async {
    try {
      final doc = await _collection.doc(docId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return Training.fromDocumentSnapshot(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ONE
  Stream<Training?> streamTrainingById(String trainingId) {
    return _collection.doc(trainingId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Training.fromDocumentSnapshot(doc);
    });
  }

  /// READ ALL
  Future<List<Training>> getAllTrainings() async {
    try {
      final query = await _collection.get();
      return query.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => Training.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ALL
  Stream<List<Training>> streamAllTrainings() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map((doc) => Training.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// UPDATE
  Future<void> updateTraining(Training training) async {
    try {
      if (training.docId == null || training.docId!.isEmpty) {
        throw Exception("trainingId null ou vide");
      }
      await _collection.doc(training.docId).update(training.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE
  Future<void> deleteTraining(String trainingId) async {
    try {
      await _collection.doc(trainingId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// GET BY CLUB ID
  Future<List<Training>> getTrainingsByClubId(String clubId) async {
    try {
      final query = await _collection
          .where(keyTgClubId, isEqualTo: clubId)
          .get();

      return query.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Training>> streamTrainingsByClubId(String clubId) {
    return _collection
        .where(keyTgClubId, isEqualTo: clubId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList());
  }

  /// GET BY SEASON ID
  Future<List<Training>> getTrainingsBySeasonId(String seasonId) async {
    try {
      final query = await _collection
          .where(keyTgSeasonId, isEqualTo: seasonId)
          .get();

      return query.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Training>> streamTrainingsBySeasonId(String seasonId) {
    return _collection
        .where(keyTgSeasonId, isEqualTo: seasonId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList());
  }

  /// GET BY TEAM ID
  Future<List<Training>> getTrainingsByTeamId(String teamId) async {
    try {
      final query = await _collection
          .where(keyTgTeamId, isEqualTo: teamId)
          .get();

      return query.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }
  Future<List<Training>> getTrainingsByTeamIdBetweenDates({
    required String teamId,
    required Timestamp start,
    required Timestamp end,
  }) async {
    try {
      final query = await _collection
          .where(keyTgTeamId, isEqualTo: teamId)
          .where(keyTgDateTime, isGreaterThanOrEqualTo: start)
          .where(keyTgDateTime, isLessThanOrEqualTo: end)
          .orderBy(keyTgDateTime)
          .get();

      return query.docs
          .map((doc) => Training.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Training>> streamTrainingsByTeamId(String teamId) {
    return _collection
        .where(keyTgTeamId, isEqualTo: teamId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList());
  }

  /// GET BY FIELD ID
  Future<List<Training>> getTrainingsByFieldId(String fieldId) async {
    try {
      final query = await _collection
          .where(keyTgFieldId, isEqualTo: fieldId)
          .get();

      return query.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Training>> streamTrainingsByFieldId(String fieldId) {
    return _collection
        .where(keyTgFieldId, isEqualTo: fieldId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList());
  }

  /// GET FINISHED TRAININGS
  Future<List<Training>> getFinishedTrainings() async {
    try {
      final query = await _collection
          .where(keyTgIsFinish, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Training>> streamFinishedTrainings() {
    return _collection
        .where(keyTgIsFinish, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList());
  }

  /// GET WITH TRACKER
  Future<List<Training>> getTrainingsWithTracker() async {
    try {
      final query = await _collection
          .where(keyTgWithTracker, isEqualTo: true)
          .get();

      return query.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Training>> streamTrainingsWithTracker() {
    return _collection
        .where(keyTgWithTracker, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList());
  }

  /// GET BY RECURRENT CODE
  Future<List<Training>> getTrainingsByReccurentCode(String reccurentCode) async {
    try {
      final query = await _collection
          .where(keyTgReccurentCode, isEqualTo: reccurentCode)
          .get();

      return query.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Training>> streamTrainingsByReccurentCode(String reccurentCode) {
    return _collection
        .where(keyTgReccurentCode, isEqualTo: reccurentCode)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList());
  }

  /// GET BY OWNER
  Future<List<Training>> getTrainingsByOwnerId(String ownerId) async {
    try {
      final query = await _collection
          .where(keyTgOwnerId, isEqualTo: ownerId)
          .get();

      return query.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Training>> streamTrainingsByOwnerId(String ownerId) {
    return _collection
        .where(keyTgOwnerId, isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList());
  }



  Stream<List<Training>> streamTrainingsBetweenDates({
    required Timestamp start,
    required Timestamp end,
  }) {
    return _collection
        .where(keyTgDateTime, isGreaterThanOrEqualTo: start)
        .where(keyTgDateTime, isLessThanOrEqualTo: end)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList());
  }

  /// GET BY CLUB + TEAM
  Future<List<Training>> getTrainingsByClubAndTeam({
    required String clubId,
    required String teamId,
  }) async {
    try {
      final query = await _collection
          .where(keyTgClubId, isEqualTo: clubId)
          .where(keyTgTeamId, isEqualTo: teamId)
          .get();

      return query.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Training>> streamTrainingsByClubAndTeam({
    required String clubId,
    required String teamId,
  }) {
    return _collection
        .where(keyTgClubId, isEqualTo: clubId)
        .where(keyTgTeamId, isEqualTo: teamId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Training.fromDocumentSnapshot(doc)).toList());
  }

  /// UPDATE FINISH STATUS
  Future<void> updateFinishStatus({
    required String trainingId,
    required bool isFinish,
  }) async {
    try {
      await _collection.doc(trainingId).update({
        keyTgIsFinish: isFinish,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE NOTIF BEFORE STATUS
  Future<void> updateNotifBeforeStatus({
    required String trainingId,
    required bool isNotifBeforeSended,
    Timestamp? dateTimeNotifBeforeSended,
  }) async {
    try {
      await _collection.doc(trainingId).update({
        keyTgIsNotifBeforeSended: isNotifBeforeSended,
        keyTgDateTimeNotifBeforeSended: dateTimeNotifBeforeSended,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE NOTIF AFTER STATUS
  Future<void> updateNotifAfterStatus({
    required String trainingId,
    required bool isNotifAfterSended,
    Timestamp? dateTimeNotifAfterSended,
  }) async {
    try {
      await _collection.doc(trainingId).update({
        keyTgIsNotifAfterSended: isNotifAfterSended,
        keyTgDateTimeNotifAfterSended: dateTimeNotifAfterSended,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE TRAINING TIMES
  Future<void> updateTrainingTimes({
    required String trainingId,
    Timestamp? trainingStartAt,
    Timestamp? trainingEndAt,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (trainingStartAt != null) {
        data[keyTgStartAt] = trainingStartAt;
      }
      if (trainingEndAt != null) {
        data[keyTgEndAt] = trainingEndAt;
      }

      if (data.isNotEmpty) {
        await _collection.doc(trainingId).update(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE TRACKER STATUS
  Future<void> updateTrackerStatus({
    required String trainingId,
    required bool withTracker,
  }) async {
    try {
      await _collection.doc(trainingId).update({
        keyTgWithTracker: withTracker,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE PLAYER TRAINING LIST
  Future<void> updatePlayerTraining({
    required String trainingId,
    required List<PlayerTraining> playerTraining,
  }) async {
    try {
      await _collection.doc(trainingId).update({
        keyTgPlayerTraining: playerTraining.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// ADD / REPLACE ONE PLAYER TRAINING
  Future<void> upsertOnePlayerTraining({
    required String trainingId,
    required PlayerTraining player,
  }) async {
    try {
      final training = await getTrainingById(trainingId);
      if (training == null) {
        throw Exception('Training introuvable');
      }

      final List<PlayerTraining> players =
      List<PlayerTraining>.from(training.playerTraining);

      final index = players.indexWhere((e) => e.playerId == player.playerId);

      if (index >= 0) {
        players[index] = player;
      } else {
        players.add(player);
      }

      await _collection.doc(trainingId).update({
        keyTgPlayerTraining: players.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// REMOVE ONE PLAYER TRAINING
  Future<void> removeOnePlayerTraining({
    required String trainingId,
    required String playerId,
  }) async {
    try {
      final training = await getTrainingById(trainingId);
      if (training == null) {
        throw Exception('Training introuvable');
      }

      final players = List<PlayerTraining>.from(training.playerTraining)
        ..removeWhere((e) => e.playerId == playerId);

      await _collection.doc(trainingId).update({
        keyTgPlayerTraining: players.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE GROUPS
  Future<void> updateTrainingGroups({
    required String trainingId,
    required List<TrainingGroup> groups,
  }) async {
    try {
      await _collection.doc(trainingId).update({
        'trainingGroup': groups.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE WORKSHOPS
  Future<void> updateTrainingWorkshops({
    required String trainingId,
    required List<TrainingWorkshop> workshops,
  }) async {
    try {
      await _collection.doc(trainingId).update({
        'trainingWorkshop': workshops.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// UPDATE WORKSHOPS COMPLETED
  Future<void> updateTrainingWorkshopsCompleted({
    required String trainingId,
    required List<TrainingWorkshopCompleted> completed,
  }) async {
    try {
      await _collection.doc(trainingId).update({
        'trainingWorkshopCompleted': completed.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// DUPLICATE TRAINING
  Future<String> duplicateTraining(Training training) async {
    try {
      final newDoc = _collection.doc();

      final newTraining = Training(
        trainingId: newDoc.id,
        seasonId: training.seasonId,
        clubId: training.clubId,
        dateTime: training.dateTime,
        dateTg: training.dateTg,
        teamId: training.teamId,
        fieldId: training.fieldId,
        duration: training.duration,
        playerTraining: training.playerTraining.map((e) => e.toMap()).toList(),
        isFinish: training.isFinish,
        withRPE: training.withRPE,
        withVICP: training.withVICP,
        isNotifBeforeSended: training.isNotifBeforeSended,
        dateTimeNotifBeforeSended: training.dateTimeNotifBeforeSended,
        isNotifAfterSended: training.isNotifAfterSended,
        dateTimeNotifAfterSended: training.dateTimeNotifAfterSended,
        sessionType: training.sessionType,
        gameState: training.gameState,
        fieldPosition: training.fieldPosition,
        gamePhases: training.gamePhases,
        mentalDominant: training.mentalDominant,
        associatedTechnicalMeans: training.associatedTechnicalMeans,
        athleticDominant: training.athleticDominant,
        gamePrinciple: training.gamePrinciple,
        tacticalPrinciple: training.tacticalPrinciple,
        version: training.version,
        isReccurent: training.isReccurent,
        reccurentCode: training.reccurentCode,
        reccurentDay: training.reccurentDay,
        reccurentStart: training.reccurentStart,
        reccurentEnd: training.reccurentEnd,
        startTime: training.startTime,
        endTime: training.endTime,
        withTracker: training.withTracker,
        trainingStartAt: training.trainingStartAt,
        trainingEndAt: training.trainingEndAt,
        ownerId: training.ownerId,
        trainingGroup: training.trainingGroup
            .map((e) => e.copyWith(players: List<String>.from(e.players)))
            .toList(),
        trainingWorkshop: training.trainingWorkshop
            .map((e) => TrainingWorkshop(
          id: e.id,
          name: e.name,
          description: e.description,
        ))
            .toList(),
        trainingWorkshopCompleted: training.trainingWorkshopCompleted
            .map((e) => e.copyWith())
            .toList(),
      );

      await newDoc.set(newTraining.toMap());
      return newDoc.id;
    } catch (e) {
      rethrow;
    }
  }
  /// GET TRAININGS BY TEAM + withTracker = true + isTrackerDataUploaded = false
  Future<List<Training>> getTrainingsToUploadTrackerData(String teamId) async {
    try {
      final query = await _collection
          .where(keyTgTeamId, isEqualTo: teamId)
          .where(keyTgWithTracker, isEqualTo: true)
          .where(keyTgIsTrackerDataUploaded, isEqualTo: false)
          .orderBy(keyTgDateTime, descending: false)
          .get();

      return query.docs
          .map((doc) => Training.fromDocumentSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error in getTrainingsToUploadTrackerData(teamId: $teamId): '
            '${e.code} - ${e.message}',
      );
      return [];
    } catch (e) {
      debugPrint(
        'Unexpected error in getTrainingsToUploadTrackerData(teamId: $teamId): $e',
      );
      return [];
    }
  }
  Stream<List<Training>> streamTrainingsByTeamIdBetweenDates({
    required String teamId,
    required Timestamp start,
    required Timestamp end,
  }) {
    return _collection
        .where(keyTgTeamId, isEqualTo: teamId)
        .where(keyTgDateTime, isGreaterThanOrEqualTo: start)
        .where(keyTgDateTime, isLessThan: end)
        .orderBy(keyTgDateTime)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Training.fromDocumentSnapshot(doc))
          .toList();
    });
  }
  /// STREAM TRAININGS BY TEAM + withTracker = true + isTrackerDataUploaded = false
  Stream<List<Training>> streamTrainingsToUploadTrackerData(String teamId) {

    return _collection
        .where(keyTgTeamId, isEqualTo: teamId)
        .where(keyTgWithTracker, isEqualTo: true)
        .where(keyTgIsTrackerDataUploaded, isEqualTo: false)
        .orderBy(keyTgDateTime, descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Training.fromDocumentSnapshot(doc))
          .toList(),
    )
        .handleError((error) {
      if (error is FirebaseException) {
        debugPrint(
          'Firestore error in streamTrainingsToUploadTrackerData(teamId: $teamId): '
              '${error.code} - ${error.message}',
        );
      } else {
        debugPrint(
          'Unexpected error in streamTrainingsToUploadTrackerData(teamId: $teamId): $error',
        );
      }
    });
  }
}