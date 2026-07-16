import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/services/training_intense_sync_service.dart';

Training _training({
  DateTime? dateTime,
  DateTime? trainingEndAt,
  bool withTracker = true,
}) {
  return Training(
    dateTime: dateTime == null ? null : Timestamp.fromDate(dateTime),
    trainingEndAt:
        trainingEndAt == null ? null : Timestamp.fromDate(trainingEndAt),
    withTracker: withTracker,
  );
}

void main() {
  group('resolveTrainingIntenseResyncWindow', () {
    test('uses dateTime → trainingEndAt (not capped to now)', () {
      final start = DateTime.utc(2026, 7, 16, 16, 0);
      final end = DateTime.utc(2026, 7, 16, 17, 30);
      final window = resolveTrainingIntenseResyncWindow(
        _training(dateTime: start, trainingEndAt: end),
      );

      expect(window, isNotNull);
      expect(window!.start, start);
      expect(window.stop, end);
    });

    test('returns null when bounds missing', () {
      expect(
        resolveTrainingIntenseResyncWindow(_training(dateTime: DateTime.now())),
        isNull,
      );
    });
  });

  group('canResyncTrainingIntense', () {
    final end = DateTime(2026, 7, 16, 18, 0);

    test('true within 48h after trainingEndAt', () {
      expect(
        canResyncTrainingIntense(
          _training(
            dateTime: end.subtract(const Duration(hours: 1)),
            trainingEndAt: end,
          ),
          now: end.add(const Duration(hours: 12)),
        ),
        isTrue,
      );
    });

    test('false after 48h window', () {
      expect(
        canResyncTrainingIntense(
          _training(
            dateTime: end.subtract(const Duration(hours: 1)),
            trainingEndAt: end,
          ),
          now: end.add(const Duration(hours: 48, minutes: 1)),
        ),
        isFalse,
      );
    });

    test('false before trainingEndAt', () {
      expect(
        canResyncTrainingIntense(
          _training(
            dateTime: end.subtract(const Duration(hours: 1)),
            trainingEndAt: end,
          ),
          now: end.subtract(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });
  });
}
