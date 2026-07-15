import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/fitbit_sync_config.dart';

class FitbitSyncRepository {
  FitbitSyncRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _syncDoc(
    String uid,
    String playerId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fitbitSync')
        .doc(playerId);
  }

  Stream<FitbitSyncConfig?> watchConfig(String uid, String playerId) {
    return _syncDoc(uid, playerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return FitbitSyncConfig.fromFirestore(doc);
    });
  }

  Future<FitbitSyncConfig?> getConfig(String uid, String playerId) async {
    final doc = await _syncDoc(uid, playerId).get();
    if (!doc.exists) return null;
    return FitbitSyncConfig.fromFirestore(doc);
  }

  Future<void> updateCoachVisibility({
    required String uid,
    required String playerId,
    required FitbitCoachVisibility visibility,
  }) async {
    await _syncDoc(uid, playerId).set(
      {'coachVisibility': visibility.toMap()},
      SetOptions(merge: true),
    );
  }
}
