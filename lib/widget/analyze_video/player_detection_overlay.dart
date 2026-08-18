import 'package:flutter/material.dart';
import 'package:grinta/services/analyze_player_detection.dart';

class PlayerDetectionOverlayPainter extends CustomPainter {
  const PlayerDetectionOverlayPainter({
    required this.boxes,
    required this.color,
    this.associatedColor,
    this.draftBox,
    this.draftColor = Colors.white,
  });

  final List<PlayerDetectionBox> boxes;
  final Color color;
  final Color? associatedColor;
  final PlayerDetectionBox? draftBox;
  final Color draftColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final box in boxes) {
      final rect = Rect.fromLTWH(
        box.left * size.width,
        box.top * size.height,
        box.width * size.width,
        box.height * size.height,
      );
      if (rect.width < 2 || rect.height < 2) continue;
      if (box.kind == PlayerDetectionKind.ball) continue;
      if ((box.playerId ?? '').trim().isEmpty) continue;
      paint.color = associatedColor ?? color;
      paint.strokeWidth = 3;
      if (box.circular) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRect(rect, paint);
      }
    }
    final draft = draftBox;
    if (draft != null) {
      final rect = Rect.fromLTWH(
        draft.left * size.width,
        draft.top * size.height,
        draft.width * size.width,
        draft.height * size.height,
      );
      if (rect.width >= 2 && rect.height >= 2) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = draftColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PlayerDetectionOverlayPainter oldDelegate) {
    return oldDelegate.boxes != boxes ||
        oldDelegate.color != color ||
        oldDelegate.associatedColor != associatedColor ||
        oldDelegate.draftBox != draftBox ||
        oldDelegate.draftColor != draftColor;
  }
}

class PlayerDetectionOverlay extends StatelessWidget {
  const PlayerDetectionOverlay({
    super.key,
    required this.boxes,
    required this.color,
    this.associatedColor,
    this.draftBox,
    this.draftColor = Colors.white,
    this.onDraftMoved,
  });

  final List<PlayerDetectionBox> boxes;
  final Color color;
  final Color? associatedColor;
  final PlayerDetectionBox? draftBox;
  final Color draftColor;
  final ValueChanged<PlayerDetectionBox>? onDraftMoved;

  @override
  Widget build(BuildContext context) {
    if (boxes.isEmpty && draftBox == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: CustomPaint(
                painter: PlayerDetectionOverlayPainter(
                  boxes: boxes,
                  color: color,
                  associatedColor: associatedColor,
                  draftBox: onDraftMoved == null ? draftBox : null,
                  draftColor: draftColor,
                ),
                size: size,
              ),
            ),
            if (draftBox != null && onDraftMoved != null)
              _DraftFrameDragLayer(
                box: draftBox!,
                size: size,
                onMoved: onDraftMoved!,
              ),
          ],
        );
      },
    );
  }
}

class _DraftFrameDragLayer extends StatefulWidget {
  const _DraftFrameDragLayer({
    required this.box,
    required this.size,
    required this.onMoved,
  });

  final PlayerDetectionBox box;
  final Size size;
  final ValueChanged<PlayerDetectionBox> onMoved;

  @override
  State<_DraftFrameDragLayer> createState() => _DraftFrameDragLayerState();
}

class _DraftFrameDragLayerState extends State<_DraftFrameDragLayer> {
  bool _dragging = false;
  bool _hovering = false;
  Offset? _start;
  double _originLeft = 0;
  double _originTop = 0;

  Rect _frameRect() {
    return Rect.fromLTWH(
      widget.box.left * widget.size.width,
      widget.box.top * widget.size.height,
      widget.box.width * widget.size.width,
      widget.box.height * widget.size.height,
    ).inflate(10);
  }

  bool _hits(Offset local) => _frameRect().contains(local);

  @override
  Widget build(BuildContext context) {
    if (widget.size.isEmpty) return const SizedBox.shrink();
    final rect = Rect.fromLTWH(
      widget.box.left * widget.size.width,
      widget.box.top * widget.size.height,
      widget.box.width * widget.size.width,
      widget.box.height * widget.size.height,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(
          rect: rect,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                color: Colors.white.withValues(alpha: 0.14),
              ),
              child: const Center(
                child: Icon(Icons.open_with, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
        MouseRegion(
          cursor: _dragging || _hovering
              ? SystemMouseCursors.move
              : SystemMouseCursors.basic,
          onHover: (event) {
            final over = _hits(event.localPosition);
            if (over != _hovering) setState(() => _hovering = over);
          },
          onExit: (_) {
            if (_hovering && !_dragging) setState(() => _hovering = false);
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              if (!_hits(event.localPosition)) return;
              _dragging = true;
              _start = event.localPosition;
              _originLeft = widget.box.left;
              _originTop = widget.box.top;
            },
            onPointerMove: (event) {
              if (!_dragging || _start == null || widget.size.isEmpty) return;
              widget.onMoved(
                moveManualPlayerFrame(
                  widget.box.copyWith(left: _originLeft, top: _originTop),
                  dx: (event.localPosition.dx - _start!.dx) / widget.size.width,
                  dy: (event.localPosition.dy - _start!.dy) / widget.size.height,
                ),
              );
            },
            onPointerUp: (_) {
              _dragging = false;
              _start = null;
            },
            onPointerCancel: (_) {
              _dragging = false;
              _start = null;
            },
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}
