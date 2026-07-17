import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/chat_action.dart';

void main() {
  test('parses send_report action', () {
    final actions = parseChatActions(<String, dynamic>{
      'actions': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'answer',
          'text': 'Je t’envoie le rapport.',
        },
        <String, dynamic>{
          'type': 'send_report',
          'params': <String, dynamic>{
            'eventId': 'evt-1',
            'eventType': 'training',
            'email': 'coach@club.fr',
          },
        },
      ],
    });

    expect(actions.whereType<ChatAnswerAction>(), hasLength(1));
    final send = actions.whereType<ChatSendReportAction>().single;
    expect(send.eventId, 'evt-1');
    expect(send.email, 'coach@club.fr');
    expect(send.isMatch, isFalse);
  });
}
