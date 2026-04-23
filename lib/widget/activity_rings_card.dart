import 'dart:math' as math;
import 'package:flutter/material.dart';

class ActivityRingItem {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;
  final Color trackColor;
  final IconData? icon;

  const ActivityRingItem({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
    required this.trackColor,
    this.icon,
  });

  double get progress {
    if (goal <= 0) return 0;
    return (value / goal).clamp(0.0, 1.0);
  }

  String get formattedValue => _formatNumber(value);
  String get formattedGoal => _formatNumber(goal);

  static String _formatNumber(double n) {
    if (n == n.roundToDouble()) {
      return n.toInt().toString();
    }
    return n.toStringAsFixed(1);
  }
}

class ActivityRingsCard extends StatefulWidget {
  final String? title;
  final bool showTitle;
  final bool showLegend;
  final bool embedded;
  final List<ActivityRingItem> rings;
  final Color backgroundColor;
  final double borderRadius;
  final Duration animationDuration;
  final EdgeInsets padding;

  const ActivityRingsCard({
    super.key,
    this.title,
    this.showTitle = true,
    this.showLegend = true,
    this.embedded = false,
    required this.rings,
    this.backgroundColor = const Color(0xFF17181C),
    this.borderRadius = 20,
    this.animationDuration = const Duration(milliseconds: 900),
    this.padding = const EdgeInsets.all(12),
  }) : assert(
  rings.length >= 1 && rings.length <= 5,
  'Le nombre d’anneaux doit être compris entre 1 et 5.',
  );

  factory ActivityRingsCard.compact({
    Key? key,
    required List<ActivityRingItem> rings,
    String? title,
    Color backgroundColor = const Color(0xFF17181C),
    double borderRadius = 14,
    EdgeInsets padding = const EdgeInsets.all(8),
    Duration animationDuration = const Duration(milliseconds: 900),
  }) {
    return ActivityRingsCard(
      key: key,
      title: title,
      showTitle: false,
      showLegend: false,
      embedded: true,
      rings: rings,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      animationDuration: animationDuration,
    );
  }

  factory ActivityRingsCard.detailed({
    Key? key,
    required List<ActivityRingItem> rings,
    String? title = 'Anneaux Activité',
    bool showTitle = true,
    bool showLegend = true,
    bool embedded = false,
    Color backgroundColor = const Color(0xFF17181C),
    double borderRadius = 20,
    EdgeInsets padding = const EdgeInsets.all(12),
    Duration animationDuration = const Duration(milliseconds: 900),
  }) {
    return ActivityRingsCard(
      key: key,
      title: title,
      showTitle: showTitle,
      showLegend: showLegend,
      embedded: embedded,
      rings: rings,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      animationDuration: animationDuration,
    );
  }

  factory ActivityRingsCard.inline({
    Key? key,
    required List<ActivityRingItem> rings,
    String? title,
    Color backgroundColor = const Color(0xFF17181C),
    double borderRadius = 14,
    EdgeInsets padding = const EdgeInsets.all(10),
    Duration animationDuration = const Duration(milliseconds: 900),
    bool showTitle = false,
  }) {
    return ActivityRingsCard(
      key: key,
      title: title,
      showTitle: showTitle,
      showLegend: true,
      embedded: true,
      rings: rings,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      animationDuration: animationDuration,
    );
  }

  @override
  State<ActivityRingsCard> createState() => _ActivityRingsCardState();
}

