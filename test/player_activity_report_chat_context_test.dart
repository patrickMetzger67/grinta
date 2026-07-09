import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/player_activity_report_chat_context.dart';

void main() {
  group('PlayerActivityReportChatContext.detectsActivityReportIntent', () {
    test('detects bilan activité with month', () {
      expect(
        PlayerActivityReportChatContext.detectsActivityReportIntent(
          'bilan sur mon activité durant le mois de mai',
        ),
        isTrue,
      );
    });

    test('detects week summary', () {
      expect(
        PlayerActivityReportChatContext.detectsActivityReportIntent(
          'résumé de ma semaine dernière',
        ),
        isTrue,
      );
    });

    test('detects personal stats with period', () {
      expect(
        PlayerActivityReportChatContext.detectsActivityReportIntent(
          'mon temps de jeu en juin',
        ),
        isTrue,
      );
    });

    test('does not detect unrelated agenda question', () {
      expect(
        PlayerActivityReportChatContext.detectsActivityReportIntent(
          'quel est mon prochain match ?',
        ),
        isFalse,
      );
    });
  });
}
