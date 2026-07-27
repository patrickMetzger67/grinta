import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/intense_gps_sync_config.dart';

class IntenseGpsSyncRepository {
  IntenseGpsSyncRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _syncDoc(
    String uid,
    String playerId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('intenseGpsSync')
        .doc(playerId);
  }

  Stream<IntenseGpsSyncConfig?> watchConfig(String uid, String playerId) {
    return _syncDoc(uid, playerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return IntenseGpsSyncConfig.fromFirestore(doc);
    });
  }

  Future<IntenseGpsSyncConfig?> getConfig(String uid, String playerId) async {
    final doc = await _syncDoc(uid, playerId).get();
    if (!doc.exists) return null;
    return IntenseGpsSyncConfig.fromFirestore(doc);
  }

  Future<void> saveConfig({
    required String uid,
    required String playerId,
    required IntenseGpsSyncConfig config,
  }) async {
    await _syncDoc(uid, playerId).set(
      config.toFirestore(),
      SetOptions(merge: true),
    );
  }

  Future<void> clearConfig({
    required String uid,
    required String playerId,
  }) async {
    await _syncDoc(uid, playerId).set(
      const IntenseGpsSyncConfig(connected: false).toFirestore(),
      SetOptions(merge: false),
    );
  }
}
