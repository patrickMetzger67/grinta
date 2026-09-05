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
    test(
      'list icon (3 bars) + week strip: chevron is ±7, not ±1',
      () {
        // Screenshot: first icon selected, title "2 septembre 2026",
        // strip LUN.31 … MER.2 … DIM.6. That is AgendaCalendarMode.day.
        final period = agendaChevronPeriodForView(
          listWithWeekStrip: true,
          weekView: false,
          monthView: false,
        );
        expect(period, AgendaHeaderPeriod.week);

        final focused = DateTime(2026, 9, 2); // mercredi
        final next = agendaWeekStripChevronDate(focused, 1);
        final previous = agendaWeekStripChevronDate(focused, -1);

        expect(next, DateTime(2026, 9, 9));
        expect(previous, DateTime(2026, 8, 26));
        expect(next, isNot(focused), reason: 'next chevron must not be a no-op');
        expect(previous, isNot(focused), reason: 'prev chevron must not be a no-op');
        expect(agendaWeekStart(next), DateTime(2026, 9, 7));
        expect(agendaWeekEnd(next), DateTime(2026, 9, 13));
        expect(agendaWeekStart(previous), DateTime(2026, 8, 24));
        expect(agendaWeekEnd(previous), DateTime(2026, 8, 30));
      },
    );

    test('week-icon view chevron also steps by 7 days', () {
      final focused = DateTime(2026, 9, 2);
      final period = agendaChevronPeriodForView(
        listWithWeekStrip: false,
        weekView: true,
        monthView: false,
      );
      expect(period, AgendaHeaderPeriod.week);
      expect(
        agendaHeaderChevronDate(
          focusedDate: focused,
          period: period,
          direction: 1,
        ),
        DateTime(2026, 9, 9),
      );
    });

    test('month grid chevron keeps day-of-month when possible', () {
      final period = agendaChevronPeriodForView(
        listWithWeekStrip: false,
        weekView: false,
        monthView: true,
      );
      expect(period, AgendaHeaderPeriod.month);
      expect(
        agendaHeaderChevronDate(
          focusedDate: DateTime(2026, 8, 15),
          period: period,
          direction: 1,
        ),
        DateTime(2026, 9, 15),
      );
      expect(
        agendaHeaderChevronDate(
          focusedDate: DateTime(2026, 8, 31),
          period: period,
          direction: 1,
        ),
        DateTime(2026, 9, 30),
      );
    });

    test('week-strip chevron never returns the same date', () {
      final focused = DateTime(2026, 9, 2);
      expect(agendaWeekStripChevronDate(focused, 1), isNot(focused));
      expect(agendaWeekStripChevronDate(focused, -1), isNot(focused));
    });

    test('day period without a week strip still steps by 1 day', () {
      expect(
        agendaChevronPeriodForView(
          listWithWeekStrip: false,
          weekView: false,
          monthView: false,
        ),
        AgendaHeaderPeriod.day,
      );
      expect(
        agendaHeaderChevronDate(
          focusedDate: DateTime(2026, 9, 2),
          period: AgendaHeaderPeriod.day,
          direction: 1,
        ),
        DateTime(2026, 9, 3),
      );
    });
  });
}
