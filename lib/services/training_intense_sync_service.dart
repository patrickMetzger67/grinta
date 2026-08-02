import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/services/sensorAnalysisService.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';
import 'package:grinta/util/highlight_minute_helper.dart';
import 'package:grinta/util/intense_live_eligibility.dart';

/// Retries when Insiders / Cloud Function returns HTTP 429 (finish + live).
const int kIntenseInsidersFetchMaxAttempts = 4;

/// Pipeline step for one player's Intense tracker during training finish.
enum IntenseDeviceSyncStage {
  pending,
  fetching,
  converting,
  analyzing,
  done,
  error,
}

/// Formats [utc] for Insiders API `start`/`stop` query params.
///
/// Example: `2026-07-09T16:00:00+0000` (UTC, no subseconds, `+0000` not `.000Z`).
String formatInsidersApiTimestamp(DateTime utc) {
  final iso = utc.toUtc().toIso8601String();
  return iso.replaceFirst(RegExp(r'\.\d+Z$'), '+0000').replaceFirst('Z', '+0000');
}

/// Time window used for Insiders preprocessed fetch.
///
/// Start = scheduled training datetime ([Training.trainingStartAt] or
/// [Training.dateTime]); stop is capped to the training slot when a scheduled
/// end exists (start + [Training.duration] or [Training.trainingEndAt]):
/// `min(sync click, scheduled end)`. Early finish therefore analyzes only
/// elapsed time; late finish does not extend past the créneau.
/// Cloud must send `start`/`stop` query params (not `start_iso`/`stop_iso`).
/// Insiders returns HTTP 403 if [start] precedes manager-account ownership.
class TrainingIntenseTimeWindow {
  const TrainingIntenseTimeWindow({
    required this.start,
    required this.stop,
  });

  final DateTime start;
  final DateTime stop;

  int get startMs => start.toUtc().millisecondsSinceEpoch;
  int get stopMs => stop.toUtc().millisecondsSinceEpoch;

  Map<String, dynamic> toCloudPayload() {
    return <String, dynamic>{
      'start': formatInsidersApiTimestamp(start),
      'stop': formatInsidersApiTimestamp(stop),
    };
  }
}

/// One present player with an assigned Intense/SIM tracker to sync at finish.
class IntenseTrainingDeviceTarget {
  IntenseTrainingDeviceTarget({
    required this.playerId,
    required this.playerLabel,
    required this.trackerLabel,
    required this.insidersDeviceId,
    required this.trackerId,
    required this.deviceOwnerDocId,
    this.deviceOwnerDeviceId = '',
  });

  final String playerId;
  final String playerLabel;
  final String trackerLabel;
  final String insidersDeviceId;
  final String trackerId;
  final String deviceOwnerDocId;
  /// Raw `TRACKER_DeviceOwner.deviceId` for diagnostics (should match [insidersDeviceId]).
  final String deviceOwnerDeviceId;

  IntenseDeviceSyncStage stage = IntenseDeviceSyncStage.pending;
  double progress = 0;
  String? errorMessage;
}

TrainingIntenseTimeWindow resolveTrainingIntenseTimeWindow(
  Training training, {
  required DateTime syncStopAt,
}) {
  final startTs = training.trainingStartAt ?? training.dateTime;
  final startUtc = (startTs?.toDate() ?? syncStopAt).toUtc();
  final syncStopUtc = syncStopAt.toUtc();

  DateTime? scheduledEndUtc;
  if (training.isFinish == true && training.trainingEndAt != null) {
    scheduledEndUtc = training.trainingEndAt!.toDate().toUtc();
  } else {
    final durationMinutes = training.duration;
    if (durationMinutes != null && durationMinutes > 0) {
      scheduledEndUtc = startUtc.add(Duration(minutes: durationMinutes));
    }
  }

  final stopUtc = scheduledEndUtc == null
      ? syncStopUtc
      : (syncStopUtc.isBefore(scheduledEndUtc) ? syncStopUtc : scheduledEndUtc);

  return TrainingIntenseTimeWindow(
    start: startUtc,
    stop: stopUtc,
  );
}

