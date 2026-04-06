import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../model/tracker/trackerData.dart';

class GpsFieldWidget extends StatelessWidget {
  final FootballFieldGps field;
  final List<HeatmapPoint> heatmapPoints;

  final Color fieldColor;
  final Color darkStripeColor;
  final Color lightStripeColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;

  final bool drawMidLine;
  final bool drawCenterCircle;
  final bool invertSides;
  final bool drawGoals;
  final bool drawStripes;
  final bool drawHeatmap;

  /// résolution de la heatmap
  final int heatmapGridX;
  final int heatmapGridY;

  /// rayon de diffusion en mètres
  final double heatmapSigmaMeters;

  /// opacité max de la heatmap
  final double heatmapMaxOpacity;

  /// seuil mini pour ignorer les très faibles valeurs
  final double heatmapMinThreshold;

  /// applique un lissage final supplémentaire sur la grille
  final bool smoothHeatmap;

  const GpsFieldWidget({
    super.key,
    required this.field,
    this.heatmapPoints = const [],
    this.fieldColor = const Color(0xFF2E7D32),
    this.darkStripeColor = const Color(0xFF2E7D32),
    this.lightStripeColor = const Color(0xFF3D9440),
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    this.padding = const EdgeInsets.all(20),
    this.drawMidLine = true,
    this.drawCenterCircle = true,
    this.invertSides = false,
    this.drawGoals = true,
    this.drawStripes = true,
    this.drawHeatmap = true,
    this.heatmapGridX = 90,
    this.heatmapGridY = 56,
    this.heatmapSigmaMeters = 4.8,
    this.heatmapMaxOpacity = 0.82,
    this.heatmapMinThreshold = 0.06,
    this.smoothHeatmap = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GpsFieldPainter(
        field: field,
        heatmapPoints: heatmapPoints,
        fieldColor: fieldColor,
        darkStripeColor: darkStripeColor,
        lightStripeColor: lightStripeColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        padding: padding,
        drawMidLine: drawMidLine,
        drawCenterCircle: drawCenterCircle,
        invertSides: invertSides,
        drawGoals: drawGoals,
        drawStripes: drawStripes,
        drawHeatmap: drawHeatmap,
        heatmapGridX: heatmapGridX,
        heatmapGridY: heatmapGridY,
        heatmapSigmaMeters: heatmapSigmaMeters,
        heatmapMaxOpacity: heatmapMaxOpacity,
        heatmapMinThreshold: heatmapMinThreshold,
        smoothHeatmap: smoothHeatmap,
      ),
    );
  }
}

class GpsFieldPainter extends CustomPainter {
  final FootballFieldGps field;
  final List<HeatmapPoint> heatmapPoints;

  final Color fieldColor;
  final Color darkStripeColor;
  final Color lightStripeColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;

  final bool drawMidLine;
  final bool drawCenterCircle;
  final bool invertSides;
  final bool drawGoals;
  final bool drawStripes;
  final bool drawHeatmap;

  final int heatmapGridX;
  final int heatmapGridY;
  final double heatmapSigmaMeters;
  final double heatmapMaxOpacity;
  final double heatmapMinThreshold;
  final bool smoothHeatmap;

