import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/chat_poll_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/chat_poll.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// In-thread poll card: vote + optional results under the options.
class ChatPollMessageCard extends StatelessWidget {
  const ChatPollMessageCard({
    super.key,
    required this.message,
  });

  final Message message;

  @override
  Widget build(BuildContext context) {
    final poll = parseChatPollData(
      extraData: message.extraData,
      fallbackQuestion: message.text,
    );
    if (poll == null) {
      return Text(message.text ?? '');
    }

    return _ChatPollBody(poll: poll);
  }
}

class _ChatPollBody extends StatefulWidget {
  const _ChatPollBody({required this.poll});

  final ChatPollData poll;

  @override
  State<_ChatPollBody> createState() => _ChatPollBodyState();
}

class _ChatPollBodyState extends State<_ChatPollBody> {
  late ChatPollVoteTally _tally;
  bool _voting = false;

  ChatPollData get _poll => widget.poll;

  @override
  void initState() {
    super.initState();
    _tally = tallyChatPollVotes(
      userVotes: const {},
      optionIds: _poll.optionIds,
    );
  }

  String? get _currentUserId => StreamChat.of(context).currentUser?.id;

  Future<void> _toggle(String optionId) async {
    final uid = _currentUserId;
    if (uid == null || _voting) return;

    final next = normalizePollVote(
      selectedOptionIds: _tally.selectedBy(uid),
      validOptionIds: _poll.optionIds,
      allowMultiple: _poll.allowMultiple,
      toggledOptionId: optionId,
    );

    setState(() {
      _voting = true;
      final optimistic = Map<String, List<String>>.from(_tally.userVotes);
      if (next.isEmpty) {
        optimistic.remove(uid);
      } else {
        optimistic[uid] = next;
      }
      _tally = tallyChatPollVotes(
        userVotes: optimistic,
        optionIds: _poll.optionIds,
      );
    });

    try {
      await ChatPollService.instance.castVote(
        pollId: _poll.id,
        userId: uid,
        optionIds: next,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.chatPollVoteError('$e'));
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final uid = _currentUserId;
    final showResults = canSeeChatPollResults(
      resultsVisible: _poll.resultsVisible,
      createdBy: _poll.createdBy,
      currentUserId: uid,
    );

    return StreamBuilder<ChatPollVoteTally>(
      stream: ChatPollService.instance.watchVotes(
        pollId: _poll.id,
        optionIds: _poll.optionIds,
      ),
      initialData: _tally,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _tally = snapshot.data!;
        }
        final liveSelected = _tally.selectedBy(uid);

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _poll.question,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _poll.allowMultiple
                    ? l10n.chatPollMultipleHint
                    : l10n.chatPollSingleHint,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              for (final option in _poll.options)
                _PollOptionTile(
                  option: option,
                  selected: liveSelected.contains(option.id),
                  showResults: showResults,
                  tally: _tally,
                  onTap: _voting ? null : () => _toggle(option.id),
                ),
              if (showResults) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.chatPollVotesCount(_tally.voterCount),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PollOptionTile extends StatelessWidget {
  const _PollOptionTile({
    required this.option,
    required this.selected,
    required this.showResults,
    required this.tally,
    required this.onTap,
  });

  final ChatPollOption option;
  final bool selected;
  final bool showResults;
  final ChatPollVoteTally tally;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ratio = showResults ? tally.ratioFor(option.id) : 0.0;
    final count = tally.countFor(option.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? colors.primary : colors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (showResults)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 20,
                        color: selected ? colors.primary : colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      if (option.hasImage) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: option.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          option.hasText
                              ? option.text
                              : context.l10n.chatPollOptionImage,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (showResults)
                        Text(
                          '$count',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
