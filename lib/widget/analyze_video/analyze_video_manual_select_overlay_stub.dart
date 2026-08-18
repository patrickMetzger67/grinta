import 'package:flutter/material.dart';
import 'package:grinta/services/analyze_player_detection.dart';

class DebugVideoManualSelectOverlay extends StatefulWidget {
  const DebugVideoManualSelectOverlay({
    super.key,
    required this.enabled,
    required this.onBox,
    this.color = const Color(0xFF1FA971),
  });

  final bool enabled;
  final ValueChanged<PlayerDetectionBox> onBox;
  final Color color;

  @override
  State<DebugVideoManualSelectOverlay> createState() =>
      _DebugVideoManualSelectOverlayState();
}

class _DebugVideoManualSelectOverlayState
    extends State<DebugVideoManualSelectOverlay> {
  Offset? _start;
  Offset? _current;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          cursor: SystemMouseCursors.precise,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              setState(() {
                _start = event.localPosition;
                _current = event.localPosition;
              });
            },
            onPointerMove: (event) {
              if (_start == null) return;
              setState(() => _current = event.localPosition);
            },
            onPointerUp: (_) => _finish(size),
            onPointerCancel: (_) => setState(() {
              _start = null;
              _current = null;
            }),
            child: CustomPaint(
              painter: _DraftBoxPainter(
                start: _start,
                current: _current,
                color: widget.color,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  void _finish(Size size) {
    final start = _start;
    final current = _current;
    setState(() {
      _start = null;
      _current = null;
    });
    if (start == null || current == null || size.isEmpty) return;
    final box = playerBoxFromNormalizedCircle(
      cx: start.dx / size.width,
      cy: start.dy / size.height,
      edgeX: current.dx / size.width,
      edgeY: current.dy / size.height,
      aspectRatio: size.width / size.height,
    );
    if (box != null) widget.onBox(box);
  }
}

class _DraftBoxPainter extends CustomPainter {
  const _DraftBoxPainter({
    required this.start,
    required this.current,
    required this.color,
  });

  final Offset? start;
  final Offset? current;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || current == null) return;
    final radius = (current! - start!).distance;
    if (radius < 3) return;
    final circle = Rect.fromCircle(center: start!, radius: radius);
    canvas.drawOval(
      circle,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      circle,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _DraftBoxPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.current != current ||
        oldDelegate.color != color;
  }
}
