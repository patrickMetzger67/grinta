import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/player.dart';
import 'playerService.dart';

/// Deletes the signed-in user's Firebase Auth account and related Firestore data.
class AccountDeletionService {
  AccountDeletionService._();

  static final AccountDeletionService instance = AccountDeletionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PlayerService _playerService = PlayerService();

  /// Removes member links, user document, then deletes the Auth user.
  ///
  /// Throws [FirebaseAuthException] (e.g. `requires-recent-login`) on failure.
  Future<void> deleteCurrentAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }

    final uid = user.uid;

    await _cleanupMemberDocuments(uid);
    await _deleteUserFirestoreData(uid);
    await user.delete();
  }

  Future<void> _cleanupMemberDocuments(String uid) async {
    final members = await _playerService.getPlayersByUserId(uid);

    for (final player in members) {
      final ref = player.ref;
      if (ref == null) continue;

      final users = _stringList(player.users);
      if (!users.contains(uid)) continue;

      final isSoleCreator = users.length == 1 &&
          users.first == uid &&
          player.creatorUserId == uid;

      if (isSoleCreator) {
        await ref.delete();
        continue;
      }

      final updatedUsers = users.where((id) => id != uid).toList();
      final updates = <String, dynamic>{
        keyPlayerUsers: updatedUsers,
      };
      if (player.userID == uid) {
        updates[keyPlayerUserID] =
            updatedUsers.isNotEmpty ? updatedUsers.first : '';
      }
      await ref.update(updates);
    }
  }

  Future<void> _deleteUserFirestoreData(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);

    final appStateSnap = await userRef.collection('app_state').get();
    if (appStateSnap.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in appStateSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await userRef.delete();
  }

  List<String> _stringList(List<dynamic>? values) {
    if (values == null) return const [];
    return values.map((value) => value.toString()).toList();
  }
}
