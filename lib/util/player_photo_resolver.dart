import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/player.dart';
import '../services/userService.dart';

/// Priorité : photo joueur → photo utilisateur lié → null (image par défaut).
Future<String?> resolvePlayerPhotoSource(Player player) async {
  final playerPhoto = player.photo?.trim() ?? '';
  if (playerPhoto.isNotEmpty) return playerPhoto;

  return resolveUserPhotoUrlForPlayer(player);
}

/// Photo utilisateur liée au joueur ([Player.userID]).
Future<String?> resolveUserPhotoUrlForPlayer(Player player) async {
  final userId = player.userID?.trim();
  if (userId == null || userId.isEmpty) return null;

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser?.uid == userId) {
    final authPhoto = currentUser!.photoURL?.trim();
    if (authPhoto != null && authPhoto.isNotEmpty) return authPhoto;
  }

  final doc = await FirebaseFirestore.instance
      .collection(UserService.collectionName)
      .doc(userId)
      .get();
  if (!doc.exists) return null;

  final data = doc.data() ?? {};
  for (final key in ['photoURL', 'photo', 'image']) {
    final value = data[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }

  return null;
}
