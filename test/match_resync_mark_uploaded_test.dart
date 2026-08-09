import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/util/match_time_event_helper.dart';

void main() {
  group('isMatchTheoreticallyFinishedByTimestamp', () {
    test('false before timestamp + duration + 15 min break', () {
      final start = DateTime(2026, 8, 6, 15, 0);
      final match = models.Match(
        timestamp: Timestamp.fromDate(start),
        duration: 90,
      );

      expect(
        isMatchTheoreticallyFinishedByTimestamp(
          match,
          now: start.add(const Duration(minutes: 104)),
        ),
        isFalse,
      );
    });

    test('true at exact timestamp + duration + 15 min break', () {
      final start = DateTime(2026, 8, 6, 15, 0);
      final match = models.Match(
        timestamp: Timestamp.fromDate(start),
        duration: 90,
      );

      expect(
        isMatchTheoreticallyFinishedByTimestamp(
          match,
          now: start.add(const Duration(minutes: 105)),
        ),
        isTrue,
      );
    });

    test('true after timestamp + duration + 15 min break', () {
      final start = DateTime(2026, 8, 6, 15, 0);
      final match = models.Match(
        timestamp: Timestamp.fromDate(start),
        duration: 90,
      );

      expect(
        isMatchTheoreticallyFinishedByTimestamp(
          match,
          now: start.add(const Duration(hours: 2)),
        ),
        isTrue,
      );
    });

    test('false when timestamp is missing', () {
      final match = models.Match(duration: 90);
      expect(
        isMatchTheoreticallyFinishedByTimestamp(
          match,
          now: DateTime(2026, 8, 6, 18),
        ),
        isFalse,
      );
    });

    test('uses default 90 minutes + 15 break when duration is null', () {
      final start = DateTime(2026, 8, 6, 15, 0);
      final match = models.Match(
        timestamp: Timestamp.fromDate(start),
      );

      expect(
        isMatchTheoreticallyFinishedByTimestamp(
          match,
          now: start.add(const Duration(minutes: 104)),
        ),
        isFalse,
      );
      expect(
        isMatchTheoreticallyFinishedByTimestamp(
          match,
          now: start.add(const Duration(minutes: 105)),
        ),
        isTrue,
      );
    });
  });
}
