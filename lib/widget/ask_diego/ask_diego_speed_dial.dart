import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/account_create_profile_entry.dart';
import 'package:grinta/widget/ask_diego/ask_diego_access.dart';
import 'package:grinta/widget/ask_diego/ask_diego_avatar.dart';

/// Optional primary screen action shown alongside Ask Diego in the speed dial.
class AskDiegoPrimaryAction {
  const AskDiegoPrimaryAction({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.heroTag,
    this.showBadge = false,
    this.showPremiumBadge = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final String heroTag;

  /// When true, shows a small status dot on the mini FAB icon.
  final bool showBadge;

  /// When true, overlays the Premium crown on the mini FAB icon.
  final bool showPremiumBadge;
}

/// Speed dial FAB: primary screen action(s) + premium-gated Ask Diego entry.
///
/// When [primaryAction] is null, shows a single Ask Diego avatar FAB.
class AskDiegoSpeedDial extends StatefulWidget {
  const AskDiegoSpeedDial({
    super.key,
    this.primaryAction,
    this.secondaryActions = const [],
    required this.heroTagPrefix,
    this.showClosedBadge = false,
  });

  final AskDiegoPrimaryAction? primaryAction;

  /// Extra mini FABs shown above [primaryAction] when the dial is open
  /// (e.g. coach player filter on the agenda).
  final List<AskDiegoPrimaryAction> secondaryActions;

  final String heroTagPrefix;

  /// Badge on the closed main FAB (e.g. agenda filter active).
  final bool showClosedBadge;

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
    final secondary = widget.secondaryActions;
    if (primary == null && secondary.isEmpty) {
      return _AskDiegoImageButton(
        heroTag: '${widget.heroTagPrefix}-ask-diego',
        tooltip: context.l10n.askDiegoTitle,
        onPressed: () => openAskDiegoFromTap(context),
        size: 56,
      );
    }

    final colors = context.appColors;
    final l10n = context.l10n;
    final useAskDiegoAsMain = primary == null;

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
                for (final action in secondary) ...[
                  _SpeedDialMiniFab(
                    heroTag: action.heroTag,
                    tooltip: action.tooltip,
                    onPressed: () {
                      _close();
                      action.onPressed();
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: colors.primary,
                    child: SubscriptionPremiumBadge.withIconOverlay(
                      context: context,
                      colors: colors,
                      showPremium: action.showPremiumBadge,
                      icon: _badgedIcon(
                        icon: action.icon,
                        showBadge: action.showBadge,
                        badgeColor: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (primary != null) ...[
                  _SpeedDialMiniFab(
                    heroTag: primary.heroTag,
                    tooltip: primary.tooltip,
                    onPressed: _onPrimaryPressed,
                    backgroundColor: Colors.white,
                    foregroundColor: colors.primary,
                    child: Icon(primary.icon),
                  ),
                ],
                const SizedBox(height: _miniFabSpacing),
              ],
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: '${widget.heroTagPrefix}-main',
          tooltip: _isOpen
              ? l10n.askDiegoCloseSpeedDial
              : (primary?.tooltip ?? l10n.askDiegoTitle),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          highlightElevation: 8,
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white, width: 2),
          ),
          onPressed: _toggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isOpen
                ? const Icon(Icons.close, key: ValueKey<String>('close'))
                : useAskDiegoAsMain
                    ? const AskDiegoAvatar(
                        key: ValueKey<String>('ask-closed'),
                        size: 40,
                        backgroundColor: Colors.white,
                      )
                    : _badgedIcon(
                        key: const ValueKey<String>('open'),
                        icon: primary.icon,
                        showBadge: widget.showClosedBadge,
                        badgeColor: Colors.white,
                      ),
          ),
        ),
      ],
    );
  }

  Widget _badgedIcon({
    Key? key,
    required IconData icon,
    required bool showBadge,
    required Color badgeColor,
  }) {
    final iconWidget = Icon(icon, key: key);
    if (!showBadge) return iconWidget;
    return Badge(
      key: key,
      smallSize: 8,
      backgroundColor: badgeColor,
      child: Icon(icon),
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
    final avatar = AskDiegoAvatar(
      size: size,
      backgroundColor: mini ? Colors.white : null,
    );
    final splashColor = colors.primary.withValues(alpha: 0.15);

    const transparentFabShape = CircleBorder();

    if (mini) {
      return FloatingActionButton.small(
        heroTag: heroTag,
        tooltip: tooltip,
        onPressed: onPressed,
        backgroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 6,
        shape: CircleBorder(
          side: BorderSide(
            color: colors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
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
      elevation: 4,
      highlightElevation: 6,
      shape: CircleBorder(
        side: BorderSide(
          color: (foregroundColor ?? Colors.black).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
