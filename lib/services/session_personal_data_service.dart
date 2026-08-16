import 'package:flutter/foundation.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/services/personal_gps_sync_service.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';
import 'package:grinta/services/tracker_field_service.dart';
import 'package:grinta/services/training_intense_sync_service.dart';
import 'package:grinta/util/match_usb_sync_window.dart';
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

  /// True when the agenda event is a training/match without a usable team kit.
  ///
  /// Shown when tracker mode is off, or when no owner is assigned on the event
  /// (team has no kit attributed to this session).
  ///
  /// The agenda control also requires an active individual owner whose email
  /// matches the profile (see [PersonalGpsSyncService.hasIndividualOwnerForEmails]).
  static bool isEligibleAgendaItem(AgendaItem item) {
    if (item.training == null && item.match == null) return false;
    final ownerId =
        (item.training?.ownerId ?? item.match?.ownerId)?.trim() ?? '';
    if (item.withTracker == true && ownerId.isNotEmpty) {
      return false;
    }
    return true;
  }

  static SessionPersonalDataWindow resolveWindow({
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
    // Include the 15' half-time break (same slot as USB / Intense).
    var stop = matchScheduledSlotEnd(start, durationMinutes);
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
  /// Always attempts a heatmap: schematic when field GPS corners exist,
  /// otherwise Google satellite fitted to the collected GPS samples.
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

    final sessionWindow = SessionPersonalDataService.resolveWindow(item: item);
    final fieldCorners = await resolveFieldGpsCorners(item);
    final isMatch = item.match != null;
    final intenseWindow = _intenseWindowForItem(
      item: item,
      sessionWindow: sessionWindow,
    );

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
      'start=${intenseWindow.start} stop=${intenseWindow.stop} '
      'hasFieldGps=${fieldCorners != null} '
      'playPeriods=${intenseWindow.playPeriods.length}',
    );

    final outcome = await _intenseSyncService.analyzeDeviceWindow(
      target: target,
      window: intenseWindow,
      eventId: eventId,
      fieldGpsCorners: fieldCorners,
      treatEmptyAsSuccess: true,
      isMatch: isMatch,
      onProgress: (t) => onStage?.call(t.stage),
    );
    if (outcome == null) return null;
    final result = outcome.result;

    final docId = '${eventId}_${device.trackerId}';
    await TrackerAnalysisService.saveAnalysis(
      result,
      docId: docId,
      eventId: eventId,
      isMatch: isMatch,
    );

    await _intenseSyncService.persistIntenseHeatmaps(
      trackerId: device.trackerId,
      playerId: playerId,
      eventId: eventId,
      samples: outcome.samples,
      result: result,
      fieldGps: outcome.fieldGps,
      isMatch: isMatch,
      playPeriods: intenseWindow.playPeriods,
    );

    await computeTeamWorkloadSummaryForEvent(
      eventId: eventId,
      training: item.training,
    );

    return result;
  }

  /// Builds the Insiders window; matches get half play periods (no Temps forts
  /// on the agenda path → scheduled halves + 15' break).
  TrainingIntenseTimeWindow _intenseWindowForItem({
    required AgendaItem item,
    required SessionPersonalDataWindow sessionWindow,
  }) {
    final match = item.match;
    if (match == null) {
      return TrainingIntenseTimeWindow(
        start: sessionWindow.start.toUtc(),
        stop: sessionWindow.stop.toUtc(),
      );
    }

    final playPeriods = resolveMatchSensorSyncPeriods(
      match: match,
      highlights: const <Highlights>[],
      fallbackStart: sessionWindow.start,
    );
    var start = sessionWindow.start;
    var stop = sessionWindow.stop;
    if (playPeriods.isNotEmpty) {
      start = playPeriods.first.start.toDate();
      final lastEnd = playPeriods.last.end.toDate();
      // Prefer full play window; shrink only when resolveWindow already
      // clock-capped an in-progress match (stop < scheduled last period end).
      stop = sessionWindow.stop.isBefore(lastEnd)
          ? sessionWindow.stop
          : lastEnd;
    }
    if (!stop.isAfter(start)) {
      stop = start.add(const Duration(minutes: 1));
    }
    return TrainingIntenseTimeWindow(
      start: start.toUtc(),
      stop: stop.toUtc(),
      playPeriods: playPeriods,
    );
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
}
