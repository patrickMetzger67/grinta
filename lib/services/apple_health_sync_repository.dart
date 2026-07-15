import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/apple_health_sync_config.dart';

class AppleHealthSyncRepository {
  AppleHealthSyncRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _syncDoc(
    String uid,
    String playerId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('appleHealthSync')
        .doc(playerId);
  }

  Stream<AppleHealthSyncConfig?> watchConfig(String uid, String playerId) {
    return _syncDoc(uid, playerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppleHealthSyncConfig.fromFirestore(doc);
    });
  }

  Future<AppleHealthSyncConfig?> getConfig(String uid, String playerId) async {
    final doc = await _syncDoc(uid, playerId).get();
    if (!doc.exists) return null;
    return AppleHealthSyncConfig.fromFirestore(doc);
  }

  Future<void> markConnected({
    required String uid,
    required String playerId,
    required String initiatedBy,
    int? recentWorkoutCount,
    DateTime? mostRecentWorkoutAt,
  }) async {
    final now = DateTime.now();
    await _syncDoc(uid, playerId).set(
      {
        'connected': true,
        'connectedAt': Timestamp.fromDate(now),
        'lastSyncedAt': Timestamp.fromDate(now),
        'initiatedBy': initiatedBy,
        if (recentWorkoutCount != null)
          'recentWorkoutCount': recentWorkoutCount,
        if (mostRecentWorkoutAt != null)
          'mostRecentWorkoutAt': Timestamp.fromDate(mostRecentWorkoutAt),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markDisconnected({
    required String uid,
    required String playerId,
  }) async {
    await _syncDoc(uid, playerId).set(
      {
        'connected': false,
        'recentWorkoutCount': FieldValue.delete(),
        'mostRecentWorkoutAt': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateCoachVisibility({
    required String uid,
    required String playerId,
    required AppleHealthCoachVisibility visibility,
  }) async {
    await _syncDoc(uid, playerId).set(
      {'coachVisibility': visibility.toMap()},
      SetOptions(merge: true),
    );
  }
}
