import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/util/training_finish_helper.dart';

void main() {
  group('Analyse charge training filter', () {
    test('planned trainings are not finished', () {
      final planned = Training(
        dateTime: Timestamp.fromDate(DateTime(2026, 7, 29, 18)),
        isFinish: false,
      );
      expect(isTrainingFinished(planned), isFalse);
    });

    test('finished trainings are included', () {
      final finished = Training(
        dateTime: Timestamp.fromDate(DateTime(2026, 7, 28, 18)),
        isFinish: true,
        trainingEndAt: Timestamp.fromDate(DateTime(2026, 7, 28, 19, 30)),
      );
      expect(isTrainingFinished(finished), isTrue);
    });

    test('trainingEndAt alone marks finished', () {
      final ended = Training(
        dateTime: Timestamp.fromDate(DateTime(2026, 7, 28, 18)),
        trainingEndAt: Timestamp.fromDate(DateTime(2026, 7, 28, 19, 30)),
      );
      expect(isTrainingFinished(ended), isTrue);
    });
  });
}
