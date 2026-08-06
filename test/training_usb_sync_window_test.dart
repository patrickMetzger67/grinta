import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/util/training_usb_sync_window.dart';

void main() {
  group('resolveTrainingUsbSyncPeriod', () {
    test('uses dateTime → dateTime + duration minutes', () {
      final start = DateTime.utc(2026, 8, 6, 16, 0);
      final training = Training(
        dateTime: Timestamp.fromDate(start),
        duration: 90,
      );

      final period = resolveTrainingUsbSyncPeriod(training);
      expect(period, isNotNull);
      expect(period!.start.toDate().toUtc(), start);
      expect(
        period.end.toDate().toUtc(),
        start.add(const Duration(minutes: 90)),
      );
    });

    test('returns null when dateTime is missing', () {
      final training = Training(duration: 90);
      expect(resolveTrainingUsbSyncPeriod(training), isNull);
    });

    test('returns null when duration is missing or non-positive', () {
      final start = Timestamp.fromDate(DateTime.utc(2026, 8, 6, 16, 0));
      expect(
        resolveTrainingUsbSyncPeriod(Training(dateTime: start)),
        isNull,
      );
      expect(
        resolveTrainingUsbSyncPeriod(Training(dateTime: start, duration: 0)),
        isNull,
      );
      expect(
        resolveTrainingUsbSyncPeriod(Training(dateTime: start, duration: -10)),
        isNull,
      );
    });

    test('ignores trainingStartAt / trainingEndAt (dateTime+duration only)', () {
      final dateTime = DateTime.utc(2026, 8, 6, 16, 0);
      final training = Training(
        dateTime: Timestamp.fromDate(dateTime),
        duration: 60,
        trainingStartAt: Timestamp.fromDate(
          dateTime.subtract(const Duration(minutes: 10)),
        ),
        trainingEndAt: Timestamp.fromDate(
          dateTime.add(const Duration(hours: 2)),
        ),
      );

      final period = resolveTrainingUsbSyncPeriod(training)!;
      expect(period.start.toDate().toUtc(), dateTime);
      expect(
        period.end.toDate().toUtc(),
        dateTime.add(const Duration(minutes: 60)),
      );
    });
  });

  group('resolveTrainingUsbSyncPeriods', () {
    test('wraps a single period or empty list', () {
      expect(resolveTrainingUsbSyncPeriods(Training(duration: 90)), isEmpty);

      final periods = resolveTrainingUsbSyncPeriods(
        Training(
          dateTime: Timestamp.fromDate(DateTime.utc(2026, 8, 6, 10)),
          duration: 45,
        ),
      );
      expect(periods, hasLength(1));
    });
  });
}
