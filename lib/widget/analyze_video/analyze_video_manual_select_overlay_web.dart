import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:web/web.dart' as web;

/// Web drawing layer: a dedicated HtmlElementView above the video.
///
/// Clicks on the `video_player` platform view never reach Flutter, so the
/// box must be drawn on its own HTML canvas.
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
  static int _nextViewId = 0;

  late final String _viewType;
  late ValueChanged<PlayerDetectionBox> _onBox;
  late Color _color;
  web.HTMLCanvasElement? _canvas;
  double? _x1;
  double? _y1;
  double? _x2;
  double? _y2;

  @override
  void initState() {
    super.initState();
    _viewType = 'grinta-debug-video-label-${_nextViewId++}';
    _onBox = widget.onBox;
    _color = widget.color;
    _registerViewFactory();
  }

  @override
  void didUpdateWidget(covariant DebugVideoManualSelectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onBox = widget.onBox;
    _color = widget.color;
  }

  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final canvas = web.HTMLCanvasElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.cursor = 'crosshair'
        ..style.touchAction = 'none'
        ..style.userSelect = 'none'
        ..style.backgroundColor = 'transparent';
      _canvas = canvas;
      canvas.addEventListener(
        'pointerdown',
        ((web.Event event) {
          _onPointerDown(event as web.PointerEvent);
        }).toJS,
      );
      canvas.addEventListener(
        'pointermove',
        ((web.Event event) {
          _onPointerMove(event as web.PointerEvent);
        }).toJS,
      );
      canvas.addEventListener(
        'pointerup',
        ((web.Event event) {
          _onPointerUp(event as web.PointerEvent);
        }).toJS,
      );
      canvas.addEventListener(
        'pointercancel',
        ((web.Event event) {
          _onPointerUp(event as web.PointerEvent);
        }).toJS,
      );
      return canvas;
    });
  }

  void _syncCanvasSize(web.HTMLCanvasElement canvas) {
    final width = canvas.clientWidth.round().clamp(1, 4096);
    final height = canvas.clientHeight.round().clamp(1, 4096);
    if (canvas.width != width) canvas.width = width;
    if (canvas.height != height) canvas.height = height;
  }

  (double, double)? _normalized(web.PointerEvent event) {
    final canvas = _canvas;
    if (canvas == null) return null;
    final rect = canvas.getBoundingClientRect();
    if (rect.width <= 0 || rect.height <= 0) return null;
    return (
      ((event.clientX - rect.left) / rect.width).clamp(0.0, 1.0),
      ((event.clientY - rect.top) / rect.height).clamp(0.0, 1.0),
    );
  }

  void _onPointerDown(web.PointerEvent event) {
    if (!event.isPrimary) return;
    event.preventDefault();
    final point = _normalized(event);
    if (point == null) return;
    _x1 = point.$1;
    _y1 = point.$2;
    _x2 = point.$1;
    _y2 = point.$2;
    final canvas = _canvas;
    if (canvas != null) {
      try {
        canvas.setPointerCapture(event.pointerId);
      } catch (_) {}
    }
    _paintDraft();
  }

  void _onPointerMove(web.PointerEvent event) {
    if (_x1 == null) return;
    event.preventDefault();
    final point = _normalized(event);
    if (point == null) return;
    _x2 = point.$1;
    _y2 = point.$2;
    _paintDraft();
  }

  void _onPointerUp(web.PointerEvent event) {
    final x1 = _x1;
    final y1 = _y1;
    final x2 = _x2;
    final y2 = _y2;
    _x1 = null;
    _y1 = null;
    _x2 = null;
    _y2 = null;
    final canvas = _canvas;
    if (canvas != null) {
      try {
        canvas.releasePointerCapture(event.pointerId);
      } catch (_) {}
      final ctx = canvas.context2D;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
    }
    if (x1 == null || y1 == null || x2 == null || y2 == null) return;
    final box = playerBoxFromNormalizedDrag(x1: x1, y1: y1, x2: x2, y2: y2);
    if (box != null) _onBox(box);
  }

  void _paintDraft() {
    final canvas = _canvas;
    final x1 = _x1;
    final y1 = _y1;
    final x2 = _x2;
    final y2 = _y2;
    if (canvas == null || x1 == null || y1 == null || x2 == null || y2 == null) {
      return;
    }
    _syncCanvasSize(canvas);
    final ctx = canvas.context2D;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    final left = (x1 < x2 ? x1 : x2) * canvas.width;
    final top = (y1 < y2 ? y1 : y2) * canvas.height;
    final width = (x1 - x2).abs() * canvas.width;
    final height = (y1 - y2).abs() * canvas.height;
    ctx.fillStyle = colorToCssHex(_color).toJS;
    ctx.globalAlpha = 0.22;
    ctx.fillRect(left, top, width, height);
    ctx.globalAlpha = 1;
    ctx.strokeStyle = colorToCssHex(_color).toJS;
    ctx.lineWidth = 3;
    ctx.strokeRect(left, top, width, height);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return HtmlElementView(viewType: _viewType);
  }
}
