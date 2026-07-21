import 'package:grinta/model/player.dart';

/// Resolves the Firestore uid that owns wearable sync docs for [player].
///
/// Mirrors Cloud Functions `readMemberOwnerUid`, then falls back to [callerUid].
/// Sync metadata lives at `users/{ownerUid}/{provider}Sync/{playerId}`.
String resolveWearableSyncOwnerUid({
  required String callerUid,
  Player? player,
}) {
  if (player == null) return callerUid;

  final userId = (player.userID ?? '').trim();
  if (userId.isNotEmpty) return userId;

  final users = player.users;
  if (users != null) {
    for (final entry in users) {
      final id = entry?.toString().trim() ?? '';
      if (id.isNotEmpty) return id;
    }
  }

  final creator = (player.creatorUserId ?? '').trim();
  if (creator.isNotEmpty) return creator;

  return callerUid;
}
