import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/util/agenda_calendar_date.dart';
import 'package:grinta/util/agenda_paint_perf.dart';

AgendaItem _item({
  required String id,
  required DateTime start,
  DateTime? end,
  AgendaItemType type = AgendaItemType.entrainement,
}) {
  return AgendaItem(
    id: id,
    type: type,
    title: id,
    startAt: start,
    endAt: end ?? start,
    allDay: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AgendaMonthPaintCache', () {
    test('stores and paints a covered range (SWR)', () {
      final cache = AgendaMonthPaintCache(maxMonths: 6);
      final items = <AgendaItem>[
        _item(id: 'a', start: DateTime(2026, 8, 10)),
        _item(id: 'b', start: DateTime(2026, 9, 2)),
        _item(id: 'c', start: DateTime(2026, 7, 20)),
      ];

      cache.storeRange(
        rangeStart: DateTime(2026, 7, 1),
        rangeEnd: DateTime(2026, 9, 30),
        items: items,
      );

      expect(cache.coversMonth(DateTime(2026, 8, 1)), isTrue);
      expect(cache.coversMonth(DateTime(2026, 10, 1)), isFalse);

      final painted = cache.tryPaintRange(
        rangeStart: DateTime(2026, 7, 1),
        rangeEnd: DateTime(2026, 9, 30),
      );
      expect(painted, isNotNull);
      expect(painted!.map((e) => e.id).toSet(), {'a', 'b', 'c'});
    });

    test('tryPaintRange returns null when a month is missing', () {
      final cache = AgendaMonthPaintCache();
      cache.storeRange(
        rangeStart: DateTime(2026, 8, 1),
        rangeEnd: DateTime(2026, 8, 31),
        items: [_item(id: 'a', start: DateTime(2026, 8, 10))],
      );

      expect(
        cache.tryPaintRange(
          rangeStart: DateTime(2026, 8, 1),
          rangeEnd: DateTime(2026, 9, 30),
        ),
        isNull,
      );
    });

    test('evicts oldest months beyond maxMonths', () {
      final cache = AgendaMonthPaintCache(maxMonths: 2);
      cache.storeRange(
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 1, 31),
        items: const [],
      );
      cache.storeRange(
        rangeStart: DateTime(2026, 2, 1),
        rangeEnd: DateTime(2026, 2, 28),
        items: const [],
      );
      cache.storeRange(
        rangeStart: DateTime(2026, 3, 1),
        rangeEnd: DateTime(2026, 3, 31),
        items: const [],
      );

      expect(cache.monthCount, 2);
      expect(cache.coversMonth(DateTime(2026, 1, 1)), isFalse);
      expect(cache.coversMonth(DateTime(2026, 2, 1)), isTrue);
      expect(cache.coversMonth(DateTime(2026, 3, 1)), isTrue);
    });
  });

  group('planAgendaPrefetchMonths', () {
    test('returns uncached months just outside the live window', () {
      final cached = <String>{
        agendaMonthPaintKey(DateTime(2026, 7, 1)),
        agendaMonthPaintKey(DateTime(2026, 8, 1)),
        agendaMonthPaintKey(DateTime(2026, 9, 1)),
      };

      final plan = planAgendaPrefetchMonths(
        focusMonth: DateTime(2026, 8, 1),
        isCached: (m) => cached.contains(agendaMonthPaintKey(m)),
        windowRadiusMonths: 1,
        prefetchRadiusMonths: 2,
      );

      expect(
        plan.map(agendaMonthPaintKey).toList(),
        ['2026-06', '2026-10'],
      );
    });

    test('skips months already cached', () {
      final plan = planAgendaPrefetchMonths(
        focusMonth: DateTime(2026, 8, 1),
        isCached: (_) => true,
      );
      expect(plan, isEmpty);
    });
  });

  group('DebouncedLatestAction', () {
    test('only the latest token runs after delay', () async {
      final gate = LatestWinsGate();
      final debouncer = DebouncedLatestAction(
        delay: const Duration(milliseconds: 40),
      );
      final ran = <int>[];

      final first = gate.begin();
      debouncer.schedule(first, (t) => ran.add(t.id));
      final second = gate.begin();
      debouncer.schedule(second, (t) => ran.add(t.id));

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(ran, [second.id]);
      debouncer.dispose();
    });

    test('stale token is ignored when timer fires', () async {
      final gate = LatestWinsGate();
      final debouncer = DebouncedLatestAction(
        delay: const Duration(milliseconds: 30),
      );
      final ran = <int>[];

      final first = gate.begin();
      debouncer.schedule(first, (t) => ran.add(t.id));
      gate.begin(); // invalidate without reschedule

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(ran, isEmpty);
      debouncer.dispose();
    });
  });

  group('AgendaPaintCoalescer', () {
    test('collapses multiple submits into one paint per frame', () async {
      final painted = <int>[];
      final coalescer = AgendaPaintCoalescer<int>(painted.add);

      coalescer.submit(1);
      coalescer.submit(2);
      coalescer.submit(3);

      expect(painted, isEmpty);
      // Flush the scheduled frame callback.
      SchedulerBinding.instance.handleBeginFrame(Duration.zero);
      SchedulerBinding.instance.handleDrawFrame();

      expect(painted, [3]);
      coalescer.dispose();
    });
  });

  group('AgendaPaintCoalescer pause/discard', () {
    test('paused mid-fling holds paints; discard drops stale queue', () {
      final painted = <int>[];
      final coalescer = AgendaPaintCoalescer<int>(painted.add);

      coalescer.setPaused(true);
      coalescer.submit(1);
      coalescer.submit(2);
      SchedulerBinding.instance.handleBeginFrame(Duration.zero);
      SchedulerBinding.instance.handleDrawFrame();
      expect(painted, isEmpty);

      coalescer.discardPending();
      coalescer.setPaused(false);
      SchedulerBinding.instance.handleBeginFrame(
        const Duration(milliseconds: 16),
      );
      SchedulerBinding.instance.handleDrawFrame();
      expect(painted, isEmpty);

      coalescer.submit(9);
      SchedulerBinding.instance.handleBeginFrame(
        const Duration(milliseconds: 32),
      );
      SchedulerBinding.instance.handleDrawFrame();
      expect(painted, [9]);
      coalescer.dispose();
    });
  });

  group('agendaPageViewNearInteger', () {
    test('detects settled vs mid-fling page offsets', () {
      expect(agendaPageViewNearInteger(null), isTrue);
      expect(agendaPageViewNearInteger(3.0), isTrue);
      expect(agendaPageViewNearInteger(3.0004), isTrue);
      expect(agendaPageViewNearInteger(3.2), isFalse);
      expect(agendaPageViewNearInteger(2.5), isFalse);
    });
  });

  group('agendaItemsPaintFingerprint', () {
    test('same items share fingerprint; different ids diverge', () {
      final a = [
        _item(id: '1', start: DateTime(2026, 8, 1)),
        _item(id: '2', start: DateTime(2026, 8, 2)),
      ];
      final b = [
        _item(id: '1', start: DateTime(2026, 8, 1)),
        _item(id: '2', start: DateTime(2026, 8, 2)),
      ];
      final c = [
        _item(id: '1', start: DateTime(2026, 8, 1)),
        _item(id: '9', start: DateTime(2026, 8, 2)),
      ];
      expect(agendaItemsPaintFingerprint(a), agendaItemsPaintFingerprint(b));
      expect(
        agendaItemsPaintFingerprint(a),
        isNot(agendaItemsPaintFingerprint(c)),
      );
    });
  });
}
