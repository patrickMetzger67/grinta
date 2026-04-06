import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

enum PitchViewMode {
  fullLandscape,
  topHalfPortrait,
  bottomHalfPortrait,
  fullPortrait,
}

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
    this.blurSigma = 6,
    this.opacity = 0.82,
  }) : assert(values.length == rows * cols);
}

class ProPitchView extends StatelessWidget {
  /// Attention :
  /// - pitchWidthM = longueur du terrain
  /// - pitchHeightM = largeur du terrain
  final double pitchWidthM; // ex: 105
  final double pitchHeightM; // ex: 68

  final EdgeInsets padding;
  final PitchViewMode mode;
  final PitchHeatmap? heatmap;
  final List<PitchPolyline> polylines;
  final bool flipY;

  /// Optionnel :
  /// Coins du terrain dans le repère terrain (mètres), ordre :
  /// [topLeft, topRight, bottomRight, bottomLeft]
  ///
  /// Si null -> rendu classique rectangulaire
  /// Si fourni -> rendu déformé selon la géométrie GPS
  final List<Offset>? fieldCornersM;

  const ProPitchView({
    super.key,
    this.pitchWidthM = 105,
    this.pitchHeightM = 68,
    this.padding = EdgeInsets.zero,
    this.mode = PitchViewMode.fullLandscape,
    this.heatmap,
    this.polylines = const [],
    this.flipY = false,
    this.fieldCornersM,
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
          fieldCornersM: fieldCornersM,
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
  final List<Offset>? fieldCornersM;

  _ProPitchPainter({
    required this.pitchWidthM,
    required this.pitchHeightM,
    required this.padding,
    required this.mode,
    required this.heatmap,
    required this.polylines,
    required this.flipY,
    required this.fieldCornersM,
  });

  double get _halfLenM => pitchWidthM / 2.0;

  bool get _hasWarpedField =>
      fieldCornersM != null && fieldCornersM!.length == 4;

  @override
  void paint(Canvas canvas, Size size) {
    final dims = _modeDimsM();
    final rect = _fitRect(size, padding, dims.dx, dims.dy);

    _drawPitchBackground(canvas, rect);

    switch (mode) {
      case PitchViewMode.fullLandscape:
        _drawFullLandscapeMarkings(canvas, rect);
        break;
      case PitchViewMode.topHalfPortrait:
        _drawTopHalfPortraitMarkings(canvas, rect);
        break;
      case PitchViewMode.bottomHalfPortrait:
        _drawBottomHalfPortraitMarkings(canvas, rect);
        break;
      case PitchViewMode.fullPortrait:
        _drawFullPortraitMarkings(canvas, rect);
        break;
    }

    final clipPath = _buildPitchClipPath(rect);

    canvas.save();
    canvas.clipPath(clipPath);

    if (heatmap != null) {
      _drawHeatmap(canvas, rect, heatmap!);
    }

    for (final pl in polylines) {
      _drawPolyline(canvas, rect, pl);
    }

    canvas.restore();

    _drawBorder(canvas, rect);
  }


  bool _isInsidePitchMeters(Offset p, {double tolerance = 0.0}) {
    return p.dx >= -tolerance &&
        p.dy >= -tolerance &&
        p.dx <= pitchWidthM + tolerance &&
        p.dy <= pitchHeightM + tolerance;
  }

  Path _buildPitchClipPath(Rect rect) {
    final path = Path();

    final p1 = _mToPx(rect, const Offset(0, 0));
    final p2 = _mToPx(rect, Offset(pitchWidthM, 0));
    final p3 = _mToPx(rect, Offset(pitchWidthM, pitchHeightM));
    final p4 = _mToPx(rect, Offset(0, pitchHeightM));

    path.moveTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);
    path.lineTo(p4.dx, p4.dy);
    path.close();

    return path;
  }

  static const int _clipLeft = 1;
  static const int _clipRight = 2;
  static const int _clipBottom = 4;
  static const int _clipTop = 8;

  int _computeOutCode(Offset p) {
    int code = 0;

    if (p.dx < 0) {
      code |= _clipLeft;
    } else if (p.dx > pitchWidthM) {
      code |= _clipRight;
    }

    if (p.dy < 0) {
      code |= _clipTop;
    } else if (p.dy > pitchHeightM) {
      code |= _clipBottom;
    }

    return code;
  }

  /// Coupe un segment contre le rectangle du terrain.
  /// Retourne null si le segment est totalement hors terrain.
  List<Offset>? _clipSegmentToPitch(Offset p0, Offset p1) {
    double x0 = p0.dx;
    double y0 = p0.dy;
    double x1 = p1.dx;
    double y1 = p1.dy;

    int outCode0 = _computeOutCode(p0);
    int outCode1 = _computeOutCode(p1);

    while (true) {
      if ((outCode0 | outCode1) == 0) {
        return [Offset(x0, y0), Offset(x1, y1)];
      }

      if ((outCode0 & outCode1) != 0) {
        return null;
      }

      final outCodeOut = outCode0 != 0 ? outCode0 : outCode1;

      double x = 0;
      double y = 0;

      if ((outCodeOut & _clipTop) != 0) {
        x = x0 + (x1 - x0) * (0 - y0) / (y1 - y0);
        y = 0;
      } else if ((outCodeOut & _clipBottom) != 0) {
        x = x0 + (x1 - x0) * (pitchHeightM - y0) / (y1 - y0);
        y = pitchHeightM;
      } else if ((outCodeOut & _clipRight) != 0) {
        y = y0 + (y1 - y0) * (pitchWidthM - x0) / (x1 - x0);
        x = pitchWidthM;
      } else if ((outCodeOut & _clipLeft) != 0) {
        y = y0 + (y1 - y0) * (0 - x0) / (x1 - x0);
        x = 0;
      }

      if (outCodeOut == outCode0) {
        x0 = x;
        y0 = y;
        outCode0 = _computeOutCode(Offset(x0, y0));
      } else {
        x1 = x;
        y1 = y;
        outCode1 = _computeOutCode(Offset(x1, y1));
      }
    }
  }

  Offset _modeDimsM() {
    if (mode == PitchViewMode.fullLandscape) {
      return Offset(pitchWidthM, pitchHeightM);
    }
    if (mode == PitchViewMode.topHalfPortrait ||
        mode == PitchViewMode.bottomHalfPortrait) {
      return Offset(pitchHeightM, _halfLenM);
    }
    return Offset(pitchHeightM, pitchWidthM);
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
    if (!_hasWarpedField) {
      return _mToPxRect(rect, m);
    }

    switch (mode) {
      case PitchViewMode.fullLandscape:
        return _mToPxWarpedFullLandscape(rect, m);
      case PitchViewMode.topHalfPortrait:
        return _mToPxWarpedHalfPortrait(rect, m, isTopHalf: true);
      case PitchViewMode.bottomHalfPortrait:
        return _mToPxWarpedHalfPortrait(rect, m, isTopHalf: false);
      case PitchViewMode.fullPortrait:
        return _mToPxWarpedFullPortrait(rect, m);
    }
  }

  Offset _mToPxRect(Rect rect, Offset m) {
    if (mode == PitchViewMode.fullPortrait) {
      final xNorm = m.dy / pitchHeightM;
      final yNorm = m.dx / pitchWidthM;

      final x = rect.left + xNorm * rect.width;
      final y = rect.top + ((flipY ? (1.0 - yNorm) : yNorm) * rect.height);

      return Offset(x, y);
    }

    if (mode == PitchViewMode.topHalfPortrait ||
        mode == PitchViewMode.bottomHalfPortrait) {
      final halfStart = mode == PitchViewMode.topHalfPortrait ? 0.0 : _halfLenM;
      final localX = (m.dx - halfStart).clamp(0.0, _halfLenM);

      final xNorm = m.dy / pitchHeightM;
      final yNorm = localX / _halfLenM;

      final x = rect.left + xNorm * rect.width;
      final y = rect.top + ((flipY ? (1.0 - yNorm) : yNorm) * rect.height);

      return Offset(x, y);
    }

    final x = rect.left + (m.dx / pitchWidthM) * rect.width;
    final yNorm = m.dy / pitchHeightM;
    final y = rect.top + ((flipY ? (1.0 - yNorm) : yNorm) * rect.height);

    return Offset(x, y);
  }

  Offset _mToPxWarpedFullLandscape(Rect rect, Offset m) {
    final warped = _warpFullFieldPoint(m);
    return Offset(
      rect.left + (warped.dx / pitchWidthM) * rect.width,
      rect.top +
          ((flipY
              ? (1.0 - (warped.dy / pitchHeightM))
              : (warped.dy / pitchHeightM)) *
              rect.height),
    );
  }

  Offset _mToPxWarpedFullPortrait(Rect rect, Offset m) {
    final warped = _warpFullFieldPoint(m);

    final xNorm = warped.dy / pitchHeightM;
    final yNorm = warped.dx / pitchWidthM;

    return Offset(
      rect.left + xNorm * rect.width,
      rect.top + ((flipY ? (1.0 - yNorm) : yNorm) * rect.height),
    );
  }

  Offset _mToPxWarpedHalfPortrait(
      Rect rect,
      Offset m, {
        required bool isTopHalf,
      }) {
    final halfStart = isTopHalf ? 0.0 : _halfLenM;
    final localX = (m.dx - halfStart).clamp(0.0, _halfLenM);
    final globalM = Offset(localX + halfStart, m.dy);

    final warped = _warpFullFieldPoint(globalM);

    final topCenter = _warpFullFieldPoint(Offset(_halfLenM, 0));
    final bottomCenter = _warpFullFieldPoint(Offset(_halfLenM, pitchHeightM));

    final fullTopMid = Offset.lerp(fieldCornersM![0], fieldCornersM![1], 0.5)!;
    final fullBottomMid =
    Offset.lerp(fieldCornersM![3], fieldCornersM![2], 0.5)!;

    final useTop = isTopHalf;

    final localTopLeft = useTop ? fieldCornersM![0] : fullTopMid;
    final localTopRight = useTop ? fieldCornersM![1] : fullBottomMid;
    final localBottomLeft = useTop ? fullTopMid : fieldCornersM![3];
    final localBottomRight = useTop ? fullBottomMid : fieldCornersM![2];

    final minX = [
      localTopLeft.dx,
      localTopRight.dx,
      localBottomLeft.dx,
      localBottomRight.dx,
    ].reduce(min);

    final maxX = [
      localTopLeft.dx,
      localTopRight.dx,
      localBottomLeft.dx,
      localBottomRight.dx,
    ].reduce(max);

    final minY = [
      localTopLeft.dy,
      localTopRight.dy,
      localBottomLeft.dy,
      localBottomRight.dy,
    ].reduce(min);

    final maxY = [
      localTopLeft.dy,
      localTopRight.dy,
      localBottomLeft.dy,
      localBottomRight.dy,
    ].reduce(max);

    final warpedXNorm =
        (warped.dy - minY) / max(1e-9, (maxY - minY)); // largeur -> horizontal
    final warpedYNorm =
        (warped.dx - minX) / max(1e-9, (maxX - minX)); // longueur -> vertical

    return Offset(
      rect.left + warpedXNorm * rect.width,
      rect.top + ((flipY ? (1.0 - warpedYNorm) : warpedYNorm) * rect.height),
    );
  }

  Offset _warpFullFieldPoint(Offset m) {
    final tl = fieldCornersM![0];
    final tr = fieldCornersM![1];
    final br = fieldCornersM![2];
    final bl = fieldCornersM![3];

    final u = (m.dx / pitchWidthM).clamp(0.0, 1.0);
    final v = (m.dy / pitchHeightM).clamp(0.0, 1.0);

    final top = Offset.lerp(tl, tr, u)!;
    final bottom = Offset.lerp(bl, br, u)!;
    return Offset.lerp(top, bottom, v)!;
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
    final stripePaint = Paint()..color = const Color(0x10FFFFFF);

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
      radius: 0.95,
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

    _drawPitchOutline(canvas, rect, lp);

    _drawMetricLine(canvas, rect, const Offset(52.5, 0), Offset(52.5, pitchHeightM), lp);

    final center = _mToPx(rect, Offset(_halfLenM, pitchHeightM / 2));
    final r = _circleRadiusPx(rect, 9.15);
    canvas.drawCircle(center, r, lp);
    canvas.drawCircle(center, lp.strokeWidth * 0.9, Paint()..color = lp.color);

    _drawFullBoxes(canvas, rect, lp);
    _drawPenaltySpotFull(canvas, rect, left: true, paint: lp);
    _drawPenaltySpotFull(canvas, rect, left: false, paint: lp);

    _drawCornerArcMetric(canvas, rect, const Offset(0, 0), 0.0, lp);
    _drawCornerArcMetric(canvas, rect, Offset(0, pitchHeightM), 3 * pi / 2, lp);
    _drawCornerArcMetric(canvas, rect, Offset(pitchWidthM, 0), pi / 2, lp);
    _drawCornerArcMetric(canvas, rect, Offset(pitchWidthM, pitchHeightM), pi, lp);
  }

  void _drawPitchOutline(Canvas canvas, Rect rect, Paint paint) {
    final path = Path();
    final p1 = _mToPx(rect, const Offset(0, 0));
    final p2 = _mToPx(rect, Offset(pitchWidthM, 0));
    final p3 = _mToPx(rect, Offset(pitchWidthM, pitchHeightM));
    final p4 = _mToPx(rect, Offset(0, pitchHeightM));

    path.moveTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);
    path.lineTo(p4.dx, p4.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawMetricLine(
      Canvas canvas,
      Rect rect,
      Offset aM,
      Offset bM,
      Paint paint,
      ) {
    final a = _mToPx(rect, aM);
    final b = _mToPx(rect, bM);
    canvas.drawLine(a, b, paint);
  }

  double _circleRadiusPx(Rect rect, double radiusM) {
    final sx = rect.width / pitchWidthM;
    final sy = rect.height / pitchHeightM;
    return radiusM * min(sx, sy);
  }

  void _drawFullBoxes(Canvas canvas, Rect rect, Paint paint) {
    _drawBoxMetric(
      canvas,
      rect,
      paint,
      leftX: 0,
      rightX: 16.5,
      topY: (pitchHeightM - 40.3) / 2,
      bottomY: (pitchHeightM + 40.3) / 2,
    );
    _drawBoxMetric(
      canvas,
      rect,
      paint,
      leftX: 0,
      rightX: 5.5,
      topY: (pitchHeightM - 18.32) / 2,
      bottomY: (pitchHeightM + 18.32) / 2,
    );
    _drawBoxMetric(
      canvas,
      rect,
      paint,
      leftX: pitchWidthM - 16.5,
      rightX: pitchWidthM,
      topY: (pitchHeightM - 40.3) / 2,
      bottomY: (pitchHeightM + 40.3) / 2,
    );
    _drawBoxMetric(
      canvas,
      rect,
      paint,
      leftX: pitchWidthM - 5.5,
      rightX: pitchWidthM,
      topY: (pitchHeightM - 18.32) / 2,
      bottomY: (pitchHeightM + 18.32) / 2,
    );
  }

  void _drawBoxMetric(
      Canvas canvas,
      Rect rect,
      Paint paint, {
        required double leftX,
        required double rightX,
        required double topY,
        required double bottomY,
      }) {
    final p1 = _mToPx(rect, Offset(leftX, topY));
    final p2 = _mToPx(rect, Offset(rightX, topY));
    final p3 = _mToPx(rect, Offset(rightX, bottomY));
    final p4 = _mToPx(rect, Offset(leftX, bottomY));

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawPenaltySpotFull(
      Canvas canvas,
      Rect rect, {
        required bool left,
        required Paint paint,
      }) {
    final p = _mToPx(
      rect,
      Offset(left ? 11.0 : pitchWidthM - 11.0, pitchHeightM / 2),
    );
    canvas.drawCircle(
      p,
      paint.strokeWidth * 0.9,
      Paint()..color = paint.color,
    );
  }

  void _drawTopHalfPortraitMarkings(Canvas canvas, Rect rect) {
    final lp = _linePaint(rect);

    _drawPitchOutline(canvas, rect, lp);
    _drawMetricLine(
      canvas,
      rect,
      Offset(0, pitchHeightM / 2),
      Offset(_halfLenM, pitchHeightM / 2),
      lp,
    );

    final center = _mToPx(rect, Offset(_halfLenM, pitchHeightM / 2));
    final r = _circleRadiusPx(rect, 9.15);
    final arcRect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(arcRect, pi, pi, false, lp);

    canvas.drawCircle(center, lp.strokeWidth * 0.9, Paint()..color = lp.color);

    _drawTopHalfBoxes(canvas, rect, lp);

    final pSpot = _mToPx(rect, const Offset(11.0, 34.0));
    canvas.drawCircle(
      pSpot,
      lp.strokeWidth * 0.9,
      Paint()..color = lp.color,
    );

    _drawCornerArcMetric(canvas, rect, const Offset(0, 0), 0.0, lp);
    _drawCornerArcMetric(canvas, rect, Offset(0, pitchHeightM), 3 * pi / 2, lp);
  }

  void _drawBottomHalfPortraitMarkings(Canvas canvas, Rect rect) {
    final lp = _linePaint(rect);

    _drawPitchOutline(canvas, rect, lp);
    _drawMetricLine(
      canvas,
      rect,
      Offset(_halfLenM, pitchHeightM / 2),
      Offset(pitchWidthM, pitchHeightM / 2),
      lp,
    );

    final center = _mToPx(rect, Offset(_halfLenM, pitchHeightM / 2));
    final r = _circleRadiusPx(rect, 9.15);
    final arcRect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(arcRect, 0, pi, false, lp);

    canvas.drawCircle(center, lp.strokeWidth * 0.9, Paint()..color = lp.color);

    _drawBottomHalfBoxes(canvas, rect, lp);

    final pSpot = _mToPx(rect, Offset(pitchWidthM - 11.0, pitchHeightM / 2));
    canvas.drawCircle(
      pSpot,
      lp.strokeWidth * 0.9,
      Paint()..color = lp.color,
    );

    _drawCornerArcMetric(canvas, rect, Offset(pitchWidthM, 0), pi / 2, lp);
    _drawCornerArcMetric(canvas, rect, Offset(pitchWidthM, pitchHeightM), pi, lp);
  }

  void _drawTopHalfBoxes(Canvas canvas, Rect rect, Paint paint) {
    _drawBoxMetric(
      canvas,
      rect,
      paint,
      leftX: 0,
      rightX: 16.5,
      topY: (pitchHeightM - 40.3) / 2,
      bottomY: (pitchHeightM + 40.3) / 2,
    );
    _drawBoxMetric(
      canvas,
      rect,
      paint,
      leftX: 0,
      rightX: 5.5,
      topY: (pitchHeightM - 18.32) / 2,
      bottomY: (pitchHeightM + 18.32) / 2,
    );
  }

  void _drawBottomHalfBoxes(Canvas canvas, Rect rect, Paint paint) {
    _drawBoxMetric(
      canvas,
      rect,
      paint,
      leftX: pitchWidthM - 16.5,
      rightX: pitchWidthM,
      topY: (pitchHeightM - 40.3) / 2,
      bottomY: (pitchHeightM + 40.3) / 2,
    );
    _drawBoxMetric(
      canvas,
      rect,
      paint,
      leftX: pitchWidthM - 5.5,
      rightX: pitchWidthM,
      topY: (pitchHeightM - 18.32) / 2,
      bottomY: (pitchHeightM + 18.32) / 2,
    );
  }

  void _drawFullPortraitMarkings(Canvas canvas, Rect rect) {
    final lp = _linePaint(rect);

    _drawPitchOutline(canvas, rect, lp);

    _drawMetricLine(
      canvas,
      rect,
      Offset(_halfLenM, 0),
      Offset(_halfLenM, pitchHeightM),
      lp,
    );

    final center = _mToPx(rect, Offset(_halfLenM, pitchHeightM / 2));
    final r = _circleRadiusPx(rect, 9.15);
    canvas.drawCircle(center, r, lp);
    canvas.drawCircle(center, lp.strokeWidth * 0.9, Paint()..color = lp.color);

    _drawFullBoxes(canvas, rect, lp);
    _drawPenaltySpotFull(canvas, rect, left: true, paint: lp);
    _drawPenaltySpotFull(canvas, rect, left: false, paint: lp);

    _drawCornerArcMetric(canvas, rect, const Offset(0, 0), 0.0, lp);
    _drawCornerArcMetric(canvas, rect, Offset(pitchWidthM, 0), pi / 2, lp);
    _drawCornerArcMetric(canvas, rect, Offset(0, pitchHeightM), 3 * pi / 2, lp);
    _drawCornerArcMetric(canvas, rect, Offset(pitchWidthM, pitchHeightM), pi, lp);
  }

  void _drawCornerArcMetric(
      Canvas canvas,
      Rect rect,
      Offset cornerM,
      double startAngle,
      Paint paint,
      ) {
    final center = _mToPx(rect, cornerM);
    final radius = _circleRadiusPx(rect, 1.0);
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, startAngle, pi / 2, false, paint);
  }

  void _drawHeatmap(Canvas canvas, Rect rect, PitchHeatmap hm) {
    final minV = hm.values.reduce(min);
    final maxV = hm.values.reduce(max);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);

    final cellW = pitchWidthM / hm.cols;
    final cellH = pitchHeightM / hm.rows;

    Color palette(double t) {
      t = t.clamp(0.0, 1.0);

      if (t < 0.25) {
        final k = t / 0.25;
        return Color.lerp(
          const Color(0x00000000),
          const Color(0xFF00E5FF),
          k,
        )!;
      } else if (t < 0.55) {
        final k = (t - 0.25) / 0.30;
        return Color.lerp(
          const Color(0xFF00E5FF),
          const Color(0xFFFFFF00),
          k,
        )!;
      } else if (t < 0.80) {
        final k = (t - 0.55) / 0.25;
        return Color.lerp(
          const Color(0xFFFFFF00),
          const Color(0xFFFF8A00),
          k,
        )!;
      } else {
        final k = (t - 0.80) / 0.20;
        return Color.lerp(
          const Color(0xFFFF8A00),
          const Color(0xFFFF2D2D),
          k,
        )!;
      }
    }

    for (int r = 0; r < hm.rows; r++) {
      for (int c = 0; c < hm.cols; c++) {
        final idx = r * hm.cols + c;
        final t = ((hm.values[idx] - minV) / range).clamp(0.0, 1.0);

        if (t < 0.10) continue;

        final boosted = pow(t, 0.75).toDouble();

        final centerM = Offset(
          (c + 0.5) * cellW,
          (r + 0.5) * cellH,
        );
        final center = _mToPx(rect, centerM);

        final baseScale = min(rect.width / pitchWidthM, rect.height / pitchHeightM);
        final radius = baseScale * max(cellW, cellH) * (0.9 + 1.8 * boosted);

        final color = palette(boosted).withOpacity(
          (hm.opacity * (0.22 + 0.78 * boosted)).clamp(0.0, 1.0),
        );

        final blobRect = Rect.fromCircle(center: center, radius: radius);

        final shader = RadialGradient(
          colors: [
            color,
            color.withOpacity(color.opacity * 0.55),
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(blobRect);

        canvas.drawCircle(
          center,
          radius,
          Paint()..shader = shader,
        );
      }
    }
  }

  void _drawPolyline(Canvas canvas, Rect rect, PitchPolyline pl) {
    if (pl.pointsM.length < 2) return;

    if (pl.segmentIntensity01 == null ||
        pl.segmentIntensity01!.length != pl.pointsM.length - 1) {
      final paint = Paint()
        ..color = const Color(0xFFF5F7FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = pl.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

      final path = Path();
      bool hasStarted = false;

      for (int i = 0; i < pl.pointsM.length - 1; i++) {
        final clipped = _clipSegmentToPitch(pl.pointsM[i], pl.pointsM[i + 1]);
        if (clipped == null) continue;

        final a = _mToPx(rect, clipped[0]);
        final b = _mToPx(rect, clipped[1]);

        if (!hasStarted) {
          path.moveTo(a.dx, a.dy);
          hasStarted = true;
        } else {
          path.lineTo(a.dx, a.dy);
        }
        path.lineTo(b.dx, b.dy);
      }

      if (hasStarted) {
        canvas.drawPath(path, paint);
      }
    } else {
      for (int i = 0; i < pl.pointsM.length - 1; i++) {
        final clipped = _clipSegmentToPitch(pl.pointsM[i], pl.pointsM[i + 1]);
        if (clipped == null) continue;

        final a = _mToPx(rect, clipped[0]);
        final b = _mToPx(rect, clipped[1]);

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
      Offset? firstVisible;
      Offset? lastVisible;

      for (int i = 0; i < pl.pointsM.length - 1; i++) {
        final clipped = _clipSegmentToPitch(pl.pointsM[i], pl.pointsM[i + 1]);
        if (clipped == null) continue;

        firstVisible ??= clipped[0];
        lastVisible = clipped[1];
      }

      if (firstVisible != null) {
        final start = _mToPx(rect, firstVisible);
        canvas.drawCircle(
          start,
          pl.strokeWidth * 1.2,
          Paint()..color = const Color(0xFF2EE06B),
        );
      }

      if (lastVisible != null) {
        final end = _mToPx(rect, lastVisible);
        canvas.drawCircle(
          end,
          pl.strokeWidth * 1.2,
          Paint()..color = const Color(0xFFFF3B30),
        );
      }
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

    List<Offset>? lastVisibleSegment;

    for (int i = 0; i < pointsM.length - 1; i++) {
      final clipped = _clipSegmentToPitch(pointsM[i], pointsM[i + 1]);
      if (clipped != null) {
        lastVisibleSegment = clipped;
      }
    }

    if (lastVisibleSegment == null) return;

    final a = _mToPx(rect, lastVisibleSegment[0]);
    final b = _mToPx(rect, lastVisibleSegment[1]);

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
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x66FFFFFF), Color(0x11FFFFFF)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    if (_hasWarpedField && mode == PitchViewMode.fullLandscape) {
      final path = Path();
      final p1 = _mToPx(rect, const Offset(0, 0));
      final p2 = _mToPx(rect, Offset(pitchWidthM, 0));
      final p3 = _mToPx(rect, Offset(pitchWidthM, pitchHeightM));
      final p4 = _mToPx(rect, Offset(0, pitchHeightM));

      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p3.dx, p3.dy);
      path.lineTo(p4.dx, p4.dy);
      path.close();

      canvas.drawPath(path, paint);
      return;
    }

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
        old.polylines != polylines ||
        old.fieldCornersM != fieldCornersM;
  }
}