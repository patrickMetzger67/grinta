import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/chat_message.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/ask_diego/ask_diego_avatar.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onSpeak,
    this.onNavigate,
    this.isSpeaking = false,
  });

  final ChatMessage message;
  final VoidCallback? onSpeak;
  final VoidCallback? onNavigate;
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isUser = message.role == ChatMessageRole.user;

    final alignment =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser
        ? colors.primary.withValues(alpha: 0.12)
        : colors.card;
    final textColor = colors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const AskDiegoAvatar(size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: message.isLoading
                      ? SizedBox(
                          width: 48,
                          height: 20,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          message.text,
                          style: TextStyle(
                            color: textColor,
                            height: 1.35,
                          ),
                        ),
                ),
                if (!isUser && !message.isLoading) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onSpeak != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: context.l10n.askDiegoListen,
                          onPressed: onSpeak,
                          icon: Icon(
                            isSpeaking
                                ? Icons.stop_circle_outlined
                                : Icons.volume_up_outlined,
                            size: 20,
                            color: colors.primary,
                          ),
                        ),
                      if (message.navigationRoute != null &&
                          onNavigate != null)
                        TextButton.icon(
                          onPressed: onNavigate,
                          icon: Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: colors.primary,
                          ),
                          label: Text(
                            message.navigationLabel ??
                                context.l10n.askDiegoOpenScreen,
                            style: TextStyle(color: colors.primary),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
