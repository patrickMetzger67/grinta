import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/screen/team_players/training_team_players_tracker.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/services/deviceOwnerService.dart' as device_owner_svc;
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/sensorAnalysisService.dart';
import 'package:grinta/services/tracker_field_service.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/insiders_device_resolver.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/training_finish_helper.dart';
import 'training_intense_sync_service.dart';

/// Default polling interval for live Intense metrics refresh.
///
/// Kept relatively long because each poll hits Insiders once per assigned
/// tracker; shorter intervals amplify 429 throttling.
const Duration kIntenseLivePollingInterval = Duration(seconds: 30);

/// Max parallel Insiders fetches during a live refresh (API rate-limits hard).
const int kIntenseLiveFetchConcurrency = 2;

/// Retries when Insiders / Cloud Function returns HTTP 429.
const int kIntenseLiveFetchMaxAttempts = 4;

/// Rolling lookback for live metrics display (recent activity, not full session).
///
/// Finish sync uses the full training slot via [resolveTrainingIntenseTimeWindow]
/// (capped to dateTime + duration); live polls only analyze samples from the last
/// [kIntenseLiveMetricsLookback].
const Duration kIntenseLiveMetricsLookback = Duration(minutes: 10);

/// Resolves the Insiders fetch window for live display: last [lookback] ending at
/// [fetchStopUtc], clamped to [sessionStartUtc] so we never query before session.
TrainingIntenseTimeWindow resolveIntenseLiveMetricsWindow({
  required DateTime sessionStartUtc,
  required DateTime fetchStopUtc,
  Duration lookback = kIntenseLiveMetricsLookback,
}) {
  final stopUtc = fetchStopUtc.toUtc();
  final sessionStart = sessionStartUtc.toUtc();
  final lookbackStart = stopUtc.subtract(lookback);
  final startUtc =
      lookbackStart.isBefore(sessionStart) ? sessionStart : lookbackStart;

  return TrainingIntenseTimeWindow(start: startUtc, stop: stopUtc);
}

/// One present player with an assigned Intense tracker during a live session.
class IntenseLivePlayerTarget {
  const IntenseLivePlayerTarget({
    required this.playerId,
    required this.player,
    required this.trackerLabel,
    required this.insidersDeviceId,
    required this.trackerId,
    required this.deviceOwnerDocId,
  });

  final String playerId;
  final Player player;
  final String trackerLabel;
  final String insidersDeviceId;
  final String trackerId;
  final String deviceOwnerDocId;
}

/// Live metrics for one player, derived from Insiders preprocessed samples.
class IntenseLivePlayerMetrics {
  const IntenseLivePlayerMetrics({
    required this.target,
    required this.workloadScore,
    required this.distanceKm,
    required this.highSpeedDurationSec,
    required this.sprintCount,
    required this.maxAccelerationMps2,
    this.analysis,
    this.errorMessage,
    this.updatedAt,
  });

  final IntenseLivePlayerTarget target;
  final double workloadScore;
  final double distanceKm;
  final double highSpeedDurationSec;
  final double sprintCount;
  final double maxAccelerationMps2;
  final TrackerAnalysisResult? analysis;
  final String? errorMessage;
  final DateTime? updatedAt;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

/// Polls Insiders preprocessed data and analyzes metrics for live Intense sessions.
class IntenseLiveDataService {
  IntenseLiveDataService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  Future<List<IntenseLivePlayerTarget>> loadTrainingTargets(
    Training training,
  ) async {
    final trackerContext =
        await TrainingTrackerContext.loadForTraining(training);
    if (trackerContext == null) return const [];

    final playerService = PlayerService();
    final targets = <IntenseLivePlayerTarget>[];

    for (final pt in training.playerTraining) {
      if (!isPresentOrDefaultPresence(pt.presenceType)) continue;

      final playerId = pt.playerId?.trim();
      if (playerId == null || playerId.isEmpty) continue;

      final deviceOwnerDocId = pt.deviceId?.trim();
      if (deviceOwnerDocId == null || deviceOwnerDocId.isEmpty) continue;

      final deviceOwner = trackerContext.ownerDeviceByDocId[deviceOwnerDocId];
      if (deviceOwner == null) continue;

      final resolution = resolveInsidersDeviceIdentifierFromOwner(deviceOwner);
      if (resolution == null || resolution.identifier.isEmpty) continue;

      final player = await playerService.getPlayerById(playerId);
      if (player == null) continue;

      final trackerId = trackerIdForAnalysis(deviceOwner);
      if (trackerId.isEmpty) continue;

      targets.add(
        IntenseLivePlayerTarget(
          playerId: playerId,
          player: player,
          trackerLabel: trackerContext.displayLabel(pt),
          insidersDeviceId: resolution.identifier,
          trackerId: trackerId,
          deviceOwnerDocId: deviceOwnerDocId,
        ),
      );
    }

    return targets;
  }