/// Full créneau for a post-finish re-sync: [Training.dateTime] → [Training.trainingEndAt].
///
/// Unlike [resolveTrainingIntenseTimeWindow], this does **not** cap to "now".
TrainingIntenseTimeWindow? resolveTrainingIntenseResyncWindow(Training training) {
  final startLocal = training.dateTime?.toDate();
  final endLocal = training.trainingEndAt?.toDate();
  if (startLocal == null || endLocal == null) return null;

  final startUtc = startLocal.toUtc();
  final endUtc = endLocal.toUtc();
  if (!endUtc.isAfter(startUtc)) {
    return TrainingIntenseTimeWindow(start: startUtc, stop: startUtc);
  }
  return TrainingIntenseTimeWindow(start: startUtc, stop: endUtc);
}

/// How long managers may re-sync Intense data after [Training.trainingEndAt].
const Duration kTrainingIntenseResyncEligibility = Duration(hours: 48);

/// True when an Intense re-sync is allowed: [Training.dateTime] +
/// [Training.trainingEndAt] set, and [now] is within 48h after end.
bool canResyncTrainingIntense(Training training, {DateTime? now}) {
  if (training.withTracker != true) return false;
  if (training.dateTime == null) return false;
  final end = training.trainingEndAt?.toDate();
  if (end == null) return false;
  final clock = now ?? DateTime.now();
  if (clock.isBefore(end)) return false;
  final deadline = end.add(kTrainingIntenseResyncEligibility);
  return !clock.isAfter(deadline);
}

/// Full match window for finish/re-sync: kick-off → full-time (Temps forts).
TrainingIntenseTimeWindow? resolveMatchIntenseResyncWindow(
  models.Match match,
  List<Highlights> highlights,
) {
  final startLocal = matchSessionStartLocal(match, highlights);
  final endLocal =
      findTimeEventHighlight(highlights, TimeType.end)?.dateTime?.toDate();
  if (startLocal == null || endLocal == null) return null;

  final startUtc = startLocal.toUtc();
  final endUtc = endLocal.toUtc();
  if (!endUtc.isAfter(startUtc)) {
    return TrainingIntenseTimeWindow(start: startUtc, stop: startUtc);
  }
  return TrainingIntenseTimeWindow(start: startUtc, stop: endUtc);
}

/// Finish window: kick-off → min(now, full-time highlight).
TrainingIntenseTimeWindow? resolveMatchIntenseFinishWindow(
  models.Match match,
  List<Highlights> highlights, {
  required DateTime syncStopAt,
}) {
  final startLocal = matchSessionStartLocal(match, highlights);
  if (startLocal == null) return null;

  final startUtc = startLocal.toUtc();
  final syncStopUtc = syncStopAt.toUtc();
  final endLocal =
      findTimeEventHighlight(highlights, TimeType.end)?.dateTime?.toDate();
  final scheduledEndUtc = endLocal?.toUtc();

  final stopUtc = scheduledEndUtc == null
      ? syncStopUtc
      : (syncStopUtc.isBefore(scheduledEndUtc) ? syncStopUtc : scheduledEndUtc);

  return TrainingIntenseTimeWindow(start: startUtc, stop: stopUtc);
}

/// True when an Intense match re-sync is allowed (48h after full-time).
bool canResyncMatchIntense({
  required models.Match match,
  required List<Highlights> highlights,
  DateTime? now,
}) {
  if (match.withTracker != true) return false;
  if (match.isMatchPlayed != true) return false;
  if (matchSessionStartLocal(match, highlights) == null) return false;
  final end =
      findTimeEventHighlight(highlights, TimeType.end)?.dateTime?.toDate();
  if (end == null) return false;
  final clock = now ?? DateTime.now();
  if (clock.isBefore(end)) return false;
  final deadline = end.add(kTrainingIntenseResyncEligibility);
  return !clock.isAfter(deadline);
}

/// GNSS step floor for Intense analysis.
///
/// Must stay **0** to match the Live pipeline ([IntenseLiveDataService]): a
/// non-zero floor (e.g. 3 m) zeroes distance at typical Insiders sample rates
/// (sub-second steps are often under 3 m even at running speed).
const double kIntenseMinMeaningfulStepDistanceMeters = 0;

/// Keeps only samples whose timestamps fall within [window] (inclusive).
List<TrackerRaw> intenseSamplesWithinWindow(
  List<TrackerRaw> samples,
  TrainingIntenseTimeWindow window,
) {
  if (samples.isEmpty) return samples;

  final startMs = window.startMs;
  final stopMs = window.stopMs;
  return samples
      .where((s) => s.timeMs >= startMs && s.timeMs <= stopMs)
      .toList(growable: false);
}

