import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/playerService.dart';
import 'package:provider/provider.dart';

import 'app_session_player_avatar.dart';

/// Photo joueur — même rendu que le profil ([AppSessionPlayerAvatar]).
class PlayerPhoto extends StatefulWidget {
  const PlayerPhoto({
    super.key,
    required this.player,
    this.radius = 18,
    this.defaultPhotoFileName = 'portrait_1920x1920.jpg',
  });

  final Player player;
  final double radius;
  final String defaultPhotoFileName;

  @override
  State<PlayerPhoto> createState() => _PlayerPhotoState();
}

class _PlayerPhotoState extends State<PlayerPhoto> {
  static final PlayerService _playerService = PlayerService();

  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = _playerService.getCachedUrlPlayer(
      widget.player,
      widget.defaultPhotoFileName,
    );
  }

  @override
  void didUpdateWidget(covariant PlayerPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldKey = oldWidget.player.keyMember ?? oldWidget.player.photo;
    final newKey = widget.player.keyMember ?? widget.player.photo;
    if (oldKey != newKey) {
      _urlFuture = _playerService.getCachedUrlPlayer(
        widget.player,
        widget.defaultPhotoFileName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberId = widget.player.keyMember;
    if (memberId != null) {
      final sessionImage =
          context.watch<AppSession>().playersPhoto[memberId];
      if (sessionImage != null) {
        return AppSessionPlayerAvatar(
          player: widget.player,
          imageProvider: sessionImage,
          radius: widget.radius,
        );
      }
    }

    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _avatar(imageProvider: null);
        }

        final imageUrl = snapshot.data?.trim() ?? '';
        if (imageUrl.isEmpty) {
          return _avatar(imageProvider: null);
        }

        return _avatar(
          imageProvider: CachedNetworkImageProvider(imageUrl),
        );
      },
    );
  }

  Widget _avatar({required ImageProvider? imageProvider}) {
    return AppSessionPlayerAvatar(
      player: widget.player,
      imageProvider: imageProvider,
      radius: widget.radius,
    );
  }
}
