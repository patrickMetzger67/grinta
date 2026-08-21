import 'package:flutter/material.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/app_theme.dart';

/// Circular avatar for an app [UserProfile] (photoURL or initials).
class AdminUserAvatar extends StatelessWidget {
  const AdminUserAvatar({
    super.key,
    required this.user,
    this.radius = 24,
  });

  final UserProfile user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final photoUrl = user.photoURL.trim();
    final size = radius * 2;

    if (photoUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colors.primary.withValues(alpha: 0.14),
        child: Text(
          user.initials,
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.75,
          ),
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: colors.primary.withValues(alpha: 0.14),
            child: Text(
              user.initials,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.75,
              ),
            ),
          );
        },
      ),
    );
  }
}
