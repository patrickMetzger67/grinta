import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Stream extraData flag for a user-created Messagerie group (not a team channel).
const String kChatGroupExtraFlag = 'grinta_group';
const String kChatGroupCreatedByKey = 'grinta_created_by';
const String kChatGroupAvatarColorKey = 'grinta_avatar_color';

const List<String> kChatGroupAvatarColorHexes = [
  '#E67E22',
  '#2980B9',
  '#27AE60',
  '#8E44AD',
  '#C0392B',
  '#16A085',
  '#2C3E50',
  '#D35400',
];

bool isGrintaUserGroupExtra(Map<String, Object?> extraData) {
  final flag = extraData[kChatGroupExtraFlag];
  return flag == true || flag == 'true';
}

bool isGrintaUserGroupChannel(Channel channel) {
  return isGrintaUserGroupExtra(channel.extraData);
}

String? chatGroupCreatedByFromExtra(Map<String, Object?> extraData) {
  final fromExtra = extraData[kChatGroupCreatedByKey]?.toString().trim();
  if (fromExtra == null || fromExtra.isEmpty) return null;
  return fromExtra;
}

String? chatGroupCreatedById(Channel channel) {
  return chatGroupCreatedByFromExtra(channel.extraData);
}

bool canManageGrintaUserGroupData({
  required Map<String, Object?> extraData,
  required String? currentUserId,
}) {
  final uid = currentUserId?.trim() ?? '';
  if (uid.isEmpty || !isGrintaUserGroupExtra(extraData)) return false;
  return chatGroupCreatedByFromExtra(extraData) == uid;
}

bool canManageGrintaUserGroup({
  required Channel channel,
  required String? currentUserId,
}) {
  return canManageGrintaUserGroupData(
    extraData: channel.extraData,
    currentUserId: currentUserId,
  );
}

String? chatGroupAvatarColorHex(Channel channel) {
  final raw = channel.extraData[kChatGroupAvatarColorKey]?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  return raw.startsWith('#') ? raw : '#$raw';
}

Color? parseChatGroupColor(String? hex) {
  var value = hex?.trim() ?? '';
  if (value.isEmpty) return null;
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}

String chatGroupInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'G';
  if (parts.length == 1) {
    final text = parts.first;
    return text.substring(0, text.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