  Future<List<IntenseLivePlayerTarget>> loadMatchTargets({
    required models.Match match,
    MatchCompo? compo,
  }) async {
    final ownerId = match.ownerId?.trim();
    if (match.withTracker != true || ownerId == null || ownerId.isEmpty) {
      return const [];
    }

    MatchCompo? resolvedCompo = compo;
    final matchId = match.id?.trim();
    if (resolvedCompo == null && matchId != null && matchId.isNotEmpty) {
      resolvedCompo =
          await MatchCompoService().getFirstMatchCompoByMatchId(matchId);
    }
    if (resolvedCompo == null) return const [];

    final devices = await device_owner_svc.DeviceOwnerService().listByOwnerId(ownerId);
    final ownerDeviceByDocId = <String, DeviceOwner>{};
    for (final device in devices) {
      ownerDeviceByDocId[device.id] = device;
    }

    final playerService = PlayerService();
    final convocations = resolvedCompo.convocation ?? const <PlayerConvo>[];
    final presentIds = convocations
        .where((c) => c.isPresent == true)
        .map((c) => c.playerID?.trim())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final compoPlayers = <PlayerCompo>[
      ...?resolvedCompo.goalkeeper,
      ...?resolvedCompo.defender,
      ...?resolvedCompo.midfielder,
      ...?resolvedCompo.midfielderAttaking,
      ...?resolvedCompo.midfielderDefensive,
      ...?resolvedCompo.stricker,
      ...?resolvedCompo.substitute,
    ];

    final targets = <IntenseLivePlayerTarget>[];
    final seenPlayerIds = <String>{};

    for (final compo in compoPlayers) {
      final playerId = compo.playerID?.trim();
      final deviceOwnerDocId = compo.deviceOwnerId?.trim();
      if (playerId == null ||
          playerId.isEmpty ||
          deviceOwnerDocId == null ||
          deviceOwnerDocId.isEmpty) {
        continue;
      }
      if (presentIds.isNotEmpty && !presentIds.contains(playerId)) {
        continue;
      }
      if (!seenPlayerIds.add(playerId)) continue;

      final deviceOwner = ownerDeviceByDocId[deviceOwnerDocId];
      if (deviceOwner == null) continue;

      final resolution = resolveInsidersDeviceIdentifierFromOwner(deviceOwner);
      if (resolution == null || resolution.identifier.isEmpty) continue;

      final player = await playerService.getPlayerById(playerId);
      if (player == null) continue;

      final trackerId = trackerIdForAnalysis(deviceOwner);
      if (trackerId.isEmpty) continue;

      final custom = compo.customName?.trim();
      final trackerLabel = (custom != null && custom.isNotEmpty)
          ? custom
          : trackerDisplayLabel(deviceOwner);

      targets.add(
        IntenseLivePlayerTarget(
          playerId: playerId,
          player: player,
          trackerLabel: trackerLabel,
          insidersDeviceId: resolution.identifier,
          trackerId: trackerId,
          deviceOwnerDocId: deviceOwnerDocId,
        ),
      );
    }

    return targets;
  }

  Future<FieldGpsCorners?> loadFieldGpsCorners(String? fieldId) async {
    final id = fieldId?.trim();
    if (id == null || id.isEmpty) return null;
    final field = await TrackerFieldService().getById(id);
    return field?.fieldGpsCorners;
  }

