import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

enum PitchViewMode { fullLandscape, topHalfPortrait, fullPortrait }

class PitchPolyline {
  final List<Offset> pointsM;
  final List<double>? segmentIntensity01;
  final double strokeWidth;
  final bool showArrow;
  final bool showStartEndDots;

  const PitchPolyline({
    required this.pointsM,
    this.segmentIntensity01,
    this.strokeWidth = 3,
    this.showArrow = true,
    this.showStartEndDots = true,
  });
}

class PitchHeatmap {
  final int rows;
  final int cols;
  final List<double> values;
  final double blurSigma;
  final double opacity;

  const PitchHeatmap({
    required this.rows,
    required this.cols,
    required this.values,
    this.blurSigma = 10,
    this.opacity = 0.55,
  }) : assert(values.length == rows * cols);
}

class ProPitchView extends StatelessWidget {
  final double pitchWidthM; // 105
  final double pitchHeightM; // 68
  final EdgeInsets padding;
  final PitchViewMode mode;
  final PitchHeatmap? heatmap;
  final List<PitchPolyline> polylines;
  final bool flipY;

  const ProPitchView({
    super.key,
    this.pitchWidthM = 105,
    this.pitchHeightM = 68,
    this.padding = EdgeInsets.zero,
    this.mode = PitchViewMode.fullLandscape,
    this.heatmap,
    this.polylines = const [],
    this.flipY = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => CustomPaint(
        size: Size(c.maxWidth, c.maxHeight),
        painter: _ProPitchPainter(
          pitchWidthM: pitchWidthM,
          pitchHeightM: pitchHeightM,
          padding: padding,
          mode: mode,
          heatmap: heatmap,
          polylines: polylines,
          flipY: flipY,
        ),
      ),
    );
  }
}

class _ProPitchPainter extends CustomPainter {
  final double pitchWidthM;
  final double pitchHeightM;
  final EdgeInsets padding;
  final PitchViewMode mode;
  final PitchHeatmap? heatmap;
  final List<PitchPolyline> polylines;
  final bool flipY;

  _ProPitchPainter({
    required this.pitchWidthM,
    required this.pitchHeightM,
    required this.padding,
    required this.mode,
    required this.heatmap,
    required this.polylines,
    required this.flipY,
  });

  double get _halfLenM => pitchWidthM / 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final dims = _modeDimsM();
    final rect = _fitRect(size, padding, dims.dx, dims.dy);

    _drawPitchBackground(canvas, rect);

    if (mode == PitchViewMode.fullLandscape) {
      _drawFullLandscapeMarkings(canvas, rect);
    } else if (mode == PitchViewMode.topHalfPortrait) {
      _drawTopHalfPortraitMarkings(canvas, rect);
    } else {
      _drawFullPortraitMarkings(canvas, rect);
    }

    if (heatmap != null) {
      _drawHeatmap(canvas, rect, heatmap!);
    }

    for (final pl in polylines) {
      _drawPolyline(canvas, rect, pl);
    }