  GpsFieldPainter({
    required this.field,
    required this.heatmapPoints,
    required this.fieldColor,
    required this.darkStripeColor,
    required this.lightStripeColor,
    required this.borderColor,
    required this.borderWidth,
    required this.padding,
    required this.drawMidLine,
    required this.drawCenterCircle,
    required this.invertSides,
    required this.drawGoals,
    required this.drawStripes,
    required this.drawHeatmap,
    required this.heatmapGridX,
    required this.heatmapGridY,
    required this.heatmapSigmaMeters,
    required this.heatmapMaxOpacity,
    required this.heatmapMinThreshold,
    required this.smoothHeatmap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    List<Offset> corners = field.cornersToPitchMeters();
    if (corners.length != 4) return;

    if (invertSides) {
      corners = [
        corners[1],
        corners[0],
        corners[3],
        corners[2],
      ];
    }

    final fitted = _fitPointsToCanvas(
      points: corners,
      size: size,
      padding: padding,
    );

    if (fitted.length != 4) return;

    final topLeft = fitted[0];
    final topRight = fitted[1];
    final bottomRight = fitted[2];
    final bottomLeft = fitted[3];

    final pitch = _PitchQuad(
      topLeft: topLeft,
      topRight: topRight,
      bottomRight: bottomRight,
      bottomLeft: bottomLeft,
      fieldLengthMeters: field.fieldLengthMeters,
      fieldWidthMeters: field.fieldWidthMeters,
    );

    final fieldPath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    final fillPaint = Paint()
      ..color = fieldColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final spotPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(fieldPath, fillPaint);

    canvas.save();
    canvas.clipPath(fieldPath);

    if (drawStripes) {
      _drawGrassStripes(canvas, pitch);
    }

    if (drawHeatmap && heatmapPoints.isNotEmpty) {
      _drawHeatmap(canvas, pitch);
    }

    _drawPitchLines(canvas, pitch, linePaint, spotPaint);

    canvas.restore();

    canvas.drawPath(fieldPath, linePaint);

    if (drawGoals) {
      _drawGoals(canvas, pitch);
    }
  }

  void _drawGrassStripes(Canvas canvas, _PitchQuad pitch) {
    const stripeCount = 10;

    for (int i = 0; i < stripeCount; i++) {
      final x0 = field.fieldLengthMeters * (i / stripeCount);
      final x1 = field.fieldLengthMeters * ((i + 1) / stripeCount);

      final p1 = pitch.pointAtMeters(x0, 0);
      final p2 = pitch.pointAtMeters(x1, 0);
      final p3 = pitch.pointAtMeters(x1, field.fieldWidthMeters);
      final p4 = pitch.pointAtMeters(x0, field.fieldWidthMeters);

      final stripePath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..close();

      final stripePaint = Paint()
        ..color = i.isEven ? darkStripeColor : lightStripeColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(stripePath, stripePaint);
    }
  }

  void _drawHeatmap(Canvas canvas, _PitchQuad pitch) {
    final validPoints = heatmapPoints.where((p) {
      return p.xMeters >= 0 &&
          p.xMeters <= field.fieldLengthMeters &&
          p.yMeters >= 0 &&
          p.yMeters <= field.fieldWidthMeters;
    }).toList();

    if (validPoints.isEmpty) return;

    final cols = heatmapGridX.clamp(16, 240);
    final rows = heatmapGridY.clamp(10, 180);

    final cellW = field.fieldLengthMeters / cols;
    final cellH = field.fieldWidthMeters / rows;

    final grid = List.generate(rows, (_) => List<double>.filled(cols, 0.0));

    final sigma = heatmapSigmaMeters <= 0 ? 4.8 : heatmapSigmaMeters;
    final radiusMeters = sigma * 3.0;
    final radiusCols = (radiusMeters / cellW).ceil();
    final radiusRows = (radiusMeters / cellH).ceil();

    for (final point in validPoints) {
      final px = invertSides
          ? field.fieldLengthMeters - point.xMeters
          : point.xMeters;
      final py = point.yMeters;

      final centerCol = (px / cellW).floor().clamp(0, cols - 1);
      final centerRow = (py / cellH).floor().clamp(0, rows - 1);

      final minCol = math.max(0, centerCol - radiusCols);
      final maxCol = math.min(cols - 1, centerCol + radiusCols);
      final minRow = math.max(0, centerRow - radiusRows);
      final maxRow = math.min(rows - 1, centerRow + radiusRows);

      final pointIntensity = point.intensity <= 0 ? 1.0 : point.intensity;

      for (int row = minRow; row <= maxRow; row++) {
        final cy = (row + 0.5) * cellH;

        for (int col = minCol; col <= maxCol; col++) {
          final cx = (col + 0.5) * cellW;

          final dx = cx - px;
          final dy = cy - py;
          final d2 = dx * dx + dy * dy;

          if (d2 > radiusMeters * radiusMeters) continue;

          final weight = math.exp(-d2 / (2 * sigma * sigma));
          grid[row][col] += pointIntensity * weight;
        }
      }
    }

    List<List<double>> finalGrid = grid;

    if (smoothHeatmap) {
      finalGrid = _smoothGrid(grid, iterations: 2);
    }

    double maxValue = 0.0;
    for (final row in finalGrid) {
      for (final value in row) {
        if (value > maxValue) {
          maxValue = value;
        }
      }
    }

    if (maxValue <= 0) return;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final raw = finalGrid[row][col];
        if (raw <= 0) continue;

        final normalized = (raw / maxValue).clamp(0.0, 1.0);

        final shaped = _shapeHeatValue(normalized);
        if (shaped < heatmapMinThreshold) continue;

        final left = col * cellW;
        final top = row * cellH;
        final right = left + cellW;
        final bottom = top + cellH;

        final p1 = pitch.pointAtMeters(left, top);
        final p2 = pitch.pointAtMeters(right, top);
        final p3 = pitch.pointAtMeters(right, bottom);
        final p4 = pitch.pointAtMeters(left, bottom);

        final cellPath = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..lineTo(p4.dx, p4.dy)
          ..close();

        final color = _heatColor(shaped).withOpacity(
          (shaped * heatmapMaxOpacity).clamp(0.0, 1.0),
        );

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..filterQuality = FilterQuality.high;

        canvas.drawPath(cellPath, paint);
      }
    }

