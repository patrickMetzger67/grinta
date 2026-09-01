import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/meta_sync_config.dart';

class MetaSyncRepository {
  MetaSyncRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const docId = 'account';

  DocumentReference<Map<String, dynamic>> _syncDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('metaSync')
        .doc(docId);
  }

  Stream<MetaSyncConfig?> watchConfig(String uid) {
    return _syncDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MetaSyncConfig.fromFirestore(doc);
    });
  }

  Future<MetaSyncConfig?> getConfig(String uid) async {
    final doc = await _syncDoc(uid).get();
    if (!doc.exists) return null;
    return MetaSyncConfig.fromFirestore(doc);
  }
}
