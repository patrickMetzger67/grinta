import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/chat_fcm_notification.dart';

void main() {
  group('looksLikeStreamChatPush', () {
    test('detects Stream data-only payloads', () {
      expect(
        looksLikeStreamChatPush({'sender': 'stream.chat', 'type': 'message.new'}),
        isTrue,
      );
      expect(looksLikeStreamChatPush({'type': 'convocation'}), isFalse);
    });
  });

  group('parseChatFcmNotification', () {
    test('fills title and body for a Stream data-only message', () {
      final parsed = parseChatFcmNotification(
        data: {
          'sender': 'stream.chat',
          'type': 'message.new',
          'cid': 'messaging:abc',
        },
      );
      expect(parsed, isNotNull);
      expect(parsed!.title, 'Messagerie');
      expect(parsed.body, 'Nouveau message');
      expect(parsed.payload['id'], 'messaging:abc');
      expect(parsed.isStreamChat, isTrue);
    });

    test('prefers notification title/body when present', () {
      final parsed = parseChatFcmNotification(
        notificationTitle: 'Alice',
        notificationBody: 'Salut',
        data: {'type': 'chat', 'id': 'u1'},
      );
      expect(parsed!.title, 'Alice');
      expect(parsed.body, 'Salut');
    });
  });

  group('shouldNotifyIncomingChatMessage', () {
    test('notifies when another member writes and no conversation is open', () {
      expect(
        shouldNotifyIncomingChatMessage(
          senderId: 'other',
          currentUserId: 'me',
          eventCid: 'messaging:abc',
          activeChannelCid: null,
        ),
        isTrue,
      );
    });

    test('does not notify for the current user or an open conversation', () {
      expect(
        shouldNotifyIncomingChatMessage(
          senderId: 'me',
          currentUserId: 'me',
          eventCid: 'messaging:abc',
          activeChannelCid: null,
        ),
        isFalse,
      );
      expect(
        shouldNotifyIncomingChatMessage(
          senderId: 'other',
          currentUserId: 'me',
          eventCid: 'messaging:abc',
          activeChannelCid: 'messaging:abc',
        ),
        isFalse,
      );
    });
  });
}
