import 'package:flutter/foundation.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/services/personal_gps_sync_service.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';
import 'package:grinta/services/tracker_field_service.dart';
import 'package:grinta/services/training_intense_sync_service.dart';
import 'package:grinta/util/heatmap_svg_generator.dart';
import 'package:grinta/util/training_finish_helper.dart';

/// Time window used when attaching personal GPS / app data to a session.
class SessionPersonalDataWindow {
  const SessionPersonalDataWindow({
    required this.start,
    required this.stop,
  });

  final DateTime start;
  final DateTime stop;
}

/// Attaches a player's personal GPS or connected-app metrics to a training/match
/// that has no team tracker kit assigned.
class SessionPersonalDataService {
  SessionPersonalDataService({
    TrainingIntenseSyncService? intenseSyncService,
    TrackerFieldService? trackerFieldService,
  })  : _intenseSyncService =
            intenseSyncService ?? TrainingIntenseSyncService(),
        _trackerFieldService = trackerFieldService ?? TrackerFieldService();

  final TrainingIntenseSyncService _intenseSyncService;
  final TrackerFieldService _trackerFieldService;

  /// True when the agenda event is a training/match without a kit owner.
  static bool isEligibleAgendaItem(AgendaItem item) {
    if (item.training == null && item.match == null) return false;
    return item.withTracker != true;
  }

