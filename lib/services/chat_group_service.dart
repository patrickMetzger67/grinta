import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../util/chat_group_channel.dart';

/// Creates and updates user Messagerie groups on Stream Chat.
class ChatGroupService extends ChangeNotifier {
  ChatGroupService._();

  static final ChatGroupService instance = ChatGroupService._();

  static const _uuid = Uuid();

  Future<String?> uploadAvatar({
    required String groupKey,
    required Uint8List bytes,
  }) async {
    final sanitized = groupKey.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final path = 'thumbs/chat_group_$sanitized.jpg';
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<Channel> createGroup({
    required StreamChatClient client,
    required String currentUserId,
    required String name,
    required List<String> memberIds,
    String? avatarColorHex,
    Uint8List? avatarBytes,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw StateError('groupNameRequired');
    }

    final members = <String>{
      currentUserId.trim(),
      ...memberIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
    }.toList();

    String? imageUrl;
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      imageUrl = await uploadAvatar(
        groupKey: 'new_${_uuid.v4()}',
        bytes: avatarBytes,
      );
    }

    // Named id so two groups with the same members stay distinct (unlike 1:1).
    final channelId = 'grp_${_uuid.v4().replaceAll('-', '')}';
    final channel = client.channel(
      'messaging',
      id: channelId,
      extraData: {
        'name': trimmedName,
        'members': members,
        kChatGroupExtraFlag: true,
        kChatGroupCreatedByKey: currentUserId.trim(),
        if (avatarColorHex != null && avatarColorHex.trim().isNotEmpty)
          kChatGroupAvatarColorKey: avatarColorHex.trim(),
        if (imageUrl != null) 'image': imageUrl,
      },
    );
    await channel.watch();
    notifyListeners();
    return channel;
  }

  Future<void> updateGroup({
    required Channel channel,
    required String name,
    String? avatarColorHex,
    Uint8List? avatarBytes,
    bool clearImage = false,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw StateError('groupNameRequired');
    }

    String? imageUrl;
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      imageUrl = await uploadAvatar(
        groupKey: channel.id ?? channel.cid ?? _uuid.v4(),
        bytes: avatarBytes,
      );
    }

    await channel.updatePartial(
      set: {
        'name': trimmedName,
        if (avatarColorHex != null && avatarColorHex.trim().isNotEmpty)
          kChatGroupAvatarColorKey: avatarColorHex.trim(),
        if (imageUrl != null) 'image': imageUrl,
        kChatGroupExtraFlag: true,
      },
      unset: clearImage && imageUrl == null ? const ['image'] : null,
    );
    notifyListeners();
  }

  Future<void> addMember({
    required Channel channel,
    required String userId,
  }) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return;
    await channel.addMembers([trimmed]);
    notifyListeners();
  }

  Future<void> removeMember({
    required Channel channel,
    required String userId,
  }) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return;
    await channel.removeMembers([trimmed]);
    notifyListeners();
  }

  Future<void> deleteGroup(Channel channel) async {
    try {
      await channel.delete();
    } catch (e, st) {
      debugPrint('ChatGroupService.delete failed, hiding instead: $e\n$st');
      await channel.hide(clearHistory: true);
    }
    notifyListeners();
  }
}
