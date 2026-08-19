import 'dart:async' show unawaited;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/screen/chat/chat_user_picker_page.dart';
import 'package:grinta/services/chat_group_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/chat_group_channel.dart';
import 'package:grinta/widget/chat_group_color_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChatGroupEditorResult {
  const ChatGroupEditorResult({
    required this.channel,
    this.deleted = false,
  });

  final Channel channel;
  final bool deleted;
}

/// Opens the create / edit group sheet.
Future<ChatGroupEditorResult?> showChatGroupEditorSheet(
  BuildContext context, {
  Channel? channel,
}) {
  return showModalBottomSheet<ChatGroupEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ChatGroupEditorSheet(channel: channel),
  );
}

class ChatGroupEditorSheet extends StatefulWidget {
  const ChatGroupEditorSheet({
    super.key,
    this.channel,
  });

  final Channel? channel;

  @override
  State<ChatGroupEditorSheet> createState() => _ChatGroupEditorSheetState();
}

class _DraftMember {
  const _DraftMember({
    required this.id,
    required this.name,
    this.image,
  });

  final String id;
  final String name;
  final String? image;
}

class _ChatGroupEditorSheetState extends State<ChatGroupEditorSheet> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<_DraftMember> _members = [];
  String? _colorHex;
  Uint8List? _avatarBytes;
  String? _existingImageUrl;
  bool _clearImage = false;
  bool _saving = false;
  bool _deleting = false;

  bool get _isEditing => widget.channel != null;

  String? get _currentUserId => StreamChat.of(context).currentUser?.id;

  @override
  void initState() {
    super.initState();
    final channel = widget.channel;
    if (channel != null) {
      _nameController.text = channel.name?.trim() ?? '';
      _colorHex = chatGroupAvatarColorHex(channel);
      final image = channel.image?.trim();
      if (image != null && image.isNotEmpty) _existingImageUrl = image;
      for (final member in channel.state?.members ?? const <Member>[]) {
        final user = member.user;
        final id = member.userId ?? user?.id;
        if (id == null || id.isEmpty) continue;
        _members.add(
          _DraftMember(
            id: id,
            name: user?.name.trim().isNotEmpty == true ? user!.name : id,
            image: user?.image,
          ),
        );
      }
    }
    _colorHex ??= kChatGroupDefaultAvatarColorHex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEditing) return;
    final current = StreamChat.of(context).currentUser;
    if (current == null) return;
    if (_members.any((member) => member.id == current.id)) return;
    _members.insert(
      0,
      _DraftMember(
        id: current.id,
        name: current.name,
        image: current.image,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
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
        _avatarBytes = bytes;
        _existingImageUrl = null;
        _clearImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.chatGroupUpdateError('$e'));
    }
  }

  Future<void> _addMember() async {
    final selected = await showChatUserPicker(
      context,
      excludeUserIds: _members.map((member) => member.id),
      title: context.l10n.chatGroupAddMember,
    );
    if (!mounted || selected == null) return;

    if (_isEditing) {
      try {
        await ChatGroupService.instance.addMember(
          channel: widget.channel!,
          userId: selected.id,
        );
      } catch (e) {
        if (!mounted) return;
        AppSnackbar.show(context, context.l10n.chatGroupUpdateError('$e'));
        return;
      }
    }

    setState(() {
      _members.add(
        _DraftMember(
          id: selected.id,
          name: selected.name,
          image: selected.image,
        ),
      );
    });
  }

  bool _isProtectedMember(_DraftMember member) {
    if (member.id == _currentUserId) return true;
    final channel = widget.channel;
    if (channel != null && chatGroupCreatedById(channel) == member.id) {
      return true;
    }
    return false;
  }

  void _removePhoto() {
    setState(() {
      _avatarBytes = null;
      _existingImageUrl = null;
      _clearImage = true;
    });
  }

  Future<void> _removeMember(_DraftMember member) async {
    if (_isProtectedMember(member)) return;

    if (_isEditing) {
      try {
        await ChatGroupService.instance.removeMember(
          channel: widget.channel!,
          userId: member.id,
        );
      } catch (e) {
        if (!mounted) return;
        AppSnackbar.show(context, context.l10n.chatGroupUpdateError('$e'));
        return;
      }
    }

    setState(() {
      _members.removeWhere((item) => item.id == member.id);
    });
  }

  Future<void> _save() async {
    if (_saving || _deleting) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.show(context, context.l10n.chatGroupNameRequired);
      return;
    }

    final client = StreamChat.of(context).client;
    final currentUserId = client.state.currentUser?.id;
    if (currentUserId == null) return;

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await ChatGroupService.instance.updateGroup(
          channel: widget.channel!,
          name: name,
          avatarColorHex: _colorHex,
          avatarBytes: _avatarBytes,
          clearImage: _clearImage && _avatarBytes == null,
        );
        if (!mounted) return;
        Navigator.of(context).pop(
          ChatGroupEditorResult(channel: widget.channel!),
        );
        return;
      }

      final channel = await ChatGroupService.instance.createGroup(
        client: client,
        currentUserId: currentUserId,
        name: name,
        memberIds: _members.map((member) => member.id).toList(),
        avatarColorHex: _colorHex,
        avatarBytes: _avatarBytes,
      );
      if (!mounted) return;
      Navigator.of(context).pop(ChatGroupEditorResult(channel: channel));
    } on StateError catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        e.message == 'groupNameRequired'
            ? context.l10n.chatGroupNameRequired
            : context.l10n.chatGroupCreateError(e.toString()),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        _isEditing
            ? context.l10n.chatGroupUpdateError('$e')
            : context.l10n.chatGroupCreateError('$e'),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final channel = widget.channel;
    if (channel == null || _deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.appColors;
        final l10n = dialogContext.l10n;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(l10n.chatGroupDeleteConfirmTitle),
          content: Text(l10n.chatGroupDeleteConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.chatGroupDeleteAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ChatGroupService.instance.deleteGroup(channel);
      if (!mounted) return;
      Navigator.of(context).pop(
        ChatGroupEditorResult(channel: channel, deleted: true),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.chatGroupDeleteError('$e'));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final currentId = _currentUserId;
    final canDelete = _isEditing &&
        canManageGrintaUserGroup(
          channel: widget.channel!,
          currentUserId: currentId,
        );
    final color = parseChatGroupColor(_colorHex);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Stack(
          children: [
            Column(
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
                    onPressed: _saving || _deleting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _isEditing
                          ? l10n.chatGroupEditTitle
                          : l10n.chatCreateGroup,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving || _deleting ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditing
                                ? l10n.chatGroupSaveAction
                                : l10n.chatGroupCreateAction,
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _saving ? null : _pickAvatar,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: color ?? colors.primary,
                        backgroundImage: _avatarBytes != null
                            ? MemoryImage(_avatarBytes!)
                            : (_existingImageUrl != null
                                ? NetworkImage(_existingImageUrl!)
                                : null),
                        child: _avatarBytes == null && _existingImageUrl == null
                            ? Text(
                                chatGroupInitials(_nameController.text),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.chatGroupPickPhoto,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  if (_avatarBytes != null || _existingImageUrl != null)
                    TextButton(
                      onPressed: _saving ? null : _removePhoto,
                      child: Text(l10n.chatGroupRemovePhoto),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.chatGroupPickColor,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ChatGroupColorPicker(
                    color: color ?? parseChatGroupColor(
                          kChatGroupDefaultAvatarColorHex,
                        )!,
                    enabled: !_saving,
                    onColorChanged: (picked) {
                      setState(() => _colorHex = colorToCssHex(picked));
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    enabled: !_saving,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.chatGroupNameLabel,
                      hintText: l10n.chatGroupNameHint,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.chatGroupMembersTitle,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text('${_members.length}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_members.isEmpty)
                    Text(
                      l10n.chatGroupAddMemberHint,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  for (final member in _members)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: member.image != null
                            ? NetworkImage(member.image!)
                            : null,
                        child: member.image == null
                            ? Text(chatGroupInitials(member.name))
                            : null,
                      ),
                      title: Text(
                        member.name,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      trailing: _isProtectedMember(member)
                          ? null
                          : IconButton(
                              tooltip: l10n.chatGroupRemoveMember,
                              onPressed:
                                  _saving ? null : () => unawaited(_removeMember(member)),
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: colors.danger,
                              ),
                            ),
                    ),
                  if (canDelete) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _saving || _deleting ? null : _delete,
                      icon: _deleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                      label: Text(l10n.chatGroupDeleteAction),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                heroTag: 'chat-group-add-member',
                tooltip: l10n.chatGroupAddMember,
                onPressed: _saving || _deleting ? null : _addMember,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
