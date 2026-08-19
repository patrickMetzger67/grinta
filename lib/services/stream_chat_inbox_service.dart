import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:grinta/services/notification_fcm_service.dart';
import 'package:grinta/util/stream_chat_inbox.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Keeps Stream Chat channels watched and unread counts live, even when the
/// Messagerie tab is not mounted (web sidebar only builds the selected page).
class StreamChatInboxService {
  StreamChatInboxService._();

  static final StreamChatInboxService instance = StreamChatInboxService._();

  StreamChatClient? _client;
  StreamSubscription<Event>? _eventsSub;
  StreamSubscription<ConnectionStatus>? _connectionSub;
  final StreamController<int> _unreadController =
      StreamController<int>.broadcast();

  int _unreadCount = 0;
  String? _activeChannelCid;
  String _fallbackTitle = 'Messagerie';
  String _fallbackBody = 'Nouveau message';
  bool _started = false;
  bool _watching = false;

  bool get isActive => _started;

  int get unreadCount => _unreadCount;

  Stream<int> get unreadCountStream => _unreadController.stream;

  /// Conversation currently on screen (no badge/notification for this cid).
  void setActiveChannelCid(String? cid) {
    final trimmed = cid?.trim();
    _activeChannelCid =
        (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    _publishUnread();
  }

  Future<void> start(
    StreamChatClient client, {
    String? fallbackTitle,
    String? fallbackBody,
  }) async {
    final title = fallbackTitle?.trim();
    final body = fallbackBody?.trim();
    if (title != null && title.isNotEmpty) {
      _fallbackTitle = title;
    }
    if (body != null && body.isNotEmpty) {
      _fallbackBody = body;
    }

    if (_started && identical(_client, client)) {
      unawaited(_watchInbox());
      return;
    }

    await stop();
    _client = client;
    _started = true;

    _eventsSub = client.on().listen(_onEvent);
    _connectionSub = client.wsConnectionStatusStream.listen((status) {
      if (status == ConnectionStatus.connected) {
        unawaited(_watchInbox());
      }
    });

    unawaited(NotificationFCMService.registerTokenWithStream(client));
    await _watchInbox();
    _publishUnread();
  }

  Future<void> stop() async {
    _started = false;
    _watching = false;
    await _eventsSub?.cancel();
    await _connectionSub?.cancel();
    _eventsSub = null;
    _connectionSub = null;
    _client = null;
    _activeChannelCid = null;
    _setUnread(0);
  }

  Future<void> _watchInbox() async {
    final client = _client;
    if (client == null || !_started || _watching) return;

    final userId = client.state.currentUser?.id.trim() ?? '';
    if (userId.isEmpty) return;

    if (client.wsConnectionStatus != ConnectionStatus.connected) {
      try {
        await client.wsConnectionStatusStream
            .firstWhere((status) => status == ConnectionStatus.connected)
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('StreamChatInboxService: wait for WS failed: $e');
      }
    }

    _watching = true;
    try {
      await client
          .queryChannels(
            filter: Filter.in_('members', [userId]),
            channelStateSort: const [SortOption.desc('last_message_at')],
            watch: true,
            presence: false,
            paginationParams: const PaginationParams(limit: 50),
          )
          .drain<void>();
    } catch (e, st) {
      debugPrint('StreamChatInboxService: queryChannels failed: $e\n$st');
    } finally {
      _watching = false;
    }
    _publishUnread();
  }

  void _onEvent(Event event) {
    final isNewMessage = event.type == EventType.messageNew ||
        event.type == EventType.notificationMessageNew;
    if (isNewMessage) {
      unawaited(_maybeNotify(event));
    }

    if (isNewMessage ||
        event.type == EventType.messageRead ||
        event.type == EventType.notificationMarkRead ||
        event.type == EventType.notificationMarkUnread ||
        event.totalUnreadCount != null) {
      _publishUnread();
    }
  }

  Future<void> _maybeNotify(Event event) async {
    final client = _client;
    final message = event.message;
    if (client == null || message == null) return;

    final shouldNotify = StreamChatInbox.shouldNotifyIncomingMessage(
      senderId: message.user?.id,
      currentUserId: client.state.currentUser?.id,
      eventCid: event.cid,
      activeChannelCid: _activeChannelCid,
      isSilent: message.silent,
    );
    if (!shouldNotify) return;

    final senderName = message.user?.name.trim() ?? '';
    final text = message.text?.trim() ?? '';
    await NotificationFCMService.showIncomingChatNotification(
      title: senderName.isNotEmpty ? senderName : _fallbackTitle,
      body: text.isNotEmpty ? text : _fallbackBody,
    );
  }

  void _publishUnread() {
    final client = _client;
    if (client == null) {
      _setUnread(0);
      return;
    }

    final channelUnreads = client.state.channels.values.map(
      (Channel channel) => channel.state?.unreadCount ?? 0,
    );
    _setUnread(
      StreamChatInbox.mergedUnreadCount(
        totalUnreadCount: client.state.totalUnreadCount,
        channelUnreads: channelUnreads,
      ),
    );
  }

  void _setUnread(int count) {
    final next = count < 0 ? 0 : count;
    if (_unreadCount == next) return;
    _unreadCount = next;
    if (!_unreadController.isClosed) {
      _unreadController.add(next);
    }
  }
}
