import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'notification';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// CREATE
  Future<String> createNotification(NotificationApp notification) async {
    try {
      final docRef = _collection.doc();

      notification.dateTimeCreated ??= Timestamp.now();
      notification.isViewed ??= false;

      await docRef.set(notification.toMap());
      notification.ref = docRef;
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// SET / UPSERT
  Future<void> setNotification(
    String notificationId,
    NotificationApp notification,
  ) async {
    try {
      notification.dateTimeCreated ??= Timestamp.now();
      notification.isViewed ??= false;

      final docRef = _collection.doc(notificationId);
      await docRef.set(notification.toMap(), SetOptions(merge: true));
      notification.ref = docRef;
    } catch (e) {
      rethrow;
    }
  }

  /// READ ONE
  Future<NotificationApp?> getNotificationById(String notificationId) async {
    try {
      final doc = await _collection.doc(notificationId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return NotificationApp.fromSnapshot(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ONE
  Stream<NotificationApp?> streamNotificationById(String notificationId) {
    return _collection.doc(notificationId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return NotificationApp.fromSnapshot(doc);
    });
  }

  /// READ ALL
  Future<List<NotificationApp>> getAllNotifications() async {
    try {
      final query = await _collection
          .orderBy(keyNotifDateTimeCreated, descending: true)
          .get();

      return query.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ALL
  Stream<List<NotificationApp>> streamAllNotifications() {
    return _collection
        .orderBy(keyNotifDateTimeCreated, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    });
  }

  /// UPDATE
  Future<void> updateNotification(NotificationApp notification) async {
    try {
      if (notification.ref == null) {
        throw Exception("La référence de la notification est nulle");
      }

      await notification.ref!.update(notification.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateNotificationById(
    String notificationId,
    NotificationApp notification,
  ) async {
    try {
      await _collection.doc(notificationId).update(notification.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _collection.doc(notificationId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNotificationByRef(NotificationApp notification) async {
    try {
      if (notification.ref == null) {
        throw Exception("La référence de la notification est nulle");
      }

      await notification.ref!.delete();
    } catch (e) {
      rethrow;
    }
  }

  /// GET BY USER ID
  Future<List<NotificationApp>> getNotificationsByUserId(String userId) async {
    try {
      final query = await _collection
          .where(keyNotifUserId, isEqualTo: userId)
          .orderBy(keyNotifDateTimeCreated, descending: true)
          .get();

      return query.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<NotificationApp>> streamNotificationsByUserId(String userId) {
    return _collection
        .where(keyNotifUserId, isEqualTo: userId)
        .orderBy(keyNotifDateTimeCreated, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    });
  }

  /// GET UNVIEWED BY USER ID
  Future<List<NotificationApp>> getUnviewedNotificationsByUserId(
    String userId,
  ) async {
    try {
      final query = await _collection
          .where(keyNotifUserId, isEqualTo: userId)
          .where(keyNotifIsViewed, isEqualTo: false)
          .orderBy(keyNotifDateTimeCreated, descending: true)
          .get();

      return query.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<NotificationApp>> streamUnviewedNotificationsByUserId(
    String userId,
  ) {
    return _collection
        .where(keyNotifUserId, isEqualTo: userId)
        .where(keyNotifIsViewed, isEqualTo: false)
        .orderBy(keyNotifDateTimeCreated, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    });
  }

  /// GET BY CLUB ID
  Future<List<NotificationApp>> getNotificationsByClubId(String clubId) async {
    try {
      final query = await _collection
          .where(keyNotifClubId, isEqualTo: clubId)
          .orderBy(keyNotifDateTimeCreated, descending: true)
          .get();

      return query.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<NotificationApp>> streamNotificationsByClubId(String clubId) {
    return _collection
        .where(keyNotifClubId, isEqualTo: clubId)
        .orderBy(keyNotifDateTimeCreated, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    });
  }

  /// GET BY OBJECT ID
  Future<List<NotificationApp>> getNotificationsByObjectId(
    String objectId,
  ) async {
    try {
      final query = await _collection
          .where(keyNotifObjectId, isEqualTo: objectId)
          .orderBy(keyNotifDateTimeCreated, descending: true)
          .get();

      return query.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<NotificationApp>> streamNotificationsByObjectId(String objectId) {
    return _collection
        .where(keyNotifObjectId, isEqualTo: objectId)
        .orderBy(keyNotifDateTimeCreated, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    });
  }

  /// GET BY TYPE
  Future<List<NotificationApp>> getNotificationsByType(NotifType type) async {
    try {
      final query = await _collection
          .where(keyNotifType, isEqualTo: type.toString())
          .orderBy(keyNotifDateTimeCreated, descending: true)
          .get();

      return query.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<NotificationApp>> streamNotificationsByType(NotifType type) {
    return _collection
        .where(keyNotifType, isEqualTo: type.toString())
        .orderBy(keyNotifDateTimeCreated, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .toList();
    });
  }

  /// MARK AS VIEWED
  Future<void> markNotificationAsViewed(String notificationId) async {
    try {
      await _collection.doc(notificationId).update({
        keyNotifIsViewed: true,
        keyNotifDateTimeViewed: Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllNotificationsAsViewedForUser(String userId) async {
    try {
      final query = await _collection
          .where(keyNotifUserId, isEqualTo: userId)
          .where(keyNotifIsViewed, isEqualTo: false)
          .get();

      if (query.docs.isEmpty) return;

      final batch = _firestore.batch();
      final now = Timestamp.now();

      for (final doc in query.docs) {
        batch.update(doc.reference, {
          keyNotifIsViewed: true,
          keyNotifDateTimeViewed: now,
        });
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
