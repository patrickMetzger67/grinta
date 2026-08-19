import 'package:flutter/material.dart';
import 'package:grinta/services/stream_chat_inbox_service.dart';
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
    final inbox = StreamChatInboxService.instance;
    if (inbox.isActive) {
      return StreamBuilder<int>(
        stream: inbox.unreadCountStream,
        initialData: inbox.unreadCount,
        builder: (context, snapshot) {
          return builder(context, snapshot.data ?? inbox.unreadCount);
        },
      );
    }

    final client = StreamChat.maybeOf(context)?.client;
    if (client == null) {
      return builder(context, 0);
    }

    return StreamBuilder<OwnUser?>(
      stream: client.state.currentUserStream,
      initialData: client.state.currentUser,
      builder: (context, userSnapshot) {
        if (userSnapshot.data == null) {
          return builder(context, 0);
        }

        return StreamBuilder<int>(
          stream: client.state.totalUnreadCountStream,
          initialData: client.state.totalUnreadCount,
          builder: (context, snapshot) {
            return builder(context, snapshot.data ?? 0);
          },
        );
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
