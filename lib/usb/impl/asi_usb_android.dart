import 'dart:typed_data';
import 'package:flutter/services.dart';

import '../asi_models.dart';
import '../asi_protocol.dart';
import '../asi_usb_client.dart';

class AndroidAsiUsbClient implements AsiUsbClient {
  static const MethodChannel _channel = MethodChannel('asi_usb');

  @override
  Future<List<AsiDeviceInfo>> listDevices() async {
    final List<dynamic> result = await _channel.invokeMethod('listDevices', {
      'vendorId': AsiProtocol.vid,
      'productId': AsiProtocol.pid,
    });

    return result.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return AsiDeviceInfo(
        id: map['id'] as String,
        vendorId: map['vendorId'] as int,
        productId: map['productId'] as int,
        productName: map['productName'] as String?,
      );
    }).toList();
  }

  Future<bool> hasPermission(String deviceId) async {
    final bool result = await _channel.invokeMethod('hasPermission', {
      'deviceId': deviceId,
    });
    return result;
  }

  Future<bool> requestPermission(String deviceId) async {
    final bool result = await _channel.invokeMethod('requestPermission', {
      'deviceId': deviceId,
    });
    return result;
  }

  @override
  Future<AsiSession> open(AsiDeviceInfo device) async {
    final allowed =
        await hasPermission(device.id) || await requestPermission(device.id);

    if (!allowed) {
      throw Exception('USB permission denied');
    }

    await _channel.invokeMethod('open', {
      'deviceId': device.id,
      'interfaceNumber': AsiProtocol.interfaceNumber,
    });

    return AsiSession(device: device);
  }

  @override
  Future<void> close(AsiSession session) async {
    await _channel.invokeMethod('close', {
      'deviceId': session.device.id,
    });
  }

  Future<void> _writeCommand(String deviceId, int command) async {
    await _channel.invokeMethod('write', {
      'deviceId': deviceId,
      'endpointAddress': AsiProtocol.writeEndpointAddress,
      'data': Uint8List.fromList([command]),
    });
  }

  Future<Uint8List> _readExact(String deviceId, int length) async {
    final Uint8List result = await _channel.invokeMethod('read', {
      'deviceId': deviceId,
      'endpointAddress': AsiProtocol.readEndpointAddress,
      'length': length,
    });

    if (result.length < length) {
      throw Exception('USB read incomplete: ${result.length}/$length');
    }

    return result;
  }

  Future<void> _expectAck(String deviceId) async {
    final ack = await _readExact(deviceId, 1);
    AsiProtocol.verifyAck(ack);
  }

  @override
  Future<String> readDeviceId(AsiSession session) async {
    final deviceId = session.device.id;
    await _writeCommand(deviceId, AsiProtocol.cmdPodGetId);
    await _expectAck(deviceId);

    final uuid = await _readExact(deviceId, 8);
    return AsiProtocol.toHex(uuid);
  }

  @override
  Future<String?> readDeviceVersion(AsiSession session) async {
    final deviceId = session.device.id;
    await _writeCommand(deviceId, AsiProtocol.cmdPodGetVer);
    await _expectAck(deviceId);

    final bytes = await _readExact(deviceId, 64);
    final trimmed = bytes.takeWhile((b) => b != 0).toList();
    if (trimmed.isEmpty) return null;
    return String.fromCharCodes(trimmed);
  }

  @override
  Future<Uint8List> downloadData(AsiSession session) async {
    final deviceId = session.device.id;

    await _writeCommand(deviceId, AsiProtocol.cmdDataRead);
    await _expectAck(deviceId);

    final sizeBytes = await _readExact(deviceId, 4);
    final dataSize = AsiProtocol.parseDataSize(sizeBytes);

    if (dataSize == 0) {
      return Uint8List(0);
    }

    final data = await _readExact(deviceId, dataSize);
    final receivedHash = await _readExact(deviceId, 32);

    AsiProtocol.verifySha256(data, receivedHash);
    return data;
  }

  @override
  Future<void> eraseData(AsiSession session) async {
    final deviceId = session.device.id;
    await _writeCommand(deviceId, AsiProtocol.cmdEraseData);
    await _expectAck(deviceId);
  }

  @override
  Future<void> eraseAll(AsiSession session) async {
    final deviceId = session.device.id;
    await _writeCommand(deviceId, AsiProtocol.cmdEraseAll);
    await _expectAck(deviceId);
  }
}

AsiUsbClient createAsiUsbClientImpl() => AndroidAsiUsbClient();