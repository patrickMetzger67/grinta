import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/tracker/device.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/model/tracker/eventSync.dart';
import 'package:grinta/model/tracker/polar_session_analysis.dart';
import 'package:grinta/services/deviceService.dart';
import 'package:grinta/services/event_sync_service.dart';
import 'package:grinta/services/polar_mobile_ble.dart';
import 'package:grinta/services/polar_session_analysis_service.dart';
import 'package:grinta/util/polar_hr_stats.dart';

/// Result of importing one Polar device for an event.
class PolarSessionImportResult {
  const PolarSessionImportResult({
    required this.analysis,
    required this.source,
  });

  final PolarSessionAnalysis analysis;
  final PolarImportChannel source;
}

/// Orchestrates end-of-session Polar kit import → `TRACKER_PolarAnalysis`
/// + `TRACKER_Sync.devices.*.polarImported`.
class PolarSessionImportService {
  PolarSessionImportService({
    PolarSessionAnalysisService? analysisService,
    EventSyncService? eventSyncService,
    DeviceService? deviceService,
    DeviceOwnerService? deviceOwnerService,
    PolarMobileBleService? ble,
  })  : _analysis = analysisService ?? PolarSessionAnalysisService(),
        _eventSync = eventSyncService ?? EventSyncService(),
        _devices = deviceService ?? DeviceService(),
        _deviceOwners = deviceOwnerService ?? DeviceOwnerService(),
        _ble = ble ?? PolarMobileBleService.instance;

  final PolarSessionAnalysisService _analysis;
  final EventSyncService _eventSync;
  final DeviceService _devices;
  final DeviceOwnerService _deviceOwners;
  final PolarMobileBleService _ble;

  bool get isBleImportSupported => _ble.isSupported;

  /// Connects over mobile BLE, lists exercises, picks nearest to [eventAt],
  /// fetches HR samples, writes analysis, marks sync.
  Future<PolarSessionImportResult> importFromBle({
    required String eventId,
    required String trackerId,
    required String playerId,
    required String importedUid,
    required DateTime eventAt,
    int? hrMaxBpm,
    Duration? connectTimeout,
  }) async {
    if (!_ble.isSupported) {
      throw UnsupportedError(
        'Polar BLE exercise import is only available on iOS/Android.',
      );
    }

    final deviceOwner = await _deviceOwners.getById(trackerId);
    if (deviceOwner == null) {
      throw StateError('TRACKER_DeviceOwner/$trackerId not found');
    }

    final polarDeviceId = deviceOwner.deviceId.trim().toUpperCase();
    if (polarDeviceId.isEmpty) {
      throw StateError('Missing Polar deviceId on DeviceOwner $trackerId');
    }

    final device = await _devices.getDeviceById(polarDeviceId);
    final deviceType = (device?.deviceType ?? 'other').trim().isEmpty
        ? 'other'
        : (device?.deviceType ?? 'other').trim();

    await _ble.connect(polarDeviceId);
    try {
      await _ble.waitForFileTransfer(
        polarDeviceId,
        timeout: connectTimeout ?? const Duration(seconds: 45),
      );

      final entries = await _ble.listExercises(polarDeviceId);
      if (entries.isEmpty) {
        throw StateError('No exercises stored on Polar $polarDeviceId');
      }

      final picked = pickExerciseNearEvent(entries, eventAt);
      if (picked == null) {
        throw StateError(
          'No Polar exercise near event time '
          '(${eventAt.toIso8601String()}) on $polarDeviceId '
          '(${entries.length} stored)',
        );
      }

      final exercise = await _ble.fetchExercise(polarDeviceId, picked);
      final stats = computePolarHrStats(
        samples: exercise.samples,
        intervalSeconds: exercise.intervalSeconds,
        hrMaxBpm: hrMaxBpm,
      );

      final analysis = PolarSessionAnalysis(
        eventId: eventId.trim(),
        playerId: playerId.trim(),
        trackerId: trackerId.trim(),
        polarDeviceId: polarDeviceId,
        deviceType: deviceType,
        duration: stats.duration,
        startedAt: picked.date.toUtc(),
        endedAt: picked.date.toUtc().add(stats.duration),
        avgHrBpm: stats.avgHrBpm,
        maxHrBpm: stats.maxHrBpm,
        minHrBpm: stats.minHrBpm,
        hrSamplesCount: stats.hrSamplesCount,
        hrZoneSeconds: stats.hrZoneSeconds,
        importChannel: PolarImportChannel.bleMobile,
        importedUid: importedUid,
        sourceFirmware: device?.firmwareVersion,
      );

      return _persist(analysis: analysis, importedUid: importedUid);
    } finally {
      try {
        await _ble.disconnect(polarDeviceId);
      } catch (e) {
        debugPrint('[PolarImport] disconnect $polarDeviceId: $e');
      }
    }
  }

