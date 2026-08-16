import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/timeRange.dart';
import 'package:grinta/model/training.dart';

/// USB / local hub sync window for a training (`withSyncing == true`).
///
/// Keeps only samples in `[Training.dateTime, dateTime + duration minutes]`.
/// Without this filter, pods that still hold previous sessions dump that data
/// into the current training analysis.
TimeRange? resolveTrainingUsbSyncPeriod(Training training) {
  final start = training.dateTime?.toDate();
  final durationMinutes = training.duration;
  if (start == null) return null;
  if (durationMinutes == null || durationMinutes <= 0) return null;

  final end = start.add(Duration(minutes: durationMinutes));
  if (!end.isAfter(start)) return null;

  return TimeRange(
    start: Timestamp.fromDate(start),
    end: Timestamp.fromDate(end),
  );
}

/// Convenience wrapper used by [TrackerHubPage].
List<TimeRange> resolveTrainingUsbSyncPeriods(Training training) {
  final period = resolveTrainingUsbSyncPeriod(training);
  if (period == null) return const <TimeRange>[];
  return <TimeRange>[period];
}
