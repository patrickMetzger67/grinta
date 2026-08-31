import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/agenda_calendar_date.dart';

void main() {
  group('LatestWinsGate', () {
    test('only the newest token stays current (switchMap)', () {
      final gate = LatestWinsGate();
      final first = gate.begin();
      expect(first.isCurrent, isTrue);

      final second = gate.begin();
      expect(first.isCurrent, isFalse);
      expect(second.isCurrent, isTrue);

      final third = gate.begin();
      expect(first.isCurrent, isFalse);
      expect(second.isCurrent, isFalse);
      expect(third.isCurrent, isTrue);
    });
  });

  group('applyMonthPageLanding / preferred day sticky', () {
    test('Aug 31 → Sep clamps display day but keeps preferred 31', () {
      final focus = applyMonthPageLanding(
        targetMonth: DateTime(2026, 9, 1),
        preferredDayOfMonth: 31,
      );
      expect(focus.displayedMonth, DateTime(2026, 9, 1));
      expect(focus.selectedDate, DateTime(2026, 9, 30));
      expect(focus.preferredDayOfMonth, 31);
    });

    test('back to Aug restores day 31 from preferred', () {
      final focus = applyMonthPageLanding(
        targetMonth: DateTime(2026, 8, 1),
        preferredDayOfMonth: 31,
      );
      expect(focus.selectedDate, DateTime(2026, 8, 31));
      expect(focus.preferredDayOfMonth, 31);
    });
  });

  group('AgendaMonthSwipeBurstSimulator', () {
    test(
      'fast Aug→Sep→Oct→Nov→Oct→Sep→Aug keeps preferred 31; stale hydrates ignored',
      () {
        final sim = AgendaMonthSwipeBurstSimulator(
          initialMonth: DateTime(2026, 8, 1),
          preferredDayOfMonth: 31,
        );
        expect(sim.selectedDate, DateTime(2026, 8, 31));

        // Burst matching the reporter path (very fast month slides).
        sim.runBurstAndFlush([
          DateTime(2026, 9, 1),
          DateTime(2026, 10, 1),
          DateTime(2026, 11, 1),
          DateTime(2026, 10, 1),
          DateTime(2026, 9, 1),
          DateTime(2026, 8, 1),
        ]);

        expect(sim.displayedMonth, DateTime(2026, 8, 1));
        expect(sim.selectedDate, DateTime(2026, 8, 31));
        expect(sim.preferredDayOfMonth, 31);

        // Only the final landing's hydrate applies; all earlier gens are stale.
        expect(sim.appliedHydrationIds, hasLength(1));
        expect(
          sim.appliedHydrationIds.single,
          sim.hydrationGate.generation,
        );
        expect(sim.ignoredStaleHydrationIds, hasLength(5));
        expect(
          sim.ignoredStaleHydrationIds,
          everyElement(isNot(sim.hydrationGate.generation)),
        );
      },
    );

    test('intermediate clamp to Sep 30 does not stick when returning to Aug', () {
      final sim = AgendaMonthSwipeBurstSimulator(
        initialMonth: DateTime(2026, 8, 1),
        preferredDayOfMonth: 31,
      );
      sim.landOnMonth(DateTime(2026, 9, 1));
      expect(sim.selectedDate, DateTime(2026, 9, 30));
      expect(sim.preferredDayOfMonth, 31);

      sim.landOnMonth(DateTime(2026, 8, 1));
      expect(sim.selectedDate, DateTime(2026, 8, 31));
      expect(sim.preferredDayOfMonth, 31);
    });
  });

  group('planAgendaWindowHydration', () {
    final aug = DateTime(2026, 8, 1);
    final julStart = DateTime(2026, 7, 1);
    final sepEnd = DateTime(2026, 9, 30);

    test('already covered window needs no reload', () {
      final plan = planAgendaWindowHydration(
        focusMonth: aug,
        currentRangeStart: julStart,
        currentRangeEnd: sepEnd,
      );
      expect(plan.alreadyFullyCovered, isTrue);
      expect(plan.needsReload, isFalse);
      expect(plan.rangeStart, julStart);
      expect(plan.rangeEnd, sepEnd);
    });

    test('uncovered month replaces range with M±1 window', () {
      final plan = planAgendaWindowHydration(
        focusMonth: DateTime(2026, 12, 1),
        currentRangeStart: julStart,
        currentRangeEnd: sepEnd,
      );
      expect(plan.alreadyFullyCovered, isFalse);
      expect(plan.needsReload, isTrue);
      expect(plan.rangeStart, DateTime(2026, 11, 1));
      expect(plan.rangeEnd, DateTime(2027, 1, 31));
    });

    test('partial cover expands range without jumping focus', () {
      final plan = planAgendaWindowHydration(
        focusMonth: DateTime(2026, 9, 1),
        currentRangeStart: julStart,
        currentRangeEnd: sepEnd,
      );
      expect(plan.alreadyFullyCovered, isFalse);
      expect(plan.needsReload, isTrue);
      expect(plan.rangeStart, julStart);
      expect(plan.rangeEnd, DateTime(2026, 10, 31));
    });

    test('oversized span collapses to focus M±1', () {
      final plan = planAgendaWindowHydration(
        focusMonth: DateTime(2026, 10, 1),
        currentRangeStart: DateTime(2026, 1, 1),
        currentRangeEnd: DateTime(2026, 10, 31),
        maxLoadedMonths: 4,
      );
      expect(plan.needsReload, isTrue);
      expect(plan.rangeStart, DateTime(2026, 9, 1));
      expect(plan.rangeEnd, DateTime(2026, 11, 30));
    });
  });
}
