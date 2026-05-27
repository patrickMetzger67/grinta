part of 'field_localization_screen.dart';

class _HeaderBar extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onBack;
  final VoidCallback onValidate;

  const _HeaderBar({
    required this.isBusy,
    required this.onBack,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const Spacer(),
          FilledButton(
            onPressed: isBusy ? null : onValidate,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: colors.border,
              disabledForegroundColor: colors.textSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isBusy
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Text(
              context.l10n.actionSave,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSearch;

  const _AddressSearchField({
    required this.controller,
    required this.isSearching,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                if (!isSearching) onSearch();
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: l10n.hintSearchAddress,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: isSearching ? null : onSearch,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSearching
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(l10n.actionOk),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMapControls extends StatelessWidget {
  final int playersPerTeam;
  final VoidCallback onPreviewGps;

  const _TopMapControls({
    required this.playersPerTeam,
    required this.onPreviewGps,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _DarkMapButton(
                icon: Icons.my_location_rounded,
                label: context.l10n.fieldLocateCorners,
                onTap: onPreviewGps,
                foregroundColor: colors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldQuickControls extends StatelessWidget {
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLengthIn;
  final VoidCallback onLengthOut;
  final VoidCallback onWidthIn;
  final VoidCallback onWidthOut;
  final VoidCallback onReset;

  const _FieldQuickControls({
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLengthIn,
    required this.onLengthOut,
    required this.onWidthIn,
    required this.onWidthOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: 92,
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
              _SmallTextButton(
                label: '+',
                tooltip: l10n.fieldTooltipZoomIn,
                onPressed: onZoomIn,
              ),
              _SmallTextButton(
                label: '-',
                tooltip: l10n.fieldTooltipZoomOut,
                onPressed: onZoomOut,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallTextButton(
                label: 'L+',
                tooltip: l10n.fieldTooltipLengthUp,
                onPressed: onLengthIn,
              ),
              _SmallTextButton(
                label: 'L-',
                tooltip: l10n.fieldTooltipLengthDown,
                onPressed: onLengthOut,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallTextButton(
                label: 'l+',
                tooltip: l10n.fieldTooltipWidthUp,
                onPressed: onWidthIn,
              ),
              _SmallTextButton(
                label: 'l-',
                tooltip: l10n.fieldTooltipWidthDown,
                onPressed: onWidthOut,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallIconButton(
                icon: Icons.rotate_left,
                tooltip: l10n.fieldTooltipRotateLeft,
                onPressed: onRotateLeft,
              ),
              _SmallIconButton(
                icon: Icons.rotate_right,
                tooltip: l10n.fieldTooltipRotateRight,
                onPressed: onRotateRight,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _SmallIconButton(
            icon: Icons.refresh,
            tooltip: l10n.actionReset,
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

class _FieldGestureHint extends StatelessWidget {
  final bool fieldEditMode;
  final VoidCallback onToggleMode;

  const _FieldGestureHint({
    required this.fieldEditMode,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              fieldEditMode
                  ? l10n.fieldHelpGestures
                  : l10n.fieldMapModeHelp,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggleMode,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: fieldEditMode ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  fieldEditMode ? Icons.touch_app_rounded : Icons.map_rounded,
                  color: fieldEditMode ? Colors.white : colors.primary,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  fieldEditMode ? l10n.entityField : l10n.entityMap,
                  style: TextStyle(
                    color: fieldEditMode ? Colors.white : colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomMapControls extends StatelessWidget {
  final MapType mapType;
  final VoidCallback onToggleMapType;
  final VoidCallback onLocate;

  const _BottomMapControls({
    required this.mapType,
    required this.onToggleMapType,
    required this.onLocate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SmallIconButton(
                icon: Icons.map_outlined,
                tooltip: context.l10n.fieldTooltipMap,
                isSelected: mapType == MapType.normal,
                onPressed: onToggleMapType,
              ),
              _SmallIconButton(
                icon: Icons.satellite_alt_rounded,
                tooltip: context.l10n.fieldTooltipSatellite,
                isSelected: mapType != MapType.normal,
                onPressed: onToggleMapType,
              ),
            ],
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onLocate,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.navigation_rounded,
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkMapButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? foregroundColor;

  const _DarkMapButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = foregroundColor ?? Colors.white;

    return Material(
      color: Colors.black.withValues(alpha: 0.68),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: effectiveColor),
              const SizedBox(width: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 11,
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

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSelected;
  final String? tooltip;

  const _SmallIconButton({
    required this.icon,
    required this.onPressed,
    this.isSelected = false,
    this.tooltip,
  });

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
          color: isSelected
              ? colors.primary.withValues(alpha: 0.24)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? colors.primary : Colors.white,
          size: 18,
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

class _SmallTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final String? tooltip;

  const _SmallTextButton({
    required this.label,
    required this.onPressed,
    this.tooltip,
  });

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
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
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

class _GeometrySummary extends StatelessWidget {
  final FieldGeometry geometry;

  const _GeometrySummary({required this.geometry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget item(String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    final l10n = context.l10n;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        item(
          l10n.fieldAverageLength,
          '${geometry.averageLengthMeters.toStringAsFixed(1)} m',
        ),
        item(
          l10n.fieldAverageWidth,
          '${geometry.averageWidthMeters.toStringAsFixed(1)} m',
        ),
        item(
          l10n.fieldSideLeft,
          '${geometry.leftLengthMeters.toStringAsFixed(1)} m',
        ),
        item(
          l10n.fieldSideRight,
          '${geometry.rightLengthMeters.toStringAsFixed(1)} m',
        ),
      ],
    );
  }
}

class _FootballPitchPainter extends CustomPainter {
  final Color lineColor;
  final Color fillColor;
  final String label;
  final Color labelColor;

  const _FootballPitchPainter({
    required this.lineColor,
    required this.fillColor,
    required this.label,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;

    final boldLinePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    final fieldRect = rect.deflate(1.2);

    canvas.drawRect(fieldRect, fillPaint);
    canvas.drawRect(fieldRect, boldLinePaint);

    final w = size.width;
    final h = size.height;

    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), linePaint);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.145, linePaint);
    canvas.drawCircle(Offset(w / 2, h / 2), 1.8, Paint()..color = lineColor);

    final penaltyWidth = w * 0.62;
    final penaltyDepth = h * 0.155;
    final goalAreaWidth = w * 0.34;
    final goalAreaDepth = h * 0.06;

    final topPenalty = Rect.fromLTWH(
      (w - penaltyWidth) / 2,
      0,
      penaltyWidth,
      penaltyDepth,
    );
    final bottomPenalty = Rect.fromLTWH(
      (w - penaltyWidth) / 2,
      h - penaltyDepth,
      penaltyWidth,
      penaltyDepth,
    );

    final topGoalArea = Rect.fromLTWH(
      (w - goalAreaWidth) / 2,
      0,
      goalAreaWidth,
      goalAreaDepth,
    );
    final bottomGoalArea = Rect.fromLTWH(
      (w - goalAreaWidth) / 2,
      h - goalAreaDepth,
      goalAreaWidth,
      goalAreaDepth,
    );

    canvas.drawRect(topPenalty, linePaint);
    canvas.drawRect(bottomPenalty, linePaint);
    canvas.drawRect(topGoalArea, linePaint);
    canvas.drawRect(bottomGoalArea, linePaint);

    canvas.drawCircle(
      Offset(w / 2, penaltyDepth * 0.68),
      1.4,
      Paint()..color = lineColor,
    );
    canvas.drawCircle(
      Offset(w / 2, h - penaltyDepth * 0.68),
      1.4,
      Paint()..color = lineColor,
    );

    final arcRadius = w * 0.14;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(w / 2, penaltyDepth * 0.68),
        radius: arcRadius,
      ),
      math.pi * 0.18,
      math.pi * 0.64,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(w / 2, h - penaltyDepth * 0.68),
        radius: arcRadius,
      ),
      -math.pi * 0.82,
      math.pi * 0.64,
      false,
      linePaint,
    );

    final goalWidth = w * 0.2;
    canvas.drawLine(
      Offset((w - goalWidth) / 2, 0),
      Offset((w + goalWidth) / 2, 0),
      boldLinePaint,
    );
    canvas.drawLine(
      Offset((w - goalWidth) / 2, h),
      Offset((w + goalWidth) / 2, h),
      boldLinePaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          shadows: const [
            Shadow(
              blurRadius: 3,
              color: Colors.black54,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (w - textPainter.width) / 2,
        h / 2 + 8,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _FootballPitchPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.label != label ||
        oldDelegate.labelColor != labelColor;
  }
}
class _AddressPreviewCard extends StatelessWidget {
  final String? address;

  const _AddressPreviewCard({
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    final hasAddress = address != null && address!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: colors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.fieldEstimatedAddress,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  hasAddress
                      ? address!
                      : l10n.fieldAddressUnavailable,
                  style: TextStyle(
                    color: hasAddress
                        ? colors.textPrimary
                        : colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}