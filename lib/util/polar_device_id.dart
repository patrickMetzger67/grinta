/// Helpers to resolve the Polar BLE device id used as `TRACKER_Device.id`.
///
/// Polar sensors advertise a local name like:
/// - `Polar H10 1C709B20`
/// - `Polar H9 A1B2C3D4`
/// - `Polar Sense 8C4CAD2D` (Verity Sense)
/// - `Polar OH1 12345678`
///
/// The trailing hex token is the **Polar device id** (also printed on the
/// sensor). Chrome Web Bluetooth's opaque `BluetoothDevice.id` is **not** this
/// value — always prefer parsing [advertisedName].
class PolarDeviceIdentity {
  const PolarDeviceIdentity({
    required this.deviceId,
    required this.deviceType,
    required this.displayName,
  });

  /// Polar BLE device id (TRACKER_Device doc id / SDK connect id).
  final String deviceId;

  /// Best-effort type label: H10, H9, Verity Sense, OH1, other.
  final String deviceType;

  /// Full advertised / display name.
  final String displayName;
}

final RegExp _trailingHexId = RegExp(
  r'([0-9A-Fa-f]{6,12})\s*$',
);

/// Parses a Polar identity from a BLE advertised name.
///
/// Returns null when no trailing hex device id is found.
PolarDeviceIdentity? parsePolarDeviceIdentity(String? advertisedName) {
  final name = advertisedName?.trim() ?? '';
  if (name.isEmpty) return null;

  final match = _trailingHexId.firstMatch(name);
  if (match == null) return null;

  final deviceId = match.group(1)!.toUpperCase();
  final beforeId = name.substring(0, match.start).trim();
  final deviceType = _inferDeviceType(beforeId);

  return PolarDeviceIdentity(
    deviceId: deviceId,
    deviceType: deviceType,
    displayName: name,
  );
}

String _inferDeviceType(String nameWithoutId) {
  final lower = nameWithoutId.toLowerCase();
  if (lower.contains('verity') ||
      lower.contains('polar sense') ||
      RegExp(r'\bsense\b').hasMatch(lower)) {
    return 'Verity Sense';
  }
  if (lower.contains('h10')) return 'H10';
  if (lower.contains('h9')) return 'H9';
  if (lower.contains('oh1')) return 'OH1';
  if (lower.startsWith('polar')) return 'other';
  return 'other';
}

/// Whether [value] looks like a Polar device id (hex, 6–12 chars).
bool looksLikePolarDeviceId(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return false;
  return RegExp(r'^[0-9A-Fa-f]{6,12}$').hasMatch(trimmed);
}
