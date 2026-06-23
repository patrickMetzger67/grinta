import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'userService.dart';
import 'playerService.dart';

/// Met en cache la photo Auth (Google/Apple/Meta) dans Firebase Storage
/// en arrière-plan ; l'affichage utilise directement l'URL Auth.
class UserAvatarService {
  UserAvatarService._();

  static final UserAvatarService instance = UserAvatarService._();

  static final Map<String, Future<String?>> _pending = {};

  static bool isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') ||
        url.contains('storage.googleapis.com');
  }

  static bool isExternalAuthPhotoUrl(String url) {
    if (isFirebaseStorageUrl(url)) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  String _avatarStoragePath(String uid) => 'thumbs/user_avatar_$uid.jpg';

  /// Télécharge la photo Auth vers Storage si besoin (arrière-plan).
  Future<String?> ensureCachedAuthPhoto(User user) async {
    final uid = user.uid.trim();
    if (uid.isEmpty) return null;

    return _pending.putIfAbsent(uid, () async {
      try {
        return await _ensureCachedAuthPhotoImpl(user);
      } finally {
        _pending.remove(uid);
      }
    });
  }

  Future<String?> _ensureCachedAuthPhotoImpl(User user) async {
    final uid = user.uid.trim();

    final existing = await _validatedStoragePhotoUrlFromFirestore(uid);
    if (existing != null) return existing;

    var authPhoto = user.photoURL?.trim();
    if (authPhoto == null || authPhoto.isEmpty) {
      try {
        await user.reload();
        authPhoto = FirebaseAuth.instance.currentUser?.photoURL?.trim();
      } catch (_) {}
    }
    if (authPhoto == null || authPhoto.isEmpty) return null;
    if (isFirebaseStorageUrl(authPhoto)) return authPhoto;

    try {
      final response = await http.get(Uri.parse(authPhoto));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }

      final ref = FirebaseStorage.instance.ref().child(_avatarStoragePath(uid));
      await ref.putData(
        response.bodyBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection(UserService.collectionName)
          .doc(uid)
          .set({'photoURL': downloadUrl}, SetOptions(merge: true));

      PlayerService.clearPlayerPhotoUrlCache();
      return downloadUrl;
    } catch (e) {
      debugPrint('UserAvatarService: cache failed uid=$uid: $e');
      return null;
    }
  }

  Future<String?> _validatedStoragePhotoUrlFromFirestore(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection(UserService.collectionName)
        .doc(uid)
        .get();
    if (!doc.exists) return null;

    final data = doc.data() ?? {};
    for (final key in ['photoURL', 'photo', 'image']) {
      final value = data[key]?.toString().trim();
      if (value == null || value.isEmpty) continue;
      if (!isFirebaseStorageUrl(value)) continue;

      if (await _isUrlAccessible(value)) return value;

      await _clearStoragePhotoUrl(uid);
      return null;
    }
    return null;
  }

  Future<bool> _isUrlAccessible(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      if (response.statusCode == 200) return true;
      if (response.statusCode == 405) {
        final getResponse = await http.get(Uri.parse(url));
        return getResponse.statusCode == 200;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearStoragePhotoUrl(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection(UserService.collectionName)
          .doc(uid)
          .set({'photoURL': FieldValue.delete()}, SetOptions(merge: true));
      PlayerService.clearPlayerPhotoUrlCache();
    } catch (_) {}
  }
}
