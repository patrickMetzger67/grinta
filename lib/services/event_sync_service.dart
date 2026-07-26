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
    final docId = (trackerSync.docId?.trim().isNotEmpty == true)
        ? trackerSync.docId!.trim()
        : trackerSync.eventId;
    await _collection.doc(docId).set(
      trackerSync.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> createEventSync({
    required String eventId,
    required String uid,
    Timestamp? syncStartAt,
    bool isFullySynced = false,
  }) async {
    await _collection.doc(eventId).set({
      'eventId': eventId,
      'isFullySynced': isFullySynced,
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

  /// Marks a Polar kit device as imported for [eventId]
  /// (`TRACKER_PolarAnalysis` written).
  Future<void> markPolarImported({
    required String eventId,
    required String deviceId,
    required String uid,
  }) async {
    await _collection.doc(eventId).set({
      'devices': {
        deviceId: {
          'deviceId': deviceId,
          'polarImported': true,
          'polarImportedAt': FieldValue.serverTimestamp(),
          'polarImportedUid': uid,
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

  /// Atomically claims the right to send feeling notifications for [eventId].
  ///
  /// Returns `true` only for the first successful claim; later callers get
  /// `false` so notifications are not sent twice.
  Future<bool> claimFeelingNotifSent(String eventId) async {
    final trimmed = eventId.trim();
    if (trimmed.isEmpty) return false;

    final docRef = _collection.doc(trimmed);
    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (snap.exists) {
        final already = snap.data()?['feelingNotifSent'] == true;
        if (already) return false;
        transaction.set(
          docRef,
          {'feelingNotifSent': true, 'eventId': trimmed},
          SetOptions(merge: true),
        );
        return true;
      }

      transaction.set(
        docRef,
        {
          'eventId': trimmed,
          'feelingNotifSent': true,
          'isFullySynced': false,
          'devices': <String, dynamic>{},
        },
        SetOptions(merge: true),
      );
      return true;
    });
  }

  /// Per-player Health export status on the event sync doc:
  /// `healthExportPlayers.{playerId}` = `exported` | `declined`.
  Future<String?> getHealthExportStatus({
    required String eventId,
    required String playerId,
  }) async {
    final event = eventId.trim();
    final player = playerId.trim();
    if (event.isEmpty || player.isEmpty) return null;
    final snap = await _collection.doc(event).get();
    if (!snap.exists) return null;
    final raw = snap.data()?['healthExportPlayers'];
    if (raw is! Map) return null;
    final value = raw[player];
    return value is String ? value : null;
  }

  Future<void> setHealthExportStatus({
    required String eventId,
    required String playerId,
    required String status,
  }) async {
    final event = eventId.trim();
    final player = playerId.trim();
    if (event.isEmpty || player.isEmpty) return;
    await _collection.doc(event).set({
      'eventId': event,
      'healthExportPlayers': {player: status},
    }, SetOptions(merge: true));
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