class _ActivityRingsCardState extends State<ActivityRingsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ActivityRingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rings != widget.rings) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (widget.showLegend ? 340.0 : 140.0);

        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : (widget.embedded ? 140.0 : 260.0);

        final hasTitle = widget.showTitle &&
            widget.title != null &&
            widget.title!.trim().isNotEmpty;

        final titleHeight = hasTitle
            ? (widget.embedded ? 22.0 : 34.0)
            : 0.0;

        final titleGap = hasTitle
            ? (widget.embedded ? 8.0 : 12.0)
            : 0.0;

        final contentWidth =
        math.max(0.0, maxWidth - widget.padding.horizontal);
        final contentHeight = math.max(
          0.0,
          maxHeight - widget.padding.vertical - titleHeight - titleGap,
        );

        final horizontalLegend =
            widget.showLegend && contentWidth >= (widget.embedded ? 240 : 320);

        final ringSize = widget.showLegend
            ? (horizontalLegend
            ? math.min(
          contentHeight,
          contentWidth * (widget.embedded ? 0.34 : 0.40),
        )
            : math.min(contentWidth, contentHeight) * 0.78)
            : math.min(contentWidth, contentHeight) * 0.96;

        final rowHeight = widget.rings.isEmpty
            ? contentHeight
            : contentHeight / widget.rings.length;

        final labelFontSize = (rowHeight * 0.22).clamp(
          widget.embedded ? 10.0 : 11.0,
          widget.embedded ? 14.0 : 18.0,
        );

        final valueFontSize = (rowHeight * 0.28).clamp(
          widget.embedded ? 11.0 : 12.0,
          widget.embedded ? 18.0 : 24.0,
        );

        final unitFontSize = (rowHeight * 0.16).clamp(
          widget.embedded ? 9.0 : 10.0,
          widget.embedded ? 13.0 : 16.0,
        );

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: SizedBox(
            width: maxWidth,
            height: maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasTitle) ...[
                  Text(
                    widget.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (widget.embedded
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.headlineMedium)
                        ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: titleGap),
                ],
                Expanded(
                  child: widget.showLegend
                      ? (horizontalLegend
                      ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: ringSize,
                        height: ringSize,
                        child: _buildRingsPainter(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLegend(
                          labelFontSize: labelFontSize,
                          valueFontSize: valueFontSize,
                          unitFontSize: unitFontSize,
                        ),
                      ),
                    ],
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: ringSize,
                        height: ringSize,
                        child: _buildRingsPainter(),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _buildLegend(
                          labelFontSize: labelFontSize,
                          valueFontSize: valueFontSize,
                          unitFontSize: unitFontSize,
                        ),
                      ),
                    ],
                  ))
                      : Center(
                    child: SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: _buildRingsPainter(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRingsPainter() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _ActivityRingsPainter(
            rings: widget.rings,
            animationValue: _animation.value,
          ),
        );
      },
    );
  }

  Widget _buildLegend({
    required double labelFontSize,
    required double valueFontSize,
    required double unitFontSize,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.rings.map((ring) {
        return Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ring.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                              '${ring.formattedValue}/${ring.formattedGoal} ',
                              style: TextStyle(
                                color: ring.color,
                                fontSize: valueFontSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: ring.unit,
                              style: TextStyle(
                                color: ring.color,
                                fontSize: unitFontSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActivityRingsPainter extends CustomPainter {
  final List<ActivityRingItem> rings;
  final double animationValue;

  _ActivityRingsPainter({
    required this.rings,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final count = rings.length.clamp(1, 5);

    final gap = shortestSide * (count >= 4 ? 0.030 : 0.040);

    final rawStrokeWidth =
        ((shortestSide * 0.84) - ((count - 1) * gap)) / (count * 2.1);

    final strokeWidth = rawStrokeWidth.clamp(
      shortestSide * 0.07,
      shortestSide * 0.18,
    );

    final outerRadius = shortestSide / 2 - strokeWidth / 2 - 2;
    const startAngle = -math.pi / 2;

    for (int i = 0; i < count; i++) {
      final ring = rings[i];
      final radius = outerRadius - (i * (strokeWidth + gap));

      if (radius <= 0) continue;

      final rect = Rect.fromCircle(center: center, radius: radius);

      final trackPaint = Paint()
        ..color = ring.trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final progressPaint = Paint()
        ..color = ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        trackPaint,
      );

      final sweepAngle = 2 * math.pi * ring.progress * animationValue;

      if (sweepAngle > 0.001) {
        canvas.drawArc(
          rect,
          startAngle,
          sweepAngle,
          false,
          progressPaint,
        );
      }

      if (ring.icon != null && sweepAngle > 0.001) {
        final endAngle = startAngle + sweepAngle;
        final iconOffset = Offset(
          center.dx + radius * math.cos(endAngle),
          center.dy + radius * math.sin(endAngle),
        );

        _drawIconBadge(
          canvas,
          iconOffset,
          ring.icon!,
          ring.color,
          strokeWidth,
        );
      }
    }
  }

  void _drawIconBadge(
      Canvas canvas,
      Offset center,
      IconData icon,
      Color color,
      double ringThickness,
      ) {
    final badgeRadius = ringThickness * 0.42;

    canvas.drawCircle(
      center,
      badgeRadius,
      Paint()..color = color,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: badgeRadius,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter oldDelegate) {
    return oldDelegate.rings != rings ||
        oldDelegate.animationValue != animationValue;
  }
}