  SessionPersonalDataWindow resolveWindow({
    required AgendaItem item,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final training = item.training;
    if (training != null) {
      final start = (training.trainingStartAt?.toDate() ??
              training.dateTime?.toDate() ??
              item.startAt)
          .toLocal();
      DateTime stop;
      if (training.trainingEndAt != null) {
        stop = training.trainingEndAt!.toDate().toLocal();
      } else if (training.duration != null && training.duration! > 0) {
        stop = start.add(Duration(minutes: training.duration!));
      } else {
        stop = item.endAt;
      }
      if (!stop.isAfter(start)) {
        stop = clock.isAfter(start) ? clock : start.add(const Duration(minutes: 1));
      }
      final cappedStop = clock.isBefore(stop) ? clock : stop;
      return SessionPersonalDataWindow(
        start: start,
        stop: cappedStop.isAfter(start)
            ? cappedStop
            : start.add(const Duration(minutes: 1)),
      );
    }

    final match = item.match;
    final start = item.startAt;
    final durationMinutes = match?.duration ?? 90;
    var stop = start.add(Duration(minutes: durationMinutes));
    if (clock.isBefore(stop)) stop = clock;
    if (!stop.isAfter(start)) {
      stop = start.add(const Duration(minutes: 1));
    }
    return SessionPersonalDataWindow(start: start, stop: stop);
  }

  Future<FieldGpsCorners?> resolveFieldGpsCorners(AgendaItem item) async {
    final match = item.match;
    if (match?.fieldGpsCorners != null) {
      return match!.fieldGpsCorners;
    }

    final fieldId = (match?.fieldId ?? item.training?.fieldId)?.trim() ?? '';
    if (fieldId.isEmpty) return null;
    final field = await _trackerFieldService.getById(fieldId);
    return field?.fieldGpsCorners;
  }

  /// Syncs personal Intense GPS into [TRACKER_Analysis] for [eventId].
  ///
  /// Generates a pitch heatmap SVG when field GPS corners are available.
  Future<TrackerAnalysisResult?> attachGps({
    required AgendaItem item,
    required String playerId,
    required PersonalGpsDeviceOption device,
    void Function(IntenseDeviceSyncStage stage)? onStage,
  }) async {
    final eventId = item.id.trim();
    if (eventId.isEmpty) {
      throw StateError('Event id missing');
    }

    final window = resolveWindow(item: item);
    final fieldCorners = await resolveFieldGpsCorners(item);
    final isMatch = item.match != null;

    final target = IntenseTrainingDeviceTarget(
      playerId: playerId,
      playerLabel: playerId,
      trackerLabel: device.label,
      insidersDeviceId: device.insidersDeviceId,
      trackerId: device.trackerId,
      deviceOwnerDocId: device.deviceOwner.id,
      deviceOwnerDeviceId: device.deviceOwner.deviceId.trim(),
    );

    debugPrint(
      '[SessionPersonalData] GPS sync → event=$eventId '
      'player=$playerId device=${device.insidersDeviceId} '
      'start=${window.start.toUtc()} stop=${window.stop.toUtc()} '
      'hasFieldGps=${fieldCorners != null}',
    );

    final result = await _intenseSyncService.analyzeDeviceWindow(
      target: target,
      window: TrainingIntenseTimeWindow(
        start: window.start.toUtc(),
        stop: window.stop.toUtc(),
      ),
      eventId: eventId,
      fieldGpsCorners: fieldCorners,
      treatEmptyAsSuccess: true,
      isMatch: isMatch,
      onProgress: (t) => onStage?.call(t.stage),
    );
    if (result == null) return null;

    final docId = '${eventId}_${device.trackerId}';
    await TrackerAnalysisService.saveAnalysis(
      result,
      docId: docId,
      eventId: eventId,
      isMatch: isMatch,
    );

    if (fieldCorners != null && result.heatmapPoints.isNotEmpty) {
      await _saveHeatmapSvgs(
        eventId: eventId,
        trackerId: device.trackerId,
        result: result,
        fieldCorners: fieldCorners,
      );
    }

    await computeTeamWorkloadSummaryForEvent(
      eventId: eventId,
      training: item.training,
    );

    return result;
  }

  /// Persists connected-app metrics (no heatmap) as [TRACKER_Analysis].
  Future<TrackerAnalysisResult> attachAppMetrics({
    required AgendaItem item,
    required String playerId,
    required String sourceId,
    required int? durationSeconds,
    required double? distanceMeters,
  }) async {
    final eventId = item.id.trim();
    if (eventId.isEmpty) {
      throw StateError('Event id missing');
    }

    final seconds = (durationSeconds ?? 0).clamp(0, 24 * 3600);
    final meters = (distanceMeters ?? 0).clamp(0, 1000000).toDouble();
    if (seconds <= 0 && meters <= 0) {
      throw StateError('Aucune métrique à associer.');
    }

    final distanceKm = meters / 1000.0;
    final duration = Duration(seconds: seconds);
    final averageSpeedKmh = seconds > 0
        ? distanceKm / (seconds / 3600.0)
        : 0.0;
    final trackerId = 'app_$sourceId';

    final result = TrackerAnalysisResult(
      trackerId: trackerId,
      playerId: playerId,
      eventId: eventId,
      distanceKm: distanceKm,
      duration: duration,
      averageSpeedKmh: averageSpeedKmh,
      maxSpeedKmh: 0,
      maxValidatedSpeedKmh: 0,
      samplesCount: 0,
      heatmapPoints: const [],
      sprintCount: 0,
      highAccelerationCount: 0,
      highSpeedDuration: Duration.zero,
      maxAccelerationMps2: 0,
      distanceByZones: const [],
      speedZones: const [],
      halfStats: const [],
      workloadScore: 0,
      workloadScorePerMinute: 0,
      playerProfile: sourceId,
      fatigueIndex: 0,
      firstHalfDistanceKm: distanceKm / 2,
      secondHalfDistanceKm: distanceKm / 2,
      distanceTimeline: const [],
    );

    await TrackerAnalysisService.saveAnalysis(
      result,
      docId: '${eventId}_${trackerId}_$playerId',
      eventId: eventId,
      isMatch: item.match != null,
    );

    await computeTeamWorkloadSummaryForEvent(
      eventId: eventId,
      training: item.training,
    );

    return result;
  }

  Future<void> _saveHeatmapSvgs({
    required String eventId,
    required String trackerId,
    required TrackerAnalysisResult result,
    required FieldGpsCorners fieldCorners,
  }) async {
    FootballFieldGps fieldGps;
    try {
      fieldGps = FootballFieldGps.fromFieldGpsCorners(fieldCorners);
    } catch (e, st) {
      debugPrint('[SessionPersonalData] field GPS invalid, skip heatmap: $e\n$st');
      return;
    }

    final svg = HeatmapSvgGenerator.generateSvg(
      field: fieldGps,
      heatmapPoints: result.heatmapPoints,
      flipX: false,
      flipY: false,
      svgWidth: 1600,
      svgHeight: 1000,
    );
    await HeatmapSvgGenerator.saveSvgToFirestore(
      fileName: '${trackerId}-${eventId}_fullMatch',
      svg: svg,
    );
    debugPrint(
      '[SessionPersonalData] heatmap saved → '
      '${trackerId}-${eventId}_fullMatch',
    );
  }
}
