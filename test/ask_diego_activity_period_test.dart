import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/ask_diego_activity_period.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  // Wednesday 2026-07-08
  final DateTime ref = DateTime(2026, 7, 8);

  setUpAll(() async {
    await initializeDateFormatting('fr');
    await initializeDateFormatting('en');
  });

  group('parseActivityPeriodFromMessage', () {
    test('parses month name mai in French activity question', () {
      final AskDiegoActivityPeriod? period = parseActivityPeriodFromMessage(
        message: 'bilan sur mon activité durant le mois de mai',
        referenceDate: ref,
        localeCode: 'fr',
      );

      expect(period, isNotNull);
      expect(period!.start, DateTime(2026, 5, 1));
      expect(period.end, DateTime(2026, 5, 31));
      expect(period.label.toLowerCase(), contains('mai'));
    });

    test('parses explicit month and year', () {
      final AskDiegoActivityPeriod? period = parseActivityPeriodFromMessage(
        message: 'mon activité en mai 2025',
        referenceDate: ref,
        localeCode: 'fr',
      );

      expect(period, isNotNull);
      expect(period!.start, DateTime(2025, 5, 1));
      expect(period.end, DateTime(2025, 5, 31));
    });

    test('parses la semaine dernière', () {
      final AskDiegoActivityPeriod? period = parseActivityPeriodFromMessage(
        message: 'résumé de ma semaine dernière',
        referenceDate: ref,
        localeCode: 'fr',
      );

      expect(period, isNotNull);
      expect(period!.start, DateTime(2026, 6, 29));
      expect(period.end, DateTime(2026, 7, 5));
      expect(period.dayCount, 7);
    });

    test('parses last week in English', () {
      final AskDiegoActivityPeriod? period = parseActivityPeriodFromMessage(
        message: 'activity summary for last week',
        referenceDate: ref,
        localeCode: 'en',
      );

      expect(period, isNotNull);
      expect(period!.start, DateTime(2026, 6, 29));
      expect(period.end, DateTime(2026, 7, 5));
    });

    test('parses le mois dernier', () {
      final AskDiegoActivityPeriod? period = parseActivityPeriodFromMessage(
        message: 'mes performances tracker sur le mois dernier',
        referenceDate: ref,
        localeCode: 'fr',
      );

      expect(period, isNotNull);
      expect(period!.start, DateTime(2026, 6, 1));
      expect(period.end, DateTime(2026, 6, 30));
    });

    test('parses last 30 days', () {
      final AskDiegoActivityPeriod? period = parseActivityPeriodFromMessage(
        message: 'my activity over the last 30 days',
        referenceDate: ref,
        localeCode: 'en',
      );

      expect(period, isNotNull);
      expect(period!.end, DateTime(2026, 7, 8));
      expect(period.start, DateTime(2026, 6, 9));
      expect(period.dayCount, 30);
    });

    test('returns null when no period expression', () {
      expect(
        parseActivityPeriodFromMessage(
          message: 'quel est mon prochain match ?',
          referenceDate: ref,
        ),
        isNull,
      );
    });
  });

  group('AskDiegoActivityPeriod.previousPeriod', () {
    test('computes previous month for May', () {
      final AskDiegoActivityPeriod may = AskDiegoActivityPeriod(
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 31),
        label: 'Mai 2026',
      );

      final previous = may.previousPeriod('fr');
      expect(previous.start, DateTime(2026, 4, 1));
      expect(previous.end, DateTime(2026, 4, 30));
      expect(previous.dayCount, 30);
    });

    test('computes previous week for last week range', () {
      final AskDiegoActivityPeriod? lastWeek = parseActivityPeriodFromMessage(
        message: 'semaine dernière',
        referenceDate: ref,
      );

      expect(lastWeek, isNotNull);
      final previous = lastWeek!.previousPeriod('fr');
      expect(previous.dayCount, 7);
      expect(previous.end, DateTime(2026, 6, 28));
      expect(previous.start, DateTime(2026, 6, 22));
    });
  });
}