    _drawBorder(canvas, rect);
  }

  Offset _modeDimsM() {
    if (mode == PitchViewMode.fullLandscape) {
      return Offset(pitchWidthM, pitchHeightM); // 105 x 68
    }
    if (mode == PitchViewMode.topHalfPortrait) {
      return Offset(pitchHeightM, _halfLenM); // 68 x 52.5
    }
    return Offset(pitchHeightM, pitchWidthM); // 68 x 105
  }

  Rect _fitRect(Size size, EdgeInsets pad, double wM, double hM) {
    final usableW = max(1.0, size.width - pad.left - pad.right);
    final usableH = max(1.0, size.height - pad.top - pad.bottom);

    final sx = usableW / wM;
    final sy = usableH / hM;
    final s = min(sx, sy);

    final w = wM * s;
    final h = hM * s;

    final left = pad.left + (usableW - w) / 2.0;
    final top = pad.top + (usableH - h) / 2.0;

    return Rect.fromLTWH(left, top, w, h);
  }

  Offset _mToPx(Rect rect, Offset m) {
    if (mode == PitchViewMode.fullPortrait) {
      final xNorm = m.dy / pitchHeightM;
      final yNorm = m.dx / pitchWidthM;

      final x = rect.left + xNorm * rect.width;
      final y = rect.top + ((flipY ? (1.0 - yNorm) : yNorm) * rect.height);

      return Offset(x, y);
    }

    final dims = _modeDimsM();
    final wM = dims.dx;
    final hM = dims.dy;

    final x = rect.left + (m.dx / wM) * rect.width;
    final yNorm = (m.dy / hM);
    final y = rect.top + ((flipY ? (1.0 - yNorm) : yNorm) * rect.height);

    return Offset(x, y);
  }

  void _drawPitchBackground(Canvas canvas, Rect rect) {
    final grassShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF1F6B3C),
        Color(0xFF2E8B57),
        Color(0xFF1F6B3C),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = grassShader);

    final stripeCount = 10;
    final stripeW = rect.width / stripeCount;
    final stripePaint = Paint()..color = const Color(0x0FFFFFFF);

    for (int i = 0; i < stripeCount; i++) {
      if (i.isOdd) {
        canvas.drawRect(
          Rect.fromLTWH(rect.left + i * stripeW, rect.top, stripeW, rect.height),
          stripePaint,
        );
      }
    }

    final vignette = RadialGradient(
      center: Alignment.center,
      radius: 0.9,
      colors: const [Color(0x00000000), Color(0x33000000)],
      stops: const [0.65, 1.0],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = vignette);
  }

  Paint _linePaint(Rect rect) => Paint()
    ..color = const Color(0xEFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.5, rect.shortestSide * 0.004);

  void _drawFullLandscapeMarkings(Canvas canvas, Rect rect) {
    final lp = _linePaint(rect);

    canvas.drawRect(rect, lp);

    canvas.drawLine(
      Offset(rect.left + rect.width / 2, rect.top),
      Offset(rect.left + rect.width / 2, rect.bottom),
      lp,
    );

    final center = rect.center;
    final r = (9.15 / pitchHeightM) * rect.height;
    canvas.drawCircle(center, r, lp);

    canvas.drawCircle(center, lp.strokeWidth * 0.9, Paint()..color = lp.color);

    _drawFullBoxes(canvas, rect, lp);
    _drawPenaltySpotFull(canvas, rect, left: true, paint: lp);
    _drawPenaltySpotFull(canvas, rect, left: false, paint: lp);

    _drawCornerArc(canvas, rect, paint: lp, isLeft: true, isTop: true);
    _drawCornerArc(canvas, rect, paint: lp, isLeft: true, isTop: false);
    _drawCornerArc(canvas, rect, paint: lp, isLeft: false, isTop: true);
    _drawCornerArc(canvas, rect, paint: lp, isLeft: false, isTop: false);
  }

  void _drawFullBoxes(Canvas canvas, Rect rect, Paint paint) {
    _drawFullBox(canvas, rect, paint, depthM: 16.5, widthM: 40.3);
    _drawFullBox(canvas, rect, paint, depthM: 5.5, widthM: 18.32);
  }

  void _drawFullBox(Canvas canvas, Rect rect, Paint paint,
      {required double depthM, required double widthM}) {
    final depthPx = (depthM / pitchWidthM) * rect.width;
    final boxHeightPx = (widthM / pitchHeightM) * rect.height;

    final top = rect.top + (rect.height - boxHeightPx) / 2;
    final bottom = top + boxHeightPx;

    canvas.drawRect(Rect.fromLTRB(rect.left, top, rect.left + depthPx, bottom), paint);
    canvas.drawRect(Rect.fromLTRB(rect.right - depthPx, top, rect.right, bottom), paint);
  }

  void _drawPenaltySpotFull(Canvas canvas, Rect rect, {required bool left, required Paint paint}) {
    final x = left
        ? rect.left + (11.0 / pitchWidthM) * rect.width
        : rect.right - (11.0 / pitchWidthM) * rect.width;
    canvas.drawCircle(Offset(x, rect.center.dy), paint.strokeWidth * 0.9, Paint()..color = paint.color);
  }

  void _drawTopHalfPortraitMarkings(Canvas canvas, Rect rect) {
    final lp = _linePaint(rect);

    canvas.drawRect(rect, lp);

    final wM = pitchHeightM;
    final hM = _halfLenM;

    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.right, rect.bottom), lp);

    final centerX = rect.left + rect.width / 2;
    final centerY = rect.bottom;
    final rPx = (9.15 / wM) * rect.width;
    final arcRect = Rect.fromCircle(center: Offset(centerX, centerY), radius: rPx);
    canvas.drawArc(arcRect, pi, pi, false, lp);

    canvas.drawCircle(Offset(centerX, centerY), lp.strokeWidth * 0.9, Paint()..color = lp.color);

    _drawTopHalfBoxes(canvas, rect, lp, wM: wM, hM: hM);

    final pSpotY = rect.top + (11.0 / hM) * rect.height;
    canvas.drawCircle(Offset(centerX, pSpotY), lp.strokeWidth * 0.9, Paint()..color = lp.color);

    _drawCornerArcTopOnly(canvas, rect, lp);
  }

  void _drawTopHalfBoxes(Canvas canvas, Rect rect, Paint paint, {required double wM, required double hM}) {
    _drawTopHalfBox(canvas, rect, paint, depthM: 16.5, widthM: 40.3, wM: wM, hM: hM);
    _drawTopHalfBox(canvas, rect, paint, depthM: 5.5, widthM: 18.32, wM: wM, hM: hM);
  }

  void _drawTopHalfBox(Canvas canvas, Rect rect, Paint paint,
      {required double depthM, required double widthM, required double wM, required double hM}) {
    final depthPx = (depthM / hM) * rect.height;
    final boxWidthPx = (widthM / wM) * rect.width;

    final left = rect.left + (rect.width - boxWidthPx) / 2;
    final top = rect.top;

    canvas.drawRect(Rect.fromLTRB(left, top, left + boxWidthPx, top + depthPx), paint);
  }

  void _drawFullPortraitMarkings(Canvas canvas, Rect rect) {
    final lp = _linePaint(rect);

    canvas.drawRect(rect, lp);

    canvas.drawLine(
      Offset(rect.left, rect.top + rect.height / 2),
      Offset(rect.right, rect.top + rect.height / 2),
      lp,
    );

    final center = rect.center;
    final r = (9.15 / pitchHeightM) * rect.width;
    canvas.drawCircle(center, r, lp);

    canvas.drawCircle(center, lp.strokeWidth * 0.9, Paint()..color = lp.color);

    _drawPortraitBoxes(canvas, rect, lp);
    _drawPenaltySpotPortrait(canvas, rect, top: true, paint: lp);
    _drawPenaltySpotPortrait(canvas, rect, top: false, paint: lp);

    _drawCornerArcPortrait(canvas, rect, paint: lp, isLeft: true, isTop: true);
    _drawCornerArcPortrait(canvas, rect, paint: lp, isLeft: false, isTop: true);
    _drawCornerArcPortrait(canvas, rect, paint: lp, isLeft: true, isTop: false);
    _drawCornerArcPortrait(canvas, rect, paint: lp, isLeft: false, isTop: false);
  }

  void _drawPortraitBoxes(Canvas canvas, Rect rect, Paint paint) {
    _drawPortraitBox(canvas, rect, paint, depthM: 16.5, widthM: 40.3);
    _drawPortraitBox(canvas, rect, paint, depthM: 5.5, widthM: 18.32);
  }

  void _drawPortraitBox(Canvas canvas, Rect rect, Paint paint,
      {required double depthM, required double widthM}) {
    final depthPx = (depthM / pitchWidthM) * rect.height;
    final boxWidthPx = (widthM / pitchHeightM) * rect.width;

    final left = rect.left + (rect.width - boxWidthPx) / 2;
    final right = left + boxWidthPx;

    canvas.drawRect(
      Rect.fromLTRB(left, rect.top, right, rect.top + depthPx),
      paint,
    );

    canvas.drawRect(
      Rect.fromLTRB(left, rect.bottom - depthPx, right, rect.bottom),
      paint,
    );
  }

  void _drawPenaltySpotPortrait(Canvas canvas, Rect rect,
      {required bool top, required Paint paint}) {
    final y = top
        ? rect.top + (11.0 / pitchWidthM) * rect.height
        : rect.bottom - (11.0 / pitchWidthM) * rect.height;

    canvas.drawCircle(
      Offset(rect.center.dx, y),
      paint.strokeWidth * 0.9,
      Paint()..color = paint.color,
    );
  }

  void _drawCornerArcTopOnly(Canvas canvas, Rect rect, Paint paint) {
    final radius = (1.0 / pitchHeightM) * rect.width;

    final tl = Rect.fromCircle(center: rect.topLeft, radius: radius);
    canvas.drawArc(tl, 0.0, pi / 2, false, paint);

    final tr = Rect.fromCircle(center: rect.topRight, radius: radius);
    canvas.drawArc(tr, pi / 2, pi / 2, false, paint);
  }

  void _drawCornerArc(Canvas canvas, Rect rect, {required Paint paint, required bool isLeft, required bool isTop}) {
    final radius = (1.0 / pitchWidthM) * rect.width;
    final cx = isLeft ? rect.left : rect.right;
    final cy = isTop ? rect.top : rect.bottom;

    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final startAngle = isTop ? (isLeft ? 0.0 : pi / 2) : (isLeft ? 3 * pi / 2 : pi);
    canvas.drawArc(arcRect, startAngle, pi / 2, false, paint);
  }

  void _drawCornerArcPortrait(Canvas canvas, Rect rect,
      {required Paint paint, required bool isLeft, required bool isTop}) {
    final radius = (1.0 / pitchHeightM) * rect.width;
    final cx = isLeft ? rect.left : rect.right;
    final cy = isTop ? rect.top : rect.bottom;

    final arcRect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: radius,
    );

    final startAngle = isTop
        ? (isLeft ? 0.0 : pi / 2)
        : (isLeft ? 3 * pi / 2 : pi);

    canvas.drawArc(arcRect, startAngle, pi / 2, false, paint);
  }

  void _drawHeatmap(Canvas canvas, Rect rect, PitchHeatmap hm) {
    final minV = hm.values.reduce(min);
    final maxV = hm.values.reduce(max);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);

    final cellW = rect.width / hm.cols;
    final cellH = rect.height / hm.rows;

    final heatPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, hm.blurSigma);

    Color palette(double t) {
      t = t.clamp(0.0, 1.0);
      if (t < 0.33) {
        final k = (t / 0.33);
        return Color.lerp(const Color(0xFF0B3D91), const Color(0xFF00C2FF), k)!;
      } else if (t < 0.66) {
        final k = ((t - 0.33) / 0.33);
        return Color.lerp(const Color(0xFF00C2FF), const Color(0xFFFFD54F), k)!;
      } else {
        final k = ((t - 0.66) / 0.34);
        return Color.lerp(const Color(0xFFFFD54F), const Color(0xFFFF3B30), k)!;
      }
    }

    for (int r = 0; r < hm.rows; r++) {
      for (int c = 0; c < hm.cols; c++) {
        final idx = r * hm.cols + c;
        final t = ((hm.values[idx] - minV) / range).clamp(0.0, 1.0);

        heatPaint.color = palette(t).withOpacity(hm.opacity * (0.15 + 0.85 * t));

        final cell = Rect.fromLTWH(
          rect.left + c * cellW,
          rect.top + r * cellH,
          cellW,
          cellH,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            cell.deflate(min(cellW, cellH) * 0.08),
            const Radius.circular(6),
          ),
          heatPaint,
        );
      }
    }
  }

  void _drawPolyline(Canvas canvas, Rect rect, PitchPolyline pl) {
    if (pl.pointsM.length < 2) return;

    if (pl.segmentIntensity01 == null || pl.segmentIntensity01!.length != pl.pointsM.length - 1) {
      final path = Path();
      for (int i = 0; i < pl.pointsM.length; i++) {
        final p = _mToPx(rect, pl.pointsM[i]);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }

      final paint = Paint()
        ..color = const Color(0xFFF5F7FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = pl.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

      canvas.drawPath(path, paint);
    } else {
      for (int i = 0; i < pl.pointsM.length - 1; i++) {
        final a = _mToPx(rect, pl.pointsM[i]);
        final b = _mToPx(rect, pl.pointsM[i + 1]);

        final t = pl.segmentIntensity01![i].clamp(0.0, 1.0);
        final col = _runPalette(t).withOpacity(0.95);

        final paint = Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = pl.strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(a, b, paint);
      }
    }

    if (pl.showStartEndDots) {
      final start = _mToPx(rect, pl.pointsM.first);
      final end = _mToPx(rect, pl.pointsM.last);

      canvas.drawCircle(start, pl.strokeWidth * 1.2, Paint()..color = const Color(0xFF2EE06B));
      canvas.drawCircle(end, pl.strokeWidth * 1.2, Paint()..color = const Color(0xFFFF3B30));
    }

    if (pl.showArrow) {
      _drawArrow(canvas, rect, pl.pointsM);
    }
  }

  Color _runPalette(double t) {
    if (t < 0.33) {
      final k = t / 0.33;
      return Color.lerp(const Color(0xFF2EE06B), const Color(0xFFFFD54F), k)!;
    } else if (t < 0.66) {
      final k = (t - 0.33) / 0.33;
      return Color.lerp(const Color(0xFFFFD54F), const Color(0xFFFF8A00), k)!;
    } else {
      final k = (t - 0.66) / 0.34;
      return Color.lerp(const Color(0xFFFF8A00), const Color(0xFFFF3B30), k)!;
    }
  }

  void _drawArrow(Canvas canvas, Rect rect, List<Offset> pointsM) {
    if (pointsM.length < 2) return;

    final a = _mToPx(rect, pointsM[pointsM.length - 2]);
    final b = _mToPx(rect, pointsM.last);

    final v = b - a;
    final len = v.distance;
    if (len < 8) return;

    final dir = v / len;
    final arrowLen = min(18.0, max(10.0, len * 0.35));
    final arrowWidth = 10.0;

    final tip = b;
    final base = b - dir * arrowLen;
    final perp = Offset(-dir.dy, dir.dx);

    final p1 = base + perp * (arrowWidth / 2);
    final p2 = base - perp * (arrowWidth / 2);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xEFFFFFFF));
  }

  void _drawBorder(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0x66FFFFFF), Color(0x11FFFFFF)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ProPitchPainter old) {
    return old.pitchWidthM != pitchWidthM ||
        old.pitchHeightM != pitchHeightM ||
        old.padding != padding ||
        old.mode != mode ||
        old.flipY != flipY ||
        old.heatmap != heatmap ||
        old.polylines != polylines;
  }
}