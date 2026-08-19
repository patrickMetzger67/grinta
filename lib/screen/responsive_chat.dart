// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'dart:ui';

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../model/feature_discovery_ids.dart';
import 'chat/chat_user_picker_page.dart';
import 'chat/stream_channel_ui_helpers.dart';
import '../util/app_theme.dart';
import '../util/chat_group_channel.dart';
import '../widget/chat_group_editor_sheet.dart';
import '../widget/chat_group_subscription_dialog.dart';
import '../widget/feature_discovery_random_banner.dart';
import '../widget/alternating_monetization_banner.dart';
import '../widget/ask_diego/ask_diego_speed_dial.dart';
import '../widget/direct_chat_channel_title.dart';
import '../widget/grinta_stream_message_input.dart';
import '../services/chat_group_service.dart';
import '../services/stream_chat_push_service.dart';


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
              child: _ChatChannelPage(
                showBackButton: false,
                onChannelRemoved: () {
                  setState(() => selectedChannel = null);
                },
              ),
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
  void initState() {
    super.initState();
    ChatGroupService.instance.addListener(_onGroupsChanged);
    unawaited(UserTrialService.instance.ensureInitialized());
  }

  void _onGroupsChanged() {
    unawaited(_listController?.refresh());
  }

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
    final user = await showChatUserPicker(context);
    if (user == null) return;
    await _createConversationWithUser(user);
  }

  Future<void> _openCreateGroup() async {
    await UserTrialService.instance.ensureInitialized();
    if (!mounted) return;
    if (!UserTrialService.instance.hasPremiumAccess) {
      await showChatGroupSubscriptionRequiredDialog(context);
      return;
    }

    final result = await showChatGroupEditorSheet(context);
    if (!mounted || result == null || result.deleted) return;
    await _listController?.refresh();
    if (!mounted) return;
    widget.onTap?.call(result.channel);
  }

  Widget? _groupLeading(Channel channel) {
    if (!isGrintaUserGroupChannel(channel)) return null;
    final image = channel.image?.trim() ?? '';
    if (image.isNotEmpty) return null;
    final color = parseChatGroupColor(chatGroupAvatarColorHex(channel));
    if (color == null) return null;
    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        chatGroupInitials(channel.name ?? ''),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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
    ChatGroupService.instance.removeListener(_onGroupsChanged);
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
      floatingActionButton: ListenableBuilder(
        listenable: UserTrialService.instance,
        builder: (context, _) {
          final showPremiumBadge =
              !UserTrialService.instance.hasPremiumAccess;
          return AskDiegoSpeedDial(
            heroTagPrefix: 'chat',
            primaryAction: AskDiegoPrimaryAction(
              heroTag: 'grinta-fab-chat',
              icon: Icons.add_comment_rounded,
              tooltip: context.l10n.actionNew,
              onPressed: _openUserPicker,
            ),
            secondaryActions: [
              AskDiegoPrimaryAction(
                heroTag: 'grinta-fab-chat-group',
                icon: Icons.group_add_rounded,
                tooltip: context.l10n.chatCreateGroup,
                showPremiumBadge: showPremiumBadge,
                onPressed: _openCreateGroup,
              ),
            ],
          );
        },
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
                leading: _groupLeading(channel),
                title: isDirectChatChannel(channel)
                    ? DirectChatChannelTitle(channel: channel)
                    : null,
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


class _ChatChannelPage extends StatefulWidget {
  const _ChatChannelPage({
    this.showBackButton = true,
    this.onBackPressed,
    this.onChannelRemoved,
  });

  final bool showBackButton;
  final void Function(BuildContext)? onBackPressed;
  final VoidCallback? onChannelRemoved;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cid = StreamChannel.of(context).channel.cid;
    StreamChatPushService.instance.setActiveChannelCid(cid);
  }

  @override
  void dispose() {
    StreamChatPushService.instance.setActiveChannelCid(null);
    _focusNode.dispose();
    _messageInputController.dispose();
    super.dispose();
  }

  Future<void> _editGroup(Channel channel) async {
    final result = await showChatGroupEditorSheet(
      context,
      channel: channel,
    );
    if (!mounted || result == null) return;
    if (result.deleted) {
      if (widget.showBackButton && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      widget.onChannelRemoved?.call();
    }
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
    final channel = StreamChannel.of(context).channel;
    final canEditGroup = canManageGrintaUserGroup(
      channel: channel,
      currentUserId: StreamChat.of(context).currentUser?.id,
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: StreamChannelHeader(
        showBackButton: widget.showBackButton,
        onBackPressed: widget.onBackPressed != null
            ? () => widget.onBackPressed!(context)
            : null,
        title: isDirectChatChannel(channel)
            ? DirectChatChannelHeaderTitle(channel: channel)
            : null,
        onTitleTap: () => openStreamChannelInfo(context, channel),
        onImageTap: () => openStreamChannelInfo(context, channel),
        actions: canEditGroup
            ? [
                IconButton(
                  tooltip: context.l10n.chatGroupEditTitle,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => unawaited(_editGroup(channel)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Center(
                    child: StreamChannelAvatar(
                      channel: channel,
                      onTap: () => openStreamChannelInfo(context, channel),
                    ),
                  ),
                ),
              ]
            : null,
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
                  child: decorateStreamChatMessage(
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
                return decorateStreamChatMessage(
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