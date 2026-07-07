import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/util/app_theme.dart';

/// Icon size for web sidebar nav and settings panel rows.
const double kWebMenuIconSize = 22;

/// Diego avatar size in the web sidebar (expanded / collapsed).
const double kWebSidebarDiegoAvatarSizeExpanded = 34;
const double kWebSidebarDiegoAvatarSizeCollapsed = 28;

/// Label style for web sidebar navigation items (Agenda, Diego, notifications…).
TextStyle webSidebarNavLabelStyle(
  BuildContext context, {
  required bool selected,
}) {
  final colors = context.appColors;
  final baseStyle = kIsWeb
      ? Theme.of(context).textTheme.bodyLarge!
      : Theme.of(context).textTheme.bodyMedium!;

  return baseStyle.copyWith(
    color: selected ? colors.textPrimary : colors.textSecondary,
    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
  );
}

/// Title style for settings menu rows — matches sidebar / account menu items.
TextStyle settingsMenuTitleStyle(BuildContext context) {
  final baseStyle = kIsWeb
      ? Theme.of(context).textTheme.bodyLarge!
      : Theme.of(context).textTheme.bodyMedium!;

  return baseStyle.copyWith(
    color: context.appColors.textPrimary,
    fontWeight: FontWeight.w600,
  );
}

/// Subtitle style for settings menu rows with secondary hint text.
TextStyle settingsMenuSubtitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall!.copyWith(
        color: context.appColors.textSecondary,
      );
}
