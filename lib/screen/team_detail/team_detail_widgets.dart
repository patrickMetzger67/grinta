part of 'team_detail_screen.dart';

class TeamThresholdCardData {
  const TeamThresholdCardData({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class _TeamMemberVm {
  const _TeamMemberVm({
    required this.player,
    required this.effectives,
    required this.trackers,
    this.grintaPositions = const <int>[],
    this.grintaFonction,
    this.isGrintaRoster = false,
    this.grintaEmail,
    this.grintaPhoneE164,
    this.grintaBirthday,
    this.grintaHeightCm,
    this.grintaWeightKg,
    this.grintaInvitationId,
    this.invitationAccepted,
  });

  final Player player;
  final Effectives? effectives;
  final List<_TrackerChipVm> trackers;
  final List<int> grintaPositions;
  final int? grintaFonction;
  final bool isGrintaRoster;
  final String? grintaEmail;
  final String? grintaPhoneE164;
  final DateTime? grintaBirthday;
  final int? grintaHeightCm;
  final double? grintaWeightKg;
  final String? grintaInvitationId;
  final bool? invitationAccepted;
}

class _TrackerChipVm {
  const _TrackerChipVm({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

/// Responsive column plan for the mobile player roster table.
class _MobileRosterLayout {
  const _MobileRosterLayout({
    required this.showPositionColumn,
    required this.showInlineEditColumn,
    required this.playerFlex,
  });

  final bool showPositionColumn;
  final bool showInlineEditColumn;
  final int playerFlex;

  static _MobileRosterLayout fromWidth(
    double width, {
    required bool canManageTeam,
    required bool canManageRoster,
  }) {
    final bool showPosition = width >= 360;
    final bool showInlineEdit = !canManageRoster || width >= 380;
    final int playerFlex = width < 360 ? 5 : 4;

    return _MobileRosterLayout(
      showPositionColumn: showPosition,
      showInlineEditColumn: showInlineEdit,
      playerFlex: playerFlex,
    );
  }
}



class _TrackerChip extends StatelessWidget {
  const _TrackerChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 180,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF232A3B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFFFFB27A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeaderSquareIconButton extends StatelessWidget {
  const _HeaderSquareIconButton({
    required this.icon,
    required this.onTap,
    this.size = 50,
    this.iconSize = 24,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF232A3B),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}

class _CircleGhostButton extends StatelessWidget {
  const _CircleGhostButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.size = 34,
    this.iconSize = 18,
    this.tooltip,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool enabled;

  static const double webTableButtonSize = 28;
  static const double webTableIconSize = 17;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final Color resolvedIconColor = !enabled
        ? colors.textSecondary.withValues(alpha: 0.35)
        : iconColor ?? colors.textSecondary;

    Widget button = InkWell(
      onTap: enabled ? onTap : null,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.border,
          ),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: resolvedIconColor,
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

class _ThresholdCard extends StatelessWidget {
  const _ThresholdCard({
    required this.data,
  });

  final TeamThresholdCardData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF232A3B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            data.value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFFFB27A),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPlayerSwipeRow extends StatefulWidget {
  const _TeamPlayerSwipeRow({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.onEdit,
    this.onRemove,
    required this.editLabel,
    required this.removeLabel,
  });

  final Widget child;
  final Color backgroundColor;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final String editLabel;
  final String removeLabel;

  bool get canSwipe => onEdit != null || onRemove != null;

  @override
  State<_TeamPlayerSwipeRow> createState() => _TeamPlayerSwipeRowState();
}

class _TeamPlayerSwipeRowState extends State<_TeamPlayerSwipeRow> {
  static const double _actionWidth = 80;
  static const double _directionLockThreshold = 10;

  double _offset = 0;
  ScrollHoldController? _scrollHold;
  Offset? _dragStartPosition;
  bool _horizontalDragActive = false;

  double get _maxOffset {
    var width = 0.0;
    if (widget.onEdit != null) {
      width += _actionWidth;
    }
    if (widget.onRemove != null) {
      width += _actionWidth;
    }
    return width;
  }

  void _onScrollHoldCanceled() {
    _scrollHold = null;
  }

  void _releaseScrollHold() {
    final ScrollHoldController? hold = _scrollHold;
    _scrollHold = null;
    hold?.cancel();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStartPosition = details.globalPosition;
    _horizontalDragActive = false;
    _releaseScrollHold();
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    _scrollHold = scrollable?.position.hold(_onScrollHoldCanceled);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_horizontalDragActive && _dragStartPosition != null) {
      final Offset delta = details.globalPosition - _dragStartPosition!;
      if (delta.distance < _directionLockThreshold) {
        return;
      }
      if (delta.dx.abs() <= delta.dy.abs()) {
        _releaseScrollHold();
        _dragStartPosition = null;
        return;
      }
      _horizontalDragActive = true;
    }

    if (!_horizontalDragActive) {
      return;
    }

    setState(() {
      _offset = (_offset - details.delta.dx).clamp(0.0, _maxOffset);
    });
  }

  void _snapOffset({double? velocity}) {
    final threshold = _maxOffset / 2;
    final bool openByVelocity =
        velocity != null && velocity < -300 && _offset > 0;
    final bool closeByVelocity =
        velocity != null && velocity > 300 && _offset < _maxOffset;

    setState(() {
      if (openByVelocity) {
        _offset = _maxOffset;
      } else if (closeByVelocity) {
        _offset = 0;
      } else {
        _offset = _offset > threshold ? _maxOffset : 0;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_horizontalDragActive || (_offset > 0 && _offset < _maxOffset)) {
      _snapOffset(velocity: details.primaryVelocity);
    }
    _dragStartPosition = null;
    _horizontalDragActive = false;
    _releaseScrollHold();
  }

  void _onHorizontalDragCancel() {
    if (_offset > 0 && _offset < _maxOffset) {
      _snapOffset();
    }
    _dragStartPosition = null;
    _horizontalDragActive = false;
    _releaseScrollHold();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (_offset <= 0) {
      return false;
    }
    if (notification is ScrollUpdateNotification ||
        notification is ScrollStartNotification) {
      _close();
    }
    return false;
  }

  void _close() {
    if (_offset > 0) {
      setState(() => _offset = 0);
    }
  }

  Widget _buildSwipeActions(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onEdit != null)
          _SwipeActionButton(
            width: _actionWidth,
            color: context.appColors.primary,
            icon: Icons.edit_outlined,
            label: widget.editLabel,
            onTap: () {
              _close();
              widget.onEdit!();
            },
          ),
        if (widget.onRemove != null)
          _SwipeActionButton(
            width: _actionWidth,
            color: context.appColors.danger,
            icon: Icons.delete_outline_rounded,
            label: widget.removeLabel,
            onTap: () {
              _close();
              widget.onRemove!();
            },
          ),
      ],
    );
  }

  @override
  void dispose() {
    _releaseScrollHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canSwipe) {
      return widget.child;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (_offset > 0)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: _offset,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerRight,
                    maxWidth: _maxOffset,
                    child: SizedBox(
                      width: _maxOffset,
                      child: _buildSwipeActions(context),
                    ),
                  ),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onHorizontalDragCancel: _onHorizontalDragCancel,
              onTap: _close,
              child: Transform.translate(
                offset: Offset(-_offset, 0),
                child: ColoredBox(
                  color: widget.backgroundColor,
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.width,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactIconCell extends StatelessWidget {
  const _CompactIconCell({
    required this.child,
    this.width = 26,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: width,
          height: width,
          child: Center(child: child),
        ),
      ),
    );
  }
}
