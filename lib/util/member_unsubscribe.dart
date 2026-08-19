/// How [Player.userID] should change when a uid is removed from `users`.
enum MemberUserIdUnsubscribeAction {
  /// [Player.userID] is another account — leave it unchanged.
  keep,

  /// [Player.userID] was the unsubscribed uid — point it at another linked user.
  reassign,

  /// No remaining linked users — clear [Player.userID].
  clear,
}

/// Firestore update plan for unsubscribing [uid] from a member profile.
class MemberUnsubscribePlan {
  const MemberUnsubscribePlan({
    required this.remainingUsers,
    required this.userIdAction,
    this.nextUserId,
  });

  /// `users` after removing [uid] (order preserved, empties dropped).
  final List<String> remainingUsers;

  final MemberUserIdUnsubscribeAction userIdAction;

  /// New [Player.userID] when [userIdAction] is [MemberUserIdUnsubscribeAction.reassign].
  final String? nextUserId;
}

bool canManageLinkedProfiles(int profileCount) => profileCount > 1;

List<String> normalizedMemberUserIds(List<dynamic>? users) {
  final ids = <String>[];
  if (users == null) return ids;
  for (final entry in users) {
    final id = entry?.toString().trim() ?? '';
    if (id.isEmpty || ids.contains(id)) continue;
    ids.add(id);
  }
  return ids;
}

/// Builds the unlink plan, or `null` when [uid] is not in [users].
MemberUnsubscribePlan? planMemberUnsubscribe({
  required List<dynamic>? users,
  required String? userID,
  required String uid,
}) {
  final trimmedUid = uid.trim();
  if (trimmedUid.isEmpty) return null;

  final current = normalizedMemberUserIds(users);
  if (!current.contains(trimmedUid)) return null;

  final remaining =
      current.where((id) => id != trimmedUid).toList(growable: false);
  final currentUserId = userID?.trim() ?? '';

  if (currentUserId.isEmpty || currentUserId != trimmedUid) {
    return MemberUnsubscribePlan(
      remainingUsers: remaining,
      userIdAction: MemberUserIdUnsubscribeAction.keep,
    );
  }

  if (remaining.isNotEmpty) {
    return MemberUnsubscribePlan(
      remainingUsers: remaining,
      userIdAction: MemberUserIdUnsubscribeAction.reassign,
      nextUserId: remaining.first,
    );
  }

  return MemberUnsubscribePlan(
    remainingUsers: remaining,
    userIdAction: MemberUserIdUnsubscribeAction.clear,
  );
}
