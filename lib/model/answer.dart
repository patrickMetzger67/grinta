import 'package:cloud_firestore/cloud_firestore.dart';
import 'training.dart';


String keyAnswerObjectId = 'objectId';
String keyAnswerUserId = 'userId';
String keyAnswerDateTimeEvent = 'dateTimeEvent';
String keyAnswerCreateDateTime = 'createDateTime';
String keyAnswerUpdateDateTime = 'updateDateTime';
String keyAnswerIsTraining = 'isTraining';
String keyAnswerIsPresent = 'isPresent';
String keyAnswerPlayerTraining = 'playerTraining';


class Answer {
  String? objectId;  // Convocation, event or training id
  String? userId;    // userId if event, memberId if training or match
  Timestamp? dateTimEvent;
  Timestamp? createDateTime;
  Timestamp? updateDateTime;
  bool? isTraining;
  bool? isPresent;   // if not training
  PlayerTraining? playerTraining; // if training
  DocumentReference? ref;

  Answer({
    this.objectId,
    this.userId,
    this.createDateTime,
    this.updateDateTime,
    this.isTraining,
    this.isPresent,
    this.playerTraining,
    this.dateTimEvent
  });

  fromMap(Map<String, dynamic>? map) {
    if(map![keyAnswerObjectId] != null) {
      objectId = map[keyAnswerObjectId];
    } else {
      objectId = '';
    }

    if(map[keyAnswerUserId] != null) {
      userId = map[keyAnswerUserId];
    } else {
      userId = '';
    }

    if(map[keyAnswerIsTraining] != null) {
      isTraining = map[keyAnswerIsTraining];
    } else {
      isTraining = false;
    }

    if(map[keyAnswerIsPresent] != null) {
      isPresent= map[keyAnswerIsPresent];
    } else {
      isPresent = false;
    }

    if(map[keyAnswerPlayerTraining] != null) {
      playerTraining = PlayerTraining.fromMap(map[keyAnswerPlayerTraining]);
    }

    if(map[keyAnswerCreateDateTime] != null) {
      createDateTime = map[keyAnswerCreateDateTime];
    }

    if(map[keyAnswerUpdateDateTime] != null) {
      updateDateTime = map[keyAnswerUpdateDateTime];
    }

    if(map[keyAnswerDateTimeEvent] != null) {
      dateTimEvent = map[keyAnswerDateTimeEvent];
    }

  }

  Answer.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    ref = documentSnapshot.reference;
    Map<String, dynamic>? map = documentSnapshot.data() as Map<String, dynamic>?;
    fromMap(map!);
  }

  Answer.fromMap(Map<String, dynamic>? map) {
    fromMap(map!);
  }

  Map<String, dynamic> toMap() {

    Map<String, dynamic> map = {
      keyAnswerObjectId:objectId,
      keyAnswerUserId:userId,
      keyAnswerCreateDateTime:createDateTime,
      keyAnswerUpdateDateTime:updateDateTime,
      keyAnswerIsTraining:isTraining,
      keyAnswerIsPresent:isPresent,
      keyAnswerPlayerTraining:(playerTraining != null)?playerTraining!.toMap():null,
      keyAnswerDateTimeEvent:dateTimEvent,
    };
    return map;
  }

  @override
  String toString() {
    return 'Answer => objectId=$objectId userId=$userId dateTimeEvent=$dateTimEvent isTraining=$isTraining isPresent=$isPresent playerTraining=${playerTraining.toString()}';
  }

}