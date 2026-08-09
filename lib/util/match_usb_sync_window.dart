import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/timeRange.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/util/highlight_minute_helper.dart';

/// Default half-time break used when Temps forts are missing.
const int kMatchUsbSyncHalftimeBreakMinutes = 15;

/// Wall-clock end of a scheduled match slot including the half-time break:
/// `start + duration/2 + 15' + duration/2` (= `start + duration + 15'` when even).
DateTime matchScheduledSlotEnd(DateTime start, int durationMinutes) {
  final minutes = durationMinutes > 0 ? durationMinutes : 90;
  final halfMinutes = minutes ~/ 2;
  return start.add(
    Duration(
      minutes: halfMinutes + kMatchUsbSyncHalftimeBreakMinutes + halfMinutes,
    ),
  );
}

/// Sensor sync periods for a match (USB `withSyncing=true` and Intense `false`).
///
/// - With Temps forts début + fin (`kickOff` + `end`): use those wall times
///   (split into halves when mi-temps / reprise are present).
/// - Otherwise (no usable Temps forts): two scheduled halves with a 15'
///   break —
///   1st `[start, start + duration/2]`,
///   2nd `[start + duration/2 + 15min, start + duration + 15min]`.
///
/// [fallbackStart] overrides [Match.timestamp] / schedule for the no-highlights
/// path (Intense prefers `dateCh`/`timeCh`).
///
/// Never returns [TimeRange] built from nulls (that used to collapse to
/// `now→now` and filter out every sample → download spinner then back to
/// « Télécharger » with no data).
List<TimeRange> resolveMatchSensorSyncPeriods({
  required models.Match match,
  required List<Highlights> highlights,
  DateTime? fallbackStart,
}) {
  final DateTime? kickOff =
      findTimeEventHighlight(highlights, TimeType.kickOff)?.dateTime?.toDate();
  final DateTime? halfTime =
      findTimeEventHighlight(highlights, TimeType.halTime)?.dateTime?.toDate();
  final DateTime? secondHalf =
      findTimeEventHighlight(highlights, TimeType.secondHalf)
          ?.dateTime
          ?.toDate();
  final DateTime? fullTime =
      findTimeEventHighlight(highlights, TimeType.end)?.dateTime?.toDate();

  if (kickOff != null &&
      fullTime != null &&
      fullTime.isAfter(kickOff)) {
    if (halfTime != null &&
        secondHalf != null &&
        halfTime.isAfter(kickOff) &&
        !secondHalf.isBefore(halfTime) &&
        fullTime.isAfter(secondHalf)) {
      return <TimeRange>[
        TimeRange(
          start: Timestamp.fromDate(kickOff),
          end: Timestamp.fromDate(halfTime),
        ),
        TimeRange(
          start: Timestamp.fromDate(secondHalf),
          end: Timestamp.fromDate(fullTime),
        ),
      ];
    }

    return <TimeRange>[
      TimeRange(
        start: Timestamp.fromDate(kickOff),
        end: Timestamp.fromDate(fullTime),
      ),
    ];
  }

  return _scheduleFallbackPeriods(
    match,
    fallbackStart: fallbackStart,
  );
}

/// USB hub alias — same rules as [resolveMatchSensorSyncPeriods].
List<TimeRange> resolveMatchUsbSyncPeriods({
  required models.Match match,
  required List<Highlights> highlights,
  DateTime? fallbackStart,
}) {
  return resolveMatchSensorSyncPeriods(
    match: match,
    highlights: highlights,
    fallbackStart: fallbackStart,
  );
}

List<TimeRange> _scheduleFallbackPeriods(
  models.Match match, {
  DateTime? fallbackStart,
}) {
  final DateTime? start = fallbackStart ??
      match.timestamp?.toDate() ??
      matchKickoffDateTime(match);
  final int minutes = match.duration ?? 90;
  if (start == null || minutes <= 0) {
    return const <TimeRange>[];
  }

  final int halfMinutes = minutes ~/ 2;
  if (halfMinutes <= 0) {
    return const <TimeRange>[];
  }

  // 1ère mi-temps: start → start + duration/2
  final DateTime firstHalfEnd = start.add(Duration(minutes: halfMinutes));
  // 2ème mi-temps: start + duration/2 + 15' → start + duration + 15'
  final DateTime secondHalfStart = firstHalfEnd.add(
    const Duration(minutes: kMatchUsbSyncHalftimeBreakMinutes),
  );
  final DateTime secondHalfEnd = secondHalfStart.add(
    Duration(minutes: halfMinutes),
  );

  if (!firstHalfEnd.isAfter(start) || !secondHalfEnd.isAfter(secondHalfStart)) {
    return const <TimeRange>[];
  }

  return <TimeRange>[
    TimeRange(
      start: Timestamp.fromDate(start),
      end: Timestamp.fromDate(firstHalfEnd),
    ),
    TimeRange(
      start: Timestamp.fromDate(secondHalfStart),
      end: Timestamp.fromDate(secondHalfEnd),
    ),
  ];
}

/// Keeps samples that fall inside any play period (excludes half-time break).
List<TrackerRaw> filterSamplesToMatchPeriods(
  List<TrackerRaw> samples,
  List<TimeRange> periods,
) {
  if (samples.isEmpty || periods.isEmpty) return samples;

  return samples.where((sample) {
    for (final period in periods) {
      final startMs = period.start.toDate().millisecondsSinceEpoch;
      final endMs = period.end.toDate().millisecondsSinceEpoch;
      if (sample.timeMs >= startMs && sample.timeMs <= endMs) {
        return true;
      }
    }
    return false;
  }).toList(growable: false);
}

/// Splits samples into 1st / 2nd half using [periods] when available.
///
/// Falls back to sample-span midpoint when fewer than two periods exist.
({List<TrackerRaw> first, List<TrackerRaw> second}) splitSamplesByMatchPeriods(
  List<TrackerRaw> samples,
  List<TimeRange> periods,
) {
  if (samples.isEmpty) {
    return (first: const <TrackerRaw>[], second: const <TrackerRaw>[]);
  }

  if (periods.length >= 2) {
    final firstPeriod = periods[0];
    final secondPeriod = periods[1];
    final firstStart = firstPeriod.start.toDate().millisecondsSinceEpoch;
    final firstEnd = firstPeriod.end.toDate().millisecondsSinceEpoch;
    final secondStart = secondPeriod.start.toDate().millisecondsSinceEpoch;
    final secondEnd = secondPeriod.end.toDate().millisecondsSinceEpoch;

    final first = samples
        .where((s) => s.timeMs >= firstStart && s.timeMs <= firstEnd)
        .toList(growable: false);
    final second = samples
        .where((s) => s.timeMs >= secondStart && s.timeMs <= secondEnd)
        .toList(growable: false);
    return (first: first, second: second);
  }

  if (samples.length < 2) {
    return (first: samples, second: const <TrackerRaw>[]);
  }

  final startMs = samples.first.timeMs;
  final endMs = samples.last.timeMs;
  final midMs = startMs + ((endMs - startMs) ~/ 2);
  final first =
      samples.where((s) => s.timeMs <= midMs).toList(growable: false);
  final second =
      samples.where((s) => s.timeMs > midMs).toList(growable: false);
  return (first: first, second: second);
}
