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
  final String code;
  final String message;
  final String userInstructions;

  final int? expectedBytes;
  final int? receivedBytes;
  final Duration? timeout;
  final String? step;
  final Object? cause;

  const AsiDownloadTimeoutException([
    this.message = 'Timeout pendant le téléchargement des données',
    this.userInstructions =
    'Le device est connecté, mais la lecture USB n’a pas répondu dans le délai prévu. '
        'Veuillez réessayer. Si le problème persiste, cliquez sur "Déconnecter", '
        'débranchez le device, puis rebranchez-le.',
    this.code = 'DOWNLOAD_TIMEOUT',
    this.expectedBytes,
    this.receivedBytes,
    this.timeout,
    this.step,
    this.cause,
  ]);

  factory AsiDownloadTimeoutException.usbRead({
    int? expectedBytes,
    int? receivedBytes,
    Duration? timeout,
    String step = 'lecture USB',
    Object? cause,
  }) {
    return AsiDownloadTimeoutException(
      expectedBytes == null
          ? 'Timeout pendant la lecture USB'
          : 'Timeout pendant la lecture USB ($expectedBytes octets)',
      'Le device semble bien connecté, mais il ne renvoie pas les données attendues assez rapidement. '
          'Veuillez relancer le téléchargement. Si cela se reproduit, cliquez sur "Déconnecter", '
          'débranchez le device, puis rebranchez-le.',
      'DOWNLOAD_TIMEOUT',
      expectedBytes,
      receivedBytes,
      timeout,
      step,
      cause,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.writeln('$code: $message');

    if (step != null && step!.trim().isNotEmpty) {
      buffer.writeln('Étape: $step');
    }

    if (expectedBytes != null) {
      buffer.writeln('Octets attendus: $expectedBytes');
    }

    if (receivedBytes != null) {
      buffer.writeln('Octets reçus: $receivedBytes');
    }

    if (timeout != null) {
      buffer.writeln('Timeout: ${timeout!.inMilliseconds} ms');
    }

    if (cause != null) {
      buffer.writeln('Cause: $cause');
    }

    buffer.write(userInstructions);

    return buffer.toString();
  }
}

class AsiUsbConnectionException implements Exception {
  final String code;
  final String message;
  final String userInstructions;
  final Object? cause;

  const AsiUsbConnectionException({
    this.code = 'USB_CONNECTION_ERROR',
    this.message = 'Erreur de connexion USB',
    this.userInstructions =
    'Veuillez vérifier que le device est connecté, autorisé, puis réessayez.',
    this.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.writeln('$code: $message');

    if (cause != null) {
      buffer.writeln('Cause: $cause');
    }

    buffer.write(userInstructions);

    return buffer.toString();
  }
}

class AsiUsbPermissionDeniedException implements Exception {
  final String message;

  const AsiUsbPermissionDeniedException([
    this.message = 'Permission USB refusée',
  ]);

  @override
  String toString() => message;
}

class AsiUsbDeviceNotFoundException implements Exception {
  final String message;

  const AsiUsbDeviceNotFoundException([
    this.message = 'Aucun device ASI détecté',
  ]);

  @override
  String toString() => message;
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