import 'package:cloud_firestore/cloud_firestore.dart';

enum NotifType {
  convocation,
  convocationFeedback,
  partnerEvent,
  playerFollowed,
  highlights,
  RPEBefore,
  RPEAfter,
  VICP,
  mvpOpenVoting,
  mvpElected,
  mvpInformVotingClosed,
  chatGroup,
  chat,
  event,
  match,
  userAppCreation,
  payment,
  trainingReminder,
  matchOpponentStatsReminder,
  pendingInvitation,
}

enum SendBy { notification, sms, email }

String keyNotifUserId = 'userId';
String keyNotifType = 'type';
String keyNotifSendBy = 'sendBy';
String keyNotifTitle = 'title';
String keyNotifbody = 'body';
String keyNotifObjectId = 'objectId';
String keyNotifIsViewed = 'isViewed';
String keyNotifDateTimeCreated = 'dateTimeCreated';
String keyNotifDateTimeViewed = 'dateTimeViewed';
String keyNotifCreatedUserId = 'createdUserId';
String keyNotifClubId = 'clubId';
String keyNotifPlayerId = 'playerId';
String keyNotifBrand = 'brand';
String keyNotifApp = 'app';

/// Grinta in-app / push docs on the shared Firebase project.
/// Aserstein listeners must ignore `brand == grinta` / `app == grinta`.
const String kNotificationBrandGrinta = 'grinta';

class NotificationApp {
  String? userId;
  NotifType? type;
  SendBy? sendBy;
  String? title;
  String? body;
  String? objectId;
  bool? isViewed;
  Timestamp? dateTimeCreated;
  Timestamp? dateTimeViewed;
  String? createdUserId;
  String? clubId;
  String? playerId;
  String? brand;
  DocumentReference? ref;

  NotificationApp(
      {this.userId,
      this.type,
      this.sendBy,
      this.title,
      this.body,
      this.objectId,
      this.isViewed = false,
      this.dateTimeCreated,
      this.createdUserId,
      this.clubId,
      this.playerId,
      this.brand,
      });

  NotificationApp.fromSnapshot(DocumentSnapshot documentSnapshot) {
    ref = documentSnapshot.reference;

    Map<String, dynamic>? map = documentSnapshot.data() as Map<String, dynamic>?;

    if (map![keyNotifUserId] != null) {
      userId = map[keyNotifUserId];
    } else {
      userId = '';
    }
    if (map[keyNotifType] != null) {
      switch (map[keyNotifType]) {
        case "NotifType.event":
          type = NotifType.event;
          break;
        case "NotifType.chat":
          type = NotifType.chat;
          break;
        case "NotifType.chatGroup":
          type = NotifType.chatGroup;
          break;
        case "NotifType.mvpInformVotingClosed":
          type = NotifType.mvpInformVotingClosed;
          break;
        case 'NotifType.mvpElected':
          type = NotifType.mvpElected;
          break;
        case 'NotifType.mvpOpenVoting':
          type = NotifType.mvpOpenVoting;
          break;
        case 'NotifType.RPEBefore':
          type = NotifType.RPEBefore;
          break;
        case 'NotifType.RPEAfter':
          type = NotifType.RPEAfter;
          break;
        case 'NotifType.VICP':
          type = NotifType.VICP;
          break;
        case 'NotifType.convocation':
          type = NotifType.convocation;
          break;
        case 'NotifType.convocationFeedback':
          type = NotifType.convocationFeedback;
          break;
        case 'NotifType.partnerEvent':
          type = NotifType.partnerEvent;
          break;
        case 'NotifType.playerFollowed':
          type = NotifType.playerFollowed;
          break;
        case 'NotifType.highlights':
          type = NotifType.highlights;
          break;
        case 'NotifType.match':
          type = NotifType.match;
          break;
        case 'NotifType.trainingReminder':
          type = NotifType.trainingReminder;
          break;
        case 'NotifType.matchOpponentStatsReminder':
          type = NotifType.matchOpponentStatsReminder;
          break;
        case 'NotifType.pendingInvitation':
          type = NotifType.pendingInvitation;
          break;
      }
    }
    if (map[keyNotifSendBy] != null) {
      switch (map[keyNotifSendBy]) {
        case 'SendBy.notification':
          sendBy = SendBy.notification;
          break;
        case 'SendBy.email':
          sendBy = SendBy.email;
          break;
      }
    }
    if (map[keyNotifTitle] != null) {
      title = map[keyNotifTitle];
    } else {
      title = '';
    }
    if (map[keyNotifbody] != null) {
      body = map[keyNotifbody];
    } else {
      body = '';
    }

    if (map[keyNotifObjectId] != null) {
      objectId = map[keyNotifObjectId];
    } else {
      objectId = '';
    }

    if (map[keyNotifIsViewed] != null) {
      isViewed = map[keyNotifIsViewed];
    } else {
      isViewed = false;
    }

    if (map[keyNotifDateTimeCreated] != null) {
      dateTimeCreated = map[keyNotifDateTimeCreated];
    }

    if (map[keyNotifDateTimeViewed] != null) {
      dateTimeViewed = map[keyNotifDateTimeViewed];
    }

    if(map[keyNotifCreatedUserId] != null) {
      createdUserId = map[keyNotifCreatedUserId];
    }
    if(map[keyNotifClubId] != null) {
      clubId = map[keyNotifClubId];
    } else {
      clubId = '';
    }
    if (map[keyNotifPlayerId] != null) {
      playerId = map[keyNotifPlayerId];
    }
    if (map[keyNotifBrand] != null) {
      brand = map[keyNotifBrand]?.toString();
    }
  }

  Map<String, dynamic> toMap() {
    final resolvedBrand = (brand ?? '').trim().isEmpty
        ? kNotificationBrandGrinta
        : brand!.trim();
    Map<String, dynamic> map = {
      keyNotifUserId: userId,
      keyNotifType: type.toString(),
      keyNotifSendBy: sendBy.toString(),
      keyNotifTitle: title,
      keyNotifbody: body,
      keyNotifObjectId: objectId,
      keyNotifIsViewed: isViewed,
      keyNotifDateTimeCreated: dateTimeCreated,
      keyNotifDateTimeViewed: dateTimeViewed,
      keyNotifCreatedUserId: createdUserId,
      keyNotifClubId: clubId,
      keyNotifPlayerId: playerId,
      keyNotifBrand: resolvedBrand,
      keyNotifApp: resolvedBrand,
    };
    return map;
  }

  @override
  String toString() {
    return 'Notification: userId:$userId ' +
        'type:${type.toString()} ' +
        'sendBy:${sendBy.toString()} ' +
        'title:$title ' +
        'body:$body ' +
        'objectId=$objectId ' +
        'isViewed:${isViewed.toString()} ' +
        'dateTimeCreated:${dateTimeCreated.toString()} ' +
        'dateTimeViewed:${dateTimeViewed.toString()} ' +
        'createUserId:$createdUserId ' +
        'clubId:$clubId ' +
        'playerId:$playerId';
  }
}
class Token {
  final int type; // 1=notificaton, 2=SMS
  final String value;
  final String userId;

  Token(this.type, this.value, this.userId);
  @override
  String toString() {

    return 'Token => type=$type ' +
        'value=$value ' +
        'userId=$userId';
  }
}