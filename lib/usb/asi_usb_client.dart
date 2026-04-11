import 'dart:typed_data';

import 'asi_models.dart';

class AsiNoDataToEraseException implements Exception {
  final String message;

  const AsiNoDataToEraseException([
    this.message = 'Aucune donnée à effacer',
  ]);

  @override
  String toString() => message;
}

class AsiDownloadTimeoutException implements Exception {
  final String message;
  final String userInstructions;

  const AsiDownloadTimeoutException([
    this.message = 'Timeout pendant le téléchargement des données',
    this.userInstructions =
    'Veuillez cliquer sur "Déconnecter", débrancher le device, puis rebrancher le device.',
  ]);

  @override
  String toString() => '$message\n$userInstructions';
}

abstract class AsiUsbClient {
  Future<AsiDeviceInfo?> requestDevicePermission();
  Future<List<AsiDeviceInfo>> listDevices();

  Future<AsiSession> open(AsiDeviceInfo device);
  Future<void> close(AsiSession session);

  Future<String> readDeviceId(AsiSession session);
  Future<String?> readDeviceVersion(AsiSession session);

  Future<Uint8List> downloadData(AsiSession session);
  Future<void> eraseData(AsiSession session);
  Future<void> eraseAll(AsiSession session);
}