import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';

class DebugVideoFrameControls extends StatelessWidget {
  const DebugVideoFrameControls({
    super.key,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onTaller,
    required this.onShorter,
    required this.onWider,
    required this.onNarrower,
    required this.onAssign,
    required this.onReset,
  });

  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onTaller;
  final VoidCallback onShorter;
  final VoidCallback onWider;
  final VoidCallback onNarrower;
  final VoidCallback onAssign;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: 118,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconButton(
                icon: Icons.keyboard_arrow_up,
                tooltip: l10n.debugVideoFrameMoveUp,
                onPressed: onMoveUp,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconButton(
                icon: Icons.keyboard_arrow_left,
                tooltip: l10n.debugVideoFrameMoveLeft,
                onPressed: onMoveLeft,
              ),
              _IconButton(
                icon: Icons.keyboard_arrow_down,
                tooltip: l10n.debugVideoFrameMoveDown,
                onPressed: onMoveDown,
              ),
              _IconButton(
                icon: Icons.keyboard_arrow_right,
                tooltip: l10n.debugVideoFrameMoveRight,
                onPressed: onMoveRight,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TextButton(
                label: 'H+',
                tooltip: l10n.debugVideoFrameTaller,
                onPressed: onTaller,
              ),
              _TextButton(
                label: 'H-',
                tooltip: l10n.debugVideoFrameShorter,
                onPressed: onShorter,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TextButton(
                label: 'L+',
                tooltip: l10n.debugVideoFrameWider,
                onPressed: onWider,
              ),
              _TextButton(
                label: 'L-',
                tooltip: l10n.debugVideoFrameNarrower,
                onPressed: onNarrower,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _IconButton(
            icon: Icons.person_add_alt_1,
            tooltip: l10n.debugVideoFrameAssign,
            onPressed: onAssign,
            emphasize: true,
          ),
          const SizedBox(height: 4),
          _IconButton(
            icon: Icons.refresh,
            tooltip: l10n.actionReset,
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.emphasize = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final child = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: emphasize
              ? colors.primary.withValues(alpha: 0.24)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: emphasize ? colors.primary : Colors.white,
          size: 18,
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

class _TextButton extends StatelessWidget {
  const _TextButton({
    required this.label,
    required this.onPressed,
    this.tooltip,
  });

  final String label;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final child = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: colors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}
