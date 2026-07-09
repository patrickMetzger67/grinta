import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/ask_diego_datetime_params.dart';

void main() {
  // Wednesday 2026-07-08
  final DateTime ref = DateTime(2026, 7, 8);

  group('parseIsoDateParam', () {
    test('parses yyyy-MM-dd', () {
      expect(parseIsoDateParam('2026-07-16'), DateTime(2026, 7, 16));
    });
  });

  group('parseTimeParam', () {
    test('parses HH:mm', () {
      expect(parseTimeParam('18:00'), const TimeOfDay(hour: 18, minute: 0));
      expect(parseTimeParam('15:30'), const TimeOfDay(hour: 15, minute: 30));
    });
  });

  group('parseFrenchRelativeDate', () {
    test('demain', () {
      expect(
        parseFrenchRelativeDate('créer un entraînement demain', ref),
        DateTime(2026, 7, 9),
      );
    });

    test('mercredi prochain from Wednesday', () {
      expect(
        parseFrenchRelativeDate(
          'peux tu me créer un entraînement pour mercredi prochain à 18 heures',
          ref,
        ),
        DateTime(2026, 7, 15),
      );
    });

    test('samedi', () {
      expect(
        parseFrenchRelativeDate('créer un match samedi à 15h', ref),
        DateTime(2026, 7, 11),
      );
    });
  });

  group('parseFrenchTime', () {
    test('18 heures', () {
      expect(
        parseFrenchTime('mercredi prochain à 18 heures'),
        const TimeOfDay(hour: 18, minute: 0),
      );
    });

    test('15h', () {
      expect(
        parseFrenchTime('créer un match samedi à 15h'),
        const TimeOfDay(hour: 15, minute: 0),
      );
    });

    test('18:00', () {
      expect(
        parseFrenchTime('à 18:00'),
        const TimeOfDay(hour: 18, minute: 0),
      );
    });
  });

  group('resolveCreateEventDateTime', () {
    test('prefers Diego params over message fallback', () {
      final AskDiegoCreateEventDateTime resolved = resolveCreateEventDateTime(
        params: const <String, dynamic>{
          'date': '2026-07-20',
          'time': '19:30',
        },
        userMessage: 'créer un entraînement samedi à 15h',
        referenceDate: ref,
      );

      expect(resolved.date, DateTime(2026, 7, 20));
      expect(resolved.time, const TimeOfDay(hour: 19, minute: 30));
    });

    test('falls back to user message when params missing', () {
      final AskDiegoCreateEventDateTime resolved = resolveCreateEventDateTime(
        params: const <String, dynamic>{},
        userMessage:
            'peux tu me créer un entraînement pour mercredi prochain à 18 heures',
        referenceDate: ref,
      );

      expect(resolved.date, DateTime(2026, 7, 15));
      expect(resolved.time, const TimeOfDay(hour: 18, minute: 0));
    });
  });
}
