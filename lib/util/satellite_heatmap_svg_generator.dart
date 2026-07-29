import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/tracker/trackerData.dart';
import 'match_creation_helper.dart';
import 'web_mercator.dart';

/// Builds heatmap SVGs over a Google Maps satellite backdrop from raw GPS.
///
/// Used when a match has sensor data but the pitch is not geolocalized
/// (no [FootballFieldGps] corners). Geolocalized pitches keep the schematic
/// pitch SVG from [HeatmapSvgGenerator].
class SatelliteHeatmapSvgGenerator {
  SatelliteHeatmapSvgGenerator._();

  /// Marker attribute so PDF rasterizers can detect satellite heatmaps.
  static const String svgDataAttr = 'data-grinta-heatmap="satellite"';

  static Future<String?> generateSvg({
    required List<TrackerRaw> samples,
    List<List<TrackerRaw>> sprintSegments = const [],
    int svgWidth = 1280,
    int svgHeight = 800,
    int gridX = 80,
    int gridY = 50,
    double sigmaMeters = 4.5,
    double minThreshold = 0.05,
    String? apiKey,
    http.Client? httpClient,
    Uint8List? satelliteImageBytes,
  }) async {
    final valid = samples.where(_isUsableSample).toList(growable: false);
    if (valid.isEmpty) return null;

    final rawBounds = GpsLatLngBounds.fromLatLngs(
      valid.map((s) => (lat: s.latitude, lng: s.longitude)),
    );
    if (rawBounds == null) return null;

    final bounds = rawBounds.padded();
    final mapWidth = svgWidth.clamp(320, 1280);
    final mapHeight = svgHeight.clamp(240, 1280);

    final zoom = WebMercator.zoomForBounds(
      south: bounds.south,
      west: bounds.west,
      north: bounds.north,
      east: bounds.east,
      width: mapWidth,
      height: mapHeight,
    );

    final centerLat = bounds.centerLat;
    final centerLng = bounds.centerLng;
    final center = WebMercator.project(centerLat, centerLng, zoom);

    Uint8List? imageBytes = satelliteImageBytes;
    if (imageBytes == null) {
      imageBytes = await _fetchSatelliteImage(
        centerLat: centerLat,
        centerLng: centerLng,
        zoom: zoom,
        width: mapWidth,
        height: mapHeight,
        apiKey: apiKey ?? kGoogleMapsGeocodingApiKey,
        client: httpClient,
      );
    }
    if (imageBytes == null || imageBytes.isEmpty) {
      debugPrint('[SatelliteHeatmap] static map fetch failed');
      return null;
    }

    final mime = _detectImageMime(imageBytes);
    final dataUri = 'data:$mime;base64,${base64Encode(imageBytes)}';

    ({double x, double y}) toPixel(double lat, double lng) {
      final p = WebMercator.project(lat, lng, zoom);
      return (
        x: p.x - center.x + mapWidth / 2.0,
        y: p.y - center.y + mapHeight / 2.0,
      );
    }

    final pixelPoints = <({double x, double y, double intensity})>[];
    for (final s in valid) {
      final p = toPixel(s.latitude, s.longitude);
      if (p.x < -mapWidth * 0.05 ||
          p.x > mapWidth * 1.05 ||
          p.y < -mapHeight * 0.05 ||
          p.y > mapHeight * 1.05) {
        continue;
      }
      pixelPoints.add((
        x: p.x.clamp(0.0, mapWidth.toDouble()),
        y: p.y.clamp(0.0, mapHeight.toDouble()),
        intensity: math.max(0.2, s.speedMps),
      ));
    }
    if (pixelPoints.isEmpty) return null;

    final mpp = WebMercator.metersPerPixel(centerLat, zoom);
    final sigmaPx = math.max(2.0, sigmaMeters / math.max(mpp, 0.01));

    final heatmapRects = _buildHeatmapRects(
      width: mapWidth.toDouble(),
      height: mapHeight.toDouble(),
      points: pixelPoints,
      gridX: gridX,
      gridY: gridY,
      sigmaPx: sigmaPx,
      minThreshold: minThreshold,
    );

    final sprintSvg = _buildSprintPolylinesSvg(
      segments: sprintSegments,
      toPixel: toPixel,
    );

    return '''
<svg xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink"
     $svgDataAttr
     width="$mapWidth"
     height="$mapHeight"
     viewBox="0 0 $mapWidth $mapHeight">
  <rect x="0" y="0" width="$mapWidth" height="$mapHeight" fill="#0b1220"/>
  <image x="0" y="0" width="$mapWidth" height="$mapHeight"
         preserveAspectRatio="none"
         href="$dataUri"
         xlink:href="$dataUri"/>
  $heatmapRects
  $sprintSvg
</svg>
''';
  }

