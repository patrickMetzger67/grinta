import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/model/tracker_owner.dart';
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

    final resolvedDeviceId = await _resolveAssignableDeviceDocId(deviceId);
    if (resolvedDeviceId == null) {
      throw StateError(
        'invalid-device-id: TRACKER_Device id required '
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

  /// Registers a Polar BLE sensor into `TRACKER_Device` (team kit inventory).
  ///
  /// [polarDeviceId] is the id printed on the sensor (Polar BLE SDK device id).
  /// Doc id = `polarDeviceId` so session assignment and BLE connect share one key.
  Future<String> createPolarDevice({
    required String polarDeviceId,
    String? ownerId,
    String? deviceType,
    String? deviceName,
    String? customName,
    String? serialNumber,
  }) async {
    await _ensureRoot();

    final id = polarDeviceId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(polarDeviceId, 'polarDeviceId', 'required');
    }

    final now = Timestamp.now();
    final type = (deviceType ?? '').trim();
    final name = (deviceName ?? '').trim();
    final label = (customName ?? '').trim();
    final serial = (serialNumber ?? '').trim();
    final kitOwnerId = ownerId?.trim() ?? '';

    final data = <String, dynamic>{
      'id': id,
      'provider': TrackerOwner.providerPolar,
      'device_type': type.isEmpty ? 'polar' : type,
      'device_name': name.isEmpty ? 'Polar $id' : name,
      'custom_name': label.isEmpty ? null : label,
      'serial_number': serial.isEmpty ? id : serial,
      'updatedAt': now,
    };
    if (kitOwnerId.isNotEmpty) {
      data['ownerId'] = kitOwnerId;
    }

    try {
      final existing = await _devicesCol.doc(id).get();
      if (!existing.exists) {
        data.putIfAbsent('ownerId', () => '');
        data['createdAt'] = now;
      }
      await _devicesCol.doc(id).set(data, SetOptions(merge: true));
    } on FirebaseException catch (e, st) {
      debugPrint('createPolarDevice failed: ${e.code} ${e.message}\n$st');
      if (e.code == 'permission-denied') {
        throw StateError('permission-denied');
      }
      rethrow;
    }

    return id;
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

  /// Resolves a `TRACKER_Device` doc id for assignment.
  ///
  /// - Polar (and other non-Insiders) devices: use the existing doc id.
  /// - Insiders / Inspirit: prefer numeric Insiders id (legacy sync).
  Future<String?> _resolveAssignableDeviceDocId(String deviceId) async {
    final trimmed = deviceId.trim();
    if (trimmed.isEmpty) return null;

    final device = await _deviceService.getDeviceById(trimmed);
    if (device != null) {
      final provider = (device.provider ?? '').trim().toLowerCase();
      if (provider == TrackerOwner.providerPolar ||
          provider == TrackerOwner.typeFootbar) {
        return device.id;
      }
      if (provider == TrackerOwner.typeInspirit || provider.isEmpty) {
        return insidersNumericIdFromString(device.id) ??
            insidersUuidFromDevice(device) ??
            device.id;
      }
      return device.id;
    }

    if (isInsidersNumericId(trimmed) || isInsidersDeviceUuid(trimmed)) {
      return trimmed;
    }

    return null;
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
