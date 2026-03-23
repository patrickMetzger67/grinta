import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class AsiProtocol {
  static const int vid = 0x1915;
  static const int pid = 0x5203;

  static const int usbAck = 0x0A;
  static const int usbNack = 0x05;

  static const int cmdPodGetId = 0x11;
  static const int cmdPodGetVer = 0x13;
  static const int cmdDataRead = 0x31;
  static const int cmdEraseData = 0x41;
  static const int cmdEraseAll = 0x43;

  static const int interfaceNumber = 0;
  static const int readEndpointAddress = 0x81;
  static const int writeEndpointAddress = 0x01;

  static const int readEndpointNumberWeb = 1;
  static const int writeEndpointNumberWeb = 1;

  static int parseDataSize(Uint8List bytes) {
    if (bytes.length != 4) {
      throw Exception('Invalid size buffer');
    }
    return (bytes[0] << 24) |
    (bytes[1] << 16) |
    (bytes[2] << 8) |
    bytes[3];
  }

  static String toHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static void verifyAck(Uint8List ack) {
    if (ack.isEmpty || ack[0] != usbAck) {
      throw Exception('No acknowledge');
    }
  }

  static void verifySha256(Uint8List data, Uint8List receivedHash) {
    final computed = Uint8List.fromList(sha256.convert(data).bytes);
    if (computed.length != receivedHash.length) {
      throw Exception('Invalid hash length');
    }

    for (int i = 0; i < computed.length; i++) {
      if (computed[i] != receivedHash[i]) {
        throw Exception(
          'Invalid hash. Received=${toHex(receivedHash)} Computed=${toHex(computed)}',
        );
      }
    }
  }
}