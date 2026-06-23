import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../model/player.dart';
import '../util/player_photo_resolver.dart';
import 'playerService.dart';

class MemberPhotoService {
  MemberPhotoService._();

  static final MemberPhotoService instance = MemberPhotoService._();

  String storagePathForFilename(String filename) => 'thumbs/$filename';

  String buildFilenameForProfile(Player profile) {
    return buildMemberPhotoFilename(
      lastName: profile.lastName?.trim() ?? '',
      firstName: profile.firstName?.trim() ?? '',
      birthDay: profile.birthDay,
    );
  }

  Future<String> uploadMemberPhoto({
    required String memberId,
    required Player profile,
    required Uint8List imageBytes,
    String? previousFilename,
  }) async {
    final filename = buildFilenameForProfile(profile);
    final ref = FirebaseStorage.instance.ref().child(storagePathForFilename(filename));

    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    await PlayerService().updatePlayerFields(memberId, {
      keyPlayerPhoto: filename,
    });

    PlayerService.clearPlayerPhotoUrlCache();

    final previous = previousFilename?.trim();
    if (previous != null &&
        previous.isNotEmpty &&
        previous != filename &&
        !previous.contains('://')) {
      unawaited(_deleteStoragePhotoIfExists(previous));
    }

    return filename;
  }

  Future<void> _deleteStoragePhotoIfExists(String filename) async {
    try {
      await FirebaseStorage.instance
          .ref()
          .child(storagePathForFilename(filename))
          .delete();
    } catch (_) {}
  }
}
