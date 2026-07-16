import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'notification';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  static bool isNotificationUnviewed(NotificationApp notification) {
    return notification.isViewed != true;
  }

  static bool isNotificationUnviewedData(Map<String, dynamic> data) {
    return data[keyNotifIsViewed] != true;
  }

  static List<NotificationApp> sortNotificationsNewestFirst(
    List<NotificationApp> notifications,
  ) {
    final sorted = List<NotificationApp>.from(notifications);
    sorted.sort((a, b) {
      final aTime = a.dateTimeCreated?.millisecondsSinceEpoch ?? 0;
      final bTime = b.dateTimeCreated?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  List<NotificationApp> _parseUnviewedNotifications(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return sortNotificationsNewestFirst(
      snapshot.docs
          .map((doc) => NotificationApp.fromSnapshot(doc))
          .where(isNotificationUnviewed)
          .toList(),
    );
  }

  void _logFirestoreReadError({
    required String method,
    required String queryContext,
    required Object error,
  }) {
    if (error is FirebaseException) {
      debugPrint(
        'Firestore read failed in NotificationService.$method: '
        'collection=$collectionName filters=[$queryContext] '
        'code=${error.code} message=${error.message}',
      );
      if (error.code == 'failed-precondition') {
        debugPrint(
          'Firestore index may be missing for $method. Full error: $error',
        );
      }
    } else {
      debugPrint(
        'Unexpected error in NotificationService.$method: '
        'collection=$collectionName filters=[$queryContext] $error',
      );
    }
  }

  Stream<T> _withReadErrorLogging<T>({
    required Stream<T> stream,
    required String method,
    required String queryContext,
  }) {
    return stream.handleError((Object error, StackTrace stackTrace) {
      _logFirestoreReadError(
        method: method,
        queryContext: queryContext,
        error: error,
      );
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

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

  /// GET UNVIEWED BY PLAYER ID
  ///
  /// Queries by [keyNotifPlayerId] only, then filters/sorts client-side so we
  /// do not require a composite index and still treat missing [keyNotifIsViewed]
  /// as unread.
  Future<List<NotificationApp>> getUnviewedNotificationsByPlayerId(
    String playerId,
  ) async {
    const method = 'getUnviewedNotificationsByPlayerId';
    final queryContext = '$keyNotifPlayerId==$playerId';
    try {
      final query = await _collection
          .where(keyNotifPlayerId, isEqualTo: playerId)
          .get();

      return _parseUnviewedNotifications(query);
    } catch (e) {
      _logFirestoreReadError(
        method: method,
        queryContext: queryContext,
        error: e,
      );
      rethrow;
    }
  }

  Stream<List<NotificationApp>> streamUnviewedNotificationsByPlayerId(
    String playerId,
  ) {
    const method = 'streamUnviewedNotificationsByPlayerId';
    final queryContext = '$keyNotifPlayerId==$playerId';
    return _withReadErrorLogging(
      method: method,
      queryContext: queryContext,
      stream: _collection
          .where(keyNotifPlayerId, isEqualTo: playerId)
          .snapshots()
          .map(_parseUnviewedNotifications),
    );
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

  /// Deletes every notification linked to [objectId] (no composite index).
  Future<int> deleteNotificationsByObjectId(String objectId) async {
    final String trimmed = objectId.trim();
    if (trimmed.isEmpty) {
      return 0;
    }

    final QuerySnapshot<Map<String, dynamic>> query = await _collection
        .where(keyNotifObjectId, isEqualTo: trimmed)
        .get();

    if (query.docs.isEmpty) {
      return 0;
    }

    const int batchLimit = 400;
    var deleted = 0;
    WriteBatch batch = _firestore.batch();
    var opsInBatch = 0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in query.docs) {
      batch.delete(doc.reference);
      opsInBatch++;
      deleted++;
      if (opsInBatch >= batchLimit) {
        await batch.commit();
        batch = _firestore.batch();
        opsInBatch = 0;
      }
    }

    if (opsInBatch > 0) {
      await batch.commit();
    }

    return deleted;
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

  Future<void> markAllNotificationsAsViewedForPlayer(String playerId) async {
    const method = 'markAllNotificationsAsViewedForPlayer';
    final queryContext = '$keyNotifPlayerId==$playerId';
    try {
      final query = await _collection
          .where(keyNotifPlayerId, isEqualTo: playerId)
          .get();

      final unviewedDocs = query.docs.where(
        (doc) => isNotificationUnviewedData(doc.data()),
      );
      if (unviewedDocs.isEmpty) return;

      final batch = _firestore.batch();
      final now = Timestamp.now();

      for (final doc in unviewedDocs) {
        batch.update(doc.reference, {
          keyNotifIsViewed: true,
          keyNotifDateTimeViewed: now,
        });
      }

      await batch.commit();
    } catch (e) {
      _logFirestoreReadError(
        method: method,
        queryContext: queryContext,
        error: e,
      );
      rethrow;
    }
  }
}
