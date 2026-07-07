// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../model/feature_discovery_ids.dart';
import 'chat/stream_channel_ui_helpers.dart';
import '../util/app_theme.dart';
import '../widget/feature_discovery_random_banner.dart';
import '../widget/alternating_monetization_banner.dart';
import '../widget/ask_diego/ask_diego_speed_dial.dart';
import '../widget/grinta_stream_message_input.dart';


class ResponsiveChat extends StatelessWidget {
  const ResponsiveChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AlternatingMonetizationBanner(),
        const FeatureDiscoveryRandomBanner(
          parentScreenId: FeatureDiscoveryIds.tabChat,
          excludeCurrentBaseScreen: true,
        ),
        Expanded(
          child: ResponsiveBuilder(
            builder: (context, sizingInformation) {
              if (sizingInformation.isDesktop || sizingInformation.isTablet) {
                return const _SplitChatView();
              }

              return _ChannelListPage(
                onTap: (channel) {
                  Navigator.push(
                    context,
                    analyticsMaterialRoute<void>(
                      screenName: AnalyticsScreenNames.chatChannel,
                      builder: (context) => StreamChannel(
                        channel: channel,
                        child: const _ChatChannelPage(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SplitChatView extends StatefulWidget {
  const _SplitChatView();

  @override
  State<_SplitChatView> createState() => _SplitChatViewState();
}

class _SplitChatViewState extends State<_SplitChatView> {
  Channel? selectedChannel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Flexible(
          child: _ChannelListPage(
            selectedChannel: selectedChannel,
            onTap: (channel) {
              setState(() {
                selectedChannel = channel;
              });
            },
          ),
        ),
        Flexible(
          flex: 2,
          child: Scaffold(
            backgroundColor: colors.background,
            body: selectedChannel != null
                ? StreamChannel(
              key: ValueKey(selectedChannel!.cid),
              channel: selectedChannel!,
              child: const _ChatChannelPage(showBackButton: false),
            )
                : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.chatSelectConversation,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChannelListPage extends StatefulWidget {
  const _ChannelListPage({
    this.onTap,
    this.selectedChannel,
  });

  final void Function(Channel)? onTap;
  final Channel? selectedChannel;

  @override
  State<_ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<_ChannelListPage> {
  StreamChannelListController? _listController;
  String? _currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentUserId = StreamChat.of(context).currentUser?.id;
    if (currentUserId == null) return;

    if (_listController == null || _currentUserId != currentUserId) {
      _currentUserId = currentUserId;

      _listController?.dispose();
      _listController = StreamChannelListController(
        client: StreamChat.of(context).client,
        filter: Filter.in_('members', [currentUserId]),
        channelStateSort: const [SortOption.desc('last_message_at')],
        limit: 20,
      );
    }
  }

  Future<void> _openUserPicker() async {
    final user = await Navigator.push<User>(
      context,
      analyticsMaterialRoute<User>(
        screenName: AnalyticsScreenNames.chatUserPicker,
        builder: (context) => const _UserPickerPage(),
      ),
    );

    if (user == null) return;

    await _createConversationWithUser(user);
  }

  Future<void> _createConversationWithUser(User otherUser) async {
    final client = StreamChat.of(context).client;
    final currentUserId = client.state.currentUser?.id;
    final colors = context.appColors;

    if (currentUserId == null) return;
    if (otherUser.id == currentUserId) return;

    try {
      final channel = client.channel(
        'messaging',
        extraData: {
          'members': [currentUserId, otherUser.id],
        },
      );

      await channel.watch();

      if (!mounted) return;

      await _listController?.refresh();

      if (!mounted) return;

      widget.onTap?.call(channel);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.danger,
          content: Text(
            context.l10n.errorChatCreate(e.toString()),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _listController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (_listController == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: colors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: AskDiegoSpeedDial(
        heroTagPrefix: 'chat',
        primaryAction: AskDiegoPrimaryAction(
          heroTag: 'grinta-fab-chat',
          icon: Icons.add_comment_rounded,
          tooltip: context.l10n.actionNew,
          onPressed: _openUserPicker,
        ),
      ),
      body: RefreshIndicator(
        color: colors.primary,
        backgroundColor: colors.surface,
        onRefresh: _listController!.refresh,
        child: StreamChannelListView(
          controller: _listController!,
          onChannelTap: widget.onTap,
          itemBuilder: (context, channels, index, defaultWidget) {
            final channel = channels[index];
            final isSelected = widget.selectedChannel?.cid == channel.cid;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.08)
                    : colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? colors.primary : colors.border,
                ),
              ),
              child: defaultWidget.copyWith(
                selected: isSelected,
              ),
            );
          },
          emptyBuilder: (context) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 42,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.emptyNoConversation,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.chatStartNewHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserPickerPage extends StatefulWidget {
  const _UserPickerPage();

  @override
  State<_UserPickerPage> createState() => _UserPickerPageState();
}

class _UserPickerPageState extends State<_UserPickerPage> {
  StreamUserListController? _userListController;
  String? _currentUserId;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentUserId = StreamChat.of(context).currentUser?.id;
    if (currentUserId == null) return;

    if (_userListController == null || _currentUserId != currentUserId) {
      _currentUserId = currentUserId;

      _userListController?.dispose();
      _userListController = StreamUserListController(
        client: StreamChat.of(context).client,
        limit: 25,
        filter: Filter.and([
          Filter.notEqual('id', currentUserId),
        ]),
        sort: const [
          SortOption(
            'name',
            direction: 1,
          ),
        ],
      );
    }
  }

  void _applySearch(String value) {
    if (_userListController == null || _currentUserId == null) return;

    final query = value.trim();

    _userListController!.filter = Filter.and([
      Filter.notEqual('id', _currentUserId!),
      if (query.isNotEmpty) Filter.autoComplete('name', query),
    ]);

    _userListController!.doInitialLoad();
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userListController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (_userListController == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(context.l10n.dialogNewConversation),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: colors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(context.l10n.dialogNewConversation),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _applySearch,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: context.l10n.hintSearchUser,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colors.textSecondary,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _applySearch('');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: colors.primary,
              backgroundColor: colors.surface,
              onRefresh: _userListController!.refresh,
              child: StreamUserListView(
                controller: _userListController!,
                onUserTap: (user) {
                  Navigator.of(context).pop(user);
                },
                itemBuilder: (context, users, index, defaultWidget) {
                  final user = users[index];

                  return Container(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: defaultWidget.copyWith(
                      onTap: () {
                        Navigator.of(context).pop(user);
                      },
                    ),
                  );
                },
                emptyBuilder: (context) {
                  final hasSearch = _searchController.text.trim().isNotEmpty;

                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasSearch
                                ? Icons.search_off_rounded
                                : Icons.people_outline_rounded,
                            size: 42,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hasSearch
                                ? context.l10n.emptyNoUserFound
                                : context.l10n.emptyNoUserAvailable,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasSearch
                                ? context.l10n.chatTryAnotherName
                                : context.l10n.chatUsersAppearHere,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatChannelPage extends StatefulWidget {
  const _ChatChannelPage({
    this.showBackButton = true,
    this.onBackPressed,
  });

  final bool showBackButton;
  final void Function(BuildContext)? onBackPressed;

  @override
  State<_ChatChannelPage> createState() => _ChatChannelPageState();
}

class _ChatChannelPageState extends State<_ChatChannelPage> {
  late final StreamMessageInputController _messageInputController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _messageInputController = StreamMessageInputController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageInputController.dispose();
    super.dispose();
  }

  void _reply(Message message) {
    _messageInputController.quotedMessage = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: StreamChannelHeader(
        showBackButton: widget.showBackButton,
        onBackPressed: widget.onBackPressed != null
            ? () => widget.onBackPressed!(context)
            : null,
        onTitleTap: () => openStreamChannelInfo(
          context,
          StreamChannel.of(context).channel,
        ),
        onImageTap: () => openStreamChannelInfo(
          context,
          StreamChannel.of(context).channel,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamMessageListView(
              threadBuilder: (_, parent) => _ThreadPage(parent: parent!),
              messageBuilder: (
                  context,
                  details,
                  messages,
                  defaultWidget,
                  ) {
                const threshold = 0.20;
                final isMyMessage = details.isMyMessage;

                final swipeDirection = isMyMessage
                    ? SwipeDirection.endToStart
                    : SwipeDirection.startToEnd;

                return Swipeable(
                  key: ValueKey(details.message.id),
                  direction: swipeDirection,
                  swipeThreshold: threshold,
                  onSwiped: (_) => _reply(details.message),
                  backgroundBuilder: (context, swipeDetails) {
                    final alignment = isMyMessage
                        ? Alignment.centerRight
                        : Alignment.centerLeft;

                    final progress =
                        math.min(swipeDetails.progress, threshold) / threshold;

                    var offset = Offset.lerp(
                      const Offset(-24, 0),
                      const Offset(12, 0),
                      progress,
                    )!;

                    if (isMyMessage) {
                      offset = Offset(-offset.dx, -offset.dy);
                    }

                    final streamTheme = StreamChatTheme.of(context);

                    return Align(
                      alignment: alignment,
                      child: Transform.translate(
                        offset: offset,
                        child: Opacity(
                          opacity: progress,
                          child: SizedBox.square(
                            dimension: 30,
                            child: CustomPaint(
                              painter: _AnimatedCircleBorderPainter(
                                progress: progress,
                                color: streamTheme.colorTheme.borders,
                              ),
                              child: Center(
                                child: StreamSvgIcon(
                                  icon: StreamSvgIcons.reply,
                                  size: lerpDouble(0, 18, progress),
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: decorateStreamMessageForReadReceipts(
                    defaultWidget: defaultWidget,
                    isMyMessage: isMyMessage,
                    onReplyTap: _reply,
                  ),
                );
              },
            ),
          ),
          GrintaStreamMessageInput(
            focusNode: _focusNode,
            messageInputController: _messageInputController,
            enableVoiceRecording: true,
            onQuotedMessageCleared:
            _messageInputController.clearQuotedMessage,
          ),
        ],
      ),
    );
  }
}

class _ThreadPage extends StatelessWidget {
  const _ThreadPage({
    required this.parent,
  });

  final Message parent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: StreamThreadHeader(parent: parent),
      body: Column(
        children: [
          Expanded(
            child: StreamMessageListView(
              parentMessage: parent,
              messageBuilder: (
                context,
                details,
                messages,
                defaultWidget,
              ) {
                return decorateStreamMessageForReadReceipts(
                  defaultWidget: defaultWidget,
                  isMyMessage: details.isMyMessage,
                );
              },
            ),
          ),
          GrintaStreamMessageInput(
            enableVoiceRecording: true,
            messageInputController: StreamMessageInputController(
              message: Message(parentId: parent.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCircleBorderPainter extends CustomPainter {
  const _AnimatedCircleBorderPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final radius = (size.width / 2) * progress;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AnimatedCircleBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}