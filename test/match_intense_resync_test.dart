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
}) {
  return models.Match(
    withTracker: withTracker,
    isMatchPlayed: isMatchPlayed,
    dateCh: dateCh,
    timeCh: timeCh,
    ownerId: 'owner1',
    duration: duration,
  );
}

void main() {
  group('isMatchSessionLive', () {
    test('true after recorded kick-off and before full-time', () {
      final kickOff = DateTime(2026, 8, 2, 15, 0);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOff),
      ];

      expect(
        isMatchSessionLive(
          match: _match(dateCh: '02/08/2026', timeCh: '15:00'),
          highlights: highlights,
          now: DateTime(2026, 8, 2, 15, 30),
        ),
        isTrue,
      );
    });

    test('true from scheduled kick-off when highlight missing', () {
      expect(
        isMatchSessionLive(
          match: _match(dateCh: '02/08/2026', timeCh: '15:00'),
          highlights: const [],
          now: DateTime(2026, 8, 2, 15, 10),
        ),
        isTrue,
      );
    });

    test('prefers schedule over recorded kick-off for Live start', () {
      // Recorded kick-off is late; Live must still open at scheduled 15:00.
      final highlights = [
        _timeEvent(
          type: TimeType.kickOff,
          at: DateTime(2026, 8, 2, 15, 20),
        ),
      ];

      expect(
        isMatchSessionLive(
          match: _match(dateCh: '02/08/2026', timeCh: '15:00'),
          highlights: highlights,
          now: DateTime(2026, 8, 2, 15, 5),
        ),
        isTrue,
      );
    });

    test('false before scheduled kick-off', () {
      expect(
        isMatchSessionLive(
          match: _match(dateCh: '02/08/2026', timeCh: '15:00'),
          highlights: const [],
          now: DateTime(2026, 8, 2, 14, 50),
        ),
        isFalse,
      );
    });

    test('false after scheduled duration + half-time break without temps forts', () {
      // Slot = 90' play + 15' break → ends 16:45.
      expect(
        isMatchSessionLive(
          match: _match(dateCh: '02/08/2026', timeCh: '15:00'),
          highlights: const [],
          now: DateTime(2026, 8, 2, 16, 40),
        ),
        isTrue,
      );
      expect(
        isMatchSessionLive(
          match: _match(dateCh: '02/08/2026', timeCh: '15:00'),
          highlights: const [],
          now: DateTime(2026, 8, 2, 16, 50),
        ),
        isFalse,
      );
    });

    test('false after full-time highlight', () {
      final kickOff = DateTime(2026, 8, 2, 15, 0);
      final end = DateTime(2026, 8, 2, 16, 50);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOff),
        _timeEvent(type: TimeType.end, at: end),
      ];

      expect(
        isMatchSessionLive(
          match: _match(dateCh: '02/08/2026', timeCh: '15:00'),
          highlights: highlights,
          now: DateTime(2026, 8, 2, 17, 0),
        ),
        isFalse,
      );
    });
  });

  group('canResyncMatchIntense', () {
    test('true within 48h after full-time', () {
      final kickOff = DateTime(2026, 8, 2, 15, 0);
      final end = DateTime(2026, 8, 2, 16, 50);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOff),
        _timeEvent(type: TimeType.end, at: end),
      ];

      expect(
        canResyncMatchIntense(
          match: _match(isMatchPlayed: true),
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
            dateCh: '02/08/2026',
            timeCh: '15:00',
          ),
          highlights: const [],
          now: DateTime(2026, 8, 2, 18, 0),
        ),
        isTrue,
      );
    });

    test('true after scheduled end without any temps forts', () {
      expect(
        canResyncMatchIntense(
          match: _match(
            dateCh: '02/08/2026',
            timeCh: '15:00',
          ),
          highlights: const [],
          now: DateTime(2026, 8, 2, 16, 50),
        ),
        isTrue,
      );
    });

    test('false during scheduled match window without temps forts', () {
      expect(
        canResyncMatchIntense(
          match: _match(
            dateCh: '02/08/2026',
            timeCh: '15:00',
          ),
          highlights: const [],
          now: DateTime(2026, 8, 2, 15, 30),
        ),
        isFalse,
      );
    });

    test('false after 48h window', () {
      final kickOff = DateTime(2026, 8, 2, 15, 0);
      final end = DateTime(2026, 8, 2, 16, 50);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOff),
        _timeEvent(type: TimeType.end, at: end),
      ];

      expect(
        canResyncMatchIntense(
          match: _match(isMatchPlayed: true),
          highlights: highlights,
          now: DateTime(2026, 8, 5, 0, 0),
        ),
        isFalse,
      );
    });
  });

  group('resolveMatchIntenseResyncWindow', () {
    test('uses kick-off and full-time timestamps when no schedule', () {
      final kickOff = DateTime(2026, 8, 2, 15, 0);
      final end = DateTime(2026, 8, 2, 16, 50);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOff),
        _timeEvent(type: TimeType.end, at: end),
      ];

      final window = resolveMatchIntenseResyncWindow(_match(), highlights);
      expect(window, isNotNull);
      expect(window!.start.toUtc(), kickOff.toUtc());
      expect(window.stop.toUtc(), end.toUtc());
    });

    test('falls back to schedule halves + 15 min break when end highlight missing', () {
      final window = resolveMatchIntenseResyncWindow(
        _match(
          isMatchPlayed: true,
          dateCh: '02/08/2026',
          timeCh: '15:00',
        ),
        const [],
      );
      expect(window, isNotNull);
      expect(window!.start.toLocal(), DateTime(2026, 8, 2, 15, 0));
      // 90' + 15' break → 16:45; two play periods exclude the break.
      expect(window.stop.toLocal(), DateTime(2026, 8, 2, 16, 45));
      expect(window.playPeriods, hasLength(2));
      expect(
        window.playPeriods[0].end.toDate().toLocal(),
        DateTime(2026, 8, 2, 15, 45),
      );
      expect(
        window.playPeriods[1].start.toDate().toLocal(),
        DateTime(2026, 8, 2, 16, 0),
      );
    });

    test('ignores late-tapped kick-off that collapses the GNSS window', () {
      // Real bug: kick-off Temps forts tapped after the match (15:46 UTC wall
      // clock) while the fixture was scheduled 15:00 → start==stop → 0 samples.
      final highlights = [
        _timeEvent(
          type: TimeType.kickOff,
          at: DateTime.utc(2026, 8, 2, 15, 46, 48).toLocal(),
        ),
      ];

      final window = resolveMatchIntenseResyncWindow(
        _match(
          isMatchPlayed: true,
          dateCh: '02/08/2026',
          timeCh: '15:00',
        ),
        highlights,
      );

      expect(window, isNotNull);
      expect(window!.start.toLocal(), DateTime(2026, 8, 2, 15, 0));
      expect(window.stop.toLocal(), DateTime(2026, 8, 2, 16, 45));
      expect(window.stop.isAfter(window.start), isTrue);
      expect(window.playPeriods, hasLength(2));
    });

    test('never returns a zero-width window', () {
      final kickOff = DateTime(2026, 8, 2, 15, 46, 48);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOff),
        _timeEvent(type: TimeType.end, at: kickOff),
      ];

      final window = resolveMatchIntenseResyncWindow(
        _match(duration: 90),
        highlights,
      );
      expect(window, isNotNull);
      // Invalid end highlight → scheduled slot including 15' break.
      expect(window!.stop.difference(window.start), const Duration(minutes: 105));
    });
  });

  group('intenseLiveMatchStartUtc', () {
    test('uses schedule when kick-off highlight missing', () {
      final start = intenseLiveMatchStartUtc(
        const [],
        match: _match(dateCh: '02/08/2026', timeCh: '15:00'),
      );
      expect(start?.toLocal(), DateTime(2026, 8, 2, 15, 0));
    });
  });
}
