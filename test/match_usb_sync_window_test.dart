import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/util/match_usb_sync_window.dart';

Highlights _timeEvent(TimeType type, DateTime at) {
  return Highlights(
    actionType: ActionType.timeEvent,
    value: TimeEvent(type: type),
    dateTime: Timestamp.fromDate(at),
  );
}

void main() {
  group('resolveMatchUsbSyncPeriods', () {
    test('without highlights splits into two halves with 15 min break', () {
      final start = DateTime.utc(2026, 8, 8, 17, 0);
      final match = models.Match(
        timestamp: Timestamp.fromDate(start),
        duration: 90,
      );

      final periods = resolveMatchUsbSyncPeriods(
        match: match,
        highlights: const <Highlights>[],
      );

      // 1ère: [T, T+45] — 2ème: [T+45+15, T+90+15]
      expect(periods, hasLength(2));
      expect(periods[0].start.toDate().toUtc(), start);
      expect(
        periods[0].end.toDate().toUtc(),
        start.add(const Duration(minutes: 45)),
      );
      expect(
        periods[1].start.toDate().toUtc(),
        start.add(const Duration(minutes: 60)),
      );
      expect(
        periods[1].end.toDate().toUtc(),
        start.add(const Duration(minutes: 105)),
      );
    });

    test('defaults duration to 90 when null', () {
      final start = DateTime.utc(2026, 8, 8, 17, 0);
      final match = models.Match(
        timestamp: Timestamp.fromDate(start),
      );

      final periods = resolveMatchUsbSyncPeriods(
        match: match,
        highlights: const <Highlights>[],
      );

      expect(periods, hasLength(2));
      expect(
        periods[0].end.toDate().toUtc(),
        start.add(const Duration(minutes: 45)),
      );
      expect(
        periods[1].start.toDate().toUtc(),
        start.add(const Duration(minutes: 60)),
      );
      expect(
        periods[1].end.toDate().toUtc(),
        start.add(const Duration(minutes: 105)),
      );
    });

    test('returns empty when timestamp is missing and no usable highlights', () {
      final match = models.Match(duration: 90);
      expect(
        resolveMatchUsbSyncPeriods(
          match: match,
          highlights: const <Highlights>[],
        ),
        isEmpty,
      );
    });

    test('with kickOff + end uses those bounds as a single period', () {
      final kickOff = DateTime.utc(2026, 8, 8, 17, 5);
      final end = DateTime.utc(2026, 8, 8, 18, 55);
      final match = models.Match(
        timestamp: Timestamp.fromDate(DateTime.utc(2026, 8, 8, 17, 0)),
        duration: 90,
      );

      final periods = resolveMatchUsbSyncPeriods(
        match: match,
        highlights: <Highlights>[
          _timeEvent(TimeType.kickOff, kickOff),
          _timeEvent(TimeType.end, end),
        ],
      );

      expect(periods, hasLength(1));
      expect(periods.first.start.toDate().toUtc(), kickOff);
      expect(periods.first.end.toDate().toUtc(), end);
    });

    test('with full half markers returns two periods', () {
      final kickOff = DateTime.utc(2026, 8, 8, 17, 0);
      final half = DateTime.utc(2026, 8, 8, 17, 48);
      final second = DateTime.utc(2026, 8, 8, 18, 0);
      final end = DateTime.utc(2026, 8, 8, 18, 50);
      final match = models.Match(
        timestamp: Timestamp.fromDate(kickOff),
        duration: 90,
      );

      final periods = resolveMatchUsbSyncPeriods(
        match: match,
        highlights: <Highlights>[
          _timeEvent(TimeType.kickOff, kickOff),
          _timeEvent(TimeType.halTime, half),
          _timeEvent(TimeType.secondHalf, second),
          _timeEvent(TimeType.end, end),
        ],
      );

      expect(periods, hasLength(2));
      expect(periods[0].start.toDate().toUtc(), kickOff);
      expect(periods[0].end.toDate().toUtc(), half);
      expect(periods[1].start.toDate().toUtc(), second);
      expect(periods[1].end.toDate().toUtc(), end);
    });

    test('incomplete highlights fall back to scheduled halves', () {
      final schedule = DateTime.utc(2026, 8, 8, 17, 0);
      final kickOffOnly = DateTime.utc(2026, 8, 8, 17, 3);
      final match = models.Match(
        timestamp: Timestamp.fromDate(schedule),
        duration: 80,
      );

      final periods = resolveMatchUsbSyncPeriods(
        match: match,
        highlights: <Highlights>[
          _timeEvent(TimeType.kickOff, kickOffOnly),
        ],
      );

      expect(periods, hasLength(2));
      expect(periods[0].start.toDate().toUtc(), schedule);
      expect(
        periods[0].end.toDate().toUtc(),
        schedule.add(const Duration(minutes: 40)),
      );
      expect(
        periods[1].start.toDate().toUtc(),
        schedule.add(const Duration(minutes: 55)),
      );
      expect(
        periods[1].end.toDate().toUtc(),
        schedule.add(const Duration(minutes: 95)),
      );
    });
  });
}
