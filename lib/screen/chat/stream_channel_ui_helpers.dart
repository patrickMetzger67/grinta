import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/chat_poll.dart';
import 'package:grinta/widget/chat_poll_message.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Opens the Stream channel info bottom sheet (member avatars + actions).
void openStreamChannelInfo(BuildContext context, Channel channel) {
  final colors = context.appColors;

  showChannelInfoModalBottomSheet(
    context: context,
    channel: channel,
    backgroundColor: colors.surface,
    onViewInfoTap: () {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StreamChannel(
            channel: channel,
            child: ChannelMembersPage(channel: channel),
          ),
        ),
      );
    },
  );
}

/// Full-screen member list for a channel.
class ChannelMembersPage extends StatefulWidget {
  const ChannelMembersPage({
    super.key,
    required this.channel,
  });

  final Channel channel;

  @override
  State<ChannelMembersPage> createState() => _ChannelMembersPageState();
}

class _ChannelMembersPageState extends State<ChannelMembersPage> {
  StreamMemberListController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = StreamMemberListController(channel: widget.channel);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = _controller;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(context.l10n.chatChannelMembersTitle),
      ),
      body: controller == null
          ? Center(
              child: CircularProgressIndicator(color: colors.primary),
            )
          : StreamMemberListView(
              controller: controller,
              itemBuilder: (context, members, index, defaultWidget) {
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border),
                  ),
                  child: defaultWidget,
                );
              },
            ),
    );
  }
}

/// Shows who has read a sent message (group channels and 1:1).
Future<void> showMessageReadReceiptsSheet(
  BuildContext context, {
  required Channel channel,
  required Message message,
}) async {
  final reads = channel.state?.read ?? const <Read>[];
  final readList = reads.readsOf(message: message);
  final memberCount = channel.memberCount ?? 0;
  final isGroup = memberCount > 2;
  final colors = context.appColors;
  final l10n = context.l10n;

  if (!message.state.isCompleted) return;
  if (!isGroup && readList.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final streamTheme = StreamChatTheme.of(sheetContext);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.chatMessageReadByTitle,
                style: streamTheme.textTheme.headlineBold.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (readList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.chatMessageNotReadYet,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: readList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final read = readList[index];
                      final user = read.user;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: StreamUserAvatar(
                          user: user,
                          constraints: const BoxConstraints.tightFor(
                            height: 40,
                            width: 40,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          user.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _formatReadTime(read.lastRead),
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

String _formatReadTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return time;
}

/// Poll card + read-receipts for channel / thread / FCM message rows.
StreamMessageWidget decorateStreamChatMessage({
  required StreamMessageWidget defaultWidget,
  required bool isMyMessage,
  void Function(Message message)? onReplyTap,
}) {
  var widget = defaultWidget;
  if (isGrintaPollMessage(defaultWidget.message.extraData)) {
    widget = widget.copyWith(
      textBuilder: (context, message) => ChatPollMessageCard(message: message),
    );
  }
  return decorateStreamMessageForReadReceipts(
    defaultWidget: widget,
    isMyMessage: isMyMessage,
    onReplyTap: onReplyTap,
  );
}

/// Wraps a [StreamMessageWidget] with read-receipt tap handling for sent messages.
StreamMessageWidget decorateStreamMessageForReadReceipts({
  required StreamMessageWidget defaultWidget,
  required bool isMyMessage,
  void Function(Message message)? onReplyTap,
}) {
  var widget = defaultWidget;
  if (onReplyTap != null) {
    widget = widget.copyWith(onReplyTap: onReplyTap);
  }

  if (!isMyMessage) return widget;

  return widget.copyWith(
    bottomRowBuilderWithDefaultWidget: (context, message, defaultBottomRow) {
      if (!message.state.isCompleted) return defaultBottomRow;

      return defaultBottomRow.copyWith(
        sendingIndicatorBuilder: (ctx, msg) {
          return GestureDetector(
            onTap: () => showMessageReadReceiptsSheet(
              ctx,
              channel: StreamChannel.of(ctx).channel,
              message: msg,
            ),
            behavior: HitTestBehavior.opaque,
            child: _MessageSendingIndicator(message: msg),
          );
        },
      );
    },
  );
}

class _MessageSendingIndicator extends StatelessWidget {
  const _MessageSendingIndicator({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final channel = StreamChannel.of(context).channel;
    final streamChatTheme = StreamChatTheme.of(context);
    final messageTheme = streamChatTheme.ownMessageTheme;
    final style = messageTheme.createdAtStyle;
    final memberCount = channel.memberCount ?? 0;

    return BetterStreamBuilder<List<Read>>(
      stream: channel.state?.readStream,
      initialData: channel.state?.read,
      builder: (context, data) {
        final readList = data.readsOf(message: message);
        final isMessageRead = readList.isNotEmpty;
        final deliveriesList = data.deliveriesOf(message: message);
        final isMessageDelivered = deliveriesList.isNotEmpty;

        Widget child = StreamSendingIndicator(
          message: message,
          isMessageRead: isMessageRead,
          isMessageDelivered: isMessageDelivered,
          size: style?.fontSize,
        );

        if (isMessageRead && memberCount > 2) {
          child = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                readList.length.toString(),
                style: style?.copyWith(
                  color: streamChatTheme.colorTheme.accentPrimary,
                ),
              ),
              const SizedBox(width: 2),
              child,
            ],
          );
        }

        return child;
      },
    );
  }
}
