import 'package:flutter/foundation.dart';
import 'package:grinta/model/tracker/deviceOwner.dart' show DeviceOwner;
import 'package:grinta/model/tracker/owner.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/services/deviceOwnerService.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/services/training_intense_sync_service.dart';
import 'package:grinta/util/insiders_device_resolver.dart';
import 'package:uuid/uuid.dart';

/// One Intense/SIM device usable for personal GPS sync.
class PersonalGpsDeviceOption {
  const PersonalGpsDeviceOption({
    required this.deviceOwner,
    required this.insidersDeviceId,
    required this.trackerId,
    required this.label,
  });

  final DeviceOwner deviceOwner;
  final String insidersDeviceId;
  final String trackerId;
  final String label;
}

/// Owner + devices available when the profile email matches a cloud-GPS owner.
class PersonalGpsOwnerAvailability {
  const PersonalGpsOwnerAvailability({
    required this.owner,
    required this.devices,
  });

  final Owner owner;
  final List<PersonalGpsDeviceOption> devices;
}

/// Resolves individual Intense owners (`withSyncing == false`) by profile email
/// and syncs GNSS via the same Insiders pipeline as training finish.
class PersonalGpsSyncService {
  PersonalGpsSyncService({
    OwnerService? ownerService,
    DeviceOwnerService? deviceOwnerService,
    TrainingIntenseSyncService? intenseSyncService,
  })  : _ownerService = ownerService ?? OwnerService(),
        _deviceOwnerService = deviceOwnerService ?? DeviceOwnerService(),
        _intenseSyncService =
            intenseSyncService ?? TrainingIntenseSyncService();

  final OwnerService _ownerService;
  final DeviceOwnerService _deviceOwnerService;
  final TrainingIntenseSyncService _intenseSyncService;

  static const String externalSource = 'intenseGps';

  /// Owners whose email matches [email], are active, use cloud GPS
  /// (`withSyncing == false`), and have at least one resolvable Insiders device.
  Future<PersonalGpsOwnerAvailability?> resolveForEmail(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) return null;

    final owners = await _ownerService.getOwnersByEmail(normalized);
    if (owners.isEmpty) return null;

    final candidates = owners
        .where((o) => o.isActive && !o.withSyncing)
        .toList(growable: false);
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      if (a.isIndividual != b.isIndividual) {
        return a.isIndividual ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    for (final owner in candidates) {
      final devices = await _loadResolvableDevices(owner);
      if (devices.isEmpty) continue;
      return PersonalGpsOwnerAvailability(owner: owner, devices: devices);
    }
    return null;
  }

  Future<List<PersonalGpsDeviceOption>> _loadResolvableDevices(
    Owner owner,
  ) async {
    final raw = await _deviceOwnerService.listByOwnerId(owner.id);
    final options = <PersonalGpsDeviceOption>[];
    for (final deviceOwner in raw) {
      final resolution =
          resolveInsidersDeviceIdentifierFromOwner(deviceOwner);
      if (resolution == null || resolution.identifier.trim().isEmpty) {
        continue;
      }
      final trackerId = trackerIdForAnalysis(deviceOwner);
      if (trackerId.trim().isEmpty) continue;
      options.add(
        PersonalGpsDeviceOption(
          deviceOwner: deviceOwner,
          insidersDeviceId: resolution.identifier.trim(),
          trackerId: trackerId,
          label: trackerDisplayLabel(deviceOwner),
        ),
      );
    }
    return options;
  }

  /// Syncs [device] over [[startAt], [stopAt]] and returns analyzed metrics.
  Future<TrackerAnalysisResult?> syncWindow({
    required PersonalGpsDeviceOption device,
    required String playerId,
    required DateTime startAt,
    required DateTime stopAt,
    void Function(IntenseDeviceSyncStage stage)? onStage,
  }) async {
    final startUtc = startAt.toUtc();
    final stopUtc = stopAt.toUtc();
    if (!stopUtc.isAfter(startUtc)) {
      throw StateError('La fenêtre GPS est invalide (fin ≤ début).');
    }

    final target = IntenseTrainingDeviceTarget(
      playerId: playerId,
      playerLabel: playerId,
      trackerLabel: device.label,
      insidersDeviceId: device.insidersDeviceId,
      trackerId: device.trackerId,
      deviceOwnerDocId: device.deviceOwner.id,
      deviceOwnerDeviceId: device.deviceOwner.deviceId.trim(),
    );

    final window = TrainingIntenseTimeWindow(start: startUtc, stop: stopUtc);
    final eventId = 'personalGps_${const Uuid().v4()}';

    debugPrint(
      '[PersonalGps] sync → ownerDevice=${device.deviceOwner.id} '
      'insiders=${device.insidersDeviceId} '
      'start=${window.toCloudPayload()['start']} '
      'stop=${window.toCloudPayload()['stop']}',
    );

    // Empty GNSS windows return null (no exception) so the UI can prompt
    // for manual entry without flooding the console with stack traces.
    return _intenseSyncService.analyzeDeviceWindow(
      target: target,
      window: window,
      eventId: eventId,
      treatEmptyAsSuccess: true,
      onProgress: (t) => onStage?.call(t.stage),
    );
  }

  /// Maps analysis metrics to personal-sport duration / distance / pace.
  static ({
    int durationSeconds,
    double distanceMeters,
    int? paceSecondsPerKm,
  }) metricsFromAnalysis(TrackerAnalysisResult result) {
    final durationSeconds = result.duration.inSeconds.clamp(0, 24 * 3600);
    final distanceMeters = (result.distanceKm * 1000).clamp(0, 1000000);
    int? paceSecondsPerKm;
    if (result.distanceKm > 0 && durationSeconds > 0) {
      paceSecondsPerKm = (durationSeconds / result.distanceKm).round();
    }
    return (
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters.toDouble(),
      paceSecondsPerKm: paceSecondsPerKm,
    );
  }
}
