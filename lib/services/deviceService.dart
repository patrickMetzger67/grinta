import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/tracker/device.dart';


  class DeviceService {
  final FirebaseFirestore _firestore;

  DeviceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'TRACKER_Device';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// CREATE
  Future<void> createDevice(Device device) async {
    final docRef = _collection.doc(device.id);

    final now = DateTime.now();

    final newDevice = device.copyWith(
      createdAt: device.createdAt ?? now,
      updatedAt: now,
    );

    await docRef.set(newDevice.toMap());
  }

  /// READ ONE
  Future<Device?> getDeviceById(String id) async {
    final doc = await _collection.doc(id).get();

    if (!doc.exists) return null;

    return Device.fromDocument(doc);
  }

  /// READ ALL
  Future<List<Device>> getAllDevices() async {
    final querySnapshot = await _collection.get();

    return querySnapshot.docs
        .map((doc) => Device.fromDocument(doc))
        .toList();
  }

  /// STREAM ALL
  Stream<List<Device>> streamAllDevices() {
    return _collection.snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Device.fromDocument(doc))
          .toList(),
    );
  }

  /// STREAM ONE
  Stream<Device?> streamDeviceById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Device.fromDocument(doc);
    });
  }

  /// UPDATE
  Future<void> updateDevice(Device device) async {
    final docRef = _collection.doc(device.id);

    final updatedDevice = device.copyWith(
      updatedAt: DateTime.now(),
    );

    await docRef.update(updatedDevice.toMap());
  }

  /// DELETE
  Future<void> deleteDevice(String id) async {
    await _collection.doc(id).delete();
  }

  /// UPSERT
  Future<void> saveDevice(Device device) async {
    final docRef = _collection.doc(device.id);
    final doc = await docRef.get();

    final now = DateTime.now();

    if (doc.exists) {
      await docRef.set(
        device.copyWith(updatedAt: now).toMap(),
        SetOptions(merge: true),
      );
    } else {
      await docRef.set(
        device.copyWith(
          createdAt: device.createdAt ?? now,
          updatedAt: now,
        ).toMap(),
      );
    }
  }

  /// Recherche par ownerId
  Future<List<Device>> getDevicesByOwnerId(String ownerId) async {
    final querySnapshot = await _collection
        .where('ownerId', isEqualTo: ownerId)
        .get();

    return querySnapshot.docs
        .map((doc) => Device.fromDocument(doc))
        .toList();
  }

  /// Recherche par provider
  Future<List<Device>> getDevicesByProvider(String provider) async {
    final querySnapshot = await _collection
        .where('provider', isEqualTo: provider)
        .get();

    return querySnapshot.docs
        .map((doc) => Device.fromDocument(doc))
        .toList();
  }

  /// Recherche par serial number
  Future<Device?> getDeviceBySerialNumber(String serialNumber) async {
    final querySnapshot = await _collection
        .where('serial_number', isEqualTo: serialNumber)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return Device.fromDocument(querySnapshot.docs.first);
  }
  // Recherche par device_name
  Future<Device?> getDeviceByDeviceName(String deviceName) async {
    final querySnapshot = await _collection
        .where('device_name', isEqualTo: deviceName)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return Device.fromDocument(querySnapshot.docs.first);
  }
}