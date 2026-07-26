import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:grinta/util/polar_device_id.dart';
import 'package:grinta/util/polar_hr_stats.dart';
import 'package:polar/polar.dart';

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

  factory PolarBleFoundDevice.fromPolarInfo(PolarDeviceInfo info) {
    final rawId = info.deviceId.trim().toUpperCase();
    final name = info.name.trim().isEmpty ? 'Polar $rawId' : info.name.trim();
    final parsed = parsePolarDeviceIdentity(name);
    return PolarBleFoundDevice(
      deviceId: parsed?.deviceId ?? rawId,
      name: name,
      rssi: info.rssi,
      isConnectable: info.isConnectable,
      deviceType: parsed?.deviceType ?? 'other',
    );
  }
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

/// Polar BLE scan / connect via the official Polar SDK (Android + iOS).
class PolarMobileBleService {
  PolarMobileBleService._();

  static final PolarMobileBleService instance = PolarMobileBleService._();

  final Polar _polar = Polar();
  StreamSubscription<PolarDeviceInfo>? _searchSub;

  bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Emits nearby Polar sensors (H10, Verity Sense, …).
  ///
  /// Call [stopSearch] when leaving the scan screen.
  Stream<PolarBleFoundDevice> searchForDevices() {
    if (!isSupported) {
      return Stream.error(
        UnsupportedError('Polar BLE scan is only available on iOS/Android.'),
      );
    }

    final controller = StreamController<PolarBleFoundDevice>.broadcast();
    final seen = <String>{};

    () async {
      try {
        await _polar.requestPermissions();
        await _searchSub?.cancel();
        _searchSub = _polar.searchForDevice().listen(
          (info) {
            final found = PolarBleFoundDevice.fromPolarInfo(info);
            if (found.deviceId.isEmpty) return;
            if (!seen.add(found.deviceId)) {
              // Refresh RSSI for an already-listed device via a new event.
            }
            if (!controller.isClosed) {
              controller.add(found);
            }
          },
          onError: (Object e, StackTrace st) {
            debugPrint('[PolarMobileBle] search error: $e\n$st');
            if (!controller.isClosed) controller.addError(e, st);
          },
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
        );
      } catch (e, st) {
        debugPrint('[PolarMobileBle] search start failed: $e\n$st');
        if (!controller.isClosed) {
          controller.addError(e, st);
          await controller.close();
        }
      }
    }();

    controller.onCancel = () async {
      await stopSearch();
    };

    return controller.stream;
  }

  Future<void> stopSearch() async {
    await _searchSub?.cancel();
    _searchSub = null;
  }

  Future<void> connect(String deviceId) async {
    final id = deviceId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'required');
    }
    await _polar.requestPermissions();
    await _polar.connectToDevice(id, requestPermissions: true);
  }

  Future<void> disconnect(String deviceId) async {
    final id = deviceId.trim();
    if (id.isEmpty) return;
    try {
      await _polar.disconnectFromDevice(id);
    } catch (e) {
      debugPrint('[PolarMobileBle] disconnect $id: $e');
    }
  }

  Stream<String> get deviceConnectedIds =>
      _polar.deviceConnected.map((e) => e.deviceId.trim().toUpperCase());

  Stream<String> get deviceDisconnectedIds => _polar.deviceDisconnected
      .map((e) => e.info.deviceId.trim().toUpperCase());

  /// Waits until Polar file-transfer feature is ready for [deviceId].
  Future<void> waitForFileTransfer(
    String deviceId, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final id = deviceId.trim().toUpperCase();
    await _polar.sdkFeatureReady
        .firstWhere(
          (e) =>
              e.identifier.trim().toUpperCase() == id &&
              e.feature == PolarSdkFeature.fileTransfer,
        )
        .timeout(timeout);
  }

  Future<List<PolarExerciseListItem>> listExercises(String deviceId) async {
    final id = deviceId.trim();
    final entries = await _polar.listExercises(id);
    return entries
        .map(
          (e) => PolarExerciseListItem(
            path: e.path,
            date: e.date,
            entryId: e.entryId,
          ),
        )
        .toList(growable: false);
  }

  Future<PolarBleExerciseData> fetchExercise(
    String deviceId,
    PolarExerciseListItem entry,
  ) async {
    final id = deviceId.trim();
    final polarEntry = PolarExerciseEntry(
      path: entry.path,
      date: entry.date,
      entryId: entry.entryId,
    );
    final data = await _polar.fetchExercise(id, polarEntry);
    return PolarBleExerciseData(
      intervalSeconds: data.interval,
      samples: List<int>.from(data.samples),
    );
  }
}
