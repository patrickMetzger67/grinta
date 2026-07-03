import 'package:flutter/material.dart';
import 'package:grinta/util/app_theme.dart';

/// Icon with an optional success-colored count badge (hidden when [count] is 0).
class NavIconCountBadge extends StatelessWidget {
  const NavIconCountBadge({
    super.key,
    required this.icon,
    required this.count,
    required this.iconColor,
    this.iconSize = 24,
  });

  final IconData icon;
  final int count;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, color: iconColor, size: iconSize);

    if (count <= 0) {
      return iconWidget;
    }

    final colors = context.appColors;
    final label = count > 99 ? '99+' : '$count';

    return Badge(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: colors.success,
      child: iconWidget,
    );
  }
}

/// Standalone success-colored count badge (hidden when [count] is 0).
class CountBadgeLabel extends StatelessWidget {
  const CountBadgeLabel({
    super.key,
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final label = count > 99 ? '99+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.success,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
