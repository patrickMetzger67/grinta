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

  /// Connects and waits until exercise APIs can be used.
  ///
  /// Subscribes to SDK events **before** [connectToDevice] to avoid missing
  /// early `sdkFeatureReady` callbacks. On iOS Verity Sense, `fileTransfer`
  /// is often never announced even when PFTP works — after a successful
  /// connection we then settle briefly and proceed.
  Future<void> connectAndPrepareForExercises(
    String deviceId, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final id = deviceId.trim().toUpperCase();
    if (id.isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'required');
    }

    final connected = Completer<void>();
    final fileTransferReady = Completer<void>();
    final features = <String>{};

    final featureSub = _polar.sdkFeatureReady.listen(
      (e) {
        final eid = e.identifier.trim().toUpperCase();
        if (eid != id) return;
        features.add(e.feature.name);
        debugPrint('[PolarMobileBle] feature ready $id → ${e.feature.name}');
        if (e.feature == PolarSdkFeature.fileTransfer &&
            !fileTransferReady.isCompleted) {
          fileTransferReady.complete();
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[PolarMobileBle] sdkFeatureReady error: $e\n$st');
      },
    );

    final connectedSub = _polar.deviceConnected.listen((info) {
      final eid = info.deviceId.trim().toUpperCase();
      debugPrint('[PolarMobileBle] deviceConnected $eid');
      if (eid == id && !connected.isCompleted) {
        connected.complete();
      }
    });

    final disconnectedSub = _polar.deviceDisconnected.listen((event) {
      final eid = event.info.deviceId.trim().toUpperCase();
      debugPrint(
        '[PolarMobileBle] deviceDisconnected $eid '
        'pairingError=${event.pairingError}',
      );
    });

    final connectBudget = Duration(
      milliseconds: timeout.inMilliseconds.clamp(1, 25000),
    );
    final overallDeadline = DateTime.now().add(timeout);

    try {
      await _polar.requestPermissions();
      // Fire-and-forget at the native layer — events above drive readiness.
      await _polar.connectToDevice(id, requestPermissions: true);

      try {
        await connected.future.timeout(connectBudget);
      } on TimeoutException {
        throw TimeoutException(
          'Polar $id did not connect within ${connectBudget.inSeconds}s. '
          'Close Polar Flow (and any other Polar app), remove the sensor from '
          'iOS Settings → Bluetooth if it stays “Connected”, wake the Verity '
          'Sense in sensor mode (heart on optical LEDs, blue side LED), then retry.',
          connectBudget,
        );
      }

      final remaining = overallDeadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        throw TimeoutException(
          'Polar $id connected but exercise API timed out '
          '(features: ${features.isEmpty ? 'none' : features.join(', ')}).',
          timeout,
        );
      }

      try {
        await fileTransferReady.future.timeout(remaining);
      } on TimeoutException {
        // Verity Sense on iOS often never emits fileTransfer even though
        // listExercises/fetchExercise can still work after connection.
        debugPrint(
          '[PolarMobileBle] fileTransfer not announced for $id after '
          'connect; features=${features.join(', ')} — settling then proceed',
        );
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } finally {
      await featureSub.cancel();
      await connectedSub.cancel();
      await disconnectedSub.cancel();
    }
  }

  /// Waits until Polar file-transfer feature is ready for [deviceId].
  ///
  /// Prefer [connectAndPrepareForExercises] which avoids missing early events.
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