  Future<IntenseLivePlayerMetrics> fetchLiveMetrics({
    required IntenseLivePlayerTarget target,
    required DateTime sessionStartUtc,
    required DateTime sessionStopUtc,
    required bool isMatch,
    required String eventId,
    FieldGpsCorners? fieldGpsCorners,
  }) async {
    try {
      final window = resolveIntenseLiveMetricsWindow(
        sessionStartUtc: sessionStartUtc,
        fetchStopUtc: sessionStopUtc,
      );
      var samples = await _fetchSamples(
        insidersDeviceId: target.insidersDeviceId,
        trackerId: target.trackerId,
        window: window,
      );
      samples = intenseSamplesWithinWindow(samples, window);

      FootballFieldGps? fieldGps;
      if (fieldGpsCorners != null) {
        fieldGps = FootballFieldGps.fromFieldGpsCorners(fieldGpsCorners);
      }

      final analysis = SensorAnalysisService.analyzeSensorData(
        trackerId: target.trackerId,
        playerId: target.playerId,
        eventId: eventId,
        allSamples: samples,
        isMatch: isMatch,
        fieldGps: fieldGps,
      );

      return IntenseLivePlayerMetrics(
        target: target,
        workloadScore: analysis.workloadScore,
        distanceKm: analysis.distanceKm,
        highSpeedDurationSec: analysis.highSpeedDuration.inMilliseconds / 1000,
        sprintCount: analysis.sprintCount.toDouble(),
        maxAccelerationMps2: analysis.maxAccelerationMps2,
        analysis: analysis,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      return IntenseLivePlayerMetrics(
        target: target,
        workloadScore: 0,
        distanceKm: 0,
        highSpeedDurationSec: 0,
        sprintCount: 0,
        maxAccelerationMps2: 0,
        errorMessage: TrainingIntenseSyncService.formatIntenseSyncError(
          e,
          target: IntenseTrainingDeviceTarget(
            playerId: target.playerId,
            playerLabel: playerDisplayName(target.player),
            trackerLabel: target.trackerLabel,
            insidersDeviceId: target.insidersDeviceId,
            trackerId: target.trackerId,
            deviceOwnerDocId: target.deviceOwnerDocId,
          ),
        ),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<List<IntenseLivePlayerMetrics>> fetchAllLiveMetrics({
    required List<IntenseLivePlayerTarget> targets,
    required DateTime sessionStartUtc,
    required DateTime sessionStopUtc,
    required bool isMatch,
    required String eventId,
    FieldGpsCorners? fieldGpsCorners,
  }) async {
    if (targets.isEmpty) return const [];

    // Never fan out one CF/Insiders call per player at once — that triggers
    // Insiders HTTP 429 ("Request was throttled") on squad-sized sessions.
    return _mapWithConcurrency<IntenseLivePlayerTarget, IntenseLivePlayerMetrics>(
      targets,
      concurrency: kIntenseLiveFetchConcurrency,
      (target) => fetchLiveMetrics(
        target: target,
        sessionStartUtc: sessionStartUtc,
        sessionStopUtc: sessionStopUtc,
        isMatch: isMatch,
        eventId: eventId,
        fieldGpsCorners: fieldGpsCorners,
      ),
    );
  }

  Future<List<TrackerRaw>> _fetchSamples({
    required String insidersDeviceId,
    required String trackerId,
    required TrainingIntenseTimeWindow window,
  }) async {
    final fetchPayload = <String, dynamic>{
      'insidersDeviceId': insidersDeviceId,
      'trackerId': trackerId,
      ...window.toCloudPayload(),
    };

    Object? lastError;
    for (var attempt = 0; attempt < kIntenseLiveFetchMaxAttempts; attempt++) {
      try {
        final fetchResult = await _functions
            .httpsCallable('fetchIntensePreprocessedSamples')
            .call(fetchPayload);

        final fetchData = Map<String, dynamic>.from(fetchResult.data as Map);
        final rawSamples = (fetchData['samples'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            <Map<String, dynamic>>[];

        var samples = rawSamples
            .map(
              (s) => TrackerRaw(
                trackerId: trackerId,
                timeMs: _asInt(s['timeMs']),
                latitude: _asDouble(s['latitude']),
                longitude: _asDouble(s['longitude']),
                speedMps: _asDouble(s['speedMps']),
              ),
            )
            .toList(growable: false);

        final asiBase64 = fetchData['asiBase64']?.toString();
        if (samples.isEmpty && asiBase64 != null && asiBase64.isNotEmpty) {
          final csv = await _convertAsiBase64ToCsv(asiBase64);
          samples = _samplesFromCsv(csv, trackerId: trackerId);
        }

        return samples;
      } on FirebaseFunctionsException catch (e) {
        lastError = e;
        if (!_isInsidersRateLimited(e) ||
            attempt >= kIntenseLiveFetchMaxAttempts - 1) {
          rethrow;
        }
        final delay = _retryDelayForRateLimit(e, attempt);
        if (kDebugMode) {
          debugPrint(
            '[IntenseLive] Insiders 429 for device=$insidersDeviceId '
            'attempt=${attempt + 1}/$kIntenseLiveFetchMaxAttempts '
            'retryIn=${delay.inMilliseconds}ms',
          );
        }
        await Future<void>.delayed(delay);
      }
    }

    throw lastError ??
        StateError('fetchIntensePreprocessedSamples failed without error');
  }

  static bool _isInsidersRateLimited(FirebaseFunctionsException e) {
    final raw = '${e.code} ${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
    return raw.contains('429') ||
        raw.contains('too many requests') ||
        raw.contains('throttl') ||
        raw.contains('rate limit');
  }

  @visibleForTesting
  static bool debugIsInsidersRateLimited(FirebaseFunctionsException e) =>
      _isInsidersRateLimited(e);

  static Duration _retryDelayForRateLimit(
    FirebaseFunctionsException e,
    int attempt,
  ) {
    final raw = '${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
    final match = RegExp(r'retry-after:\s*(\d+)').firstMatch(raw);
    if (match != null) {
      final seconds = int.tryParse(match.group(1)!) ?? 1;
      // Insiders often returns Retry-After: 1s; pad a bit under load.
      return Duration(milliseconds: (seconds.clamp(1, 15) * 1000) + 250);
    }
    return Duration(milliseconds: 600 * (1 << attempt));
  }

  @visibleForTesting
  static Duration debugRetryDelayForRateLimit(
    FirebaseFunctionsException e,
    int attempt,
  ) =>
      _retryDelayForRateLimit(e, attempt);

  /// Runs [mapper] over [items] with at most [concurrency] in flight.
  static Future<List<R>> _mapWithConcurrency<T, R>(
    List<T> items,
    Future<R> Function(T item) mapper, {
    required int concurrency,
  }) async {
    if (items.isEmpty) return const [];
    final results = List<R?>.filled(items.length, null);
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final index = nextIndex;
        nextIndex += 1;
        if (index >= items.length) return;
        results[index] = await mapper(items[index]);
      }
    }

    final workerCount = concurrency.clamp(1, items.length);
    await Future.wait(List.generate(workerCount, (_) => worker()));
    return results.cast<R>();
  }

  Future<String> _convertAsiBase64ToCsv(String asiBase64) async {
    final result = await _functions.httpsCallable('insidersConvertAsiToCsv').call(
      <String, dynamic>{
        'asiBase64': asiBase64,
        'filename': 'inspirit_data.ASI',
      },
    );
    final data = Map<String, dynamic>.from(result.data['data'] as Map);
    return data['csv'] as String;
  }

  List<TrackerRaw> _samplesFromCsv(String csv, {required String trackerId}) {
    final lines = const LineSplitter().convert(csv);
    if (lines.isEmpty) return const <TrackerRaw>[];

    final header = lines.first.split(',').map((e) => e.trim()).toList();
    final timeIdx = header.indexOf('time [POSIXms]');
    final latIdx = header.indexOf('latitude [deg]');
    final lonIdx = header.indexOf('longitude [deg]');
    final speedIdx = header.indexOf('speed [m/s]');

    final samples = <TrackerRaw>[];
    for (var i = 1; i < lines.length; i++) {
      final cols = lines[i].split(',').map((e) => e.trim()).toList();
      if (cols.length < 3) continue;

      final timeMs = timeIdx >= 0 && timeIdx < cols.length
          ? int.tryParse(cols[timeIdx]) ?? 0
          : 0;
      final latitude = latIdx >= 0 && latIdx < cols.length
          ? double.tryParse(cols[latIdx]) ?? 0
          : 0;
      final longitude = lonIdx >= 0 && lonIdx < cols.length
          ? double.tryParse(cols[lonIdx]) ?? 0
          : 0;
      final speedMps = speedIdx >= 0 && speedIdx < cols.length
          ? double.tryParse(cols[speedIdx]) ?? 0
          : 0;

      if (timeMs <= 0) continue;
      samples.add(
        TrackerRaw(
          trackerId: trackerId,
          timeMs: timeMs,
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
          speedMps: speedMps.toDouble(),
        ),
      );
    }
    return samples;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// Convenience loader when only event id is known (training).
Future<Training?> loadTrainingForLive(String eventId) {
  return TrainingService().getTrainingById(eventId.trim());
}
