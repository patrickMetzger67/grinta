import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/tracker/trackerData.dart';

class HeatmapSvgGenerator {
  /// Génère une image SVG vectorielle du terrain + heatmap.
  static String generateSvg({
    required FootballFieldGps field,
    required List<HeatmapPoint> heatmapPoints,
    bool invertSides = false,
    double svgWidth = 1200,
    double svgHeight = 800,
    int gridX = 80,
    int gridY = 50,
    double sigmaMeters = 4.5,
    double minThreshold = 0.05,
    bool drawStripes = true,
  }) {
    final fieldLength = field.fieldLengthMeters;
    final fieldWidth = field.fieldWidthMeters;

    const margin = 40.0;

    final usableWidth = svgWidth - (margin * 2);
    final usableHeight = svgHeight - (margin * 2);

    final scale = math.min(
      usableWidth / fieldLength,
      usableHeight / fieldWidth,
    );

    final pitchWidthPx = fieldLength * scale;
    final pitchHeightPx = fieldWidth * scale;

    final offsetX = (svgWidth - pitchWidthPx) / 2;
    final offsetY = (svgHeight - pitchHeightPx) / 2;

    double mapX(double xMeters) {
      final x = invertSides ? fieldLength - xMeters : xMeters;
      return offsetX + (x * scale);
    }

    double mapY(double yMeters) {
      return offsetY + (yMeters * scale);
    }

    final validPoints = heatmapPoints.where((p) {
      return p.xMeters >= 0 &&
          p.xMeters <= fieldLength &&
          p.yMeters >= 0 &&
          p.yMeters <= fieldWidth;
    }).toList();

    final heatmapRects = _buildHeatmapRects(
      fieldLength: fieldLength,
      fieldWidth: fieldWidth,
      heatmapPoints: validPoints,
      invertSides: invertSides,
      gridX: gridX,
      gridY: gridY,
      sigmaMeters: sigmaMeters,
      minThreshold: minThreshold,
      mapX: mapX,
      mapY: mapY,
      scale: scale,
    );

    final stripes = drawStripes
        ? _buildStripes(
      fieldLength: fieldLength,
      fieldWidth: fieldWidth,
      stripeCount: 10,
      mapX: mapX,
      mapY: mapY,
      scale: scale,
    )
        : '';

    final pitchLines = _buildPitchLines(
      fieldLength: fieldLength,
      fieldWidth: fieldWidth,
      mapX: mapX,
      mapY: mapY,
      scale: scale,
    );

    return '''
<svg xmlns="http://www.w3.org/2000/svg"
     width="${svgWidth.toStringAsFixed(0)}"
     height="${svgHeight.toStringAsFixed(0)}"
     viewBox="0 0 ${svgWidth.toStringAsFixed(2)} ${svgHeight.toStringAsFixed(2)}">

  <rect x="0" y="0" width="${svgWidth.toStringAsFixed(2)}" height="${svgHeight.toStringAsFixed(2)}" fill="#0b1220"/>

  <defs>
    <clipPath id="pitchClip">
      <rect x="${offsetX.toStringAsFixed(2)}"
            y="${offsetY.toStringAsFixed(2)}"
            width="${pitchWidthPx.toStringAsFixed(2)}"
            height="${pitchHeightPx.toStringAsFixed(2)}" />
    </clipPath>
  </defs>

  <rect x="${offsetX.toStringAsFixed(2)}"
        y="${offsetY.toStringAsFixed(2)}"
        width="${pitchWidthPx.toStringAsFixed(2)}"
        height="${pitchHeightPx.toStringAsFixed(2)}"
        fill="#2E7D32" />

  $stripes

  <g clip-path="url(#pitchClip)">
    $heatmapRects
  </g>

  $pitchLines
</svg>
''';
  }

  static String _buildStripes({
    required double fieldLength,
    required double fieldWidth,
    required int stripeCount,
    required double Function(double xMeters) mapX,
    required double Function(double yMeters) mapY,
    required double scale,
  }) {
    final buffer = StringBuffer();

    for (int i = 0; i < stripeCount; i++) {
      final x0 = fieldLength * (i / stripeCount);
      final stripeW = (fieldLength / stripeCount) * scale;

      final color = i.isEven ? '#2E7D32' : '#3D9440';

      buffer.writeln('''
<rect x="${mapX(x0).toStringAsFixed(2)}"
      y="${mapY(0).toStringAsFixed(2)}"
      width="${stripeW.toStringAsFixed(2)}"
      height="${(fieldWidth * scale).toStringAsFixed(2)}"
      fill="$color" />
''');
    }

    return buffer.toString();
  }

