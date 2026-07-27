import 'package:grinta/util/polar_device_id.dart';

/// Result of a Chrome Web Bluetooth pick (web only).
class PolarWebBluetoothPick {
  const PolarWebBluetoothPick({
    required this.identity,
    required this.browserDeviceId,
    required this.connected,
  });

  final PolarDeviceIdentity identity;

  /// Opaque Chrome `BluetoothDevice.id` (origin-scoped, not the Polar id).
  final String browserDeviceId;

  final bool connected;
}

/// Stub outside web — Web Bluetooth is Chrome-only.
class PolarWebBluetoothService {
  PolarWebBluetoothService._();

  static final PolarWebBluetoothService instance = PolarWebBluetoothService._();

  bool get isSupported => false;

  Future<PolarWebBluetoothPick?> pickPolarDevice() async {
    throw UnsupportedError(
      'Web Bluetooth Polar picker is only available in Chrome on web.',
    );
  }
}
