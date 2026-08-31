import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/agenda_calendar_date.dart';

void main() {
  group('addMonthsKeepingDay', () {
    test('31 Aug → 30 Sep when sliding to next month', () {
      final result = addMonthsKeepingDay(DateTime(2026, 8, 31), 1);
      expect(result, DateTime(2026, 9, 30));
    });

    test('30 Sep → 30 Aug when sliding to previous month', () {
      final result = addMonthsKeepingDay(DateTime(2026, 9, 30), -1);
      expect(result, DateTime(2026, 8, 30));
    });

    test('15 Jan keeps day across months', () {
      final result = addMonthsKeepingDay(DateTime(2026, 1, 15), 1);
      expect(result, DateTime(2026, 2, 15));
    });

    test('31 Jan → 28 Feb in non-leap year', () {
      final result = addMonthsKeepingDay(DateTime(2026, 1, 31), 1);
      expect(result, DateTime(2026, 2, 28));
    });
  });

  group('clampDateToMonth', () {
    test('clamps 31 onto September', () {
      final result = clampDateToMonth(
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 1),
      );
      expect(result, DateTime(2026, 9, 30));
    });

    test('keeps 15 onto next month', () {
      final result = clampDateToMonth(
        DateTime(2026, 8, 15),
        DateTime(2026, 9, 1),
      );
      expect(result, DateTime(2026, 9, 15));
    });
  });

  group('addWeeksKeepingWeekday', () {
    test('Monday 31 Aug → Monday 7 Sep with one swipe forward', () {
      final result = addWeeksKeepingWeekday(DateTime(2026, 8, 31), 1);
      expect(result, DateTime(2026, 9, 7));
      expect(result.weekday, DateTime.monday);
    });

    test('Monday 31 Aug → Monday 24 Aug with one swipe backward', () {
      final result = addWeeksKeepingWeekday(DateTime(2026, 8, 31), -1);
      expect(result, DateTime(2026, 8, 24));
      expect(result.weekday, DateTime.monday);
    });
  });
}
