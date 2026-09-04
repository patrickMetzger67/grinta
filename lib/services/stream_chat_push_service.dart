import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../services/notification_fcm_service.dart';
import '../util/chat_fcm_notification.dart';
import '../util/fcm_token.dart';

/// Registers the FCM token with Stream and delivers Android/iOS chat alerts.
///
/// Incoming messages: local notification when the conversation is not open.
/// Outgoing messages: Grinta FCM to the other members (works even if the
/// Stream dashboard has no Firebase push config).
class StreamChatPushService {
  StreamChatPushService._();

  static final StreamChatPushService instance = StreamChatPushService._();

  StreamChatClient? _client;
  StreamSubscription<Event>? _eventsSub;
  bool _started = false;
  String? _activeChannelCid;
  String _fallbackTitle = 'Messagerie';
  String _fallbackBody = 'Nouveau message';

  String? get activeChannelCid => _activeChannelCid;

  void setActiveChannelCid(String? cid) {
    final trimmed = cid?.trim();
    _activeChannelCid =
        (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    NotificationFCMService.activeChatChannelCid = _activeChannelCid;
  }

  Future<void> start(
    StreamChatClient client, {
    String? fallbackTitle,
    String? fallbackBody,
  }) async {
    final title = fallbackTitle?.trim();
    final body = fallbackBody?.trim();
    if (title != null && title.isNotEmpty) _fallbackTitle = title;
    if (body != null && body.isNotEmpty) _fallbackBody = body;

    if (_started && identical(_client, client)) {
      unawaited(NotificationFCMService.registerTokenWithStream(client));
      return;
    }

    await stop();
    _client = client;
    _started = true;
    NotificationFCMService.bindStreamClient(client);

    _eventsSub = client.on().listen(_onEvent);
    unawaited(NotificationFCMService.registerTokenWithStream(client));
  }

  Future<void> stop() async {
    _started = false;
    await _eventsSub?.cancel();
    _eventsSub = null;
    _client = null;
    _activeChannelCid = null;
    NotificationFCMService.activeChatChannelCid = null;
    NotificationFCMService.bindStreamClient(null);
  }

  void _onEvent(Event event) {
    final isNewMessage = event.type == EventType.messageNew ||
        event.type == EventType.notificationMessageNew;
    if (!isNewMessage) return;
    unawaited(_handleNewMessage(event));
  }

  Future<void> _handleNewMessage(Event event) async {
    final client = _client;
    final message = event.message;
    if (client == null || message == null) return;

    final currentUserId = client.state.currentUser?.id;
    final senderId = message.user?.id;
    if (currentUserId == null || senderId == null) return;

    if (senderId == currentUserId) {
      await _notifyPeers(event: event, message: message);
      return;
    }

    if (kIsWeb) return;

    final shouldNotify = shouldNotifyIncomingChatMessage(
      senderId: senderId,
      currentUserId: currentUserId,
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
      payload: {
        'type': 'chat',
        'id': event.cid ?? '',
        'cid': event.cid ?? '',
      },
      notificationKey: event.cid ?? message.id,
    );
  }

  Future<void> _notifyPeers({
    required Event event,
    required Message message,
  }) async {
    final client = _client;
    final currentUserId = client?.state.currentUser?.id;
    if (client == null || currentUserId == null) return;

    final channel = _channelForEvent(client, event);
    final memberIds = <String>{
      ...?channel?.state?.members
          .map((member) => member.userId)
          .whereType<String>(),
    };
    memberIds.remove(currentUserId);
    if (!shouldCallChatPushCloudFunction(peerUserIds: memberIds)) return;

    final tokens = await NotificationFCMService.fetchFcmTokensForUsers(
      memberIds,
    );

    final senderName = message.user?.name.trim() ?? '';
    final text = message.text?.trim() ?? '';
    await NotificationFCMService.instance.postNotification(
      tokens: tokens,
      title: senderName.isNotEmpty ? senderName : _fallbackTitle,
      body: text.isNotEmpty ? text : _fallbackBody,
      type: 'chat',
      payload: {
        'id': channel?.id ?? event.cid ?? '',
        'type': 'chat',
        'cid': event.cid ?? channel?.cid ?? '',
      },
      recipientUserIds: memberIds.toList(),
    );
  }

  Channel? _channelForEvent(StreamChatClient client, Event event) {
    final cid = event.cid?.trim() ?? '';
    if (cid.isEmpty) return null;
    final existing = client.state.channels[cid];
    if (existing != null) return existing;
    if (!cid.contains(':')) return client.channel('messaging', id: cid);
    final parts = cid.split(':');
    return client.channel(parts.first, id: parts.sublist(1).join(':'));
  }
}
