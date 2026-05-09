import 'package:flutter/material.dart';

import '../model/player.dart';
import '../services/playerService.dart';
import '../util/app_theme.dart';

class PlayerPhoto extends StatelessWidget {
  const PlayerPhoto({
    required this.player,
    this.radius = 18,
  });

  final Player player;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final PlayerService playerService = PlayerService();

    return FutureBuilder<String>(
      future: playerService.getUrlPlayer(player, "portrait_1920x1920.jpg"),
      builder: (context, photoSnapshot) {
        final String? imageUrl = photoSnapshot.data;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: colors.primary.withValues(alpha: 0.12),
            backgroundImage: NetworkImage(imageUrl),
          );
        }

        final String initials = _initials(
          player.firstName ?? '',
          player.lastName ?? '',
        );

        return CircleAvatar(
          radius: radius,
          backgroundColor: colors.primary.withValues(alpha: 0.12),
          child: Text(
            initials,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }

  String _initials(String firstName, String lastName) {
    final String f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final String l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    final String value = '$f$l';

    return value.isEmpty ? '?' : value;
  }
}