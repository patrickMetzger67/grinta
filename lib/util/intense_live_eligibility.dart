import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/tracker/owner.dart';
import 'package:grinta/model/tracker_owner.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/util/buildTimestampFromDateAndTime.dart';
import 'package:grinta/util/highlight_minute_helper.dart';
import 'package:grinta/util/training_creation_helper.dart';
import 'package:grinta/util/training_finish_helper.dart';

/// True when the owner streams via Intense cloud (no USB sync).
///
/// Older `TRACKER_Owner` docs may omit [Owner.withSyncing]; those default to
/// `true` in [Owner.fromMap] even when [Owner.typeTracker] is `intense`.
bool ownerUsesIntenseCloudSync(Owner owner) {
  if (!TrackerOwner.withSyncingForType(owner.typeTracker)) {
    return true;
  }
  return !owner.withSyncing;
}

/// Returns true when the linked tracker kit uses Intense cloud sync (no USB).
Future<bool> isIntenseTrackerOwner(String? ownerId) async {
  final id = ownerId?.trim();
  if (id == null || id.isEmpty) return false;

  try {
    final owner = await OwnerService().getOwnerById(id);
    final isIntense = owner != null && ownerUsesIntenseCloudSync(owner);
    if (kDebugMode) {
      debugPrint(
        '[IntenseLive] ownerId=$id found=${owner != null} '
        'type=${owner?.typeTracker} withSyncing=${owner?.withSyncing} '
        'eligible=$isIntense',
      );
    }
    return isIntense;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[IntenseLive] ownerId=$id fetch failed: $e\n$st');
    }
    return false;
  }
}

int _trainingDurationMinutes(Training training) {
  final duration = training.duration;
  if (duration != null && duration > 0) {
    return duration;
  }
  return 0;
}

/// Scheduled training start from the créneau horaire: [Training.startTime] on
/// [Training.dateTg] (or the local date from [Training.dateTime]).
///
/// Ignores [Training.trainingStartAt].
DateTime? trainingScheduledStart(Training training) {
  final startTime = training.startTime?.trim();
  DateTime? date = parseTrainingDateTg(training.dateTg);
  date ??= training.dateTime != null
      ? DateUtils.dateOnly(training.dateTime!.toDate())
      : null;

  if (date != null && startTime != null && startTime.isNotEmpty) {
    final timeOfDay = parseTrainingTime(startTime);
    if (timeOfDay != null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
    }
  }

  return training.dateTime?.toDate();
}

/// Scheduled training end from duration, explicit end time, or agenda fallback.
///
/// Ignores [Training.trainingStartAt]. Uses [Training.trainingEndAt] only when
/// the session is finished.
DateTime? trainingScheduledEndAt(Training training, DateTime scheduledStart) {
  if (isTrainingFinished(training) && training.trainingEndAt != null) {
    return training.trainingEndAt!.toDate();
  }

  final durationMinutes = _trainingDurationMinutes(training);
  if (durationMinutes > 0) {
    return scheduledStart.add(Duration(minutes: durationMinutes));
  }

  final dateTg = training.dateTg?.trim();
  final endTime = training.endTime?.trim();
  if (dateTg != null &&
      dateTg.isNotEmpty &&
      endTime != null &&
      endTime.isNotEmpty) {
    try {
      return buildTimestampFromDateAndTime(
        date: dateTg,
        time: endTime,
      ).toDate();
    } catch (_) {}
  }

  return null;
}

/// Live window: [Training.dateTime] ≤ now < [Training.dateTime] + [Training.duration].
bool isTrainingSessionLive({
  required Training training,
  DateTime? scheduledStart,
  DateTime? scheduledEnd,
  DateTime? now,
}) {
  if (training.withTracker != true) return false;
  if (training.isFinish == true) return false;

  final start = training.dateTime?.toDate() ?? scheduledStart;
  if (start == null) return false;

  final durationMinutes = training.duration;
  if (durationMinutes == null || durationMinutes <= 0) return false;

  final end = start.add(Duration(minutes: durationMinutes));
  final clock = now ?? DateTime.now();
  return !clock.isBefore(start) && clock.isBefore(end);
}

/// Match session is live-eligible: kick-off known (recorded or scheduled),
/// full-time not reached, and [now] is at/after kick-off.
bool isMatchSessionLive({
  required models.Match match,
  required List<Highlights> highlights,
  DateTime? now,
}) {
  if (match.withTracker != true) return false;
  if (match.isMatchPlayed == true) return false;

  final end = findTimeEventHighlight(highlights, TimeType.end);
  if (end?.dateTime != null) return false;

  final kickOffAt = matchSessionStartLocal(match, highlights);
  if (kickOffAt == null) return false;

  final clock = now ?? DateTime.now();
  return !clock.isBefore(kickOffAt);
}

/// Local kick-off: recorded Temps forts highlight, else scheduled match time.
DateTime? matchSessionStartLocal(
  models.Match match,
  List<Highlights> highlights,
) {
  final kickOff = findTimeEventHighlight(highlights, TimeType.kickOff);
  final recorded = kickOff?.dateTime?.toDate();
  if (recorded != null) return recorded;
  return matchKickoffDateTime(match);
}

/// Session start for Insiders fetch (UTC).
DateTime intenseLiveTrainingStartUtc(Training training) {
  final startTs = training.trainingStartAt ?? training.dateTime;
  return (startTs?.toDate() ?? DateTime.now()).toUtc();
}

/// Session start for Insiders fetch (UTC): kick-off highlight, else schedule.
DateTime? intenseLiveMatchStartUtc(
  List<Highlights> highlights, {
  models.Match? match,
}) {
  final kickOff = findTimeEventHighlight(highlights, TimeType.kickOff);
  final recorded = kickOff?.dateTime?.toDate();
  if (recorded != null) return recorded.toUtc();
  if (match == null) return null;
  return matchKickoffDateTime(match)?.toUtc();
}
