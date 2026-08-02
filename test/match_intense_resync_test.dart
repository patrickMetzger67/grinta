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
}) {
  return models.Match(
    withTracker: withTracker,
    isMatchPlayed: isMatchPlayed,
    dateCh: dateCh,
    timeCh: timeCh,
    ownerId: 'owner1',
    duration: 90,
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
          match: _match(),
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

    test('false after full-time highlight', () {
      final kickOff = DateTime(2026, 8, 2, 15, 0);
      final end = DateTime(2026, 8, 2, 16, 50);
      final highlights = [
        _timeEvent(type: TimeType.kickOff, at: kickOff),
        _timeEvent(type: TimeType.end, at: end),
      ];

      expect(
        isMatchSessionLive(
          match: _match(),
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
    test('uses kick-off and full-time timestamps', () {
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
  });
}
