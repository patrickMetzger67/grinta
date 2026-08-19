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

  group('parseFcmNotification', () {
    test('fills title and body for a Stream data-only message', () {
      final parsed = parseFcmNotification(
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
      expect(parsed.isChat, isTrue);
    });

    test('prefers notification title/body when present', () {
      final parsed = parseFcmNotification(
        notificationTitle: 'Alice',
        notificationBody: 'Salut',
        data: {'type': 'chat', 'id': 'u1'},
      );
      expect(parsed!.title, 'Alice');
      expect(parsed.body, 'Salut');
    });

    test('parses convocation, RPE and team invite payloads', () {
      final convocation = parseFcmNotification(
        notificationTitle: 'Convocation',
        notificationBody: 'Match samedi',
        data: {'type': 'convocation', 'id': 'match-1'},
      );
      expect(convocation, isNotNull);
      expect(convocation!.title, 'Convocation');
      expect(convocation.body, 'Match samedi');
      expect(convocation.isChat, isFalse);

      final rpe = parseFcmNotification(
        data: {
          'type': 'RPEAfter',
          'title': 'Ressenti',
          'body': 'Comment s’est passée la séance ?',
          'id': 'event-1',
        },
      );
      expect(rpe!.title, 'Ressenti');
      expect(rpe.isChat, isFalse);

      final invite = parseFcmNotification(
        data: {
          'type': 'teamDetail',
          'body': 'Tu as été ajouté à l’équipe',
          'id': 'team-1',
        },
      );
      expect(invite!.title, 'Grinta');
      expect(invite.body, 'Tu as été ajouté à l’équipe');
      expect(invite.isChat, isFalse);
    });
  });

  group('shouldDisplayRemoteFcm', () {
    test('always displays non-chat types', () {
      expect(
        shouldDisplayRemoteFcm(
          data: {'type': 'convocation', 'id': 'match-1'},
          activeChatChannelCid: 'messaging:abc',
        ),
        isTrue,
      );
    });

    test('suppresses chat only when that conversation is open', () {
      expect(
        shouldDisplayRemoteFcm(
          data: {'type': 'chat', 'cid': 'messaging:abc'},
          activeChatChannelCid: 'messaging:abc',
        ),
        isFalse,
      );
      expect(
        shouldDisplayRemoteFcm(
          data: {'type': 'chat', 'cid': 'messaging:abc'},
          activeChatChannelCid: 'messaging:other',
        ),
        isTrue,
      );
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
