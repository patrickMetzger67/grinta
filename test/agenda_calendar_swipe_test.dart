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

    test('calendar arithmetic keeps Monday across EU DST fallback', () {
      // Last Sunday of Oct 2026 is the 25th (clocks go back).
      expect(
        addWeeksKeepingWeekday(DateTime(2026, 10, 19), 1),
        DateTime(2026, 10, 26),
      );
    });
  });

  group('agendaHeaderChevronDate', () {
    test('week view chevron steps by 7 days, not 1', () {
      final focused = DateTime(2026, 9, 2); // Wednesday
      final next = agendaHeaderChevronDate(
        focusedDate: focused,
        period: AgendaHeaderPeriod.week,
        direction: 1,
      );
      final previous = agendaHeaderChevronDate(
        focusedDate: focused,
        period: AgendaHeaderPeriod.week,
        direction: -1,
      );

      expect(next, DateTime(2026, 9, 9));
      expect(previous, DateTime(2026, 8, 26));
      expect(next.weekday, DateTime.wednesday);
      expect(previous.weekday, DateTime.wednesday);
      expect(next.difference(focused).inDays, 7);
      expect(focused.difference(previous).inDays, 7);
    });

    test('day view chevron still steps by 1 day', () {
      final focused = DateTime(2026, 9, 2);
      expect(
        agendaHeaderChevronDate(
          focusedDate: focused,
          period: AgendaHeaderPeriod.day,
          direction: 1,
        ),
        DateTime(2026, 9, 3),
      );
      expect(
        agendaHeaderChevronDate(
          focusedDate: focused,
          period: AgendaHeaderPeriod.day,
          direction: -1,
        ),
        DateTime(2026, 9, 1),
      );
    });

    test('month view chevron keeps day-of-month when possible', () {
      expect(
        agendaHeaderChevronDate(
          focusedDate: DateTime(2026, 8, 15),
          period: AgendaHeaderPeriod.month,
          direction: 1,
        ),
        DateTime(2026, 9, 15),
      );
      expect(
        agendaHeaderChevronDate(
          focusedDate: DateTime(2026, 8, 31),
          period: AgendaHeaderPeriod.month,
          direction: 1,
        ),
        DateTime(2026, 9, 30),
      );
    });
  });
}