/// Cloud + optional local fallback for Intense tracker recovery at training finish.
class TrainingIntenseSyncService {
  TrainingIntenseSyncService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  static const int _minRequiredSamples = 1;

  Future<void> syncDevice({
    required IntenseTrainingDeviceTarget target,
    required Training training,
    required TrainingIntenseTimeWindow window,
    FieldGpsCorners? fieldGpsCorners,
    void Function(IntenseTrainingDeviceTarget target)? onProgress,
  }) async {
    final trainingId = training.docId?.trim() ?? training.trainingId?.trim();
    if (trainingId == null || trainingId.isEmpty) {
      throw StateError('Training id missing');
    }

    final result = await analyzeDeviceWindow(
      target: target,
      window: window,
      eventId: trainingId,
      fieldGpsCorners: fieldGpsCorners,
      onProgress: onProgress,
      treatEmptyAsSuccess: true,
    );

    if (result == null) return;

    await TrackerAnalysisService.saveAnalysis(
      result,
      docId: '${trainingId}_${target.trackerId}',
      eventId: trainingId,
    );
  }

  /// Same Insiders pipeline as [syncDevice] for a match event id.
  Future<void> syncMatchDevice({
    required IntenseTrainingDeviceTarget target,
    required String matchId,
    required TrainingIntenseTimeWindow window,
    FieldGpsCorners? fieldGpsCorners,
    void Function(IntenseTrainingDeviceTarget target)? onProgress,
  }) async {
    final eventId = matchId.trim();
    if (eventId.isEmpty) {
      throw StateError('Match id missing');
    }

    final result = await analyzeDeviceWindow(
      target: target,
      window: window,
      eventId: eventId,
      fieldGpsCorners: fieldGpsCorners,
      onProgress: onProgress,
      treatEmptyAsSuccess: true,
      isMatch: true,
    );

    if (result == null) return;

    await TrackerAnalysisService.saveAnalysis(
      result,
      docId: '${eventId}_${target.trackerId}',
      eventId: eventId,
    );
  }

