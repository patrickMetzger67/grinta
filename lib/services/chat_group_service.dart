import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import 'stream_channel_service.dart';

const String kCreateChatGroupFunctionName = 'createChatGroup';
const String kUpdateChatGroupFunctionName = 'updateChatGroup';
const String kAddChatGroupMemberFunctionName = 'addChatGroupMember';
const String kRemoveChatGroupMemberFunctionName = 'removeChatGroupMember';
const String kDeleteChatGroupFunctionName = 'deleteChatGroup';

/// Creates and updates user Messagerie groups via Cloud Functions + Stream.
class ChatGroupService extends ChangeNotifier {
  ChatGroupService._();

  static final ChatGroupService instance = ChatGroupService._();

  static const _uuid = Uuid();

  FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(
        region: kStreamFunctionsRegion,
      );

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

    final channelId = 'grp_${_uuid.v4().replaceAll('-', '')}';
    String? imageUrl;
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      imageUrl = await uploadAvatar(
        groupKey: channelId,
        bytes: avatarBytes,
      );
    }

    final data = await _call(kCreateChatGroupFunctionName, {
      'channelId': channelId,
      'name': trimmedName,
      'memberIds': members,
      if (avatarColorHex != null && avatarColorHex.trim().isNotEmpty)
        'avatarColorHex': avatarColorHex.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    });

    final createdId = (data['channelId'] ?? channelId).toString();
    final channel = client.channel('messaging', id: createdId);
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

    final channelId = _channelId(channel);
    if (channelId == null) {
      throw StateError('missingChannelId');
    }

    String? imageUrl;
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      imageUrl = await uploadAvatar(
        groupKey: channelId,
        bytes: avatarBytes,
      );
    }

    await _call(kUpdateChatGroupFunctionName, {
      'channelId': channelId,
      'name': trimmedName,
      if (avatarColorHex != null && avatarColorHex.trim().isNotEmpty)
        'avatarColorHex': avatarColorHex.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      'clearImage': clearImage && imageUrl == null,
    });
    await channel.watch();
    notifyListeners();
  }

  Future<void> addMember({
    required Channel channel,
    required String userId,
  }) async {
    final trimmed = userId.trim();
    final channelId = _channelId(channel);
    if (trimmed.isEmpty || channelId == null) return;
    await _call(kAddChatGroupMemberFunctionName, {
      'channelId': channelId,
      'userId': trimmed,
    });
    await channel.watch();
    notifyListeners();
  }

  Future<void> removeMember({
    required Channel channel,
    required String userId,
  }) async {
    final trimmed = userId.trim();
    final channelId = _channelId(channel);
    if (trimmed.isEmpty || channelId == null) return;
    await _call(kRemoveChatGroupMemberFunctionName, {
      'channelId': channelId,
      'userId': trimmed,
    });
    await channel.watch();
    notifyListeners();
  }

  Future<void> deleteGroup(Channel channel) async {
    final channelId = _channelId(channel);
    if (channelId == null) {
      throw StateError('missingChannelId');
    }
    try {
      await _call(kDeleteChatGroupFunctionName, {
        'channelId': channelId,
      });
    } catch (e, st) {
      debugPrint('ChatGroupService.delete failed, hiding instead: $e\n$st');
      await channel.hide(clearHistory: true);
    }
    notifyListeners();
  }

  String? _channelId(Channel channel) {
    final id = channel.id?.trim();
    if (id != null && id.isNotEmpty) return id;
    final cid = channel.cid?.trim() ?? '';
    if (cid.contains(':')) {
      return cid.split(':').sublist(1).join(':');
    }
    return cid.isEmpty ? null : cid;
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(payload);
      final data = result.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      final message = e.message?.trim();
      if (message != null && message.isNotEmpty) {
        throw StateError(message);
      }
      throw StateError(e.code);
    }
  }
}