    _drawHeatmapSoftOverlay(canvas, pitch, finalGrid, cols, rows, cellW, cellH, maxValue);
  }

  List<List<double>> _smoothGrid(
      List<List<double>> grid, {
        int iterations = 1,
      }) {
    var current = grid.map((row) => [...row]).toList();

    for (int iteration = 0; iteration < iterations; iteration++) {
      final rows = current.length;
      final cols = current.first.length;
      final next = List.generate(rows, (_) => List<double>.filled(cols, 0.0));

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          double sum = 0.0;
          double weightSum = 0.0;

          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              final rr = r + dr;
              final cc = c + dc;

              if (rr < 0 || rr >= rows || cc < 0 || cc >= cols) continue;

              double weight;
              if (dr == 0 && dc == 0) {
                weight = 4.0;
              } else if (dr == 0 || dc == 0) {
                weight = 2.0;
              } else {
                weight = 1.0;
              }

              sum += current[rr][cc] * weight;
              weightSum += weight;
            }
          }

          next[r][c] = weightSum == 0 ? 0.0 : sum / weightSum;
        }
      }

      current = next;
    }

    return current;
  }

  double _shapeHeatValue(double normalized) {
    final v = normalized.clamp(0.0, 1.0);

    if (v <= 0.0) return 0.0;

    final shaped = math.pow(v, 0.72).toDouble();

    // petit renforcement des zones médianes/fortes
    return (shaped * 1.08).clamp(0.0, 1.0);
  }

  Color _heatColor(double t) {
    final v = t.clamp(0.0, 1.0);

    if (v < 0.18) {
      return Color.lerp(
        const Color(0xFF0D47A1),
        const Color(0xFF1565C0),
        v / 0.18,
      )!;
    } else if (v < 0.36) {
      return Color.lerp(
        const Color(0xFF1565C0),
        const Color(0xFF00B0FF),
        (v - 0.18) / 0.18,
      )!;
    } else if (v < 0.54) {
      return Color.lerp(
        const Color(0xFF00B0FF),
        const Color(0xFF00E676),
        (v - 0.36) / 0.18,
      )!;
    } else if (v < 0.74) {
      return Color.lerp(
        const Color(0xFF00E676),
        const Color(0xFFFFEB3B),
        (v - 0.54) / 0.20,
      )!;
    } else {
      return Color.lerp(
        const Color(0xFFFFEB3B),
        const Color(0xFFE53935),
        (v - 0.74) / 0.26,
      )!;
    }
  }

  void _drawHeatmapSoftOverlay(
      Canvas canvas,
      _PitchQuad pitch,
      List<List<double>> grid,
      int cols,
      int rows,
      double cellW,
      double cellH,
      double maxValue,
      ) {
    final overlayPaint = Paint()
      ..style = PaintingStyle.fill
      ..filterQuality = FilterQuality.high;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final raw = grid[row][col];
        if (raw <= 0) continue;

        final normalized = (raw / maxValue).clamp(0.0, 1.0);
        final shaped = _shapeHeatValue(normalized);

        if (shaped < heatmapMinThreshold + 0.04) continue;

        final centerX = (col + 0.5) * cellW;
        final centerY = (row + 0.5) * cellH;

        final center = pitch.pointAtMeters(centerX, centerY);

        final pxRadius = _averagePixelRadius(
          pitch,
          cellW * 1.35,
          cellH * 1.35,
        );

        final baseColor = _heatColor(shaped);
        final alpha = (shaped * heatmapMaxOpacity * 0.22).clamp(0.0, 0.26);

        overlayPaint.shader = ui.Gradient.radial(
          center,
          pxRadius,
          [
            baseColor.withOpacity(alpha),
            baseColor.withOpacity(alpha * 0.45),
            baseColor.withOpacity(0.0),
          ],
          const [0.0, 0.55, 1.0],
        );

        canvas.drawCircle(center, pxRadius, overlayPaint);
      }
    }
  }

  double _averagePixelRadius(_PitchQuad pitch, double metersX, double metersY) {
    final p0 = pitch.pointAtMeters(0, 0);
    final px = pitch.pointAtMeters(metersX, 0);
    final py = pitch.pointAtMeters(0, metersY);

    final dx = (px - p0).distance;
    final dy = (py - p0).distance;

    return ((dx + dy) / 2).clamp(1.0, 80.0);
  }

  void _drawPitchLines(
      Canvas canvas,
      _PitchQuad pitch,
      Paint linePaint,
      Paint spotPaint,
      ) {
    final fieldLength = field.fieldLengthMeters;
    final fieldWidth = field.fieldWidthMeters;
    final halfLength = fieldLength / 2;
    final halfWidth = fieldWidth / 2;

    const penaltyAreaDepth = 16.5;
    const goalAreaDepth = 5.5;
    const goalWidth = 7.32;
    const penaltyAreaWidth = 40.32;
    const goalAreaWidth = 18.32;
    const penaltySpotDistance = 11.0;
    const centerCircleRadius = 9.15;
    const penaltyArcRadius = 9.15;
    const cornerRadius = 1.0;
    const spotRadiusPx = 2.8;

    if (drawMidLine) {
      _drawMetersLine(
        canvas,
        pitch,
        Offset(halfLength, 0),
        Offset(halfLength, fieldWidth),
        linePaint,
      );
    }

    if (drawCenterCircle) {
      _drawMappedCircle(
        canvas,
        pitch,
        centerMeters: Offset(halfLength, halfWidth),
        radiusMeters: centerCircleRadius,
        paint: linePaint,
      );

      canvas.drawCircle(
        pitch.pointAtMeters(halfLength, halfWidth),
        spotRadiusPx,
        spotPaint,
      );
    }

    final penaltyAreaTop = (fieldWidth - penaltyAreaWidth) / 2;
    final penaltyAreaBottom = penaltyAreaTop + penaltyAreaWidth;

    _drawMetersRect(
      canvas,
      pitch,
      left: 0,
      top: penaltyAreaTop,
      right: penaltyAreaDepth,
      bottom: penaltyAreaBottom,
      paint: linePaint,
    );

    _drawMetersRect(
      canvas,
      pitch,
      left: fieldLength - penaltyAreaDepth,
      top: penaltyAreaTop,
      right: fieldLength,
      bottom: penaltyAreaBottom,
      paint: linePaint,
    );

    final goalAreaTop = (fieldWidth - goalAreaWidth) / 2;
    final goalAreaBottom = goalAreaTop + goalAreaWidth;

    _drawMetersRect(
      canvas,
      pitch,
      left: 0,
      top: goalAreaTop,
      right: goalAreaDepth,
      bottom: goalAreaBottom,
      paint: linePaint,
    );

    _drawMetersRect(
      canvas,
      pitch,
      left: fieldLength - goalAreaDepth,
      top: goalAreaTop,
      right: fieldLength,
      bottom: goalAreaBottom,
      paint: linePaint,
    );

    final leftPenaltySpot = pitch.pointAtMeters(penaltySpotDistance, halfWidth);
    final rightPenaltySpot =
    pitch.pointAtMeters(fieldLength - penaltySpotDistance, halfWidth);

    canvas.drawCircle(leftPenaltySpot, spotRadiusPx, spotPaint);
    canvas.drawCircle(rightPenaltySpot, spotRadiusPx, spotPaint);

    final penaltyArcAngle =
    math.acos((penaltyAreaDepth - penaltySpotDistance) / penaltyArcRadius);

    _drawArcFromAngles(
      canvas,
      pitch,
      centerMeters: Offset(penaltySpotDistance, halfWidth),
      radiusMeters: penaltyArcRadius,
      startAngle: -penaltyArcAngle,
      endAngle: penaltyArcAngle,
      paint: linePaint,
    );

    _drawArcFromAngles(
      canvas,
      pitch,
      centerMeters: Offset(fieldLength - penaltySpotDistance, halfWidth),
      radiusMeters: penaltyArcRadius,
      startAngle: math.pi - penaltyArcAngle,
      endAngle: math.pi + penaltyArcAngle,
      paint: linePaint,
    );

    _drawCornerArc(
      canvas,
      pitch,
      corner: _Corner.topLeft,
      radiusMeters: cornerRadius,
      paint: linePaint,
    );
    _drawCornerArc(
      canvas,
      pitch,
      corner: _Corner.topRight,
      radiusMeters: cornerRadius,
      paint: linePaint,
    );
    _drawCornerArc(
      canvas,
      pitch,
      corner: _Corner.bottomRight,
      radiusMeters: cornerRadius,
      paint: linePaint,
    );
    _drawCornerArc(
      canvas,
      pitch,
      corner: _Corner.bottomLeft,
      radiusMeters: cornerRadius,
      paint: linePaint,
    );

    final goalLineTop = (fieldWidth - goalWidth) / 2;
    final goalLineBottom = goalLineTop + goalWidth;

    _drawMetersLine(
      canvas,
      pitch,
      Offset(0, goalLineTop),
      Offset(0, goalLineBottom),
      linePaint,
    );

    _drawMetersLine(
      canvas,
      pitch,
      Offset(fieldLength, goalLineTop),
      Offset(fieldLength, goalLineBottom),
      linePaint,
    );
  }

  void _drawGoals(Canvas canvas, _PitchQuad pitch) {
    final fieldWidth = field.fieldWidthMeters;
    const goalWidth = 7.32;
    const goalDepthMeters = 2.2;

    final goalTop = (fieldWidth - goalWidth) / 2;
    final goalBottom = goalTop + goalWidth;

    final leftTopPost = pitch.pointAtMeters(0, goalTop);
    final leftBottomPost = pitch.pointAtMeters(0, goalBottom);
    final leftBackTop = pitch.pointAtMeters(-goalDepthMeters, goalTop);
    final leftBackBottom = pitch.pointAtMeters(-goalDepthMeters, goalBottom);

    final rightTopPost = pitch.pointAtMeters(field.fieldLengthMeters, goalTop);
    final rightBottomPost =
    pitch.pointAtMeters(field.fieldLengthMeters, goalBottom);
    final rightBackTop =
    pitch.pointAtMeters(field.fieldLengthMeters + goalDepthMeters, goalTop);
    final rightBackBottom = pitch.pointAtMeters(
      field.fieldLengthMeters + goalDepthMeters,
      goalBottom,
    );

    final goalPaint = Paint()
      ..color = borderColor.withOpacity(0.95)
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final netPaint = Paint()
      ..color = borderColor.withOpacity(0.30)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(leftTopPost, leftBackTop, goalPaint);
    canvas.drawLine(leftBottomPost, leftBackBottom, goalPaint);
    canvas.drawLine(leftBackTop, leftBackBottom, goalPaint);

    canvas.drawLine(rightTopPost, rightBackTop, goalPaint);
    canvas.drawLine(rightBottomPost, rightBackBottom, goalPaint);
    canvas.drawLine(rightBackTop, rightBackBottom, goalPaint);

    for (int i = 1; i <= 4; i++) {
      final t = i / 5;

      final l1 = Offset.lerp(leftTopPost, leftBackTop, t)!;
      final l2 = Offset.lerp(leftBottomPost, leftBackBottom, t)!;
      canvas.drawLine(l1, l2, netPaint);

      final r1 = Offset.lerp(rightTopPost, rightBackTop, t)!;
      final r2 = Offset.lerp(rightBottomPost, rightBackBottom, t)!;
      canvas.drawLine(r1, r2, netPaint);
    }

    for (int i = 1; i <= 5; i++) {
      final t = i / 6;

      final l1 = Offset.lerp(leftTopPost, leftBottomPost, t)!;
      final l2 = Offset.lerp(leftBackTop, leftBackBottom, t)!;
      canvas.drawLine(l1, l2, netPaint);

      final r1 = Offset.lerp(rightTopPost, rightBottomPost, t)!;
      final r2 = Offset.lerp(rightBackTop, rightBackBottom, t)!;
      canvas.drawLine(r1, r2, netPaint);
    }
  }

  void _drawMetersRect(
      Canvas canvas,
      _PitchQuad pitch, {
        required double left,
        required double top,
        required double right,
        required double bottom,
        required Paint paint,
      }) {
    final p1 = pitch.pointAtMeters(left, top);
    final p2 = pitch.pointAtMeters(right, top);
    final p3 = pitch.pointAtMeters(right, bottom);
    final p4 = pitch.pointAtMeters(left, bottom);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawMetersLine(
      Canvas canvas,
      _PitchQuad pitch,
      Offset fromMeters,
      Offset toMeters,
      Paint paint,
      ) {
    final p1 = pitch.pointAtMeters(fromMeters.dx, fromMeters.dy);
    final p2 = pitch.pointAtMeters(toMeters.dx, toMeters.dy);
    canvas.drawLine(p1, p2, paint);
  }

  void _drawMappedCircle(
      Canvas canvas,
      _PitchQuad pitch, {
        required Offset centerMeters,
        required double radiusMeters,
        required Paint paint,
        int steps = 72,
      }) {
    final path = Path();

    for (int i = 0; i <= steps; i++) {
      final angle = (2 * math.pi * i) / steps;
      final x = centerMeters.dx + math.cos(angle) * radiusMeters;
      final y = centerMeters.dy + math.sin(angle) * radiusMeters;
      final p = pitch.pointAtMeters(x, y);

      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawArcFromAngles(
      Canvas canvas,
      _PitchQuad pitch, {
        required Offset centerMeters,
        required double radiusMeters,
        required double startAngle,
        required double endAngle,
        required Paint paint,
        int steps = 48,
      }) {
    final path = Path();

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = startAngle + (endAngle - startAngle) * t;

      final x = centerMeters.dx + math.cos(angle) * radiusMeters;
      final y = centerMeters.dy + math.sin(angle) * radiusMeters;
      final p = pitch.pointAtMeters(x, y);

      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawCornerArc(
      Canvas canvas,
      _PitchQuad pitch, {
        required _Corner corner,
        required double radiusMeters,
        required Paint paint,
        int steps = 18,
      }) {
    late Offset center;
    late double startAngle;
    late double endAngle;

    switch (corner) {
      case _Corner.topLeft:
        center = const Offset(0, 0);
        startAngle = 0;
        endAngle = math.pi / 2;
        break;
      case _Corner.topRight:
        center = Offset(field.fieldLengthMeters, 0);
        startAngle = math.pi / 2;
        endAngle = math.pi;
        break;
      case _Corner.bottomRight:
        center = Offset(field.fieldLengthMeters, field.fieldWidthMeters);
        startAngle = math.pi;
        endAngle = 3 * math.pi / 2;
        break;
      case _Corner.bottomLeft:
        center = Offset(0, field.fieldWidthMeters);
        startAngle = 3 * math.pi / 2;
        endAngle = 2 * math.pi;
        break;
    }

    final path = Path();

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = startAngle + (endAngle - startAngle) * t;

      final x = center.dx + math.cos(angle) * radiusMeters;
      final y = center.dy + math.sin(angle) * radiusMeters;
      final p = pitch.pointAtMeters(x, y);

      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  List<Offset> _fitPointsToCanvas({
    required List<Offset> points,
    required Size size,
    required EdgeInsets padding,
  }) {
    if (points.isEmpty) return [];

    final minX = points.map((e) => e.dx).reduce(math.min);
    final maxX = points.map((e) => e.dx).reduce(math.max);
    final minY = points.map((e) => e.dy).reduce(math.min);
    final maxY = points.map((e) => e.dy).reduce(math.max);

    final rawWidth = maxX - minX;
    final rawHeight = maxY - minY;

    if (rawWidth <= 0 || rawHeight <= 0) {
      final center = Offset(size.width / 2, size.height / 2);
      return List.generate(points.length, (_) => center);
    }

    final availableWidth = size.width - padding.left - padding.right;
    final availableHeight = size.height - padding.top - padding.bottom;

    if (availableWidth <= 0 || availableHeight <= 0) {
      return List.generate(points.length, (_) => Offset.zero);
    }

    final scale = math.min(
      availableWidth / rawWidth,
      availableHeight / rawHeight,
    );

    final scaledWidth = rawWidth * scale;
    final scaledHeight = rawHeight * scale;

    final dx = padding.left + (availableWidth - scaledWidth) / 2;
    final dy = padding.top + (availableHeight - scaledHeight) / 2;

    return points.map((p) {
      return Offset(
        (p.dx - minX) * scale + dx,
        (p.dy - minY) * scale + dy,
      );
    }).toList();
  }

  @override
  bool shouldRepaint(covariant GpsFieldPainter oldDelegate) {
    return oldDelegate.field != field ||
        oldDelegate.heatmapPoints != heatmapPoints ||
        oldDelegate.fieldColor != fieldColor ||
        oldDelegate.darkStripeColor != darkStripeColor ||
        oldDelegate.lightStripeColor != lightStripeColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.padding != padding ||
        oldDelegate.drawMidLine != drawMidLine ||
        oldDelegate.drawCenterCircle != drawCenterCircle ||
        oldDelegate.invertSides != invertSides ||
        oldDelegate.drawGoals != drawGoals ||
        oldDelegate.drawStripes != drawStripes ||
        oldDelegate.drawHeatmap != drawHeatmap ||
        oldDelegate.heatmapGridX != heatmapGridX ||
        oldDelegate.heatmapGridY != heatmapGridY ||
        oldDelegate.heatmapSigmaMeters != heatmapSigmaMeters ||
        oldDelegate.heatmapMaxOpacity != heatmapMaxOpacity ||
        oldDelegate.heatmapMinThreshold != heatmapMinThreshold ||
        oldDelegate.smoothHeatmap != smoothHeatmap;
  }
}

enum _Corner {
  topLeft,
  topRight,
  bottomRight,
  bottomLeft,
}

class _PitchQuad {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;
  final double fieldLengthMeters;
  final double fieldWidthMeters;

  const _PitchQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.fieldLengthMeters,
    required this.fieldWidthMeters,
  });

  Offset pointAtMeters(double xMeters, double yMeters) {
    final u = fieldLengthMeters == 0 ? 0.0 : (xMeters / fieldLengthMeters);
    final v = fieldWidthMeters == 0 ? 0.0 : (yMeters / fieldWidthMeters);

    final top = Offset.lerp(topLeft, topRight, u)!;
    final bottom = Offset.lerp(bottomLeft, bottomRight, u)!;

    return Offset.lerp(top, bottom, v)!;
  }
}