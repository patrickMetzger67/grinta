import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/tracker/owner.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/util/intense_live_eligibility.dart';

Owner _owner({
  required String typeTracker,
  bool withSyncing = true,
}) {
  return Owner(
    name: 'Kit',
    typeTracker: typeTracker,
    isActive: true,
    withSyncing: withSyncing,
    email: 'kit@example.com',
    firstname: 'Kit',
    lastname: 'Owner',
    uidCreate: 'u1',
    uidUpdate: 'u1',
  );
}

void main() {
  group('ownerUsesIntenseCloudSync', () {
    test('returns true for intense type even when withSyncing defaults true', () {
      expect(
        ownerUsesIntenseCloudSync(_owner(typeTracker: 'intense', withSyncing: true)),
        isTrue,
      );
    });

    test('returns true for Intense type with mixed case', () {
      expect(
        ownerUsesIntenseCloudSync(_owner(typeTracker: 'Intense', withSyncing: true)),
        isTrue,
      );
    });

    test('returns true when withSyncing is explicitly false', () {
      expect(
        ownerUsesIntenseCloudSync(_owner(typeTracker: 'inspirit', withSyncing: false)),
        isTrue,
      );
    });

    test('returns false for USB-sync owners', () {
      expect(
        ownerUsesIntenseCloudSync(_owner(typeTracker: 'inspirit', withSyncing: true)),
        isFalse,
      );
    });
  });

  group('trainingScheduledStart', () {
    test('prefers startTime wall clock on dateTg', () {
      final dateTime = Timestamp.fromDate(DateTime.utc(2026, 7, 9, 18, 0));
      final training = Training(
        dateTime: dateTime,
        dateTg: '09/07/2026',
        startTime: '20:00',
      );

      expect(
        trainingScheduledStart(training),
        DateTime(2026, 7, 9, 20, 0),
      );
    });

    test('falls back to dateTime when startTime missing', () {
      final dateTime = Timestamp.fromDate(DateTime.utc(2026, 7, 9, 18, 0));
      final training = Training(dateTime: dateTime);

      expect(
        trainingScheduledStart(training),
        dateTime.toDate(),
      );
    });
  });

  group('trainingScheduledEndAt', () {
    test('uses duration from scheduled start', () {
      final start = DateTime(2026, 7, 9, 20, 0);
      final training = Training(duration: 90);

      expect(
        trainingScheduledEndAt(training, start),
        start.add(const Duration(minutes: 90)),
      );
    });

    test('falls back to dateTg and endTime when duration missing', () {
      final start = DateTime(2026, 7, 9, 20, 0);
      final training = Training(
        dateTg: '09/07/2026',
        endTime: '21:30',
      );

      expect(
        trainingScheduledEndAt(training, start),
        DateTime(2026, 7, 9, 21, 30),
      );
    });
  });

  group('isTrainingSessionLive', () {
    final scheduledStart = DateTime(2026, 7, 9, 20, 0);
    final scheduledEnd = scheduledStart.add(const Duration(minutes: 90));

    Training liveTraining({
      bool withTracker = true,
      Timestamp? dateTime,
      Timestamp? trainingStartAt,
      bool isFinish = false,
      Timestamp? trainingEndAt,
      int? duration,
      String? dateTg,
      String? startTime,
      String? endTime,
      String? ownerId,
    }) {
      return Training(
        withTracker: withTracker,
        dateTime: dateTime ?? Timestamp.fromDate(DateTime.utc(2026, 7, 9, 18, 0)),
        trainingStartAt: trainingStartAt,
        isFinish: isFinish,
        trainingEndAt: trainingEndAt,
        duration: duration ?? 90,
        dateTg: dateTg ?? '09/07/2026',
        startTime: startTime ?? '20:00',
        endTime: endTime ?? '21:30',
        ownerId: ownerId ?? '2ed996a7-af16-4c77-9d66-cde06d6dd1a9',
      );
    }

    test('returns true for Jul 9 2026 user doc at 20:55 Paris slot', () {
      final training = liveTraining();

      expect(
        isTrainingSessionLive(
          training: training,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
          now: DateTime(2026, 7, 9, 20, 55),
        ),
        isTrue,
      );
    });

    test('returns true when duration is stored as string in Firestore map', () {
      final training = Training.fromMap(<String, dynamic>{
        'withTracker': true,
        'isFinish': false,
        'duration': '90',
        'ownerId': '2ed996a7-af16-4c77-9d66-cde06d6dd1a9',
        'startEnd': '21:30',
        'startTime': '20:00',
        'dateTg': '09/07/2026',
        'dateTime': Timestamp.fromDate(DateTime.utc(2026, 7, 9, 18, 0)),
      });

      expect(
        isTrainingSessionLive(
          training: training,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
          now: DateTime(2026, 7, 9, 20, 55),
        ),
        isTrue,
      );
    });

    test('returns false when duration missing even with agenda endAt', () {
      final training = Training(
        withTracker: true,
        dateTime: Timestamp.fromDate(DateTime.utc(2026, 7, 9, 18, 0)),
        dateTg: '09/07/2026',
        startTime: '20:00',
        endTime: '21:30',
      );

      expect(
        isTrainingSessionLive(
          training: training,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
          now: DateTime(2026, 7, 9, 20, 55),
        ),
        isFalse,
      );
    });

    test('ignores trainingStartAt outside scheduled window', () {
      final training = liveTraining(
        trainingStartAt: Timestamp.fromDate(
          scheduledStart.subtract(const Duration(hours: 2)),
        ),
      );

      expect(
        isTrainingSessionLive(
          training: training,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
          now: scheduledStart.subtract(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });

    test('returns false before scheduled start', () {
      final training = liveTraining();

      expect(
        isTrainingSessionLive(
          training: training,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
          now: scheduledStart.subtract(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });

    test('returns false at scheduled end (exclusive)', () {
      final training = liveTraining(duration: 90);

      expect(
        isTrainingSessionLive(
          training: training,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
          now: scheduledEnd,
        ),
        isFalse,
      );
    });

    test('returns false when finished', () {
      final training = liveTraining(isFinish: true);

      expect(
        isTrainingSessionLive(
          training: training,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
          now: scheduledStart.add(const Duration(minutes: 10)),
        ),
        isFalse,
      );
    });

    test('returns false without tracker', () {
      final training = liveTraining(withTracker: false);

      expect(
        isTrainingSessionLive(
          training: training,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
          now: scheduledStart.add(const Duration(minutes: 10)),
        ),
        isFalse,
      );
    });
  });
}
