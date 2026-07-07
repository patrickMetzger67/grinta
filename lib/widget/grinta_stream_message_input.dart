import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/stream_chat_theme.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Stream message input with a Grinta-themed emoji picker button.
///
/// Stream Chat removed the built-in emoji picker from [StreamMessageInput] in
/// v5; this widget adds one via [StreamMessageInput.actionsBuilder] while
/// preserving the default attachment, command (GIPHY), and voice actions.
class GrintaStreamMessageInput extends StatefulWidget {
  const GrintaStreamMessageInput({
    super.key,
    this.messageInputController,
    this.focusNode,
    this.enableVoiceRecording = true,
    this.onQuotedMessageCleared,
  });

  final StreamMessageInputController? messageInputController;
  final FocusNode? focusNode;
  final bool enableVoiceRecording;
  final VoidCallback? onQuotedMessageCleared;

  @override
  State<GrintaStreamMessageInput> createState() =>
      _GrintaStreamMessageInputState();
}

class _GrintaStreamMessageInputState extends State<GrintaStreamMessageInput> {
  StreamMessageInputController? _ownedController;
  bool _showEmojiPicker = false;

  StreamMessageInputController get _controller =>
      widget.messageInputController ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.messageInputController == null) {
      _ownedController = StreamMessageInputController();
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });

    if (_showEmojiPicker) {
      widget.focusNode?.unfocus();
    } else {
      widget.focusNode?.requestFocus();
    }
  }

  Widget _buildEmojiButton(StreamMessageInputThemeData messageInputTheme) {
    return IconButton(
      icon: Icon(
        _showEmojiPicker
            ? Icons.keyboard_rounded
            : Icons.emoji_emotions_outlined,
      ),
      color: _showEmojiPicker
          ? messageInputTheme.expandButtonColor
          : messageInputTheme.actionButtonIdleColor,
      onPressed: _toggleEmojiPicker,
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: WidgetStatePropertyAll(Size.square(32)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final messageInputTheme = StreamMessageInputTheme.of(context);
    final locale = Localizations.localeOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamMessageInput(
          focusNode: widget.focusNode,
          messageInputController: _controller,
          enableVoiceRecording: widget.enableVoiceRecording,
          enableActionAnimation: false,
          showCommandsButton: true,
          disableAttachments: false,
          onQuotedMessageCleared: widget.onQuotedMessageCleared,
          actionsBuilder: (context, defaultActions) => [
            ...defaultActions,
            _buildEmojiButton(messageInputTheme),
          ],
        ),
        if (_showEmojiPicker)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(color: colors.border),
              ),
            ),
            child: EmojiPicker(
              textEditingController: _controller.textFieldController,
              onBackspacePressed: () {
                final controller = _controller.textFieldController;
                final text = controller.text;
                final selection = controller.selection;

                if (selection.start < 0) return;

                final start = selection.start;
                final end = selection.end;
                if (start == end && start > 0) {
                  final before = text.substring(0, start);
                  final after = text.substring(end);
                  final newText = before.isNotEmpty
                      ? before.substring(0, before.length - 1) + after
                      : after;
                  controller.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(
                      offset: (start - 1).clamp(0, newText.length),
                    ),
                  );
                } else if (start != end) {
                  final newText = text.replaceRange(start, end, '');
                  controller.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: start),
                  );
                }
              },
              config: GrintaStreamChatTheme.emojiPickerConfig(
                colors: colors,
                locale: locale,
              ),
            ),
          ),
      ],
    );
  }
}
