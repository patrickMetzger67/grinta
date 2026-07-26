import 'package:flutter/foundation.dart';

/// Planned Polar BLE session bridge for team kits (`typeTracker: polar`).
///
/// Inventory & assignment reuse the GPS tracker model:
/// - `TRACKER_Owner` (`typeTracker: polar`)
/// - `TRACKER_Device` (`provider: polar`, doc id = Polar BLE device id)
/// - `TRACKER_DeviceOwner` → `Team.owners` / `GrintaPlayer.trackers` / session
///
/// This service is the future home of Polar BLE SDK wiring (scan / connect /
/// HR stream). Phase 1 registers devices manually; live capture comes next.
///
/// Distinct from AccessLink wearables (`users/{uid}/polarSync/{playerId}`).
class PolarBleSessionService {
  PolarBleSessionService._();

  static final PolarBleSessionService instance = PolarBleSessionService._();

  /// Whether live BLE capture is available on this platform.
  ///
  /// Web is always unsupported; mobile support lands with the Polar BLE SDK
  /// dependency.
  bool get isLiveCaptureSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Placeholder until Polar BLE SDK is wired.
  ///
  /// Returns `false` so UI can show a clear “not yet available” state without
  /// crashing coaches who already linked a Polar kit owner to a team.
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
    debugPrint('[PolarBle] stopSession (no-op)');
  }
}
