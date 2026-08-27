import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';

/// Close control for the settings menu (header or end of the page).
class SettingsCloseButton extends StatelessWidget {
  const SettingsCloseButton({
    super.key,
    required this.onPressed,
    this.fullWidth = false,
  });

  final VoidCallback onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    if (!fullWidth) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: colors.primary),
        child: Text(l10n.actionClose),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.close_rounded, size: 20),
          label: Text(l10n.actionClose),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.border),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
