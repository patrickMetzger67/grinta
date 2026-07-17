import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/chat_action.dart';
import 'package:grinta/services/session_report_action_resolver.dart';

void main() {
  test('resolves yesterday training PDF request for named team', () {
    final action = SessionReportActionResolver.resolve(
      userMessage:
          "tu peux m'envoyer en PDF le rapport de la séance de hier de l'équipe Séniors 1 ?",
      appContext: <String, dynamic>{
        'sessionReports': <String, dynamic>{
          'defaultEmail': 'coach@club.fr',
          'sessions': <Map<String, dynamic>>[
            <String, dynamic>{
              'eventId': 'evt-other',
              'type': 'training',
              'title': 'U15',
              'teamName': 'U15',
              'hasStats': true,
            },
            <String, dynamic>{
              'eventId': 'evt-seniors',
              'type': 'training',
              'title': 'Entraînement Séniors 1',
              'teamName': 'Séniors 1',
              'hasStats': true,
            },
          ],
        },
      },
    );

    expect(action, isA<ChatSendReportAction>());
    expect(action!.eventId, 'evt-seniors');
    expect(action.email, 'coach@club.fr');
    expect(action.isMatch, isFalse);
  });

  test('returns null when no stats sessions', () {
    final action = SessionReportActionResolver.resolve(
      userMessage: "envoie le rapport PDF d'hier",
      appContext: <String, dynamic>{
        'sessionReports': <String, dynamic>{
          'defaultEmail': 'coach@club.fr',
          'sessions': <Map<String, dynamic>>[
            <String, dynamic>{
              'eventId': 'evt-1',
              'type': 'training',
              'hasStats': false,
            },
          ],
        },
      },
    );

    expect(action, isNull);
  });
}
