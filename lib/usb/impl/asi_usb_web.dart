import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../asi_models.dart';
import '../asi_protocol.dart';
import '../asi_usb_client.dart';

@JS('globalThis')
external JSObject get globalThis;

Future<T> _promiseToFuture<T>(JSAny? promise) {
  if (promise == null) {
    throw Exception('Promise JS nulle');
  }

  final completer = Completer<T>();
  final jsPromise = promise as JSObject;

  final then = jsPromise.getProperty('then'.toJS);
  if (then == null) {
    throw Exception('Objet JS non Promise');
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

class WebAsiUsbClient implements AsiUsbClient {
  JSObject get _usb {
    final usb = globalThis.getProperty('asiUsb'.toJS);
    if (usb == null) {
      throw Exception(
        'window.asiUsb est introuvable. Vérifie web/index.html.',
      );
    }
    return usb as JSObject;
  }

  @override
  Future<AsiDeviceInfo?> requestDevicePermission() async {
    try {
      final options = JSObject()
        ..setProperty(
          'filters'.toJS,
          [
            JSObject()
              ..setProperty('vendorId'.toJS, AsiProtocol.vid.toJS)
              ..setProperty('productId'.toJS, AsiProtocol.pid.toJS),
          ].toJS,
        );

      final result = await _promiseToFuture<JSObject>(
        _usb.callMethod('requestDevice'.toJS, options),
      );

      final serialNumber = result.getProperty('serialNumber'.toJS);
      final vendorId = result.getProperty('vendorId'.toJS);
      final productId = result.getProperty('productId'.toJS);
      final productName = result.getProperty('productName'.toJS);

      return AsiDeviceInfo(
        id: serialNumber?.dartify()?.toString() ?? 'web-device',
        vendorId: ((vendorId?.dartify() as num?) ?? 0).toInt(),
        productId: ((productId?.dartify() as num?) ?? 0).toInt(),
        productName: productName?.dartify()?.toString(),
      );
    } catch (e) {
      debugPrint('requestDevice error: $e');
      return null;
    }
  }

  @override
  Future<List<AsiDeviceInfo>> listDevices() async {
    try {
      final devicesJs = await _promiseToFuture<JSArray>(
        _usb.callMethod('getDevices'.toJS),
      );

      final result = <AsiDeviceInfo>[];

      for (var i = 0; i < devicesJs.length; i++) {
        final device = devicesJs[i] as JSObject;

        final serialNumber = device.getProperty('serialNumber'.toJS);
        final vendorId = device.getProperty('vendorId'.toJS);
        final productId = device.getProperty('productId'.toJS);
        final productName = device.getProperty('productName'.toJS);

        result.add(
          AsiDeviceInfo(
            id: serialNumber?.dartify()?.toString() ?? 'web-device-$i',
            vendorId: ((vendorId?.dartify() as num?) ?? 0).toInt(),
            productId: ((productId?.dartify() as num?) ?? 0).toInt(),
            productName: productName?.dartify()?.toString(),
          ),
        );
      }

      return result;
    } catch (e) {
      debugPrint('getDevices error: $e');
      return [];
    }
  }

  @override
  Future<AsiSession> open(AsiDeviceInfo device) async {
    await _promiseToFuture<JSAny?>(
      _usb.callMethod('open'.toJS),
    );

    return AsiSession(device: device);
  }

  @override
  Future<void> close(AsiSession session) async {
    await _promiseToFuture<JSAny?>(
      _usb.callMethod('close'.toJS),
    );
  }

  Future<void> _prepareEndpoints() async {
    print('USB: prepare endpoints');

    await _promiseToFuture<JSAny?>(
      _usb.callMethod(
        'prepareEndpoints'.toJS,
        AsiProtocol.readEndpointNumberWeb.toJS,
        AsiProtocol.writeEndpointNumberWeb.toJS,
      ),
    ).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        throw const AsiDownloadTimeoutException(
          'Timeout pendant la préparation des endpoints USB',
        );
      },
    );

    print('USB: endpoints prepared');
  }

  int _extractBytesWritten(JSAny? result) {
    final value = result?.dartify();

    if (value == null) {
      return 1;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is Map) {
      final bytesWritten = value['bytesWritten'];
      if (bytesWritten is num) {
        return bytesWritten.toInt();
      }

      final status = value['status'];
      if (status == 'ok') {
        return 1;
      }
    }

    return 1;
  }

  Future<void> _writeCommand(int command) async {
    print('WRITE: start cmd=0x${command.toRadixString(16)}');

    final result = await _promiseToFuture<JSAny?>(
      _usb.callMethod(
        'transferOut'.toJS,
        AsiProtocol.writeEndpointNumberWeb.toJS,
        Uint8List.fromList([command]).toJS,
      ),
    ).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        throw AsiDownloadTimeoutException(
          'Timeout pendant l\'envoi de la commande 0x${command.toRadixString(16)}',
        );
      },
    );

    print('WRITE: result=${result?.dartify()}');

    final bytesWritten = _extractBytesWritten(result);
    print('WRITE: bytesWritten=$bytesWritten');

    if (bytesWritten <= 0) {
      throw Exception('USB write failed');
    }

    print('WRITE: done');
  }

  Future<Uint8List> _readUpTo(
      int length, {
        Duration timeout = const Duration(seconds: 2),
      }) async {
    final result = await _promiseToFuture<JSArray>(
      _usb.callMethod(
        'transferIn'.toJS,
        AsiProtocol.readEndpointNumberWeb.toJS,
        length.toJS,
      ),
    ).timeout(
      timeout,
      onTimeout: () {
        throw AsiDownloadTimeoutException(
          'Timeout pendant la lecture USB ($length octets)',
        );
      },
    );

    final dartList = result.dartify();

    if (dartList is! List) {
      throw Exception('Réponse USB invalide');
    }

    final values = dartList.map((e) => (e as num).toInt()).toList();

    print(
      'READ request=$length got=${values.length} raw=${values.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}',
    );

    return Uint8List.fromList(values);
  }

  Future<Uint8List?> _tryReadUpTo(
      int length, {
        Duration timeout = const Duration(milliseconds: 900),
      }) async {
    try {
      final data = await _readUpTo(
        length,
        timeout: timeout,
      );

      if (data.isEmpty) {
        return null;
      }

      return data;
    } on AsiDownloadTimeoutException catch (e) {
      print('READ TIMEOUT treated as no data: $e');
      return null;
    } on TimeoutException catch (e) {
      print('READ TIMEOUT treated as no data: $e');
      return null;
    }
  }

  Future<Uint8List> _readExact(int length) async {
    final data = await _readUpTo(length);

    if (data.length < length) {
      throw Exception('USB read incomplete: ${data.length}/$length');
    }

    return data;
  }

  String _hex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  Future<void> _expectAck({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final remaining = deadline.difference(DateTime.now());

      final effectiveTimeout = remaining.inMilliseconds <= 0
          ? const Duration(milliseconds: 1)
          : remaining;

      try {
        final ack = await _readUpTo(
          1,
          timeout: effectiveTimeout,
        );

        print('ACK RAW: ${_hex(ack)}');

        if (ack.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 60));
          continue;
        }

        AsiProtocol.verifyAck(ack);
        print('ACK OK');
        return;
      } on AsiDownloadTimeoutException {
        break;
      } catch (e) {
        print('ACK ignored error: $e');
        await Future.delayed(const Duration(milliseconds: 60));
      }
    }

    throw const AsiDownloadTimeoutException('Aucun ACK reçu');
  }

  Future<Uint8List> _readFirstStreamChunkOrEmpty(int packetSize) async {
    for (int attempt = 0; attempt < 8; attempt++) {
      final chunk = await _tryReadUpTo(
        packetSize,
        timeout: const Duration(milliseconds: 900),
      );

      if (chunk == null || chunk.isEmpty) {
        print('FIRST STREAM CHUNK empty attempt=$attempt');
        await Future.delayed(const Duration(milliseconds: 80));
        continue;
      }

      print(
        'FIRST STREAM CHUNK attempt=$attempt len=${chunk.length} raw=${_hex(chunk)}',
      );

      if (chunk.length == 1 && chunk[0] == AsiProtocol.usbAck) {
        print('FIRST STREAM: standalone ACK');
        await Future.delayed(const Duration(milliseconds: 80));
        continue;
      }

      return chunk;
    }

    return Uint8List(0);
  }

  Future<Uint8List?> _readNextStreamChunkOrNull(int packetSize) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      final chunk = await _tryReadUpTo(
        packetSize,
        timeout: const Duration(milliseconds: 900),
      );

      if (chunk == null || chunk.isEmpty) {
        print('NEXT STREAM CHUNK empty attempt=$attempt');
        await Future.delayed(const Duration(milliseconds: 60));
        continue;
      }

      print(
        'NEXT STREAM CHUNK attempt=$attempt len=${chunk.length} raw=${_hex(chunk)}',
      );

      if (chunk.length == 1 && chunk[0] == AsiProtocol.usbAck) {
        print('NEXT STREAM: standalone ACK ignored');
        await Future.delayed(const Duration(milliseconds: 60));
        continue;
      }

      return chunk;
    }

    return null;
  }

  @override
  Future<String> readDeviceId(AsiSession session) async {
    await _writeCommand(AsiProtocol.cmdPodGetId);
    await _expectAck();

    final uuid = await _readExact(8);
    return AsiProtocol.toHex(uuid);
  }

  @override
  Future<String?> readDeviceVersion(AsiSession session) async {
    await _writeCommand(AsiProtocol.cmdPodGetVer);
    await _expectAck();

    final bytes = await _readUpTo(64);
    final trimmed = bytes.takeWhile((b) => b != 0).toList();

    if (trimmed.isEmpty) return null;

    return String.fromCharCodes(trimmed);
  }

  @override
  Future<Uint8List> downloadData(AsiSession session) async {
    try {
      print('DOWNLOAD: prepare');
      await _prepareEndpoints();

      await Future.delayed(const Duration(milliseconds: 120));

      print('DOWNLOAD: before CMD_DATA_READ');
      await _writeCommand(AsiProtocol.cmdDataRead);
      print('DOWNLOAD: after CMD_DATA_READ');

      await Future.delayed(const Duration(milliseconds: 120));

      const int packetSize = 256;
      final allBytes = <int>[];

      final firstChunk = await _readFirstStreamChunkOrEmpty(packetSize);

      if (firstChunk.isEmpty) {
        print('DOWNLOAD: aucune donnée disponible');
        return Uint8List(0);
      }

      allBytes.addAll(firstChunk);
      print('STREAM TOTAL=${allBytes.length}');

      if (firstChunk.length < packetSize) {
        print('STREAM END detected on first short packet');
      } else {
        while (true) {
          final chunk = await _readNextStreamChunkOrNull(packetSize);

          if (chunk == null || chunk.isEmpty) {
            print(
              'STREAM END detected by timeout/no more data after ${allBytes.length} bytes',
            );
            break;
          }

          allBytes.addAll(chunk);
          print('STREAM TOTAL=${allBytes.length}');

          if (chunk.length < packetSize) {
            print('STREAM END detected by short packet');
            break;
          }
        }
      }

      if (allBytes.isEmpty) {
        print('DOWNLOAD: aucune donnée disponible');
        return Uint8List(0);
      }

      if (allBytes.length <= 32) {
        throw Exception(
          'Flux trop court pour contenir données + hash: ${allBytes.length} octets',
        );
      }

      final data = Uint8List.fromList(
        allBytes.sublist(0, allBytes.length - 32),
      );

      final hash = Uint8List.fromList(
        allBytes.sublist(allBytes.length - 32),
      );

      print('DATA LEN=${data.length}');
      print('HASH RAW: ${_hex(hash)}');

      AsiProtocol.verifySha256(data, hash);
      print('DOWNLOAD: hash OK');

      return data;
    } on AsiDownloadTimeoutException {
      rethrow;
    } on TimeoutException {
      throw const AsiDownloadTimeoutException();
    }
  }

  @override
  Future<void> eraseData(AsiSession session) async {
    await _writeCommand(AsiProtocol.cmdEraseAll);

    try {
      await _expectAck(timeout: const Duration(seconds: 3));
      await Future.delayed(const Duration(milliseconds: 300));
    } on AsiDownloadTimeoutException {
      throw const AsiNoDataToEraseException();
    } on TimeoutException {
      throw const AsiNoDataToEraseException();
    }
  }

  @override
  Future<void> eraseAll(AsiSession session) async {
    await _writeCommand(AsiProtocol.cmdEraseAll);

    try {
      await _expectAck(timeout: const Duration(seconds: 3));
      await Future.delayed(const Duration(milliseconds: 300));
    } on AsiDownloadTimeoutException {
      throw const AsiNoDataToEraseException();
    } on TimeoutException {
      throw const AsiNoDataToEraseException();
    }
  }
}

AsiUsbClient createAsiUsbClientImpl() => WebAsiUsbClient();