  static String _buildHeatmapRects({
    required double fieldLength,
    required double fieldWidth,
    required List<HeatmapPoint> heatmapPoints,
    required bool invertSides,
    required int gridX,
    required int gridY,
    required double sigmaMeters,
    required double minThreshold,
    required double Function(double xMeters) mapX,
    required double Function(double yMeters) mapY,
    required double scale,
  }) {
    if (heatmapPoints.isEmpty) return '';

    final cols = gridX.clamp(12, 220);
    final rows = gridY.clamp(8, 160);

    final cellW = fieldLength / cols;
    final cellH = fieldWidth / rows;

    final sigma = sigmaMeters <= 0 ? 4.5 : sigmaMeters;
    final radiusMeters = sigma * 3.0;
    final radiusCols = (radiusMeters / cellW).ceil();
    final radiusRows = (radiusMeters / cellH).ceil();

    final grid = List.generate(rows, (_) => List<double>.filled(cols, 0.0));

    for (final point in heatmapPoints) {
      final px = invertSides ? fieldLength - point.xMeters : point.xMeters;
      final py = point.yMeters;
      final intensity = point.intensity <= 0 ? 1.0 : point.intensity;

      final centerCol = (px / cellW).floor().clamp(0, cols - 1);
      final centerRow = (py / cellH).floor().clamp(0, rows - 1);

      final minCol = math.max(0, centerCol - radiusCols);
      final maxCol = math.min(cols - 1, centerCol + radiusCols);
      final minRow = math.max(0, centerRow - radiusRows);
      final maxRow = math.min(rows - 1, centerRow + radiusRows);

      for (int row = minRow; row <= maxRow; row++) {
        final cy = (row + 0.5) * cellH;

        for (int col = minCol; col <= maxCol; col++) {
          final cx = (col + 0.5) * cellW;

          final dx = cx - px;
          final dy = cy - py;
          final d2 = dx * dx + dy * dy;

          if (d2 > radiusMeters * radiusMeters) continue;

          final weight = math.exp(-d2 / (2 * sigma * sigma));
          grid[row][col] += intensity * weight;
        }
      }
    }

    final smoothGrid = _smoothGrid(grid, iterations: 2);

    double maxValue = 0.0;
    for (final row in smoothGrid) {
      for (final value in row) {
        if (value > maxValue) {
          maxValue = value;
        }
      }
    }

    if (maxValue <= 0) return '';

    final buffer = StringBuffer();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final normalized = (smoothGrid[row][col] / maxValue).clamp(0.0, 1.0);
        final shaped = math.pow(normalized, 0.72).toDouble();

        if (shaped < minThreshold) continue;

        final left = col * cellW;
        final top = row * cellH;

        final x = mapX(left);
        final y = mapY(top);
        final w = cellW * scale;
        final h = cellH * scale;

        final color = _heatColorHex(shaped);
        final opacity = (shaped * 0.85).clamp(0.0, 1.0);

        buffer.writeln('''
<rect x="${x.toStringAsFixed(2)}"
      y="${y.toStringAsFixed(2)}"
      width="${w.toStringAsFixed(2)}"
      height="${h.toStringAsFixed(2)}"
      fill="$color"
      fill-opacity="${opacity.toStringAsFixed(3)}" />
''');
      }
    }

    return buffer.toString();
  }

  static List<List<double>> _smoothGrid(
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

          next[r][c] = sum / weightSum;
        }
      }

      current = next;
    }

    return current;
  }

  static String _heatColorHex(double t) {
    final v = t.clamp(0.0, 1.0);

    int r, g, b;

    if (v < 0.18) {
      final k = v / 0.18;
      r = _lerpInt(13, 21, k);
      g = _lerpInt(71, 101, k);
      b = _lerpInt(161, 192, k);
    } else if (v < 0.36) {
      final k = (v - 0.18) / 0.18;
      r = _lerpInt(21, 0, k);
      g = _lerpInt(101, 176, k);
      b = _lerpInt(192, 255, k);
    } else if (v < 0.54) {
      final k = (v - 0.36) / 0.18;
      r = _lerpInt(0, 0, k);
      g = _lerpInt(176, 230, k);
      b = _lerpInt(255, 118, k);
    } else if (v < 0.74) {
      final k = (v - 0.54) / 0.20;
      r = _lerpInt(0, 255, k);
      g = _lerpInt(230, 235, k);
      b = _lerpInt(118, 59, k);
    } else {
      final k = (v - 0.74) / 0.26;
      r = _lerpInt(255, 229, k);
      g = _lerpInt(235, 57, k);
      b = _lerpInt(59, 53, k);
    }

    return '#${_hex2(r)}${_hex2(g)}${_hex2(b)}';
  }

  static int _lerpInt(int a, int b, double t) {
    return (a + (b - a) * t).round().clamp(0, 255);
  }

  static String _hex2(int v) => v.toRadixString(16).padLeft(2, '0');

  static String _buildPitchLines({
    required double fieldLength,
    required double fieldWidth,
    required double Function(double xMeters) mapX,
    required double Function(double yMeters) mapY,
    required double scale,
  }) {
    const lineColor = '#ffffff';
    const lineWidth = 2.5;

    const penaltyAreaDepth = 16.5;
    const goalAreaDepth = 5.5;
    const goalWidth = 7.32;
    const penaltyAreaWidth = 40.32;
    const goalAreaWidth = 18.32;
    const penaltySpotDistance = 11.0;
    const centerCircleRadius = 9.15;
    const cornerRadius = 1.0;

    final halfLength = fieldLength / 2;
    final halfWidth = fieldWidth / 2;

    final penaltyAreaTop = (fieldWidth - penaltyAreaWidth) / 2;
    final penaltyAreaBottom = penaltyAreaTop + penaltyAreaWidth;

    final goalAreaTop = (fieldWidth - goalAreaWidth) / 2;
    final goalAreaBottom = goalAreaTop + goalAreaWidth;

    final goalLineTop = (fieldWidth - goalWidth) / 2;
    final goalLineBottom = goalLineTop + goalWidth;

    final penaltyArcAngle =
    math.acos((penaltyAreaDepth - penaltySpotDistance) / centerCircleRadius);

    final buffer = StringBuffer();

    buffer.writeln('''
<rect x="${mapX(0).toStringAsFixed(2)}"
      y="${mapY(0).toStringAsFixed(2)}"
      width="${(fieldLength * scale).toStringAsFixed(2)}"
      height="${(fieldWidth * scale).toStringAsFixed(2)}"
      fill="none"
      stroke="$lineColor"
      stroke-width="$lineWidth" />
''');

    buffer.writeln('''
<line x1="${mapX(halfLength).toStringAsFixed(2)}"
      y1="${mapY(0).toStringAsFixed(2)}"
      x2="${mapX(halfLength).toStringAsFixed(2)}"
      y2="${mapY(fieldWidth).toStringAsFixed(2)}"
      stroke="$lineColor"
      stroke-width="$lineWidth" />
''');

    buffer.writeln('''
<circle cx="${mapX(halfLength).toStringAsFixed(2)}"
        cy="${mapY(halfWidth).toStringAsFixed(2)}"
        r="${(centerCircleRadius * scale).toStringAsFixed(2)}"
        fill="none"
        stroke="$lineColor"
        stroke-width="$lineWidth" />
''');

    buffer.writeln(_rectSvg(
      x: mapX(0),
      y: mapY(penaltyAreaTop),
      w: penaltyAreaDepth * scale,
      h: penaltyAreaWidth * scale,
      stroke: lineColor,
      strokeWidth: lineWidth,
    ));

    buffer.writeln(_rectSvg(
      x: mapX(fieldLength - penaltyAreaDepth),
      y: mapY(penaltyAreaTop),
      w: penaltyAreaDepth * scale,
      h: penaltyAreaWidth * scale,
      stroke: lineColor,
      strokeWidth: lineWidth,
    ));

    buffer.writeln(_rectSvg(
      x: mapX(0),
      y: mapY(goalAreaTop),
      w: goalAreaDepth * scale,
      h: goalAreaWidth * scale,
      stroke: lineColor,
      strokeWidth: lineWidth,
    ));

    buffer.writeln(_rectSvg(
      x: mapX(fieldLength - goalAreaDepth),
      y: mapY(goalAreaTop),
      w: goalAreaDepth * scale,
      h: goalAreaWidth * scale,
      stroke: lineColor,
      strokeWidth: lineWidth,
    ));

    buffer.writeln(_spotSvg(mapX(penaltySpotDistance), mapY(halfWidth)));
    buffer.writeln(_spotSvg(mapX(fieldLength - penaltySpotDistance), mapY(halfWidth)));
    buffer.writeln(_spotSvg(mapX(halfLength), mapY(halfWidth)));

    buffer.writeln(_arcPathSvg(
      centerX: mapX(penaltySpotDistance),
      centerY: mapY(halfWidth),
      radius: centerCircleRadius * scale,
      startAngle: -penaltyArcAngle,
      endAngle: penaltyArcAngle,
      stroke: lineColor,
      strokeWidth: lineWidth,
    ));

    buffer.writeln(_arcPathSvg(
      centerX: mapX(fieldLength - penaltySpotDistance),
      centerY: mapY(halfWidth),
      radius: centerCircleRadius * scale,
      startAngle: math.pi - penaltyArcAngle,
      endAngle: math.pi + penaltyArcAngle,
      stroke: lineColor,
      strokeWidth: lineWidth,
    ));

    buffer.writeln(_cornerArcSvg(mapX(0), mapY(0), cornerRadius * scale, 0, math.pi / 2));
    buffer.writeln(_cornerArcSvg(mapX(fieldLength), mapY(0), cornerRadius * scale, math.pi / 2, math.pi));
    buffer.writeln(_cornerArcSvg(mapX(fieldLength), mapY(fieldWidth), cornerRadius * scale, math.pi, 3 * math.pi / 2));
    buffer.writeln(_cornerArcSvg(mapX(0), mapY(fieldWidth), cornerRadius * scale, 3 * math.pi / 2, 2 * math.pi));

    buffer.writeln('''
<line x1="${mapX(0).toStringAsFixed(2)}"
      y1="${mapY(goalLineTop).toStringAsFixed(2)}"
      x2="${mapX(0).toStringAsFixed(2)}"
      y2="${mapY(goalLineBottom).toStringAsFixed(2)}"
      stroke="$lineColor"
      stroke-width="$lineWidth" />
''');

    buffer.writeln('''
<line x1="${mapX(fieldLength).toStringAsFixed(2)}"
      y1="${mapY(goalLineTop).toStringAsFixed(2)}"
      x2="${mapX(fieldLength).toStringAsFixed(2)}"
      y2="${mapY(goalLineBottom).toStringAsFixed(2)}"
      stroke="$lineColor"
      stroke-width="$lineWidth" />
''');

    return buffer.toString();
  }

  static String _rectSvg({
    required double x,
    required double y,
    required double w,
    required double h,
    required String stroke,
    required double strokeWidth,
  }) {
    return '''
<rect x="${x.toStringAsFixed(2)}"
      y="${y.toStringAsFixed(2)}"
      width="${w.toStringAsFixed(2)}"
      height="${h.toStringAsFixed(2)}"
      fill="none"
      stroke="$stroke"
      stroke-width="$strokeWidth" />
''';
  }

  static String _spotSvg(double cx, double cy) {
    return '''
<circle cx="${cx.toStringAsFixed(2)}"
        cy="${cy.toStringAsFixed(2)}"
        r="3.2"
        fill="#ffffff" />
''';
  }

  static String _arcPathSvg({
    required double centerX,
    required double centerY,
    required double radius,
    required double startAngle,
    required double endAngle,
    required String stroke,
    required double strokeWidth,
  }) {
    final x1 = centerX + math.cos(startAngle) * radius;
    final y1 = centerY + math.sin(startAngle) * radius;
    final x2 = centerX + math.cos(endAngle) * radius;
    final y2 = centerY + math.sin(endAngle) * radius;

    final largeArcFlag = (endAngle - startAngle).abs() > math.pi ? 1 : 0;

    return '''
<path d="M ${x1.toStringAsFixed(2)} ${y1.toStringAsFixed(2)}
         A ${radius.toStringAsFixed(2)} ${radius.toStringAsFixed(2)} 0 $largeArcFlag 1 ${x2.toStringAsFixed(2)} ${y2.toStringAsFixed(2)}"
      fill="none"
      stroke="$stroke"
      stroke-width="$strokeWidth" />
''';
  }

  static String _cornerArcSvg(
      double cx,
      double cy,
      double radius,
      double startAngle,
      double endAngle,
      ) {
    final x1 = cx + math.cos(startAngle) * radius;
    final y1 = cy + math.sin(startAngle) * radius;
    final x2 = cx + math.cos(endAngle) * radius;
    final y2 = cy + math.sin(endAngle) * radius;

    return '''
<path d="M ${x1.toStringAsFixed(2)} ${y1.toStringAsFixed(2)}
         A ${radius.toStringAsFixed(2)} ${radius.toStringAsFixed(2)} 0 0 1 ${x2.toStringAsFixed(2)} ${y2.toStringAsFixed(2)}"
      fill="none"
      stroke="#ffffff"
      stroke-width="2.5" />
''';
  }

  static Future<void> saveSvgToFirestore({
    required String fileName,
    required String svg,
  }) async {
    await FirebaseFirestore.instance.collection('TRACKER_Svg').doc(fileName).set({
      'svgFiles': {
        fileName: {
          'fileName': fileName,
          'svg': svg,
          'contentType': 'image/svg+xml',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
    }, SetOptions(merge: true));
  }

  static Future<String?> loadSvgFromFirestore({
    required String fileName,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('TRACKER_Svg')
        .doc(fileName)
        .get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    final svgFiles = data['svgFiles'];
    if (svgFiles is! Map) return null;

    final fileEntry = svgFiles[fileName];
    if (fileEntry is! Map) return null;

    return fileEntry['svg']?.toString();
  }
}