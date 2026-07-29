import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/coach_filter_period.dart';

void main() {
  group('CoachFilterPeriodRange', () {
    final now = DateTime(2026, 7, 29); // Wednesday

    test('week is calendar Monday–Sunday inclusive', () {
      final range = CoachFilterPeriodRange.inclusive(
        period: CoachFilterPeriod.week,
        now: now,
      );
      expect(range.start, DateTime(2026, 7, 27)); // Monday
      expect(range.end, DateTime(2026, 8, 2)); // Sunday
    });

    test('month is calendar month inclusive', () {
      final range = CoachFilterPeriodRange.inclusive(
        period: CoachFilterPeriod.month,
        now: now,
      );
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, DateTime(2026, 7, 31));
    });

    test('queryExclusive end is day after inclusive end', () {
      final range = CoachFilterPeriodRange.queryExclusive(
        period: CoachFilterPeriod.week,
        now: now,
      );
      expect(range.start, DateTime(2026, 7, 27));
      expect(range.end, DateTime(2026, 8, 3)); // Monday after Sunday
    });
  });
}
