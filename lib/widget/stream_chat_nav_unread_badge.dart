import 'package:flutter/material.dart';
import 'package:grinta/widget/nav_icon_count_badge.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Rebuilds when Stream Chat total unread message count changes.
class StreamChatUnreadCountBuilder extends StatelessWidget {
  const StreamChatUnreadCountBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, int unreadCount) builder;

  @override
  Widget build(BuildContext context) {
    final streamChat = StreamChat.maybeOf(context);
    final client = streamChat?.client;

    if (client == null || client.state.currentUser == null) {
      return builder(context, 0);
    }

    return StreamBuilder<int>(
      stream: client.state.totalUnreadCountStream,
      initialData: client.state.totalUnreadCount,
      builder: (context, snapshot) {
        return builder(context, snapshot.data ?? 0);
      },
    );
  }
}

/// Navigation icon with optional unread message count badge.
class StreamChatNavIconBadge extends StatelessWidget {
  const StreamChatNavIconBadge({
    super.key,
    required this.icon,
    required this.iconColor,
    this.iconSize = 24,
  });

  final IconData icon;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return StreamChatUnreadCountBuilder(
      builder: (context, unreadCount) {
        return NavIconCountBadge(
          icon: icon,
          count: unreadCount,
          iconColor: iconColor,
          iconSize: iconSize,
        );
      },
    );
  }
}