  /// Same Insiders fetch + local analysis as [syncDevice], without writing
  /// `TRACKER_Analysis`. Returns `null` when the GNSS window is empty.
  Future<TrackerAnalysisResult?> analyzeDeviceWindow({
    required IntenseTrainingDeviceTarget target,
    required TrainingIntenseTimeWindow window,
    required String eventId,
    FieldGpsCorners? fieldGpsCorners,
    void Function(IntenseTrainingDeviceTarget target)? onProgress,
    bool treatEmptyAsSuccess = true,
    bool isMatch = false,
  }) async {
    void emit(IntenseDeviceSyncStage stage, double progress) {
      target.stage = stage;
      target.progress = progress;
      onProgress?.call(target);
    }

    try {
      target.errorMessage = null;
      emit(IntenseDeviceSyncStage.fetching, 0.15);

      final insidersDeviceId = target.insidersDeviceId.trim();
      if (insidersDeviceId.isEmpty) {
        throw StateError(
          'Identifiant Insiders manquant pour ${target.trackerLabel}.',
        );
      }

      final windowPayload = window.toCloudPayload();
      final start = windowPayload['start'] as String;
      final stop = windowPayload['stop'] as String;
      final fetchPayload = <String, dynamic>{
        'insidersDeviceId': insidersDeviceId,
        'trackerId': target.trackerId,
        ...windowPayload,
      };

      debugPrint(
        '[IntenseSync] Insiders query → device=$insidersDeviceId start=$start stop=$stop',
      );
      debugPrint(
        '[IntenseSync] fetchIntensePreprocessedSamples → '
        'insidersDeviceId=$insidersDeviceId '
        'deviceOwner.deviceId=${target.deviceOwnerDeviceId} '
        'deviceOwnerDocId=${target.deviceOwnerDocId} '
        'trackerId=${target.trackerId}',
      );

      late final HttpsCallableResult<dynamic> fetchResult;
      try {
        fetchResult = await _fetchPreprocessedSamplesWithRetry(
          fetchPayload: fetchPayload,
          trackerLabel: target.trackerLabel,
          insidersDeviceId: insidersDeviceId,
        );
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'failed-precondition' &&
            _looksLikeEmptyGnssWindow(
              '${e.message ?? ''} ${e.details ?? ''}',
            )) {
          debugPrint(
            '[IntenseSync] fetchIntensePreprocessedSamples empty GNSS window '
            'for ${target.trackerLabel} — treating as success',
          );
          emit(IntenseDeviceSyncStage.done, 1);
          if (treatEmptyAsSuccess) return null;
          throw StateError(
            'Aucune donnée GNSS pour « ${target.trackerLabel} » '
            'sur la période demandée.',
          );
        }
        _logInsidersRequestUrlFromDetails(e.details, label: 'error');
        debugPrint(
          '[IntenseSync] fetchIntensePreprocessedSamples FAILED '
          'code=${e.code} message=${e.message} details=${e.details}',
        );
        rethrow;
      } catch (e) {
        debugPrint('[IntenseSync] fetchIntensePreprocessedSamples FAILED error=$e');
        rethrow;
      }

      final fetchData = Map<String, dynamic>.from(fetchResult.data as Map);
      _logInsidersRequestUrlFromDetails(fetchData, label: 'response');
      final insidersQuery = fetchData['insidersQuery'];
      if (insidersQuery is Map) {
        final q = Map<String, dynamic>.from(insidersQuery);
        debugPrint(
          '[IntenseSync] insidersQuery → start=${q['start']} stop=${q['stop']}',
        );
      }
      final metadataKeys = fetchData.keys.where((k) => k != 'samples').toList();
      debugPrint(
        '[IntenseSync] fetchIntensePreprocessedSamples OK '
        'sampleCount=${(fetchData['samples'] as List?)?.length ?? 0} '
        'hasAsiBase64=${fetchData['asiBase64'] != null && fetchData['asiBase64'].toString().isNotEmpty} '
        'metadataKeys=$metadataKeys',
      );
      final rawSamples = (fetchData['samples'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          <Map<String, dynamic>>[];

      emit(IntenseDeviceSyncStage.converting, 0.45);

      var samples = rawSamples
          .map(
            (s) => TrackerRaw(
              trackerId: target.trackerId,
              timeMs: _asInt(s['timeMs']),
              latitude: _asDouble(s['latitude']),
              longitude: _asDouble(s['longitude']),
              speedMps: _asDouble(s['speedMps']),
            ),
          )
          .toList(growable: false);

      final asiBase64 = fetchData['asiBase64']?.toString();
      if (samples.length < _minRequiredSamples &&
          asiBase64 != null &&
          asiBase64.isNotEmpty) {
        final csv = await _convertAsiBase64ToCsv(asiBase64);
        samples = _samplesFromCsv(csv, trackerId: target.trackerId);
      }

      samples = intenseSamplesWithinWindow(samples, window);

      if (samples.length < _minRequiredSamples) {
        debugPrint(
          '[IntenseSync] no GNSS samples for ${target.trackerLabel} '
          'on requested window'
          '${treatEmptyAsSuccess ? ' — empty result' : ''}',
        );
        emit(IntenseDeviceSyncStage.done, 1);
        if (treatEmptyAsSuccess) return null;
        throw StateError(
          'Aucune donnée GNSS pour « ${target.trackerLabel} » '
          'sur la période demandée.',
        );
      }

      emit(IntenseDeviceSyncStage.analyzing, 0.7);

      FootballFieldGps? fieldGps;
      if (fieldGpsCorners != null) {
        fieldGps = FootballFieldGps.fromFieldGpsCorners(fieldGpsCorners);
      }

      final result = SensorAnalysisService.analyzeSensorData(
        trackerId: target.trackerId,
        playerId: target.playerId,
        eventId: eventId,
        allSamples: samples,
        isMatch: isMatch,
        fieldGps: fieldGps,
        minMeaningfulStepDistanceMeters: kIntenseMinMeaningfulStepDistanceMeters,
      );

      emit(IntenseDeviceSyncStage.done, 1);
      return result;
    } catch (e) {
      target.errorMessage = formatIntenseSyncError(e, target: target);
      debugPrint(
        '[IntenseSync] analyzeDeviceWindow FAILED trackerId=${target.trackerId} '
        'insidersDeviceId=${target.insidersDeviceId} '
        'errorMessage=${target.errorMessage}',
      );
      emit(IntenseDeviceSyncStage.error, target.progress);
      rethrow;
    }
  }

  /// Same Insiders 429 backoff as [IntenseLiveDataService._fetchSamples].
  Future<HttpsCallableResult<dynamic>> _fetchPreprocessedSamplesWithRetry({
    required Map<String, dynamic> fetchPayload,
    required String trackerLabel,
    required String insidersDeviceId,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < kIntenseInsidersFetchMaxAttempts; attempt++) {
      try {
        return await _functions
            .httpsCallable('fetchIntensePreprocessedSamples')
            .call(fetchPayload);
      } on FirebaseFunctionsException catch (e) {
        lastError = e;
        if (!_isInsidersRateLimited(e) ||
            attempt >= kIntenseInsidersFetchMaxAttempts - 1) {
          rethrow;
        }
        final delay = _retryDelayForRateLimit(e, attempt);
        debugPrint(
          '[IntenseSync] Insiders 429 for tracker=$trackerLabel '
          'device=$insidersDeviceId '
          'attempt=${attempt + 1}/$kIntenseInsidersFetchMaxAttempts '
          'retryIn=${delay.inMilliseconds}ms',
        );
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

  static Duration _retryDelayForRateLimit(
    FirebaseFunctionsException e,
    int attempt,
  ) {
    final raw = '${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
    final match = RegExp(r'retry-after:\s*(\d+)').firstMatch(raw);
    if (match != null) {
      final seconds = int.tryParse(match.group(1)!) ?? 1;
      return Duration(milliseconds: (seconds.clamp(1, 15) * 1000) + 250);
    }
    return Duration(milliseconds: 600 * (1 << attempt));
  }

  /// Maps cloud/local errors to user-facing French messages for the finish dialog.
  static String formatIntenseSyncError(
    Object error, {
    required IntenseTrainingDeviceTarget target,
  }) {
    final raw = error.toString();

    if (error is FirebaseFunctionsException) {
      if (error.code == 'permission-denied') {
        return _permissionDeniedMessage(target);
      }
      if (error.code == 'failed-precondition' &&
          _looksLikeEmptyGnssWindow(raw)) {
        return _noGnssDataMessage(target);
      }
      if (error.code == 'not-found') {
        return 'Capteur Insiders introuvable pour « ${target.trackerLabel} » '
            '(identifiant ${target.insidersDeviceId}). '
            'Vérifiez la synchronisation Inspirit dans l\'admin.';
      }
      if (error.code == 'invalid-argument' &&
          raw.toLowerCase().contains('insidersdeviceid')) {
        return 'Identifiant Insiders invalide pour « ${target.trackerLabel} » '
            '(${target.insidersDeviceId}).';
      }
    }

    final lower = raw.toLowerCase();
    if (lower.contains('429') ||
        lower.contains('too many requests') ||
        lower.contains('throttl')) {
      return 'API Insiders saturée temporairement pour « ${target.trackerLabel} ». '
          'Réessayez dans quelques secondes.';
    }

    if (raw.contains('403') ||
        raw.contains('You do not have permission') ||
        raw.contains('permission-denied')) {
      return _permissionDeniedMessage(target);
    }

    if (error is StateError) {
      return raw.replaceFirst('Bad state: ', '');
    }

    return raw;
  }

  static String _permissionDeniedMessage(IntenseTrainingDeviceTarget target) {
    return 'Accès refusé Insiders pour « ${target.trackerLabel} » : '
        'la période demandée (start/stop) ne doit pas commencer avant '
        'l\'affectation du capteur au compte manager Insiders '
        '(TRACKER_SERVER_CONFIG). Vérifiez l\'horaire de l\'entraînement '
        'par rapport à la date d\'affectation côté Insiders.';
  }

  static void _logInsidersRequestUrlFromDetails(
    Object? details, {
    required String label,
  }) {
    if (details is! Map) return;
    final map = Map<String, dynamic>.from(details);
    final url = map['insidersRequestUrl'] ??
        map['requestUrl'] ??
        map['url'] ??
        map['insidersUrl'] ??
        map['request_url'];
    if (url == null || url.toString().trim().isEmpty) return;
    debugPrint('[IntenseSync] Insiders request URL ($label): $url');
  }

  static bool _looksLikeEmptyGnssWindow(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('no gnss data') ||
        lower.contains('no sensor samples') ||
        lower.contains('count=0');
  }

  static String _noGnssDataMessage(IntenseTrainingDeviceTarget target) {
    return 'Aucune donnée GNSS pour « ${target.trackerLabel} » sur la période '
        'demandée : le capteur doit être utilisé en extérieur. '
        '(Une réponse Insiders vide n\'est pas une erreur d\'accès.)';
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
