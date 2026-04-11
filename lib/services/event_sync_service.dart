import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/tracker/eventSync.dart';

class EventSyncService {
  static const String collectionName = 'TRACKER_Sync';

  final FirebaseFirestore _firestore;

  EventSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<void> createOrUpdateEventSync(EventSync trackerSync) async {
    await _collection.doc(trackerSync.eventId).set(
      trackerSync.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> createEventSync({
    required String eventId,
    required String uid,
    Timestamp? syncStartAt,
  }) async {
    await _collection.doc(eventId).set({
      'syncStartAt': syncStartAt ?? FieldValue.serverTimestamp(),
      'syncStartUid': uid,
      'syncEndAt': null,
      'syncEndUid': null,
      'devices': {},
    }, SetOptions(merge: true));
  }

  Stream<EventSync?> streamEventSync(String eventId) {
    return FirebaseFirestore.instance
        .collection('TRACKER_Sync')
        .doc(eventId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return EventSync.fromFirestore(doc);
    });
  }

  Future<void> startSync({
    required String eventId,
    required String uid,
  }) async {
    await _collection.doc(eventId).set({
      'syncStartAt': FieldValue.serverTimestamp(),
      'syncStartUid': uid,
    }, SetOptions(merge: true));
  }

  Future<void> endSync({
    required String eventId,
    required String uid,
  }) async {
    await _collection.doc(eventId).set({
      'syncEndAt': FieldValue.serverTimestamp(),
      'syncEndUid': uid,
    }, SetOptions(merge: true));
  }

  Future<EventSync?> getEventSync(String eventId) async {
    final doc = await _collection.doc(eventId).get();
    if (!doc.exists) return null;
    return EventSync.fromFirestore(doc);
  }


  Future<void> deleteEventSync(String eventId) async {
    await _collection.doc(eventId).delete();
  }

  Future<void> upsertDeviceSync({
    required String eventId,
    required DeviceSync deviceSync,
  }) async {
    await _collection.doc(eventId).set({
      'devices': {
        deviceSync.deviceId: deviceSync.toMap(),
      },
    }, SetOptions(merge: true));
  }

  Future<void> markDataDownloaded({
    required String eventId,
    required String deviceId,
    required String uid,
  }) async {
    await _collection.doc(eventId).set({
      'devices': {
        deviceId: {
          'deviceId': deviceId,
          'dataDownloaded': true,
          'dataDownloadedAt': FieldValue.serverTimestamp(),
          'dataDownloadedUid': uid,
        }
      }
    }, SetOptions(merge: true));
  }

  Future<void> markErased({
    required String eventId,
    required String deviceId,
    required String uid,
  }) async {
    await _collection.doc(eventId).set({
      'devices': {
        deviceId: {
          'deviceId': deviceId,
          'erased': true,
          'erasedAt': FieldValue.serverTimestamp(),
          'erasedUid': uid,
        }
      }
    }, SetOptions(merge: true));
  }

  Future<void> resetDeviceSync({
    required String eventId,
    required String deviceId,
  }) async {
    await _collection.doc(eventId).set({
      'devices': {
        deviceId: {
          'deviceId': deviceId,
          'dataDownloaded': false,
          'dataDownloadedAt': null,
          'dataDownloadedUid': null,
          'erased': false,
          'erasedAt': null,
          'erasedUid': null,
        }
      }
    }, SetOptions(merge: true));
  }

  Future<void> removeDeviceSync({
    required String eventId,
    required String deviceId,
  }) async {
    await _collection.doc(eventId).update({
      'devices.$deviceId': FieldValue.delete(),
    });
  }

  Future<List<EventSync>> getAllEventSyncs() async {
    final querySnapshot = await _collection.get();
    return querySnapshot.docs
        .map((doc) => EventSync.fromFirestore(doc))
        .toList();
  }

  Stream<List<EventSync>> streamAllEventSyncs() {
    return _collection.snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => EventSync.fromFirestore(doc))
          .toList(),
    );
  }
}