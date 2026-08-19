/// Parsing and policy for chat / Stream FCM payloads.
class ChatFcmNotification {
  const ChatFcmNotification({
    required this.title,
    required this.body,
    required this.payload,
    required this.isStreamChat,
  });

  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final bool isStreamChat;
}

bool looksLikeStreamChatPush(Map<String, dynamic> data) {
  final sender = data['sender']?.toString().trim().toLowerCase() ?? '';
  final type = data['type']?.toString().trim().toLowerCase() ?? '';
  return sender == 'stream.chat' ||
      type == 'message.new' ||
      type == 'notification.message_new';
}

String? firstNonEmptyText(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

/// Builds a local-notification model from an FCM `notification` + `data` pair.
ChatFcmNotification? parseChatFcmNotification({
  String? notificationTitle,
  String? notificationBody,
  required Map<String, dynamic> data,
  String fallbackTitle = 'Messagerie',
  String fallbackBody = 'Nouveau message',
}) {
  final isStream = looksLikeStreamChatPush(data);
  final title = firstNonEmptyText([
        notificationTitle,
        data['title']?.toString(),
        data['channel_name']?.toString(),
      ]) ??
      (isStream ? fallbackTitle : null);
  if (title == null) return null;

  final body = firstNonEmptyText([
        notificationBody,
        data['body']?.toString(),
        data['message']?.toString(),
      ]) ??
      (isStream ? fallbackBody : '');

  final payload = Map<String, dynamic>.from(data);
  if (isStream && (payload['type']?.toString().trim().isEmpty ?? true)) {
    payload['type'] = 'chat';
  }
  payload['id'] ??= firstNonEmptyText([
    data['cid']?.toString(),
    data['channel_id']?.toString(),
    data['id']?.toString(),
  ]);

  return ChatFcmNotification(
    title: title,
    body: body,
    payload: payload,
    isStreamChat: isStream,
  );
}

bool shouldNotifyIncomingChatMessage({
  required String? senderId,
  required String? currentUserId,
  required String? eventCid,
  required String? activeChannelCid,
  bool isSilent = false,
}) {
  if (isSilent) return false;
  final sender = senderId?.trim() ?? '';
  final me = currentUserId?.trim() ?? '';
  if (me.isEmpty || sender.isEmpty || sender == me) return false;

  final cid = eventCid?.trim() ?? '';
  final active = activeChannelCid?.trim() ?? '';
  if (cid.isNotEmpty && active.isNotEmpty && cid == active) {
    return false;
  }
  return true;
}

int notificationIdForKey(String key) {
  final trimmed = key.trim();
  if (trimmed.isEmpty) {
    return DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
  }
  return trimmed.hashCode & 0x7fffffff;
}
