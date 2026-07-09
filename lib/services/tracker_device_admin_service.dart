import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/services/deviceService.dart';
import 'package:grinta/services/user_root_service.dart';
import 'package:grinta/util/insiders_device_resolver.dart';

/// Admin-only operations on shared `TRACKER_Device` / `TRACKER_DeviceOwner`
/// collections. Writes require platform admin (`isRoot`).
class TrackerDeviceAdminService {
  TrackerDeviceAdminService._();

  static final TrackerDeviceAdminService instance = TrackerDeviceAdminService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceOwnerService _deviceOwnerService = DeviceOwnerService();
  final DeviceService _deviceService = DeviceService();

  CollectionReference<Map<String, dynamic>> get _devicesCol =>
      _firestore.collection(DeviceService.collectionName);

  Future<void> _ensureRoot() async {
    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }
  }

  Future<void> assignDeviceToOwner({
    required String deviceId,
    required String ownerId,
    String? customName,
  }) async {
    await _ensureRoot();

    final resolvedDeviceId = await _resolveInsidersDeviceDocId(deviceId);
    if (resolvedDeviceId == null) {
      throw StateError(
        'invalid-device-id: Insiders device id required for TRACKER_Device '
        '(got "$deviceId")',
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final deviceOwner = DeviceOwner(
      id: '',
      ownerId: ownerId,
      deviceId: resolvedDeviceId,
      customName: customName?.trim().isEmpty == true ? null : customName?.trim(),
      affectedAt: Timestamp.now(),
      affectedUid: uid,
    );

    try {
      await _devicesCol.doc(resolvedDeviceId).update(<String, dynamic>{
        'ownerId': ownerId,
        'updatedAt': Timestamp.now(),
      });
      await _deviceOwnerService.create(deviceOwner);
    } on FirebaseException catch (e, st) {
      debugPrint('assignDeviceToOwner failed: ${e.code} ${e.message}\n$st');
      if (e.code == 'permission-denied') {
        throw StateError('permission-denied');
      }
      rethrow;
    }
  }

  Future<void> unassignDevice(String deviceId) async {
    await _ensureRoot();

    try {
      await _devicesCol.doc(deviceId).update(<String, dynamic>{
        'ownerId': '',
        'updatedAt': Timestamp.now(),
      });

      final deviceOwner = await _deviceOwnerService.getByDeviceId(deviceId);
      if (deviceOwner != null) {
        await _deviceOwnerService.delete(deviceOwner.id);
      }
    } on FirebaseException catch (e, st) {
      debugPrint('unassignDevice failed: ${e.code} ${e.message}\n$st');
      if (e.code == 'permission-denied') {
        throw StateError('permission-denied');
      }
      rethrow;
    }
  }

  Future<int> upsertSyncedDevices(
    List<Map<String, dynamic>> devices, {
    required String provider,
  }) async {
    await _ensureRoot();

    if (devices.isEmpty) return 0;

    final batch = _firestore.batch();
    final now = Timestamp.now();
    var written = 0;

    for (final raw in devices) {
      final normalized = _normalizeSyncedDevice(raw);
      final id = (normalized['id'] ?? '').toString().trim();

      final docId = id.isNotEmpty ? id : _devicesCol.doc().id;
      final ref = _devicesCol.doc(docId);

      final data = <String, dynamic>{
        ...normalized,
        'id': docId,
        'provider': provider,
        'updatedAt': now,
      };
      data.putIfAbsent('createdAt', () => now);

      batch.set(ref, data, SetOptions(merge: true));
      written++;
    }

    try {
      await batch.commit();
    } on FirebaseException catch (e, st) {
      debugPrint('upsertSyncedDevices failed: ${e.code} ${e.message}\n$st');
      if (e.code == 'permission-denied') {
        throw StateError('permission-denied');
      }
      rethrow;
    }

    return written;
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchDevicesOrdered() {
    return _deviceService.streamDevicesOrderedByUpdatedAt();
  }

  /// Ensures assignments store the TRACKER_Device doc id (Insiders numeric id).
  Future<String?> _resolveInsidersDeviceDocId(String deviceId) async {
    final trimmed = deviceId.trim();
    if (trimmed.isEmpty) return null;

    if (isInsidersNumericId(trimmed) || isInsidersDeviceUuid(trimmed)) {
      return trimmed;
    }

    final device = await _deviceService.getDeviceById(trimmed);
    if (device == null) return null;

    return insidersNumericIdFromString(device.id) ??
        insidersUuidFromDevice(device);
  }

  /// Coerces Insiders API fields to Firestore-friendly shapes (strings for text fields).
  Map<String, dynamic> _normalizeSyncedDevice(Map<String, dynamic> raw) {
    String? asString(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    return <String, dynamic>{
      ...raw,
      'id': asString(raw['id'] ?? raw['deviceId'] ?? raw['uid']),
      'serial_number': asString(
        raw['serial_number'] ?? raw['serialNumber'] ?? raw['serial'],
      ),
      'device_name': asString(raw['device_name'] ?? raw['deviceName'] ?? raw['name']),
      'device_type': asString(raw['device_type'] ?? raw['deviceType']),
      'firmware_version': asString(
        raw['firmware_version'] ?? raw['firmwareVersion'],
      ),
      'hardware_version': asString(
        raw['hardware_version'] ?? raw['hardwareVersion'],
      ),
    };
  }
}
