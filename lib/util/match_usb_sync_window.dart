import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/timeRange.dart';
import 'package:grinta/util/highlight_minute_helper.dart';

/// USB / local hub sync window for a match (`withSyncing == true`).
///
/// - With Temps forts début + fin (`kickOff` + `end`): use those wall times
///   (split into halves when mi-temps / reprise are present).
/// - Otherwise: `[Match.timestamp, timestamp + duration minutes]`.
///
/// Never returns [TimeRange] built from nulls (that used to collapse to
/// `now→now` and filter out every sample → download spinner then back to
/// « Télécharger » with no data).
List<TimeRange> resolveMatchUsbSyncPeriods({
  required models.Match match,
  required List<Highlights> highlights,
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

  return _scheduleFallbackPeriods(match);
}

List<TimeRange> _scheduleFallbackPeriods(models.Match match) {
  final DateTime? start = match.timestamp?.toDate();
  final int minutes = match.duration ?? 90;
  if (start == null || minutes <= 0) {
    return const <TimeRange>[];
  }

  final DateTime end = start.add(Duration(minutes: minutes));
  if (!end.isAfter(start)) {
    return const <TimeRange>[];
  }

  return <TimeRange>[
    TimeRange(
      start: Timestamp.fromDate(start),
      end: Timestamp.fromDate(end),
    ),
  ];
}