  static bool _isUsableSample(TrackerRaw s) {
    if (s.latitude.abs() > 90 || s.longitude.abs() > 180) return false;
    if (s.latitude == 0 && s.longitude == 0) return false;
    return true;
  }

  static Future<Uint8List?> _fetchSatelliteImage({
    required double centerLat,
    required double centerLng,
    required int zoom,
    required int width,
    required int height,
    required String apiKey,
    http.Client? client,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty || key == 'TA_CLE_GOOGLE_MAPS_ICI') {
      return null;
    }

    // Static Maps free tier caps at 640px; scale=2 yields sharper tiles.
    final requestWidth = math.min(640, width);
    final requestHeight = math.min(640, height);
    final scale = (width > 640 || height > 640) ? 2 : 1;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/staticmap',
      <String, String>{
        'center':
            '${centerLat.toStringAsFixed(6)},${centerLng.toStringAsFixed(6)}',
        'zoom': '$zoom',
        'size': '${requestWidth}x$requestHeight',
        'scale': '$scale',
        'maptype': 'satellite',
        'key': key,
      },
    );

    final httpClient = client ?? http.Client();
    final ownedClient = client == null;
    try {
      final response = await httpClient
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        debugPrint(
          '[SatelliteHeatmap] staticmap HTTP ${response.statusCode}',
        );
        return null;
      }
      final bytes = response.bodyBytes;
      if (bytes.isEmpty) return null;
      // Google returns JSON error payloads with 200 in some misconfig cases.
      if (bytes.length < 32) return null;
      if (bytes[0] == 0x7B /* '{' */) return null;
      return bytes;
    } catch (e, st) {
      debugPrint('[SatelliteHeatmap] staticmap exception: $e\n$st');
      return null;
    } finally {
      if (ownedClient) httpClient.close();
    }
  }

  static String _detectImageMime(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    return 'image/jpeg';
  }

  static String _buildHeatmapRects({
    required double width,
    required double height,
    required List<({double x, double y, double intensity})> points,
    required int gridX,
    required int gridY,
    required double sigmaPx,
    required double minThreshold,
  }) {
    if (points.isEmpty) return '';

    final cols = gridX.clamp(12, 220);
    final rows = gridY.clamp(8, 160);
    final cellW = width / cols;
    final cellH = height / rows;
    final sigma = sigmaPx <= 0 ? 6.0 : sigmaPx;
    final radiusPx = sigma * 3.0;
    final radiusCols = (radiusPx / cellW).ceil();
    final radiusRows = (radiusPx / cellH).ceil();

    final grid = List.generate(rows, (_) => List<double>.filled(cols, 0.0));

    for (final point in points) {
      final px = point.x;
      final py = point.y;
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
          if (d2 > radiusPx * radiusPx) continue;
          final weight = math.exp(-d2 / (2 * sigma * sigma));
          grid[row][col] += intensity * weight;
        }
      }
    }

    final smoothGrid = _smoothGrid(grid, iterations: 2);

    double maxValue = 0.0;
    for (final row in smoothGrid) {
      for (final value in row) {
        if (value > maxValue) maxValue = value;
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
        final color = _heatColorHex(shaped);
        final opacity = (shaped * 0.85).clamp(0.0, 1.0);

        buffer.writeln(
          '<rect x="${left.toStringAsFixed(2)}" '
          'y="${top.toStringAsFixed(2)}" '
          'width="${cellW.toStringAsFixed(2)}" '
          'height="${cellH.toStringAsFixed(2)}" '
          'fill="$color" '
          'fill-opacity="${opacity.toStringAsFixed(3)}" />',
        );
      }
    }
    return buffer.toString();
  }

  static String _buildSprintPolylinesSvg({
    required List<List<TrackerRaw>> segments,
    required ({double x, double y}) Function(double lat, double lng) toPixel,
  }) {
    if (segments.isEmpty) return '';

    const sprintColor = '#D32F2F';
    final buffer = StringBuffer();

    for (final segment in segments) {
      final usable = segment.where(_isUsableSample).toList(growable: false);
      if (usable.length < 2) continue;

      final points = <String>[];
      for (final s in usable) {
        final p = toPixel(s.latitude, s.longitude);
        points.add(
          '${p.x.toStringAsFixed(2)},${p.y.toStringAsFixed(2)}',
        );
      }

      buffer.writeln(
        '<polyline points="${points.join(' ')}" '
        'fill="none" stroke="$sprintColor" stroke-width="3.5" '
        'stroke-linecap="round" stroke-linejoin="round" '
        'stroke-opacity="0.95" />',
      );

      final end = toPixel(usable.last.latitude, usable.last.longitude);
      final prev = toPixel(
        usable[usable.length - 2].latitude,
        usable[usable.length - 2].longitude,
      );
      final dx = end.x - prev.x;
      final dy = end.y - prev.y;
      final length = math.sqrt(dx * dx + dy * dy);
      if (length > 0.001) {
        final ux = dx / length;
        final uy = dy / length;
        const arrowLength = 12.0;
        const arrowWidth = 5.5;
        final baseX = end.x - ux * arrowLength;
        final baseY = end.y - uy * arrowLength;
        final leftX = baseX + (-uy) * arrowWidth;
        final leftY = baseY + ux * arrowWidth;
        final rightX = baseX - (-uy) * arrowWidth;
        final rightY = baseY - ux * arrowWidth;
        buffer.writeln(
          '<polygon points="'
          '${end.x.toStringAsFixed(2)},${end.y.toStringAsFixed(2)} '
          '${leftX.toStringAsFixed(2)},${leftY.toStringAsFixed(2)} '
          '${rightX.toStringAsFixed(2)},${rightY.toStringAsFixed(2)}" '
          'fill="$sprintColor" fill-opacity="0.95" />',
        );
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
              final weight = (dr == 0 && dc == 0)
                  ? 4.0
                  : (dr == 0 || dc == 0)
                      ? 2.0
                      : 1.0;
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
      r = _lerpInt(30, 33, k);
      g = _lerpInt(136, 150, k);
      b = _lerpInt(229, 243, k);
    } else if (v < 0.40) {
      final k = (v - 0.18) / 0.22;
      r = _lerpInt(33, 0, k);
      g = _lerpInt(150, 200, k);
      b = _lerpInt(243, 83, k);
    } else if (v < 0.62) {
      final k = (v - 0.40) / 0.22;
      r = _lerpInt(0, 255, k);
      g = _lerpInt(200, 235, k);
      b = _lerpInt(83, 59, k);
    } else if (v < 0.74) {
      final k = (v - 0.62) / 0.12;
      r = _lerpInt(255, 255, k);
      g = _lerpInt(235, 152, k);
      b = _lerpInt(59, 0, k);
    } else {
      final k = (v - 0.74) / 0.26;
      r = _lerpInt(255, 229, k);
      g = _lerpInt(152, 57, k);
      b = _lerpInt(0, 53, k);
    }

    return '#${_hex2(r)}${_hex2(g)}${_hex2(b)}';
  }

  static int _lerpInt(int a, int b, double t) {
    return (a + (b - a) * t).round().clamp(0, 255);
  }

  static String _hex2(int v) => v.toRadixString(16).padLeft(2, '0');
}
