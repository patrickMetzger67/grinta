import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/calendar_sync_config.dart';

class CalendarSyncRepository {
  CalendarSyncRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _configDoc(
    String uid,
    String playerId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('calendarSync')
        .doc(playerId);
  }

  CollectionReference<Map<String, dynamic>> _eventMapCollection(
    String uid,
    String playerId,
  ) {
    return _configDoc(uid, playerId).collection('eventMap');
  }

  Stream<CalendarSyncConfig?> watchConfig(String uid, String playerId) {
    return _configDoc(uid, playerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CalendarSyncConfig.fromFirestore(doc);
    });
  }

  Future<CalendarSyncConfig?> getConfig(String uid, String playerId) async {
    final doc = await _configDoc(uid, playerId).get();
    if (!doc.exists) return null;
    return CalendarSyncConfig.fromFirestore(doc);
  }

  Future<void> saveConfig({
    required String uid,
    required String playerId,
    required CalendarSyncConfig config,
  }) async {
    await _configDoc(uid, playerId).set(
      config.toFirestore(),
      SetOptions(merge: true),
    );
  }

  Future<void> setEnabled({
    required String uid,
    required String playerId,
    required bool enabled,
  }) async {
    await _configDoc(uid, playerId).set(
      {'enabled': enabled},
      SetOptions(merge: true),
    );
  }

  Future<void> updateLastSyncedAt({
    required String uid,
    required String playerId,
  }) async {
    await _configDoc(uid, playerId).set(
      {'lastSyncedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<List<CalendarSyncEventMapEntry>> getAllEventMaps(
    String uid,
    String playerId,
  ) async {
    final snapshot = await _eventMapCollection(uid, playerId).get();
    return snapshot.docs
        .map(CalendarSyncEventMapEntry.fromFirestore)
        .toList();
  }

  Future<void> upsertEventMap({
    required String uid,
    required String playerId,
    required String grintaEventId,
    required CalendarSyncEventMapEntry entry,
  }) async {
    await _eventMapCollection(uid, playerId)
        .doc(grintaEventId)
        .set(entry.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteEventMap({
    required String uid,
    required String playerId,
    required String grintaEventId,
  }) async {
    await _eventMapCollection(uid, playerId).doc(grintaEventId).delete();
  }

  Future<void> deleteAllEventMaps(String uid, String playerId) async {
    final snapshot = await _eventMapCollection(uid, playerId).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
