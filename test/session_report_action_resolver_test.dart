import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/chat_action.dart';
import 'package:grinta/services/session_report_action_resolver.dart';

void main() {
  test('resolves yesterday training PDF request for named team', () {
    final result = SessionReportActionResolver.resolveDetailed(
      userMessage:
          'tu peux m\'envoyer par mail le rapport de la séance de l\'équipe séniors 1 de hier soir',
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

    expect(result.canSend, isTrue);
    expect(result.action, isA<ChatSendReportAction>());
    expect(result.action!.eventId, 'evt-seniors');
    expect(result.action!.email, 'coach@club.fr');
    expect(result.action!.isMatch, isFalse);
  });

  test('returns no_stats when no stats sessions', () {
    final result = SessionReportActionResolver.resolveDetailed(
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

    expect(result.action, isNull);
    expect(result.failureReason, 'no_stats');
  });
}
