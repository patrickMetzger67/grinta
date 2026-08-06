import 'package:flutter/foundation.dart';
import 'package:grinta/model/tracker/deviceOwner.dart' show DeviceOwner;
import 'package:grinta/model/tracker/owner.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/services/deviceOwnerService.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/services/training_intense_sync_service.dart';
import 'package:grinta/util/gps_distance_smoothing.dart';
import 'package:grinta/util/intense_live_eligibility.dart';
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

/// Result of a personal GPS window sync (analysis + sample time bounds).
class PersonalGpsSyncResult {
  const PersonalGpsSyncResult({
    required this.analysis,
    required this.firstSampleAt,
    required this.lastSampleAt,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.paceSecondsPerKm,
  });

  final TrackerAnalysisResult analysis;
  final DateTime firstSampleAt;
  final DateTime lastSampleAt;
  final int durationSeconds;
  final double distanceMeters;
  final int? paceSecondsPerKm;
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

  /// Active individual owners (`isIndividual`) whose email matches [email].
  Future<List<Owner>> resolveIndividualOwnersForEmail(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) return const [];

    // Firestore email match is case-sensitive — try exact then lowercase.
    var owners = await _ownerService.getOwnersByEmail(normalized);
    final lower = normalized.toLowerCase();
    if (owners.isEmpty && lower != normalized) {
      owners = await _ownerService.getOwnersByEmail(lower);
    }
    final individuals = owners
        .where((o) => o.isActive && o.isIndividual)
        .toList(growable: false);
    individuals.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return individuals;
  }

  /// True when any of [emails] matches an active individual owner.
  Future<bool> hasIndividualOwnerForEmails(Iterable<String> emails) async {
    for (final email in emails) {
      final owners = await resolveIndividualOwnersForEmail(email);
      if (owners.isNotEmpty) return true;
    }
    return false;
  }

  /// Individual owners whose email matches [email], use cloud GPS
  /// (`withSyncing == false`), and have at least one resolvable Insiders device.
  Future<PersonalGpsOwnerAvailability?> resolveForEmail(String email) async {
    final candidates = await resolveIndividualOwnersForEmail(email);
    if (candidates.isEmpty) return null;

    // Prefer cloud Intense kits (handles omitted withSyncing on older docs).
    final gpsCandidates = candidates
        .where(ownerUsesIntenseCloudSync)
        .toList(growable: false);
    if (gpsCandidates.isEmpty) return null;

    for (final owner in gpsCandidates) {
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
  Future<PersonalGpsSyncResult?> syncWindow({
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
      'stop=${window.toCloudPayload()['stop']} '
      'startLocal=${startAt.toIso8601String()} '
      'stopLocal=${stopAt.toIso8601String()}',
    );

    // Empty GNSS windows return null (no exception) so the UI can prompt
    // for manual entry without flooding the console with stack traces.
    final outcome = await _intenseSyncService.analyzeDeviceWindow(
      target: target,
      window: window,
      eventId: eventId,
      treatEmptyAsSuccess: true,
      onProgress: (t) => onStage?.call(t.stage),
    );

    if (outcome == null || outcome.samples.isEmpty) {
      debugPrint('[PersonalGps] sync → empty GNSS window (null outcome)');
      return null;
    }

    final samples = List<TrackerRaw>.from(outcome.samples)
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));
    final first = samples.first;
    final last = samples.last;
    final firstSampleAt =
        DateTime.fromMillisecondsSinceEpoch(first.timeMs, isUtc: true).toLocal();
    final lastSampleAt =
        DateTime.fromMillisecondsSinceEpoch(last.timeMs, isUtc: true).toLocal();

    logIntenseSampleTimestampRange(
      'PersonalGps kept samples',
      samples,
      window: window,
    );

    final metrics = metricsFromAnalysis(outcome.result);
    debugPrint(
      '[PersonalGps] sync result → '
      'sampleStart=${firstSampleAt.toIso8601String()} '
      'sampleEnd=${lastSampleAt.toIso8601String()} '
      'duration=${metrics.durationSeconds}s '
      'distanceKm=${(metrics.distanceMeters / 1000).toStringAsFixed(3)} '
      'paceSecPerKm=${metrics.paceSecondsPerKm} '
      'samples=${outcome.result.samplesCount}',
    );

    return PersonalGpsSyncResult(
      analysis: outcome.result,
      firstSampleAt: firstSampleAt,
      lastSampleAt: lastSampleAt,
      durationSeconds: metrics.durationSeconds,
      distanceMeters: metrics.distanceMeters,
      paceSecondsPerKm: metrics.paceSecondsPerKm,
    );
  }

  /// Maps analysis metrics to personal-sport duration / distance / pace.
  ///
  /// Applies a max average-speed clamp so residual GNSS jitter cannot invent
  /// absurd paces (e.g. 2:00 /km from a walk).
  static ({
    int durationSeconds,
    double distanceMeters,
    int? paceSecondsPerKm,
  }) metricsFromAnalysis(TrackerAnalysisResult result) {
    final durationSeconds = result.duration.inSeconds.clamp(0, 24 * 3600);
    final rawDistanceMeters = (result.distanceKm * 1000).clamp(0, 1000000);
    final distanceMeters = clampPersonalGpsDistanceMeters(
      distanceMeters: rawDistanceMeters.toDouble(),
      durationSeconds: durationSeconds,
    );
    if (distanceMeters < rawDistanceMeters) {
      debugPrint(
        '[PersonalGps] distance clamped → '
        'rawKm=${result.distanceKm.toStringAsFixed(3)} '
        'clampedKm=${(distanceMeters / 1000).toStringAsFixed(3)} '
        'duration=${durationSeconds}s',
      );
    }
    int? paceSecondsPerKm;
    if (distanceMeters > 0 && durationSeconds > 0) {
      paceSecondsPerKm =
          (durationSeconds / (distanceMeters / 1000.0)).round();
    }
    return (
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      paceSecondsPerKm: paceSecondsPerKm,
    );
  }
}
