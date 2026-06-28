import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/player_photo_resolver.dart';

import 'app_session_player_avatar.dart';

/// Photo joueur — même rendu que le profil ([AppSessionPlayerAvatar]).
class PlayerPhoto extends StatefulWidget {
  const PlayerPhoto({
    super.key,
    required this.player,
    this.radius = 18,
    this.defaultPhotoFileName = defaultPlayerAvatarFilename,
  });

  final Player player;
  final double radius;
  final String defaultPhotoFileName;

  @override
  State<PlayerPhoto> createState() => _PlayerPhotoState();
}

class _PlayerPhotoState extends State<PlayerPhoto> {
  static final PlayerService _playerService = PlayerService();

  late Future<List<String>> _avatarUrlsFuture;

  @override
  void initState() {
    super.initState();
    _avatarUrlsFuture = _loadAvatarUrls();
  }

  @override
  void didUpdateWidget(covariant PlayerPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_avatarCacheIdentity(oldWidget.player) !=
        _avatarCacheIdentity(widget.player)) {
      _avatarUrlsFuture = _loadAvatarUrls();
    }
  }

  Future<List<String>> _loadAvatarUrls() {
    return _playerService.getCachedPlayerAvatarUrls(
      widget.player,
      defaultPhotoFileName: widget.defaultPhotoFileName,
      authUser: FirebaseAuth.instance.currentUser,
    );
  }

  static String _avatarCacheIdentity(Player player) {
    final memberId = effectiveMemberId(player) ?? '';
    final photo = player.photo ?? '';
    final userId = player.userID ?? '';
    final users = (player.users ?? []).join(',');
    return '$memberId|$photo|$userId|$users';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _avatarUrlsFuture,
      builder: (context, snapshot) {
        return AppSessionPlayerAvatar(
          player: widget.player,
          imageUrls: snapshot.data,
          radius: widget.radius,
          watchSessionForStaleWebAvatar: true,
        );
      },
    );
  }
}
