import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onMicPressed,
    required this.isListening,
    required this.isSending,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final bool isListening;
  final bool isSending;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: enabled && !isSending ? onMicPressed : null,
              tooltip: isListening ? l10n.askDiegoStopListening : l10n.askDiegoStartListening,
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none_outlined,
                color: isListening ? colors.warning : colors.primary,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !isSending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled && !isSending ? (_) => onSend() : null,
                decoration: InputDecoration(
                  hintText: l10n.askDiegoInputHint,
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: enabled && !isSending ? onSend : null,
              tooltip: l10n.askDiegoSend,
              icon: isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  : Icon(Icons.send_rounded, color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
