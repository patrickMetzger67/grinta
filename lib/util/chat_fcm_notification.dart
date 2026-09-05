/// Parsing and policy for FCM payloads (chat, convocations, RPE, invitations…).
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

  bool get isChat =>
      isStreamChat || isChatNotificationType(payload['type']?.toString());
}

bool looksLikeStreamChatPush(Map<String, dynamic> data) {
  final sender = data['sender']?.toString().trim().toLowerCase() ?? '';
  final type = data['type']?.toString().trim().toLowerCase() ?? '';
  return sender == 'stream.chat' ||
      type == 'message.new' ||
      type == 'notification.message_new';
}

bool isChatNotificationType(String? type) {
  switch ((type ?? '').trim().toLowerCase()) {
    case 'chat':
    case 'chatgroup':
    case 'message.new':
    case 'notification.message_new':
      return true;
    default:
      return false;
  }
}

bool isChatFcmData(Map<String, dynamic> data) {
  return looksLikeStreamChatPush(data) ||
      isChatNotificationType(data['type']?.toString());
}

String? firstNonEmptyText(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

/// Builds a local-notification model from an FCM `notification` + `data` pair.
///
/// Works for every Grinta push type (convocation, RPE, team invite, chat…).
ChatFcmNotification? parseFcmNotification({
  String? notificationTitle,
  String? notificationBody,
  required Map<String, dynamic> data,
  String chatFallbackTitle = 'Messagerie',
  String chatFallbackBody = 'Nouveau message',
  String genericFallbackTitle = 'Grinta',
}) {
  final isStream = looksLikeStreamChatPush(data);
  final type = data['type']?.toString().trim() ?? '';
  final isChat = isStream || isChatNotificationType(type);

  var title = firstNonEmptyText([
    notificationTitle,
    data['title']?.toString(),
    data['channel_name']?.toString(),
  ]);
  var body = firstNonEmptyText([
        notificationBody,
        data['body']?.toString(),
        data['message']?.toString(),
      ]) ??
      '';

  if (title == null) {
    if (isChat) {
      title = chatFallbackTitle;
      if (body.isEmpty) body = chatFallbackBody;
    } else if (body.isNotEmpty || type.isNotEmpty) {
      title = genericFallbackTitle;
    } else {
      return null;
    }
  } else if (isChat && body.isEmpty) {
    body = chatFallbackBody;
  }

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

/// Alias kept for existing call sites / tests.
ChatFcmNotification? parseChatFcmNotification({
  String? notificationTitle,
  String? notificationBody,
  required Map<String, dynamic> data,
  String fallbackTitle = 'Messagerie',
  String fallbackBody = 'Nouveau message',
}) {
  return parseFcmNotification(
    notificationTitle: notificationTitle,
    notificationBody: notificationBody,
    data: data,
    chatFallbackTitle: fallbackTitle,
    chatFallbackBody: fallbackBody,
  );
}

/// Whether a remote FCM should raise a local banner.
///
/// Non-chat types always display. Chat is suppressed only when that
/// conversation is already on screen.
bool shouldDisplayRemoteFcm({
  required Map<String, dynamic> data,
  String? activeChatChannelCid,
}) {
  final brand = data['brand']?.toString().trim().toLowerCase() ?? '';
  if (brand == 'aserstein') return false;
  if (!isChatFcmData(data)) return true;
  final cid = firstNonEmptyText([
    data['cid']?.toString(),
    data['id']?.toString(),
    data['channel_id']?.toString(),
  ]);
  final active = activeChatChannelCid?.trim() ?? '';
  if (cid != null && active.isNotEmpty && cid == active) {
    return false;
  }
  return true;
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
