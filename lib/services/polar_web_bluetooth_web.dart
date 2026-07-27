import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:grinta/util/polar_device_id.dart';

/// Result of a Chrome Web Bluetooth pick.
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

@JS('navigator')
external JSObject get _navigator;

/// Chrome Web Bluetooth picker for Polar sensors (namePrefix `Polar`).
///
/// Extracts the Polar device id from the advertised name
/// (e.g. `Polar H10 1C709B20` → `1C709B20`).
class PolarWebBluetoothService {
  PolarWebBluetoothService._();

  static final PolarWebBluetoothService instance = PolarWebBluetoothService._();

  bool get isSupported {
    try {
      final bluetooth = _navigator.getProperty('bluetooth'.toJS);
      return bluetooth != null;
    } catch (_) {
      return false;
    }
  }

  Future<PolarWebBluetoothPick?> pickPolarDevice() async {
    if (!isSupported) {
      throw StateError('web-bluetooth-unsupported');
    }

    final bluetooth = _navigator.getProperty('bluetooth'.toJS) as JSObject;

    // Heart Rate + Battery are standard GATT services on Polar straps/sensors.
    final options = JSObject()
      ..setProperty(
        'filters'.toJS,
        <JSObject>[
          JSObject()..setProperty('namePrefix'.toJS, 'Polar'.toJS),
        ].toJS,
      )
      ..setProperty(
        'optionalServices'.toJS,
        <JSAny>[
          'heart_rate'.toJS,
          'battery_service'.toJS,
        ].toJS,
      );

    JSObject device;
    try {
      device = await _promiseToFuture<JSObject>(
        bluetooth.callMethod('requestDevice'.toJS, options),
      );
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('cancel') || message.contains('chooser')) {
        return null;
      }
      rethrow;
    }

    final name = device.getProperty('name'.toJS)?.dartify()?.toString().trim();
    final browserId =
        device.getProperty('id'.toJS)?.dartify()?.toString().trim() ?? '';

    final identity = parsePolarDeviceIdentity(name);
    if (identity == null) {
      throw StateError(
        'polar-id-not-in-name: advertised name "$name" has no Polar device id. '
        'Enter the id printed on the sensor manually.',
      );
    }

    var connected = false;
    try {
      final gatt = device.getProperty('gatt'.toJS);
      if (gatt != null) {
        final gattObj = gatt as JSObject;
        final server = await _promiseToFuture<JSObject>(
          gattObj.callMethod('connect'.toJS),
        );
        connected = server.getProperty('connected'.toJS)?.dartify() == true;
        // Disconnect after identity capture — inventory add does not need a
        // long-lived GATT session yet.
        try {
          gattObj.callMethod('disconnect'.toJS);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[PolarWebBluetooth] GATT connect skipped/failed: $e');
    }

    return PolarWebBluetoothPick(
      identity: identity,
      browserDeviceId: browserId,
      connected: connected,
    );
  }
}

Future<T> _promiseToFuture<T>(JSAny? promise) {
  if (promise == null) {
    return Future.error(StateError('Promise JS nulle'));
  }

  final completer = Completer<T>();
  final jsPromise = promise as JSObject;
  final then = jsPromise.getProperty('then'.toJS);
  if (then == null) {
    return Future.error(StateError('Objet JS non Promise'));
  }

  (then as JSFunction).callAsFunction(
    jsPromise,
    ((JSAny? value) {
      completer.complete(value as T);
    }).toJS,
    ((JSAny? error) {
      completer.completeError(error ?? 'Unknown JS error');
    }).toJS,
  );

  return completer.future;
}
