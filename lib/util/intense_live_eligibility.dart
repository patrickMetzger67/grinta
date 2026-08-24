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
import 'package:grinta/util/match_usb_sync_window.dart';
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

/// Match Live window for noSync / Intense cloud kits.
///
/// Does **not** require a Temps forts kick-off highlight. Uses the calendar
/// kick-off ([Match.dateCh]/[Match.timeCh], [scheduledStart], or field-linked
/// [Match.timestamp]) first, then a recorded kick-off only as fallback. Ends at
/// full-time highlight, else schedule + duration + 15' break (or [scheduledEnd]).
bool isMatchSessionLive({
  required models.Match match,
  required List<Highlights> highlights,
  DateTime? scheduledStart,
  DateTime? scheduledEnd,
  DateTime? now,
}) {
  if (match.withTracker != true) return false;
  if (match.isMatchPlayed == true) return false;

  final endHighlight =
      findTimeEventHighlight(highlights, TimeType.end)?.dateTime?.toDate();
  if (endHighlight != null) return false;

  final kickOffAt = matchLiveStartLocal(
    match,
    highlights,
    scheduledStart: scheduledStart,
  );
  if (kickOffAt == null) return false;

  final clock = now ?? DateTime.now();
  if (clock.isBefore(kickOffAt)) return false;

  final endAt = scheduledEnd ??
      matchIntenseScheduledEndLocal(match, kickOffAt) ??
      kickOffAt.add(const Duration(minutes: 90));
  return clock.isBefore(endAt);
}

/// Calendar kick-off when Temps forts are missing.
///
/// Order: [Match.dateCh]/[timeCh] → [scheduledStart] → field-linked
/// [Match.timestamp].
DateTime? matchCalendarKickoffLocal(
  models.Match match, {
  DateTime? scheduledStart,
}) {
  return matchKickoffDateTime(match) ??
      scheduledStart ??
      match.timestamp?.toDate();
}

/// Live kick-off: **calendar first** (no Temps forts required), then recorded.
DateTime? matchLiveStartLocal(
  models.Match match,
  List<Highlights> highlights, {
  DateTime? scheduledStart,
}) {
  final scheduled = matchCalendarKickoffLocal(
    match,
    scheduledStart: scheduledStart,
  );
  if (scheduled != null) return scheduled;

  final kickOff = findTimeEventHighlight(highlights, TimeType.kickOff);
  return kickOff?.dateTime?.toDate();
}

/// Scheduled full-time from kick-off + duration + 15' half-time break.
///
/// Same wall-clock slot as sensor sync periods without Temps forts
/// (`duration/2` + 15' + `duration/2`).
DateTime? matchIntenseScheduledEndLocal(
  models.Match match,
  DateTime kickOffAt,
) {
  final durationMinutes = match.duration ?? 90;
  return matchScheduledSlotEnd(kickOffAt, durationMinutes);
}

/// Local kick-off for Insiders windows: recorded Temps forts, else calendar.
DateTime? matchSessionStartLocal(
  models.Match match,
  List<Highlights> highlights,
) {
  final kickOff = findTimeEventHighlight(highlights, TimeType.kickOff);
  final recorded = kickOff?.dateTime?.toDate();
  if (recorded != null) return recorded;
  return matchCalendarKickoffLocal(match);
}

/// Session start for Insiders fetch (UTC).
DateTime intenseLiveTrainingStartUtc(Training training) {
  final startTs = training.trainingStartAt ?? training.dateTime;
  return (startTs?.toDate() ?? DateTime.now()).toUtc();
}

/// Session start for Live / Insiders fetch (UTC).
///
/// Prefers the calendar kick-off (date/time, agenda, or [Match.timestamp]) so
/// Live / re-sync work without a Temps forts « début de match ». Falls back to
/// a recorded kick-off when present.
DateTime? intenseLiveMatchStartUtc(
  List<Highlights> highlights, {
  models.Match? match,
  DateTime? scheduledStart,
}) {
  if (match != null) {
    final liveStart = matchLiveStartLocal(
      match,
      highlights,
      scheduledStart: scheduledStart,
    );
    if (liveStart != null) return liveStart.toUtc();
  }
  final kickOff = findTimeEventHighlight(highlights, TimeType.kickOff);
  return kickOff?.dateTime?.toDate().toUtc();
}
