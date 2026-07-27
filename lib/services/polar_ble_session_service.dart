import 'package:flutter/foundation.dart';
import 'package:grinta/services/polar_mobile_ble.dart';
import 'package:grinta/services/polar_session_import_service.dart';

/// Polar BLE bridge for team kits (`typeTracker: polar`).
///
/// Inventory & assignment reuse the GPS tracker model:
/// - `TRACKER_Owner` (`typeTracker: polar`)
/// - `TRACKER_Device` (`provider: polar`, doc id = Polar BLE device id)
/// - `TRACKER_DeviceOwner` → `Team.owners` / `GrintaPlayer.trackers` / session
///
/// Device discovery:
/// - **Web / Chrome:** [PolarWebBluetoothService] picker
/// - **iOS / Android:** [PolarMobileBleService] scan + connect
///
/// End-of-session import: [PolarSessionImportService] → `TRACKER_PolarAnalysis`.
/// Distinct from AccessLink wearables (`users/{uid}/polarSync/{playerId}`).
class PolarBleSessionService {
  PolarBleSessionService._();

  static final PolarBleSessionService instance = PolarBleSessionService._();

  /// Whether live BLE capture / scan is available on this platform.
  bool get isLiveCaptureSupported {
    if (kIsWeb) return false;
    return PolarMobileBleService.instance.isSupported;
  }

  /// Whether offline exercise pull (list/fetch) is available.
  bool get isExerciseImportSupported =>
      PolarMobileBleService.instance.isSupported;

  /// Placeholder for multi-sensor live session streaming.
  ///
  /// Inventory pairing + end-of-session import are implemented;
  /// live HR during sessions stays out of scope.
  Future<bool> startSession({
    required String ownerId,
    required String eventId,
    required List<String> deviceOwnerDocIds,
  }) async {
    debugPrint(
      '[PolarBle] startSession not implemented yet '
      '(ownerId=$ownerId eventId=$eventId devices=${deviceOwnerDocIds.length})',
    );
    return false;
  }

  Future<void> stopSession() async {
    await PolarMobileBleService.instance.stopSearch();
    debugPrint('[PolarBle] stopSession');
  }
}
