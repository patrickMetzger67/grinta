import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/agenda_calendar_date.dart';

void main() {
  group('monthPageSelectedDate / preferred day', () {
    test('Aug 31 → Sep keeps preferred 31 as Sep 30', () {
      final result = monthPageSelectedDate(
        targetMonth: DateTime(2026, 9, 1),
        preferredDayOfMonth: 31,
      );
      expect(result, DateTime(2026, 9, 30));
    });

    test('Sep 30 → Aug restores preferred 31 (not 30)', () {
      // After clamping on Sep, preferred day must still be 31 so back nav
      // returns to "today" (31 Aug) instead of drifting to 30 Aug.
      final result = monthPageSelectedDate(
        targetMonth: DateTime(2026, 8, 1),
        preferredDayOfMonth: 31,
      );
      expect(result, DateTime(2026, 8, 31));
    });

    test('preferred 15 stays stable across months', () {
      expect(
        monthPageSelectedDate(
          targetMonth: DateTime(2026, 9, 1),
          preferredDayOfMonth: 15,
        ),
        DateTime(2026, 9, 15),
      );
      expect(
        monthPageSelectedDate(
          targetMonth: DateTime(2026, 8, 1),
          preferredDayOfMonth: 15,
        ),
        DateTime(2026, 8, 15),
      );
    });

    test('Jan 31 → Feb non-leap clamps to 28, back restores 31', () {
      expect(
        monthPageSelectedDate(
          targetMonth: DateTime(2026, 2, 1),
          preferredDayOfMonth: 31,
        ),
        DateTime(2026, 2, 28),
      );
      expect(
        monthPageSelectedDate(
          targetMonth: DateTime(2026, 1, 1),
          preferredDayOfMonth: 31,
        ),
        DateTime(2026, 1, 31),
      );
    });
  });

  group('weekOverlapsMonth', () {
    test('week fully inside month overlaps', () {
      expect(weekOverlapsMonth(DateTime(2026, 8, 10), DateTime(2026, 8, 1)), isTrue);
    });

    test('week spanning Aug/Sep overlaps both months', () {
      final weekStart = DateTime(2026, 8, 31);
      expect(weekOverlapsMonth(weekStart, DateTime(2026, 8, 1)), isTrue);
      expect(weekOverlapsMonth(weekStart, DateTime(2026, 9, 1)), isTrue);
    });

    test('week in August does not overlap October', () {
      expect(
        weekOverlapsMonth(DateTime(2026, 8, 10), DateTime(2026, 10, 1)),
        isFalse,
      );
    });
  });

  group('LatestWinsGate', () {
    test('newer begin() makes previous token stale', () {
      final gate = LatestWinsGate();
      final first = gate.begin();
      expect(first.isCurrent, isTrue);

      final second = gate.begin();
      expect(first.isCurrent, isFalse);
      expect(second.isCurrent, isTrue);
    });
  });

  group('planAgendaWindowHydration', () {
    test('returns alreadyFullyCovered when M±1 is loaded', () {
      final plan = planAgendaWindowHydration(
        focusMonth: DateTime(2026, 8, 1),
        currentRangeStart: DateTime(2026, 7, 1),
        currentRangeEnd: DateTime(2026, 9, 30),
      );
      expect(plan.alreadyFullyCovered, isTrue);
      expect(plan.needsReload, isFalse);
    });

    test('plans reload when focus month is outside range', () {
      final plan = planAgendaWindowHydration(
        focusMonth: DateTime(2026, 11, 1),
        currentRangeStart: DateTime(2026, 7, 1),
        currentRangeEnd: DateTime(2026, 9, 30),
      );
      expect(plan.needsReload, isTrue);
      expect(plan.alreadyFullyCovered, isFalse);
      expect(plan.rangeStart, DateTime(2026, 10, 1));
      expect(plan.rangeEnd, DateTime(2026, 12, 31));
    });
  });

  group('week date-pick → month pager sync', () {
    test(
      'pick Dec 21 in week then open month → page is December, not August',
      () {
        const int initialPage = 1200;
        final DateTime anchor = DateTime(2026, 8, 1); // today month
        final DateTime picked = DateTime(2026, 12, 21);

        // Reproduce stale controller still on August after the picker.
        int controllerPage = initialPage;

        final AgendaMonthSwipeFocus focus = focusAfterDatePickForMonth(
          pickedDate: picked,
        );
        expect(focus.displayedMonth, DateTime(2026, 12, 1));
        expect(focus.selectedDate, DateTime(2026, 12, 21));
        expect(focus.preferredDayOfMonth, 21);

        // Format change to month must jump the pager to the focused month.
        controllerPage = agendaMonthPageIndex(
          anchorMonth: anchor,
          month: focus.displayedMonth,
          initialPage: initialPage,
        );
        expect(
          agendaMonthForPageIndex(
            anchorMonth: anchor,
            page: controllerPage,
            initialPage: initialPage,
          ),
          DateTime(2026, 12, 1),
        );
        expect(controllerPage, isNot(initialPage));
      },
    );

    test(
      'prev chevron uses displayed month (Dec→Nov), not stale August page',
      () {
        const int initialPage = 1200;
        final DateTime anchor = DateTime(2026, 8, 1);
        final DateTime displayed = DateTime(2026, 12, 1);

        // Stale controller still on August (the bug).
        final int stalePage = initialPage;
        expect(
          agendaMonthForPageIndex(
            anchorMonth: anchor,
            page: stalePage,
            initialPage: initialPage,
          ),
          DateTime(2026, 8, 1),
        );

        // Wrong: previousPage from stale August → July.
        final int wrongPrev = stalePage - 1;
        expect(
          agendaMonthForPageIndex(
            anchorMonth: anchor,
            page: wrongPrev,
            initialPage: initialPage,
          ),
          DateTime(2026, 7, 1),
        );

        // Correct: chevron derived from focused/displayed December → November.
        final int correctPrev = agendaAdjacentMonthPageFromFocus(
          displayedMonth: displayed,
          anchorMonth: anchor,
          initialPage: initialPage,
          monthDelta: -1,
        );
        expect(
          agendaMonthForPageIndex(
            anchorMonth: anchor,
            page: correctPrev,
            initialPage: initialPage,
          ),
          DateTime(2026, 11, 1),
        );
        expect(correctPrev, isNot(wrongPrev));

        final AgendaMonthSwipeFocus novFocus = applyMonthPageLanding(
          targetMonth: DateTime(2026, 11, 1),
          preferredDayOfMonth: 21,
        );
        expect(novFocus.selectedDate, DateTime(2026, 11, 21));
      },
    );

    test('agendaMonthPageIndex is symmetric with agendaMonthForPageIndex', () {
      const int initialPage = 1200;
      final DateTime anchor = DateTime(2026, 8, 1);
      for (final DateTime month in <DateTime>[
        DateTime(2026, 8, 1),
        DateTime(2026, 12, 1),
        DateTime(2027, 1, 1),
        DateTime(2025, 11, 1),
      ]) {
        final int page = agendaMonthPageIndex(
          anchorMonth: anchor,
          month: month,
          initialPage: initialPage,
        );
        expect(
          agendaMonthForPageIndex(
            anchorMonth: anchor,
            page: page,
            initialPage: initialPage,
          ),
          month,
        );
      }
    });
  });
}
