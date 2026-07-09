import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/services/training_intense_sync_service.dart';

void main() {
  group('formatInsidersApiTimestamp', () {
    test('uses UTC +0000 suffix without subseconds', () {
      expect(
        formatInsidersApiTimestamp(DateTime.utc(2026, 7, 9, 16, 0)),
        '2026-07-09T16:00:00+0000',
      );
    });

    test('strips subseconds from UTC instants', () {
      expect(
        formatInsidersApiTimestamp(
          DateTime.utc(2026, 7, 9, 16, 42, 56, 251),
        ),
        '2026-07-09T16:42:56+0000',
      );
    });
  });

  group('resolveTrainingIntenseTimeWindow', () {
    test('uses training start without pre-buffer', () {
      final trainingStart = DateTime.utc(2026, 7, 8, 14, 0);
      final syncStop = DateTime.utc(2026, 7, 8, 16, 30);
      final training = Training(
        dateTime: Timestamp.fromDate(trainingStart),
      );

      final window = resolveTrainingIntenseTimeWindow(
        training,
        syncStopAt: syncStop,
      );

      expect(window.start.toUtc(), trainingStart);
      expect(window.stop.toUtc(), syncStop);
    });

    test('prefers trainingStartAt over dateTime', () {
      final dateTime = DateTime.utc(2026, 7, 8, 13, 0);
      final trainingStartAt = DateTime.utc(2026, 7, 8, 14, 0);
      final syncStop = DateTime.utc(2026, 7, 8, 16, 30);
      final training = Training(
        dateTime: Timestamp.fromDate(dateTime),
        trainingStartAt: Timestamp.fromDate(trainingStartAt),
      );

      final window = resolveTrainingIntenseTimeWindow(
        training,
        syncStopAt: syncStop,
      );

      expect(window.start.toUtc(), trainingStartAt);
    });

    test('does not subtract ten minutes before training start', () {
      final trainingStart = DateTime.utc(2026, 7, 8, 15, 0);
      final syncStop = DateTime.utc(2026, 7, 8, 16, 0);
      final training = Training(
        trainingStartAt: Timestamp.fromDate(trainingStart),
      );

      final window = resolveTrainingIntenseTimeWindow(
        training,
        syncStopAt: syncStop,
      );

      expect(
        window.start.toUtc().difference(trainingStart),
        Duration.zero,
      );
    });

    test('caps stop at sync click when user finishes early', () {
      // France CEST (UTC+2): training 18:00–19:30 local, user clicks Terminer at 18:42.
      final trainingStart = DateTime.utc(2026, 7, 9, 16, 0);
      final scheduledEnd = DateTime.utc(2026, 7, 9, 17, 30);
      final syncStop = DateTime.utc(2026, 7, 9, 16, 42, 56, 251);
      final training = Training(
        trainingStartAt: Timestamp.fromDate(trainingStart),
        duration: 90,
      );

      final window = resolveTrainingIntenseTimeWindow(
        training,
        syncStopAt: syncStop,
      );

      expect(window.start.toUtc(), trainingStart);
      expect(window.stop.toUtc(), syncStop);
      expect(window.stop.toUtc().isBefore(scheduledEnd), isTrue);
      expect(window.toCloudPayload()['start'], '2026-07-09T16:00:00+0000');
      expect(window.toCloudPayload()['stop'], '2026-07-09T16:42:56+0000');
    });

    test('caps stop at scheduled end when user finishes after slot', () {
      final trainingStart = DateTime.utc(2026, 7, 9, 16, 0);
      final scheduledEnd = DateTime.utc(2026, 7, 9, 17, 30);
      final syncStop = DateTime.utc(2026, 7, 9, 18, 0);
      final training = Training(
        trainingStartAt: Timestamp.fromDate(trainingStart),
        duration: 90,
      );

      final window = resolveTrainingIntenseTimeWindow(
        training,
        syncStopAt: syncStop,
      );

      expect(window.start.toUtc(), trainingStart);
      expect(window.stop.toUtc(), scheduledEnd);
      expect(window.stop.toUtc().isBefore(syncStop), isTrue);
    });

    test('uses dateTime and duration when trainingStartAt is null', () {
      final dateTime = DateTime.utc(2026, 7, 9, 16, 0);
      final syncStop = DateTime.utc(2026, 7, 9, 16, 25);
      final training = Training(
        dateTime: Timestamp.fromDate(dateTime),
        duration: 90,
      );

      final window = resolveTrainingIntenseTimeWindow(
        training,
        syncStopAt: syncStop,
      );

      expect(window.start.toUtc(), dateTime);
      expect(window.stop.toUtc(), syncStop);
    });

    test('uses duration while session active even if trainingEndAt preset', () {
      final trainingStart = DateTime.utc(2026, 7, 9, 16, 0);
      final trainingEndAt = DateTime.utc(2026, 7, 9, 17, 45);
      final syncStop = DateTime.utc(2026, 7, 9, 16, 30);
      final training = Training(
        trainingStartAt: Timestamp.fromDate(trainingStart),
        trainingEndAt: Timestamp.fromDate(trainingEndAt),
        duration: 90,
      );

      final window = resolveTrainingIntenseTimeWindow(
        training,
        syncStopAt: syncStop,
      );

      expect(window.stop.toUtc(), syncStop);
    });

    test('uses trainingEndAt as scheduled end when session already finished', () {
      final trainingStart = DateTime.utc(2026, 7, 9, 16, 0);
      final trainingEndAt = DateTime.utc(2026, 7, 9, 17, 45);
      final syncStop = DateTime.utc(2026, 7, 9, 18, 0);
      final training = Training(
        trainingStartAt: Timestamp.fromDate(trainingStart),
        trainingEndAt: Timestamp.fromDate(trainingEndAt),
        duration: 90,
        isFinish: true,
      );

      final window = resolveTrainingIntenseTimeWindow(
        training,
        syncStopAt: syncStop,
      );

      expect(window.stop.toUtc(), trainingEndAt);
    });
  });

  group('intenseSamplesWithinWindow', () {
    test('keeps only samples inside inclusive bounds', () {
      final window = TrainingIntenseTimeWindow(
        start: DateTime.utc(2026, 7, 9, 16, 0),
        stop: DateTime.utc(2026, 7, 9, 16, 30),
      );
      const trackerId = 't1';
      final samples = [
        TrackerRaw(
          trackerId: trackerId,
          timeMs: window.startMs - 1,
          latitude: 0,
          longitude: 0,
          speedMps: 0,
        ),
        TrackerRaw(
          trackerId: trackerId,
          timeMs: window.startMs,
          latitude: 0,
          longitude: 0,
          speedMps: 0,
        ),
        TrackerRaw(
          trackerId: trackerId,
          timeMs: window.stopMs,
          latitude: 0,
          longitude: 0,
          speedMps: 0,
        ),
        TrackerRaw(
          trackerId: trackerId,
          timeMs: window.stopMs + 1,
          latitude: 0,
          longitude: 0,
          speedMps: 0,
        ),
      ];

      final filtered = intenseSamplesWithinWindow(samples, window);

      expect(filtered.length, 2);
      expect(filtered.first.timeMs, window.startMs);
      expect(filtered.last.timeMs, window.stopMs);
    });
  });
}
