import 'package:flutter/foundation.dart';
import 'package:grinta/model/tracker/device.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';

/// TEMP: hardcoded Insiders device id for Intense sync testing. Set to null to disable.
/// When set, overrides [DeviceOwner.deviceId] for all Intense API calls.
const String? kDebugHardcodedInsidersDeviceId = null;

final RegExp _insidersUuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Whether [value] looks like an Insiders platform device UUID
/// (legacy TRACKER_Device doc id from older sync assumptions).
bool isInsidersDeviceUuid(String value) {
  return _insidersUuidPattern.hasMatch(value.trim());
}

/// Whether [value] is the numeric Insiders device `id` from `GET /v1/devices/`.
bool isInsidersNumericId(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  return int.tryParse(trimmed) != null;
}

/// Returns the numeric Insiders `id` when [value] is a non-negative integer string.
String? insidersNumericIdFromString(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (int.tryParse(trimmed) == null) return null;
  return trimmed;
}

/// Returns the Insiders UUID from a [Device] document id when valid (legacy).
String? insidersUuidFromDevice(Device? device) {
  if (device == null) return null;
  final id = device.id.trim();
  if (id.isEmpty) return null;
  return isInsidersDeviceUuid(id) ? id : null;
}

/// Which field supplied the Insiders API path parameter.
enum InsidersDeviceIdentifierField {
  /// `TRACKER_DeviceOwner.deviceId` — numeric Insiders sensor id for API calls.
  deviceOwnerDeviceId,
}

class InsidersDeviceResolution {
  const InsidersDeviceResolution({
    required this.identifier,
    required this.fieldUsed,
  });

  final String identifier;
  final InsidersDeviceIdentifierField fieldUsed;
}

/// Resolves the Insiders API device identifier for
/// `GET /v1/devices/{device}/preprocessed/`.
///
/// Chain:
/// 1. Load `TRACKER_DeviceOwner/{deviceOwnerDocId}` (`playerTraining.deviceId`)
/// 2. Return `deviceOwner.deviceId` — numeric Insiders `id` from Inspirit sync,
///    NOT `customName` (display label like `"10"`) nor IMEI/serial.
InsidersDeviceResolution? _debugInsidersOverride() {
  final override = kDebugHardcodedInsidersDeviceId?.trim();
  if (override == null || override.isEmpty) return null;
  debugPrint('[InsidersResolver] DEBUG override → $override');
  return InsidersDeviceResolution(
    identifier: override,
    fieldUsed: InsidersDeviceIdentifierField.deviceOwnerDeviceId,
  );
}

Future<InsidersDeviceResolution?> resolveInsidersDeviceIdentifier(
  String deviceOwnerDocId,
) async {
  final debugOverride = _debugInsidersOverride();
  if (debugOverride != null) return debugOverride;

  final docId = deviceOwnerDocId.trim();
  if (docId.isEmpty) return null;

  final deviceOwnerService = DeviceOwnerService();
  final deviceOwner = await deviceOwnerService.getById(docId);
  if (deviceOwner == null) {
    _logResolver(docId, 'FAILED — DeviceOwner not found');
    return null;
  }

  return resolveInsidersDeviceIdentifierFromOwner(deviceOwner);
}

/// Same as [resolveInsidersDeviceIdentifier] when [DeviceOwner] is already loaded.
InsidersDeviceResolution? resolveInsidersDeviceIdentifierFromOwner(
  DeviceOwner deviceOwner,
) {
  final debugOverride = _debugInsidersOverride();
  if (debugOverride != null) return debugOverride;

  final docId = deviceOwner.id.trim();
  final insidersDeviceId = deviceOwner.deviceId.trim();

  if (insidersDeviceId.isEmpty) {
    _logResolver(docId, 'FAILED — DeviceOwner.deviceId empty');
    return null;
  }

  debugPrint(
    '[InsidersResolver] resolved → $insidersDeviceId '
    '(field=${InsidersDeviceIdentifierField.deviceOwnerDeviceId.name}, '
    'deviceOwnerDocId=$docId)',
  );
  _logResolver(
    docId,
    'identifier from DeviceOwner.deviceId: $insidersDeviceId',
  );

  return InsidersDeviceResolution(
    identifier: insidersDeviceId,
    fieldUsed: InsidersDeviceIdentifierField.deviceOwnerDeviceId,
  );
}

void _logResolver(String deviceOwnerDocId, String message) {
  debugPrint('[InsidersResolver] deviceOwnerDocId=$deviceOwnerDocId → $message');
}

/// Human-readable tracker label for UI (customName preferred).
String trackerDisplayLabel(DeviceOwner deviceOwner) {
  final custom = deviceOwner.customName?.trim();
  if (custom != null && custom.isNotEmpty) return custom;
  return deviceOwner.deviceId.trim();
}

/// Short tracker id for analysis doc keys — display label, not Insiders API id.
String trackerIdForAnalysis(DeviceOwner deviceOwner) =>
    trackerDisplayLabel(deviceOwner);
