import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/ask_diego/ask_diego_access.dart';
import 'package:grinta/widget/ask_diego/ask_diego_avatar.dart';

/// Optional primary screen action shown alongside Ask Diego in the speed dial.
class AskDiegoPrimaryAction {
  const AskDiegoPrimaryAction({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.heroTag,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final String heroTag;
}

/// Speed dial FAB: primary screen action + premium-gated Ask Diego entry.
///
/// When [primaryAction] is null, shows a single Ask Diego avatar FAB.
class AskDiegoSpeedDial extends StatefulWidget {
  const AskDiegoSpeedDial({
    super.key,
    this.primaryAction,
    required this.heroTagPrefix,
  });

  final AskDiegoPrimaryAction? primaryAction;
  final String heroTagPrefix;

  @override
  State<AskDiegoSpeedDial> createState() => _AskDiegoSpeedDialState();
}

class _AskDiegoSpeedDialState extends State<AskDiegoSpeedDial>
    with SingleTickerProviderStateMixin {
  static const _miniFabSpacing = 64.0;

  bool _isOpen = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      unawaited(_controller.forward());
    } else {
      unawaited(_controller.reverse());
    }
  }

  void _close() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    unawaited(_controller.reverse());
  }

  void _onPrimaryPressed() {
    _close();
    widget.primaryAction!.onPressed();
  }

  void _onAskDiegoPressed() {
    _close();
    openAskDiegoFromTap(context);
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryAction;
    if (primary == null) {
      return _AskDiegoImageButton(
        heroTag: '${widget.heroTagPrefix}-ask-diego',
        tooltip: context.l10n.askDiegoTitle,
        onPressed: () => openAskDiegoFromTap(context),
        size: 56,
      );
    }

    final colors = context.appColors;
    final l10n = context.l10n;

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        FadeTransition(
          opacity: _expandAnimation,
          child: ScaleTransition(
            scale: _expandAnimation,
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _AskDiegoImageButton(
                  heroTag: '${widget.heroTagPrefix}-ask-diego',
                  tooltip: l10n.askDiegoTitle,
                  onPressed: _onAskDiegoPressed,
                  size: 40,
                  mini: true,
                ),
                const SizedBox(height: 12),
                _SpeedDialMiniFab(
                  heroTag: primary.heroTag,
                  tooltip: primary.tooltip,
                  onPressed: _onPrimaryPressed,
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  child: Icon(primary.icon),
                ),
                const SizedBox(height: _miniFabSpacing),
              ],
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: '${widget.heroTagPrefix}-main',
          tooltip: _isOpen ? l10n.askDiegoCloseSpeedDial : primary.tooltip,
          onPressed: _toggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              _isOpen ? Icons.close : primary.icon,
              key: ValueKey<bool>(_isOpen),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tappable Ask Diego avatar without a colored circular background.
class _AskDiegoImageButton extends StatelessWidget {
  const _AskDiegoImageButton({
    required this.heroTag,
    required this.tooltip,
    required this.onPressed,
    required this.size,
    this.mini = false,
  });

  final String heroTag;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final avatar = AskDiegoAvatar(size: size);
    final splashColor = colors.primary.withValues(alpha: 0.15);

    const transparentFabShape = CircleBorder();

    if (mini) {
      return FloatingActionButton.small(
        heroTag: heroTag,
        tooltip: tooltip,
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        shape: transparentFabShape,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        splashColor: splashColor,
        child: avatar,
      );
    }

    return FloatingActionButton(
      heroTag: heroTag,
      tooltip: tooltip,
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      shape: transparentFabShape,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      splashColor: splashColor,
      child: avatar,
    );
  }
}

class _SpeedDialMiniFab extends StatelessWidget {
  const _SpeedDialMiniFab({
    required this.heroTag,
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String heroTag;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      tooltip: tooltip,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: child,
    );
  }
}
