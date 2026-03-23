import 'dart:typed_data';
import 'asi_models.dart';

abstract class AsiUsbClient {
  Future<List<AsiDeviceInfo>> listDevices();

  Future<AsiSession> open(AsiDeviceInfo device);
  Future<void> close(AsiSession session);

  Future<String> readDeviceId(AsiSession session);
  Future<String?> readDeviceVersion(AsiSession session);

  Future<Uint8List> downloadData(AsiSession session);
  Future<void> eraseData(AsiSession session);
  Future<void> eraseAll(AsiSession session);
}