  /// Manual cardio entry (Chrome / fallback when BLE pull is unavailable).
  Future<PolarSessionImportResult> importManual({
    required String eventId,
    required String trackerId,
    required String playerId,
    required String importedUid,
    required Duration duration,
    int? avgHrBpm,
    int? maxHrBpm,
    int? minHrBpm,
    Map<String, int> hrZoneSeconds = const <String, int>{},
    double? caloriesKcal,
    double? distanceMeters,
    int? steps,
    PolarImportChannel channel = PolarImportChannel.manual,
  }) async {
    final deviceOwner = await _deviceOwners.getById(trackerId);
    if (deviceOwner == null) {
      throw StateError('TRACKER_DeviceOwner/$trackerId not found');
    }

    final polarDeviceId = deviceOwner.deviceId.trim().toUpperCase();
    final device = polarDeviceId.isEmpty
        ? null
        : await _devices.getDeviceById(polarDeviceId);
    final deviceType = (device?.deviceType ?? 'other').trim().isEmpty
        ? 'other'
        : (device?.deviceType ?? 'other').trim();

    final analysis = PolarSessionAnalysis(
      eventId: eventId.trim(),
      playerId: playerId.trim(),
      trackerId: trackerId.trim(),
      polarDeviceId: polarDeviceId,
      deviceType: deviceType,
      duration: duration,
      avgHrBpm: avgHrBpm,
      maxHrBpm: maxHrBpm,
      minHrBpm: minHrBpm,
      hrSamplesCount: 0,
      hrZoneSeconds: hrZoneSeconds,
      caloriesKcal: caloriesKcal,
      distanceMeters: distanceMeters,
      steps: steps,
      importChannel: channel,
      importedUid: importedUid,
      sourceFirmware: device?.firmwareVersion,
    );

    return _persist(analysis: analysis, importedUid: importedUid);
  }

  Future<PolarSessionImportResult> _persist({
    required PolarSessionAnalysis analysis,
    required String importedUid,
  }) async {
    await _analysis.saveAnalysis(analysis);
    await _eventSync.markPolarImported(
      eventId: analysis.eventId,
      deviceId: analysis.trackerId,
      uid: importedUid,
    );
    return PolarSessionImportResult(
      analysis: analysis,
      source: analysis.importChannel,
    );
  }

  /// Ensures [eventId] has DeviceSync stubs for each tracker id.
  Future<EventSync> ensureEventSync({
    required String eventId,
    required Map<String, String> devicePlayerMap,
    required String uid,
  }) async {
    final existing = await _eventSync.getEventSync(eventId);
    if (existing != null) return existing;

    final devices = <String, DeviceSync>{};
    for (final trackerId in devicePlayerMap.keys) {
      final id = trackerId.trim();
      if (id.isEmpty) continue;
      devices[id] = DeviceSync(deviceId: id);
    }

    final created = EventSync(
      eventId: eventId,
      devices: devices,
      syncStartUid: uid,
      syncStartAt: Timestamp.now(),
    );
    await _eventSync.createOrUpdateEventSync(created);
    return created;
  }

  Future<Device?> loadDeviceForTracker(String trackerId) async {
    final owner = await _deviceOwners.getById(trackerId);
    final polarId = owner?.deviceId.trim().toUpperCase() ?? '';
    if (polarId.isEmpty) return null;
    return _devices.getDeviceById(polarId);
  }

  Future<DeviceOwner?> loadDeviceOwner(String trackerId) =>
      _deviceOwners.getById(trackerId);
}
