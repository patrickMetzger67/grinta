import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/tracker/deviceOwner.dart';

class DeviceOwnerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('TRACKER_DeviceOwner');

  /// CREATE (doc id auto)
  Future<String> create(DeviceOwner deviceOwner) async {
    final ref = _col.doc();
    final data = deviceOwner.toMap();

    // sécurise affectedAt si jamais
    data.putIfAbsent('affectedAt', () => Timestamp.now());

    await ref.set(data);
    return ref.id;
  }

  /// CREATE/UPSERT (doc id custom)
  Future<void> setById(String id, DeviceOwner deviceOwner) async {
    await _col.doc(id).set(deviceOwner.toMap(), SetOptions(merge: true));
  }

  /// READ: par id doc Firestore
  Future<DeviceOwner?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return DeviceOwner.fromDoc(doc);
  }

  /// READ: recherche d'un device par son deviceId (ton besoin)
  /// Renvoie la dernière affectation trouvée (si plusieurs, on prend la plus récente).
  Future<DeviceOwner?> getByDeviceId(String deviceId) async {
    final q = await _col
        .where('deviceId', isEqualTo: deviceId)
        .orderBy('affectedAt', descending: true)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;
    return DeviceOwner.fromDoc(q.docs.first);
  }

  /// UPDATE: merge partiel
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update(data);
  }

  /// DELETE
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  /// LIST: tous les devices affectés à un ownerId
  Future<List<DeviceOwner>> listByOwnerId(String ownerId) async {
    final q = await _col
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('affectedAt', descending: true)
        .get();

    return q.docs.map(DeviceOwner.fromDoc).toList();
  }

  /// STREAM (optionnel): devices par ownerId en live
  Stream<List<DeviceOwner>> watchByOwnerId(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('affectedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(DeviceOwner.fromDoc).toList());
  }

  /// (Optionnel) Unassign / delete by deviceId (si tu veux retirer une affectation)
  Future<void> deleteLatestByDeviceId(String deviceId) async {
    final q = await _col
        .where('deviceId', isEqualTo: deviceId)
        .orderBy('affectedAt', descending: true)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return;
    await _col.doc(q.docs.first.id).delete();
  }
}