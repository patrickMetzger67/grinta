import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/session_report_chat_context.dart';

void main() {
  group('SessionReportChatContext.detectsSessionReportIntent', () {
    test('detects French yesterday session report request', () {
      expect(
        SessionReportChatContext.detectsSessionReportIntent(
          "Ask Gio, envoie-moi le rapport de la séance d'hier",
        ),
        isTrue,
      );
    });

    test('detects English today match report', () {
      expect(
        SessionReportChatContext.detectsSessionReportIntent(
          "Send me today's match report",
        ),
        isTrue,
      );
    });

    test('detects envoyer en PDF le rapport de la séance', () {
      expect(
        SessionReportChatContext.detectsSessionReportIntent(
          "tu peux m'envoyer en PDF le rapport de la séance de hier de l'équipe Séniors 1 ?",
        ),
        isTrue,
      );
    });

    test('does not detect unrelated agenda question', () {
      expect(
        SessionReportChatContext.detectsSessionReportIntent(
          'quel est mon prochain match ?',
        ),
        isFalse,
      );
    });
  });

  group('SessionReportChatContext.extractEmailFromMessage', () {
    test('extracts email address', () {
      expect(
        SessionReportChatContext.extractEmailFromMessage(
          'envoie le rapport à coach@club.fr s’il te plaît',
        ),
        'coach@club.fr',
      );
    });
  });
}
