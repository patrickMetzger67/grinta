import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/stream_chat_inbox.dart';

void main() {
  group('StreamChatInbox.mergedUnreadCount', () {
    test('uses the channel sum when it is higher than the user total', () {
      expect(
        StreamChatInbox.mergedUnreadCount(
          totalUnreadCount: 0,
          channelUnreads: const [1, 2],
        ),
        3,
      );
    });

    test('uses the user total when channels have not been watched yet', () {
      expect(
        StreamChatInbox.mergedUnreadCount(
          totalUnreadCount: 4,
          channelUnreads: const [],
        ),
        4,
      );
    });

    test('ignores negative or empty channel unread values', () {
      expect(
        StreamChatInbox.mergedUnreadCount(
          totalUnreadCount: 1,
          channelUnreads: const [0, -2],
        ),
        1,
      );
    });
  });

  group('StreamChatInbox.shouldNotifyIncomingMessage', () {
    test('notifies when another member writes and no conversation is open', () {
      expect(
        StreamChatInbox.shouldNotifyIncomingMessage(
          senderId: 'other',
          currentUserId: 'me',
          eventCid: 'messaging:abc',
          activeChannelCid: null,
        ),
        isTrue,
      );
    });

    test('does not notify for the current user\'s own messages', () {
      expect(
        StreamChatInbox.shouldNotifyIncomingMessage(
          senderId: 'me',
          currentUserId: 'me',
          eventCid: 'messaging:abc',
          activeChannelCid: null,
        ),
        isFalse,
      );
    });

    test('does not notify when that conversation is already open', () {
      expect(
        StreamChatInbox.shouldNotifyIncomingMessage(
          senderId: 'other',
          currentUserId: 'me',
          eventCid: 'messaging:abc',
          activeChannelCid: 'messaging:abc',
        ),
        isFalse,
      );
    });

    test('does not notify silent messages', () {
      expect(
        StreamChatInbox.shouldNotifyIncomingMessage(
          senderId: 'other',
          currentUserId: 'me',
          eventCid: 'messaging:abc',
          activeChannelCid: null,
          isSilent: true,
        ),
        isFalse,
      );
    });
  });
}
