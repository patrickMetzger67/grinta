// device_owner.dart
import 'package:cloud_firestore/cloud_firestore.dart';

String? _parseCustomName(Object? value) {
  final trimmed = value?.toString().trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

class DeviceOwner {
  final String id; // id du doc Firestore
  final String ownerId;
  final String deviceId;
  final String? customName;
  final Timestamp affectedAt;
  final String affectedUid;

  DeviceOwner({
    required this.id,
    required this.ownerId,
    required this.deviceId,
    required this.affectedAt,
    required this.affectedUid,
    this.customName,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'deviceId': deviceId,
      'affectedAt': affectedAt,
      'affectedUid': affectedUid,
      'customeName': customName,
    };
  }

  static DeviceOwner fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DeviceOwner(
      id: doc.id,
      ownerId: (data['ownerId'] ?? '').toString(),
      deviceId: (data['deviceId'] ?? '').toString(),
      affectedAt: (data['affectedAt'] is Timestamp)
          ? data['affectedAt'] as Timestamp
          : Timestamp.now(),
      affectedUid: (data['affectedUid'] ?? '').toString(),
      customName: _parseCustomName(data['customeName']),
    );
  }
}

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

  /// READ: tous les devices par ownerId
  Future<List<DeviceOwner>> getByOwnerId(String ownerId) async {
    final snapshot = await _col
        .where('ownerId', isEqualTo: ownerId)
        .get();

    return snapshot.docs
        .map((doc) => DeviceOwner.fromDoc(doc))
        .toList();
  }

  /// STREAM: tous les devices par ownerId
  Stream<List<DeviceOwner>> streamByOwnerId(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeviceOwner.fromDoc(doc))
          .toList();
    });
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

  Future<DeviceOwner?> getByOwnerIdAndCustomName(String ownerId, String customName) async {
    final q = await _col
        .where('ownerId', isEqualTo: ownerId)
        .where('customeName', isEqualTo: customName)
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