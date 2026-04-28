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
    return n.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class ActivityRingsCard extends StatefulWidget {
  /// Conservé pour compatibilité, mais non affiché.
  final String? title;

  /// Conservé pour compatibilité, mais non utilisé.
  final bool showTitle;

  final bool showLegend;
  final bool embedded;

  /// Workload optionnel.
  final bool showWorkload;
  final double? workloadScore;
  final String workloadLabel;
  final String workloadUnit;
  final Color workloadColor;

  final List<ActivityRingItem> rings;
  final Color backgroundColor;
  final double borderRadius;
  final Duration animationDuration;
  final EdgeInsets padding;

  const ActivityRingsCard({
    super.key,
    this.title,
    this.showTitle = false,
    this.showLegend = true,
    this.embedded = false,
    this.showWorkload = false,
    this.workloadScore,
    this.workloadLabel = 'Workload',
    this.workloadUnit = '',
    this.workloadColor = Colors.white,
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
    bool showWorkload = false,
    double? workloadScore,
    String workloadLabel = 'Workload',
    String workloadUnit = '',
    Color workloadColor = Colors.white,
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
      showWorkload: showWorkload,
      workloadScore: workloadScore,
      workloadLabel: workloadLabel,
      workloadUnit: workloadUnit,
      workloadColor: workloadColor,
    );
  }

  factory ActivityRingsCard.detailed({
    Key? key,
    required List<ActivityRingItem> rings,
    String? title,
    bool showTitle = false,
    bool showLegend = true,
    bool embedded = false,
    Color backgroundColor = const Color(0xFF17181C),
    double borderRadius = 20,
    EdgeInsets padding = const EdgeInsets.all(12),
    Duration animationDuration = const Duration(milliseconds: 900),
    bool showWorkload = false,
    double? workloadScore,
    String workloadLabel = 'Workload',
    String workloadUnit = '',
    Color workloadColor = Colors.white,
  }) {
    return ActivityRingsCard(
      key: key,
      title: title,
      showTitle: false,
      showLegend: showLegend,
      embedded: embedded,
      rings: rings,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      animationDuration: animationDuration,
      showWorkload: showWorkload,
      workloadScore: workloadScore,
      workloadLabel: workloadLabel,
      workloadUnit: workloadUnit,
      workloadColor: workloadColor,
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
    bool showLegend = true,
    bool showWorkload = false,
    double? workloadScore,
    String workloadLabel = 'Workload',
    String workloadUnit = '',
    Color workloadColor = Colors.white,
  }) {
    return ActivityRingsCard(
      key: key,
      title: title,
      showTitle: false,
      showLegend: showLegend,
      embedded: true,
      rings: rings,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      animationDuration: animationDuration,
      showWorkload: showWorkload,
      workloadScore: workloadScore,
      workloadLabel: workloadLabel,
      workloadUnit: workloadUnit,
      workloadColor: workloadColor,
    );
  }

  @override
  State<ActivityRingsCard> createState() => _ActivityRingsCardState();
}

class _ActivityRingsCardState extends State<ActivityRingsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  String get _formattedWorkloadScore {
    final score = widget.workloadScore ?? 0;
    return score.toStringAsFixed(2).replaceAll('.', ',');
  }

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

    if (oldWidget.rings != widget.rings ||
        oldWidget.workloadScore != widget.workloadScore) {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (widget.embedded ? 260.0 : 360.0);

        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : (widget.embedded ? 90.0 : 120.0);

        final contentWidth = math.max(
          0.0,
          maxWidth - widget.padding.horizontal,
        );

        final contentHeight = math.max(
          0.0,
          maxHeight - widget.padding.vertical,
        );

        final hasWorkload =
            widget.showWorkload && widget.workloadScore != null;

        final hasLegend = widget.showLegend && widget.rings.isNotEmpty;

        final isTiny = contentWidth < 150 || contentHeight < 55;
        final gap = isTiny ? 4.0 : 10.0;

        return SizedBox(
          width: constraints.hasBoundedWidth ? double.infinity : maxWidth,
          height: constraints.hasBoundedHeight ? double.infinity : maxHeight,
          child: Container(
            padding: widget.padding,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasWorkload) ...[
                  Expanded(
                    flex: hasLegend ? 32 : 40,
                    child: _buildWorkloadColumn(),
                  ),
                  SizedBox(width: gap),
                ],

                Expanded(
                  flex: hasLegend ? 28 : 60,
                  child: _buildRingsColumn(),
                ),

                if (hasLegend) ...[
                  SizedBox(width: gap),
                  Expanded(
                    flex: hasWorkload ? 40 : 48,
                    child: _buildLegendColumn(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkloadColumn() {
    final labelFontSize = widget.embedded ? 9.0 : 11.0;
    final scoreFontSize = widget.embedded ? 20.0 : 28.0;
    final unitFontSize = widget.embedded ? 9.0 : 12.0;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.workloadLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            RichText(
              maxLines: 1,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _formattedWorkloadScore,
                    style: TextStyle(
                      color: widget.workloadColor,
                      fontSize: scoreFontSize,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  if (widget.workloadUnit.trim().isNotEmpty)
                    TextSpan(
                      text: ' ${widget.workloadUnit}',
                      style: TextStyle(
                        color: widget.workloadColor,
                        fontSize: unitFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingsColumn() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ringSize = math.max(
          0.0,
          math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          ),
        );

        return Center(
          child: SizedBox(
            width: ringSize,
            height: ringSize,
            child: _buildRingsPainter(),
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

  Widget _buildLegendColumn() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowHeight = widget.rings.isEmpty
            ? constraints.maxHeight
            : constraints.maxHeight / widget.rings.length;

        final dotSize = (rowHeight * 0.22).clamp(4.0, 9.0).toDouble();

        final labelFontSize = (rowHeight * 0.24).clamp(
          widget.embedded ? 7.0 : 9.0,
          widget.embedded ? 12.0 : 15.0,
        ).toDouble();

        final valueFontSize = (rowHeight * 0.28).clamp(
          widget.embedded ? 8.0 : 10.0,
          widget.embedded ? 13.0 : 17.0,
        ).toDouble();

        final unitFontSize = (rowHeight * 0.20).clamp(
          widget.embedded ? 7.0 : 8.0,
          widget.embedded ? 11.0 : 13.0,
        ).toDouble();

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.rings.map((ring) {
            return Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    SizedBox(
                      width: dotSize,
                      height: dotSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: ring.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

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

                    const SizedBox(width: 6),

                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: RichText(
                          maxLines: 1,
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
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
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
    if (size.width <= 0 || size.height <= 0 || rings.isEmpty) return;

    final shortestSide = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final count = rings.length.clamp(1, 5).toInt();

    final gap = shortestSide * (count >= 4 ? 0.030 : 0.040);

    final rawStrokeWidth =
        ((shortestSide * 0.84) - ((count - 1) * gap)) / (count * 2.1);

    final strokeWidth = rawStrokeWidth.clamp(
      shortestSide * 0.07,
      shortestSide * 0.18,
    ).toDouble();

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