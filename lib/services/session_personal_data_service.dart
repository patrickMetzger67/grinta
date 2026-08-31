import 'package:flutter/foundation.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/timeRange.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/services/personal_gps_sync_service.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';
import 'package:grinta/services/tracker_field_service.dart';
import 'package:grinta/services/training_intense_sync_service.dart';
import 'package:grinta/util/match_usb_sync_window.dart';
import 'package:grinta/util/training_finish_helper.dart';

/// First half duration for individual live GPS match sync (minutes).
const int kPersonalMatchGpsFirstHalfMinutes = 45;

/// Half-time break for individual live GPS match sync (minutes).
const int kPersonalMatchGpsHalftimeBreakMinutes = 15;

/// Second half duration for individual live GPS match sync (minutes).
const int kPersonalMatchGpsSecondHalfMinutes = 45;

/// Extra tolerance after full-time for injury / added time (minutes).
const int kPersonalMatchGpsInjuryTimeToleranceMinutes = 10;

/// Total Insiders fetch span from confirmed kick-off for a 90' match.
const int kPersonalMatchGpsTotalSpanMinutes =
    kPersonalMatchGpsFirstHalfMinutes +
    kPersonalMatchGpsHalftimeBreakMinutes +
    kPersonalMatchGpsSecondHalfMinutes +
    kPersonalMatchGpsInjuryTimeToleranceMinutes;

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

  /// Builds the Insiders window for an individual match GPS sync.
  ///
  /// Span from [kickOff]: 45' + 15' break + 45' + 10' added-time tolerance.
  /// [now] caps the stop when the match is still in progress.
  static SessionPersonalDataWindow resolveMatchGpsWindow({
    required DateTime kickOff,
    DateTime? now,
  }) {
    final clock = (now ?? DateTime.now()).toLocal();
    final start = kickOff.toLocal();
    var stop = start.add(
      const Duration(minutes: kPersonalMatchGpsTotalSpanMinutes),
    );
    if (clock.isBefore(stop)) stop = clock;
    if (!stop.isAfter(start)) {
      stop = start.add(const Duration(minutes: 1));
    }
    return SessionPersonalDataWindow(start: start, stop: stop);
  }

  static SessionPersonalDataWindow resolveWindow({
    required AgendaItem item,
    DateTime? matchKickOff,
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

    final kickOff = matchKickOff ?? item.startAt;
    return resolveMatchGpsWindow(kickOff: kickOff, now: clock);
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
    DateTime? matchKickOff,
    void Function(IntenseDeviceSyncStage stage)? onStage,
  }) async {
    final eventId = item.id.trim();
    if (eventId.isEmpty) {
      throw StateError('Event id missing');
    }

    final isMatch = item.match != null;
    final sessionWindow = SessionPersonalDataService.resolveWindow(
      item: item,
      matchKickOff: isMatch ? matchKickOff : null,
    );
    final fieldCorners = await resolveFieldGpsCorners(item);
    final intenseWindow = _intenseWindowForItem(sessionWindow: sessionWindow);
    final heatmapPlayPeriods = _matchPlayPeriodsForHeatmaps(
      item: item,
      matchKickOff: matchKickOff,
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
      'heatmapPlayPeriods=${heatmapPlayPeriods.length}',
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
      playPeriods: heatmapPlayPeriods,
    );

    await computeTeamWorkloadSummaryForEvent(
      eventId: eventId,
      training: item.training,
    );

    return result;
  }

  /// Builds the Insiders window for personal GPS.
  ///
  /// Matches use the player-confirmed kick-off plage (45' + 15' + 45' + 10').
  /// Play periods are omitted here so half-time samples stay in overall
  /// analysis; H1/H2 heatmaps use [_matchPlayPeriodsForHeatmaps] separately.
  TrainingIntenseTimeWindow _intenseWindowForItem({
    required SessionPersonalDataWindow sessionWindow,
  }) {
    var start = sessionWindow.start;
    var stop = sessionWindow.stop;
    if (!stop.isAfter(start)) {
      stop = start.add(const Duration(minutes: 1));
    }
    return TrainingIntenseTimeWindow(
      start: start.toUtc(),
      stop: stop.toUtc(),
    );
  }

  /// Scheduled 1st/2nd half bounds for match heatmaps (excludes lead/trail).
  List<TimeRange> _matchPlayPeriodsForHeatmaps({
    required AgendaItem item,
    DateTime? matchKickOff,
  }) {
    final match = item.match;
    if (match == null) return const <TimeRange>[];

    return resolveMatchSensorSyncPeriods(
      match: match,
      highlights: const <Highlights>[],
      fallbackStart: matchKickOff ?? item.startAt,
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
