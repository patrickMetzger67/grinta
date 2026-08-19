import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/chat_poll_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/chat_poll.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Opens the WhatsApp-style poll composer.
Future<bool> showChatPollCreatorSheet(
  BuildContext context, {
  required Channel channel,
  required bool isDirectChat,
}) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ChatPollCreatorSheet(
      channel: channel,
      isDirectChat: isDirectChat,
    ),
  );
  return created == true;
}

class ChatPollCreatorSheet extends StatefulWidget {
  const ChatPollCreatorSheet({
    super.key,
    required this.channel,
    required this.isDirectChat,
  });

  final Channel channel;
  final bool isDirectChat;

  @override
  State<ChatPollCreatorSheet> createState() => _ChatPollCreatorSheetState();
}

class _ChatPollCreatorSheetState extends State<ChatPollCreatorSheet> {
  final TextEditingController _questionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<ChatPollDraftOption> _options = [
    ChatPollDraftOption(),
    ChatPollDraftOption(),
  ];
  final Map<String, TextEditingController> _optionControllers = {};
  bool _allowMultiple = false;
  bool _resultsVisible = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final option in _options) {
      _optionControllers[option.id] = TextEditingController(text: option.text);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(ChatPollDraftOption option) {
    return _optionControllers.putIfAbsent(
      option.id,
      () => TextEditingController(text: option.text),
    );
  }

  Future<void> _pickOptionImage(ChatPollDraftOption option) async {
    try {
      Uint8List? bytes;
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        bytes = result?.files.single.bytes;
      } else {
        final picked = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (picked != null) bytes = await picked.readAsBytes();
      }
      if (!mounted || bytes == null || bytes.isEmpty) return;
      setState(() {
        option.imageBytes = bytes;
        option.imageUrl = null;
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.chatPollSendError('$e'));
    }
  }

  void _addOption() {
    if (_options.length >= kChatPollMaxOptions) return;
    final option = ChatPollDraftOption();
    setState(() {
      _options.add(option);
      _optionControllers[option.id] = TextEditingController();
    });
  }

  void _removeOption(ChatPollDraftOption option) {
    if (_options.length <= kChatPollMinOptions) return;
    setState(() {
      _options.removeWhere((item) => item.id == option.id);
      _optionControllers.remove(option.id)?.dispose();
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final reordered = reorderChatPollOptions(_options, oldIndex, newIndex);
      _options
        ..clear()
        ..addAll(reordered);
    });
  }

  Future<void> _send() async {
    if (_saving) return;
    final currentUserId = StreamChat.of(context).currentUser?.id;
    if (currentUserId == null) return;

    for (final option in _options) {
      option.text = _controllerFor(option).text;
    }

    final error = validateChatPoll(
      question: _questionController.text,
      validOptionCount: _options.where((option) => option.isValid).length,
    );
    if (error == 'questionRequired') {
      AppSnackbar.show(context, context.l10n.chatPollQuestionRequired);
      return;
    }
    if (error != null) {
      AppSnackbar.show(context, context.l10n.chatPollOptionsMin);
      return;
    }

    setState(() => _saving = true);
    try {
      await ChatPollService.instance.createPoll(
        channel: widget.channel,
        currentUserId: currentUserId,
        question: _questionController.text,
        options: _options,
        allowMultiple: _allowMultiple,
        resultsVisible: _resultsVisible,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StateError catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        e.message == 'questionRequired'
            ? context.l10n.chatPollQuestionRequired
            : e.message == 'optionsMin'
                ? context.l10n.chatPollOptionsMin
                : context.l10n.chatPollSendError(e.toString()),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.chatPollSendError('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      l10n.chatPollCreate,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _send,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.chatPollSend),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  TextField(
                    controller: _questionController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.chatPollQuestionLabel,
                      hintText: l10n.chatPollQuestionHint,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.chatPollOptionsLabel,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _options.length,
                    onReorder: _saving ? (_, __) {} : _onReorder,
                    itemBuilder: (context, index) {
                      final option = _options[index];
                      return _PollOptionEditor(
                        key: ValueKey(option.id),
                        option: option,
                        controller: _controllerFor(option),
                        index: index,
                        enabled: !_saving,
                        canRemove: _options.length > kChatPollMinOptions,
                        onPickImage: () => _pickOptionImage(option),
                        onClearImage: () {
                          setState(() {
                            option.imageBytes = null;
                            option.imageUrl = null;
                          });
                        },
                        onRemove: () => _removeOption(option),
                        onTextChanged: (value) {
                          option.text = value;
                        },
                      );
                    },
                  ),
                  if (_options.length < kChatPollMaxOptions)
                    TextButton.icon(
                      onPressed: _saving ? null : _addOption,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.chatPollOptionAdd),
                    ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _allowMultiple,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _allowMultiple = value),
                    title: Text(
                      l10n.chatPollAllowMultiple,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    subtitle: Text(
                      _allowMultiple
                          ? l10n.chatPollMultipleHint
                          : l10n.chatPollSingleHint,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _resultsVisible,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _resultsVisible = value),
                    title: Text(
                      widget.isDirectChat
                          ? l10n.chatPollResultsVisibleDirect
                          : l10n.chatPollResultsVisibleGroup,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    subtitle: Text(
                      _resultsVisible
                          ? l10n.chatPollResultsVisibleHint
                          : l10n.chatPollResultsHidden,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollOptionEditor extends StatelessWidget {
  const _PollOptionEditor({
    super.key,
    required this.option,
    required this.controller,
    required this.index,
    required this.enabled,
    required this.canRemove,
    required this.onPickImage,
    required this.onClearImage,
    required this.onRemove,
    required this.onTextChanged,
  });

  final ChatPollDraftOption option;
  final TextEditingController controller;
  final int index;
  final bool enabled;
  final bool canRemove;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onRemove;
  final ValueChanged<String> onTextChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final hasImage = option.imageBytes != null ||
        (option.imageUrl != null && option.imageUrl!.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            enabled: enabled,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Icon(Icons.drag_handle_rounded, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  enabled: enabled,
                  onChanged: onTextChanged,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.chatPollOptionHint(index + 1),
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: option.imageBytes != null
                              ? Image.memory(
                                  option.imageBytes!,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  option.imageUrl!,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: enabled ? onClearImage : null,
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.chatPollOptionPickImage,
            onPressed: enabled ? onPickImage : null,
            icon: Icon(
              hasImage
                  ? Icons.add_photo_alternate_rounded
                  : Icons.image_outlined,
              color: colors.primary,
            ),
          ),
          if (canRemove)
            IconButton(
              tooltip: l10n.chatPollOptionRemove,
              onPressed: enabled ? onRemove : null,
              icon: Icon(Icons.remove_circle_outline, color: colors.danger),
            ),
        ],
      ),
    );
  }
}
