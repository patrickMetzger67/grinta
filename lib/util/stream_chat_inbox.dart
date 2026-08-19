/// Pure helpers for Stream Chat unread badges and incoming-message alerts.
abstract final class StreamChatInbox {
  StreamChatInbox._();

  /// Prefer the higher of Stream's user-level total and the sum of watched
  /// channel unreads (user total can stay stale when channels are watched).
  static int mergedUnreadCount({
    required int totalUnreadCount,
    required Iterable<int> channelUnreads,
  }) {
    var sum = 0;
    for (final count in channelUnreads) {
      if (count > 0) sum += count;
    }
    final total = totalUnreadCount < 0 ? 0 : totalUnreadCount;
    return total > sum ? total : sum;
  }

  /// Whether a newly arrived message should show a device/browser notification.
  static bool shouldNotifyIncomingMessage({
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
}
