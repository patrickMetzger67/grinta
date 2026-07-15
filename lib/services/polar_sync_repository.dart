import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/polar_sync_config.dart';

class PolarSyncRepository {
  PolarSyncRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _syncDoc(
    String uid,
    String playerId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('polarSync')
        .doc(playerId);
  }

  Stream<PolarSyncConfig?> watchConfig(String uid, String playerId) {
    return _syncDoc(uid, playerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PolarSyncConfig.fromFirestore(doc);
    });
  }

  Future<PolarSyncConfig?> getConfig(String uid, String playerId) async {
    final doc = await _syncDoc(uid, playerId).get();
    if (!doc.exists) return null;
    return PolarSyncConfig.fromFirestore(doc);
  }

  Future<void> updateCoachVisibility({
    required String uid,
    required String playerId,
    required PolarCoachVisibility visibility,
  }) async {
    await _syncDoc(uid, playerId).set(
      {'coachVisibility': visibility.toMap()},
      SetOptions(merge: true),
    );
  }
}
