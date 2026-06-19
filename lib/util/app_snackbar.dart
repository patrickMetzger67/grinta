import 'package:flutter/material.dart';

import 'app_theme.dart';

/// SnackBar cohérent avec le thème Grinta — fond visible et bon contraste.
class AppSnackbar {
  AppSnackbar._();

  static SnackBar build(
    BuildContext context,
    String message, {
    bool isError = true,
    double extraBottomMargin = 16,
  }) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final Color backgroundColor;
    final Color textColor;

    if (isError) {
      backgroundColor = colors.primary;
      textColor = Colors.white;
    } else {
      backgroundColor = brightness == Brightness.dark
          ? const Color(0xFF3D4048)
          : const Color(0xFF2A2A2E);
      textColor = Colors.white;
    }

    return SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + extraBottomMargin),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isError
              ? colors.primary.withValues(alpha: 0.6)
              : colors.primary.withValues(alpha: 0.45),
        ),
      ),
      duration: const Duration(seconds: 4),
    );
  }

  static void show(
    BuildContext context,
    String message, {
    bool isError = true,
    double extraBottomMargin = 16,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        build(
          context,
          message,
          isError: isError,
          extraBottomMargin: extraBottomMargin,
        ),
      );
  }
}

/// Marge basse adaptée au bottom sheet mobile de connexion.
const double kLoginSheetSnackBarBottomMargin = 72;

void showLoginSnackBar(
  BuildContext context,
  String message, {
  bool isError = true,
  double extraBottomMargin = kLoginSheetSnackBarBottomMargin,
}) {
  AppSnackbar.show(
    context,
    message,
    isError: isError,
    extraBottomMargin: extraBottomMargin,
  );
}
