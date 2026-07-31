import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/opponent_analysis_prompt_state_service.dart';

void main() {
  group('OpponentAnalysisPromptStateService', () {
    late OpponentAnalysisPromptStateService service;

    setUp(() {
      service = OpponentAnalysisPromptStateService.instance;
      service.debugReset();
      service.nowLocal = () => DateTime(2026, 7, 31, 10);
    });

    test('shouldPromptMatch is true for unknown match', () {
      expect(service.shouldPromptMatch('match-1'), isTrue);
    });

    test('shouldPromptMatch is false after skipped or sent', () {
      service.debugReset(matchStatus: {'match-2': 'skipped'});
      expect(service.shouldPromptMatch('match-2'), isFalse);

      service.debugReset(matchStatus: {'match-1': 'sent'});
      expect(service.shouldPromptMatch('match-1'), isFalse);
    });

    test('accepted without sent can be asked again (retry after failed Oui)', () {
      service.debugReset(matchStatus: {'match-1': 'accepted'});
      expect(service.shouldPromptMatch('match-1'), isTrue);
    });

    test('isSnoozed respects snoozeUntilDate (exclusive of that day)', () {
      service.debugReset(snoozeUntilDate: '2026-08-01');
      expect(service.isSnoozed, isTrue);
      expect(service.shouldPromptMatch('match-1'), isFalse);

      service.nowLocal = () => DateTime(2026, 8, 1, 9);
      expect(service.isSnoozed, isFalse);
      expect(service.shouldPromptMatch('match-1'), isTrue);
    });

    test('formatLocalDate / parseLocalDate round-trip', () {
      final date = DateTime(2026, 7, 31);
      final formatted = OpponentAnalysisPromptStateService.formatLocalDate(date);
      expect(formatted, '2026-07-31');
      expect(
        OpponentAnalysisPromptStateService.parseLocalDate(formatted),
        DateTime(2026, 7, 31),
      );
    });
  });
}
