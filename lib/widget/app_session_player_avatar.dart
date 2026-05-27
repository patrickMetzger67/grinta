import 'package:flutter/material.dart';
import 'package:grinta/model/player.dart';

/// Avatar joueur (initiales ou photo) réutilisable dans l'app.
class AppSessionPlayerAvatar extends StatelessWidget {
  const AppSessionPlayerAvatar({
    super.key,
    required this.player,
    required this.imageProvider,
    this.radius = 18,
  });

  final Player player;
  final ImageProvider? imageProvider;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final firstName = player.firstName ?? '';
    final lastName = player.lastName ?? '';
    final initials = _buildInitials(firstName, lastName);

    return CircleAvatar(
      radius: radius,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              initials,
              style: TextStyle(fontSize: radius * 0.65),
            )
          : null,
    );
  }

  String _buildInitials(String firstName, String lastName) {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    final value = '$f$l';
    return value.isNotEmpty ? value : '?';
  }
}
