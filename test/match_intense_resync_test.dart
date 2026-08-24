import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/services/training_intense_sync_service.dart';
import 'package:grinta/util/intense_live_eligibility.dart';

Highlights _timeEvent({
  required TimeType type,
  required DateTime at,
}) {
  return Highlights(
    matchCalendarId: 'm1',
    teamId: 't1',
    minute: 1,
    actionType: ActionType.timeEvent,
    value: TimeEvent(type: type),
    dateTime: Timestamp.fromDate(at),
  );
}

models.Match _match({
  bool withTracker = true,
  bool isMatchPlayed = false,
  String? dateCh,
  String? timeCh,
  int? duration = 90,
  DateTime? timestamp,
}) {
  return models.Match(
    withTracker: withTracker,
    isMatchPlayed: isMatchPlayed,
    dateCh: dateCh,
    timeCh: timeCh,
    ownerId: 'owner1',
    duration: duration,
    timestamp: timestamp == null ? null : Timestamp.fromDate(timestamp),
  );
}

void main() {
  final kickOffTs = DateTime(2026, 8, 2, 15, 0);

  group('isMatchSessionLive', () {
    test('true after recorded kick-off and before full-time', () {
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOffTs),
      ];

      expect(
        isMatchSessionLive(
          match: _match(timestamp: kickOffTs),
          highlights: highlights,
          now: DateTime(2026, 8, 2, 15, 30),
        ),
        isTrue,
      );
    });

    test('true from Match.timestamp when highlight missing', () {
      expect(
        isMatchSessionLive(
          match: _match(timestamp: kickOffTs),
          highlights: const [],
          now: DateTime(2026, 8, 2, 15, 10),
        ),
        isTrue,
      );
    });

    test('prefers Match.timestamp over late recorded kick-off for Live start', () {
      // Recorded kick-off is late; Live must still open at Match.timestamp.
      final highlights = [
        _timeEvent(
          type: TimeType.kickOff,
          at: DateTime(2026, 8, 2, 15, 20),
        ),
      ];

      expect(
        isMatchSessionLive(
          match: _match(timestamp: kickOffTs),
          highlights: highlights,
          now: DateTime(2026, 8, 2, 15, 5),
        ),
        isTrue,
      );
    });

    test('ignores dateCh/timeCh when Match.timestamp is set', () {
      // dateCh/timeCh say 18:00 but timestamp is 15:00 — timestamp wins.
      expect(
        isMatchSessionLive(
          match: _match(
            dateCh: '02/08/2026',
            timeCh: '18:00',
            timestamp: kickOffTs,
          ),
          highlights: const [],
          now: DateTime(2026, 8, 2, 15, 10),
        ),
        isTrue,
      );
      expect(
        isMatchSessionLive(
          match: _match(
            dateCh: '02/08/2026',
            timeCh: '18:00',
            timestamp: kickOffTs,
          ),
          highlights: const [],
          now: DateTime(2026, 8, 2, 14, 50),
        ),
        isFalse,
      );
    });

    test('false before Match.timestamp kick-off', () {
      expect(
        isMatchSessionLive(
          match: _match(timestamp: kickOffTs),
          highlights: const [],
          now: DateTime(2026, 8, 2, 14, 50),
        ),
        isFalse,
      );
    });

    test('false after timestamp duration + half-time break without temps forts', () {
      // Slot = 90' play + 15' break → ends 16:45.
      expect(
        isMatchSessionLive(
          match: _match(timestamp: kickOffTs),
          highlights: const [],
          now: DateTime(2026, 8, 2, 16, 40),
        ),
        isTrue,
      );
      expect(
        isMatchSessionLive(
          match: _match(timestamp: kickOffTs),
          highlights: const [],
          now: DateTime(2026, 8, 2, 16, 50),
        ),
        isFalse,
      );
    });

    test('false after full-time highlight', () {
      final end = DateTime(2026, 8, 2, 16, 50);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOffTs),
        _timeEvent(type: TimeType.end, at: end),
      ];

      expect(
        isMatchSessionLive(
          match: _match(timestamp: kickOffTs),
          highlights: highlights,
          now: DateTime(2026, 8, 2, 17, 0),
        ),
        isFalse,
      );
    });

    test('false when only dateCh/timeCh present without timestamp', () {
      expect(
        isMatchSessionLive(
          match: _match(dateCh: '02/08/2026', timeCh: '15:00'),
          highlights: const [],
          now: DateTime(2026, 8, 2, 15, 10),
        ),
        isFalse,
      );
    });
  });

  group('canResyncMatchIntense', () {
    test('true within 48h after full-time', () {
      final end = DateTime(2026, 8, 2, 16, 50);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOffTs),
        _timeEvent(type: TimeType.end, at: end),
      ];

      expect(
        canResyncMatchIntense(
          match: _match(isMatchPlayed: true, timestamp: kickOffTs),
          highlights: highlights,
          now: DateTime(2026, 8, 3, 10, 0),
        ),
        isTrue,
      );
    });

    test('true when match played without full-time highlight', () {
      expect(
        canResyncMatchIntense(
          match: _match(
            isMatchPlayed: true,
            timestamp: kickOffTs,
          ),
          highlights: const [],
          now: DateTime(2026, 8, 2, 18, 0),
        ),
        isTrue,
      );
    });

    test('true after timestamp slot end without any temps forts', () {
      expect(
        canResyncMatchIntense(
          match: _match(timestamp: kickOffTs),
          highlights: const [],
          now: DateTime(2026, 8, 2, 16, 50),
        ),
        isTrue,
      );
    });

    test('false during timestamp match window without temps forts', () {
      expect(
        canResyncMatchIntense(
          match: _match(timestamp: kickOffTs),
          highlights: const [],
          now: DateTime(2026, 8, 2, 15, 30),
        ),
        isFalse,
      );
    });

    test('false after 48h window', () {
      final end = DateTime(2026, 8, 2, 16, 50);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOffTs),
        _timeEvent(type: TimeType.end, at: end),
      ];

      expect(
        canResyncMatchIntense(
          match: _match(isMatchPlayed: true, timestamp: kickOffTs),
          highlights: highlights,
          now: DateTime(2026, 8, 5, 0, 0),
        ),
        isFalse,
      );
    });
  });

  group('resolveMatchIntenseResyncWindow', () {
    test('uses kick-off and full-time Temps forts when both present', () {
      final end = DateTime(2026, 8, 2, 16, 50);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOffTs),
        _timeEvent(type: TimeType.end, at: end),
      ];

      final window = resolveMatchIntenseResyncWindow(
        _match(timestamp: kickOffTs),
        highlights,
      );
      expect(window, isNotNull);
      expect(window!.start.toUtc(), kickOffTs.toUtc());
      expect(window.stop.toUtc(), end.toUtc());
    });

    test(
      'builds halves + 15 min break from Match.timestamp when no temps forts',
      () {
        final window = resolveMatchIntenseResyncWindow(
          _match(
            isMatchPlayed: true,
            timestamp: kickOffTs,
            // dateCh/timeCh must be ignored for Intense windows.
            dateCh: '02/08/2026',
            timeCh: '18:00',
          ),
          const [],
        );

        expect(window, isNotNull);
        expect(window!.start.toLocal(), kickOffTs);
        // T+45, pause 15', T+45 → stop at T+105.
        expect(
          window.stop.toLocal(),
          kickOffTs.add(const Duration(minutes: 105)),
        );
        expect(window.playPeriods, hasLength(2));
        expect(
          window.playPeriods[0].start.toDate().toLocal(),
          kickOffTs,
        );
        expect(
          window.playPeriods[0].end.toDate().toLocal(),
          kickOffTs.add(const Duration(minutes: 45)),
        );
        expect(
          window.playPeriods[1].start.toDate().toLocal(),
          kickOffTs.add(const Duration(minutes: 60)),
        );
        expect(
          window.playPeriods[1].end.toDate().toLocal(),
          kickOffTs.add(const Duration(minutes: 105)),
        );
      },
    );

    test('Live is open during timestamp-built slot without temps forts', () {
      expect(
        isMatchSessionLive(
          match: _match(timestamp: kickOffTs),
          highlights: const [],
          now: kickOffTs.add(const Duration(minutes: 70)),
        ),
        isTrue,
      );
      expect(
        isMatchSessionLive(
          match: _match(timestamp: kickOffTs),
          highlights: const [],
          now: kickOffTs.add(const Duration(minutes: 110)),
        ),
        isFalse,
      );
    });

    test('can re-sync after timestamp slot ends without temps forts', () {
      expect(
        canResyncMatchIntense(
          match: _match(timestamp: kickOffTs),
          highlights: const [],
          now: kickOffTs.add(const Duration(minutes: 110)),
        ),
        isTrue,
      );
    });

    test('ignores late-tapped kick-off; keeps Match.timestamp window', () {
      // Real bug: kick-off Temps forts tapped after the match (15:46 UTC wall
      // clock) while Match.timestamp is 15:00 → must not collapse to start==stop.
      final highlights = [
        _timeEvent(
          type: TimeType.kickOff,
          at: DateTime.utc(2026, 8, 2, 15, 46, 48).toLocal(),
        ),
      ];

      final window = resolveMatchIntenseResyncWindow(
        _match(
          isMatchPlayed: true,
          timestamp: kickOffTs,
        ),
        highlights,
      );

      expect(window, isNotNull);
      expect(window!.start.toLocal(), kickOffTs);
      expect(window.stop.toLocal(), DateTime(2026, 8, 2, 16, 45));
      expect(window.stop.isAfter(window.start), isTrue);
      expect(window.playPeriods, hasLength(2));
    });

    test('never returns a zero-width window', () {
      final lateKickOff = DateTime(2026, 8, 2, 15, 46, 48);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: lateKickOff),
        _timeEvent(type: TimeType.end, at: lateKickOff),
      ];

      final window = resolveMatchIntenseResyncWindow(
        _match(duration: 90, timestamp: kickOffTs),
        highlights,
      );
      expect(window, isNotNull);
      // Invalid end highlight + incomplete Temps forts → timestamp slot + 15'.
      expect(
        window!.stop.difference(window.start),
        const Duration(minutes: 105),
      );
      expect(window.start.toLocal(), kickOffTs);
    });

    test('returns null when Match.timestamp missing and no usable temps forts', () {
      final window = resolveMatchIntenseResyncWindow(
        _match(dateCh: '02/08/2026', timeCh: '15:00'),
        const [],
      );
      expect(window, isNull);
    });
  });

  group('intenseLiveMatchStartUtc', () {
    test('uses Match.timestamp when kick-off highlight missing', () {
      final start = intenseLiveMatchStartUtc(
        const [],
        match: _match(timestamp: kickOffTs),
      );
      expect(start?.toLocal(), kickOffTs);
    });

    test('prefers Match.timestamp over dateCh/timeCh', () {
      final start = intenseLiveMatchStartUtc(
        const [],
        match: _match(
          dateCh: '02/08/2026',
          timeCh: '18:00',
          timestamp: kickOffTs,
        ),
      );
      expect(start?.toLocal(), kickOffTs);
    });

    test('does not use dateCh/timeCh alone', () {
      final start = intenseLiveMatchStartUtc(
        const [],
        match: _match(dateCh: '02/08/2026', timeCh: '15:00'),
      );
      expect(start, isNull);
    });
  });
}
