import 'package:grinta/util/polar_device_id.dart';
import 'package:grinta/util/polar_hr_stats.dart';

/// Discovered Polar sensor (mobile BLE scan).
class PolarBleFoundDevice {
  const PolarBleFoundDevice({
    required this.deviceId,
    required this.name,
    required this.rssi,
    required this.isConnectable,
    this.deviceType = 'other',
  });

  final String deviceId;
  final String name;
  final int rssi;
  final bool isConnectable;
  final String deviceType;

  PolarDeviceIdentity get identity => PolarDeviceIdentity(
        deviceId: deviceId,
        deviceType: deviceType,
        displayName: name,
      );
}

/// HR exercise payload fetched from a Polar sensor.
class PolarBleExerciseData {
  const PolarBleExerciseData({
    required this.intervalSeconds,
    required this.samples,
  });

  final int intervalSeconds;
  final List<int> samples;
}

/// Stub when Polar BLE SDK is unavailable (web / unsupported platforms).
class PolarMobileBleService {
  PolarMobileBleService._();

  static final PolarMobileBleService instance = PolarMobileBleService._();

  bool get isSupported => false;

  Stream<PolarBleFoundDevice> searchForDevices() {
    throw UnsupportedError('Polar BLE scan is only available on iOS/Android.');
  }

  Future<void> stopSearch() async {}

  Future<void> connect(String deviceId) async {
    throw UnsupportedError(
      'Polar BLE connect is only available on iOS/Android.',
    );
  }

  Future<void> disconnect(String deviceId) async {}

  Stream<String> get deviceConnectedIds => const Stream.empty();

  Stream<String> get deviceDisconnectedIds => const Stream.empty();

  Future<void> connectAndPrepareForExercises(
    String deviceId, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    throw UnsupportedError(
      'Polar BLE connect is only available on iOS/Android.',
    );
  }

  Future<void> waitForFileTransfer(
    String deviceId, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    throw UnsupportedError(
      'Polar BLE file transfer is only available on iOS/Android.',
    );
  }

  Future<List<PolarExerciseListItem>> listExercises(String deviceId) async {
    throw UnsupportedError(
      'Polar BLE listExercises is only available on iOS/Android.',
    );
  }

  Future<PolarBleExerciseData> fetchExercise(
    String deviceId,
    PolarExerciseListItem entry,
  ) async {
    throw UnsupportedError(
      'Polar BLE fetchExercise is only available on iOS/Android.',
    );
  }
}
