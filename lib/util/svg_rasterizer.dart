import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;

/// Rasterizes heatmap SVGs for PDF embedding.
///
/// Prefer the pure-Dart path ([heatmapSvgStringToPngBytes]): production
/// heatmaps are mostly `<rect>` cells and `dart:ui` `toImage` is unreliable
/// on Flutter Web. Falls back to flutter_svg when needed.
Future<Uint8List?> svgStringToPngBytes(
  String svg, {
  double targetWidth = 720,
}) async {
  final String trimmed = svg.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final Uint8List? fromRects = heatmapSvgStringToPngBytes(
    trimmed,
    targetWidth: targetWidth.round(),
  );
  if (fromRects != null && fromRects.isNotEmpty) {
    return fromRects;
  }

  return brandSvgToPngBytes(trimmed, targetWidth: targetWidth);
}

/// Rasterizes brand / UI SVGs for PDF embedding (always via flutter_svg).
///
/// Prefer this for logos (Whoop, Strava, Apple, …). [svgStringToPngBytes]
/// first tries the heatmap rect path, which used to mis-render simple brand
/// marks that contain a background `<rect>` as a green pitch square.
Future<Uint8List?> brandSvgToPngBytes(
  String svg, {
  double targetWidth = 72,
}) async {
  final String trimmed = svg.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return _flutterSvgToPngBytes(trimmed, targetWidth: targetWidth);
}

/// Pure-Dart rasterizer for TRACKER_Svg heatmaps (pitch + heat rects).
///
/// Works on web/mobile/desktop without `dart:ui` image encoding.
/// Returns null when the SVG does not look like a heatmap so callers can
/// fall back to [brandSvgToPngBytes] for logos and other marks.
Uint8List? heatmapSvgStringToPngBytes(
  String svg, {
  int targetWidth = 720,
}) {
  try {
    final _SvgSize? size = _parseSvgSize(svg);
    if (size == null || size.width <= 0 || size.height <= 0) {
      return null;
    }

    final int outW = targetWidth.clamp(64, 1600);
    final double scale = outW / size.width;
    final int outH = (size.height * scale).round().clamp(64, 1600);

    final img.Image image = img.Image(width: outW, height: outH);
    img.fill(image, color: img.ColorRgba8(11, 18, 32, 255));

    // Pitch fill (first large green-ish rect, else generator default).
    final List<_SvgRectPaint> rects = _parseSvgRects(svg);
    _SvgRectPaint? pitch;
    for (final _SvgRectPaint rect in rects) {
      if (rect.width >= size.width * 0.4 &&
          rect.height >= size.height * 0.4 &&
          _isPitchGreen(rect.color)) {
        pitch = rect;
        break;
      }
    }
    pitch ??= _SvgRectPaint(
      x: size.width * 0.05,
      y: size.height * 0.05,
      width: size.width * 0.9,
      height: size.height * 0.9,
      color: img.ColorRgba8(46, 125, 50, 255),
    );
    _fillRect(image, pitch, scale);

    // Heat cells (smaller colored rects with opacity).
    var heatCellCount = 0;
    for (final _SvgRectPaint rect in rects) {
      if (identical(rect, pitch)) continue;
      if (rect.width >= size.width * 0.4 && rect.height >= size.height * 0.4) {
        continue;
      }
      if (rect.color.a == 0) continue;
      // Skip near-black background leftovers.
      if (rect.color.r < 20 && rect.color.g < 20 && rect.color.b < 30) {
        continue;
      }
      heatCellCount++;
      _fillRect(image, rect, scale);
    }

    // Brand logos (Whoop, Apple, …) often have a viewBox + background rect.
    // Without heat cells, this path would return a green pitch square.
    if (heatCellCount == 0) {
      return null;
    }

    // Pitch outline + boxes from white stroke rects in the SVG itself.
    for (final _SvgRectPaint rect in _parseSvgStrokeRects(svg)) {
      _strokeRect(image, rect, scale, thickness: 2);
    }
    // Center circle / arcs from <circle> strokes.
    for (final _SvgCirclePaint circle in _parseSvgStrokeCircles(svg)) {
      img.drawCircle(
        image,
        x: (circle.cx * scale).round(),
        y: (circle.cy * scale).round(),
        radius: (circle.r * scale).round().clamp(2, 400),
        color: img.ColorRgba8(255, 255, 255, 255),
      );
    }

    return Uint8List.fromList(img.encodePng(image));
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('heatmapSvgStringToPngBytes failed: $e\n$st');
    }
    return null;
  }
}

Future<Uint8List?> _flutterSvgToPngBytes(
  String svg, {
  required double targetWidth,
}) async {
  try {
    final String sanitized = svg
        .replaceAll(RegExp(r'clip-path="[^"]*"'), '')
        .replaceAll(RegExp(r'<clipPath[\s\S]*?</clipPath>'), '');

    final PictureInfo pictureInfo = await vg.loadPicture(
      SvgStringLoader(sanitized),
      null,
    );
    try {
      final ui.Size size = pictureInfo.size;
      if (size.width <= 0 || size.height <= 0) {
        return null;
      }

      final int width = targetWidth.round().clamp(1, 2048);
      final int height =
          (size.height * (width / size.width)).round().clamp(1, 2048);

      final ui.Image image = await pictureInfo.picture.toImage(width, height);
      try {
        final ByteData? pngData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (pngData != null && pngData.lengthInBytes > 0) {
          return pngData.buffer.asUint8List();
        }

        // Web fallback: raw RGBA → encode with package:image.
        final ByteData? rgba = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (rgba == null || rgba.lengthInBytes == 0) {
          return null;
        }
        final img.Image raw = img.Image.fromBytes(
          width: width,
          height: height,
          bytes: rgba.buffer,
          order: img.ChannelOrder.rgba,
        );
        return Uint8List.fromList(img.encodePng(raw));
      } finally {
        image.dispose();
      }
    } finally {
      pictureInfo.picture.dispose();
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('_flutterSvgToPngBytes failed: $e\n$st');
    }
    return null;
  }
}

class _SvgSize {
  const _SvgSize(this.width, this.height);
  final double width;
  final double height;
}

class _SvgRectPaint {
  const _SvgRectPaint({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final img.ColorRgba8 color;
}

class _SvgCirclePaint {
  const _SvgCirclePaint({
    required this.cx,
    required this.cy,
    required this.r,
  });

  final double cx;
  final double cy;
  final double r;
}

_SvgSize? _parseSvgSize(String svg) {
  final RegExp viewBox = RegExp(
    r'viewBox\s*=\s*"\s*([0-9.+-eE]+)\s+([0-9.+-eE]+)\s+([0-9.+-eE]+)\s+([0-9.+-eE]+)\s*"',
  );
  final Match? vb = viewBox.firstMatch(svg);
  if (vb != null) {
    final double w = double.tryParse(vb.group(3) ?? '') ?? 0;
    final double h = double.tryParse(vb.group(4) ?? '') ?? 0;
    if (w > 0 && h > 0) return _SvgSize(w, h);
  }

  final double? w = _attrDouble(svg, 'width', rootOnly: true);
  final double? h = _attrDouble(svg, 'height', rootOnly: true);
  if (w != null && h != null && w > 0 && h > 0) {
    return _SvgSize(w, h);
  }
  return null;
}

double? _attrDouble(String source, String name, {bool rootOnly = false}) {
  final String haystack = rootOnly
      ? source.substring(0, source.length.clamp(0, 400))
      : source;
  final Match? m = RegExp(
    '$name\\s*=\\s*"([0-9.+-eE]+)"',
  ).firstMatch(haystack);
  if (m == null) return null;
  return double.tryParse(m.group(1) ?? '');
}

List<_SvgRectPaint> _parseSvgRects(String svg) {
  final RegExp re = RegExp(
    r'<rect\b([^>]*)/?>',
    caseSensitive: false,
  );
  final List<_SvgRectPaint> out = <_SvgRectPaint>[];
  for (final Match m in re.allMatches(svg)) {
    final String attrs = m.group(1) ?? '';
    if (attrs.contains('stroke') && !attrs.contains('fill')) {
      continue;
    }
    final double? x = _readAttr(attrs, 'x');
    final double? y = _readAttr(attrs, 'y');
    final double? w = _readAttr(attrs, 'width');
    final double? h = _readAttr(attrs, 'height');
    if (x == null || y == null || w == null || h == null) continue;
    if (w <= 0 || h <= 0) continue;

    final img.ColorRgba8? color = _parseFill(attrs);
    if (color == null) continue;

    out.add(
      _SvgRectPaint(x: x, y: y, width: w, height: h, color: color),
    );
  }
  return out;
}

List<_SvgCirclePaint> _parseSvgStrokeCircles(String svg) {
  final RegExp re = RegExp(
    r'<circle\b([^>]*)/?>',
    caseSensitive: false,
  );
  final List<_SvgCirclePaint> out = <_SvgCirclePaint>[];
  for (final Match m in re.allMatches(svg)) {
    final String attrs = m.group(1) ?? '';
    final double? cx = _readAttr(attrs, 'cx');
    final double? cy = _readAttr(attrs, 'cy');
    final double? r = _readAttr(attrs, 'r');
    if (cx == null || cy == null || r == null || r <= 0) continue;
    out.add(_SvgCirclePaint(cx: cx, cy: cy, r: r));
  }
  return out;
}

List<_SvgRectPaint> _parseSvgStrokeRects(String svg) {
  final RegExp re = RegExp(
    r'<rect\b([^>]*)/?>',
    caseSensitive: false,
  );
  final List<_SvgRectPaint> out = <_SvgRectPaint>[];
  for (final Match m in re.allMatches(svg)) {
    final String attrs = m.group(1) ?? '';
    if (!attrs.contains('stroke')) continue;
    final double? x = _readAttr(attrs, 'x');
    final double? y = _readAttr(attrs, 'y');
    final double? w = _readAttr(attrs, 'width');
    final double? h = _readAttr(attrs, 'height');
    if (x == null || y == null || w == null || h == null) continue;
    out.add(
      _SvgRectPaint(
        x: x,
        y: y,
        width: w,
        height: h,
        color: img.ColorRgba8(255, 255, 255, 255),
      ),
    );
  }
  return out;
}

double? _readAttr(String attrs, String name) {
  final Match? m = RegExp(
    '$name\\s*=\\s*"([0-9.+-eE]+)"',
  ).firstMatch(attrs);
  if (m == null) return null;
  return double.tryParse(m.group(1) ?? '');
}

img.ColorRgba8? _parseFill(String attrs) {
  final Match? fillMatch = RegExp(
    r'''fill\s*=\s*["']([^"']+)["']''',
  ).firstMatch(attrs);
  if (fillMatch == null) return null;
  final String fill = fillMatch.group(1)!.trim();
  if (fill == 'none') return null;

  double opacity = 1;
  final Match? op = RegExp(
    r'''fill-opacity\s*=\s*["']([0-9.+-eE]+)["']''',
  ).firstMatch(attrs);
  if (op != null) {
    opacity = (double.tryParse(op.group(1) ?? '') ?? 1).clamp(0.0, 1.0);
  }

  final img.ColorRgba8? rgb = _parseColor(fill);
  if (rgb == null) return null;
  final int alpha = ((opacity * 255).round()).clamp(0, 255).toInt();
  return img.ColorRgba8(
    rgb.r.round(),
    rgb.g.round(),
    rgb.b.round(),
    alpha,
  );
}

img.ColorRgba8? _parseColor(String raw) {
  String value = raw.trim();
  if (value.startsWith('#')) {
    value = value.substring(1);
    if (value.length == 3) {
      value = value.split('').map((c) => '$c$c').join();
    }
    if (value.length != 6) return null;
    final int? n = int.tryParse(value, radix: 16);
    if (n == null) return null;
    return img.ColorRgba8(
      (n >> 16) & 0xff,
      (n >> 8) & 0xff,
      n & 0xff,
      255,
    );
  }
  final Match? rgb = RegExp(
    r'rgba?\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)',
  ).firstMatch(value);
  if (rgb != null) {
    return img.ColorRgba8(
      (double.tryParse(rgb.group(1)!) ?? 0).round().clamp(0, 255),
      (double.tryParse(rgb.group(2)!) ?? 0).round().clamp(0, 255),
      (double.tryParse(rgb.group(3)!) ?? 0).round().clamp(0, 255),
      255,
    );
  }
  return null;
}

bool _isPitchGreen(img.ColorRgba8 color) {
  return color.g.round() > color.r.round() + 20 &&
      color.g.round() > color.b.round();
}

void _fillRect(img.Image image, _SvgRectPaint rect, double scale) {
  final int x0 = (rect.x * scale).round().clamp(0, image.width - 1);
  final int y0 = (rect.y * scale).round().clamp(0, image.height - 1);
  final int x1 =
      ((rect.x + rect.width) * scale).round().clamp(x0 + 1, image.width);
  final int y1 =
      ((rect.y + rect.height) * scale).round().clamp(y0 + 1, image.height);

  final int srcA = rect.color.a.round();
  if (srcA <= 0) return;
  final int sr = rect.color.r.round();
  final int sg = rect.color.g.round();
  final int sb = rect.color.b.round();

  for (int y = y0; y < y1; y++) {
    for (int x = x0; x < x1; x++) {
      if (srcA >= 250) {
        image.setPixelRgba(x, y, sr, sg, sb, 255);
      } else {
        final img.Pixel dst = image.getPixel(x, y);
        final int dr = dst.r.toInt();
        final int dg = dst.g.toInt();
        final int db = dst.b.toInt();
        final int inv = 255 - srcA;
        image.setPixelRgba(
          x,
          y,
          ((sr * srcA + dr * inv) / 255).round(),
          ((sg * srcA + dg * inv) / 255).round(),
          ((sb * srcA + db * inv) / 255).round(),
          255,
        );
      }
    }
  }
}

void _strokeRect(
  img.Image image,
  _SvgRectPaint rect,
  double scale, {
  int thickness = 2,
}) {
  final int x0 = (rect.x * scale).round();
  final int y0 = (rect.y * scale).round();
  final int x1 = ((rect.x + rect.width) * scale).round();
  final int y1 = ((rect.y + rect.height) * scale).round();
  img.drawRect(
    image,
    x1: x0,
    y1: y0,
    x2: x1,
    y2: y1,
    color: rect.color,
    thickness: thickness,
  );
}

/// Crops [bytes] to a circular PNG avatar for PDF markers.
///
/// Outside the circle is filled white (PDF does not composite PNG alpha —
/// transparent pixels become black).
Uint8List? circularCropPngBytes(Uint8List bytes, {int size = 96}) {
  try {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final img.Image squared = img.copyResizeCropSquare(decoded, size: size);
    final img.Image out = img.Image(width: size, height: size);
    // White, not transparent — avoids black halo in package:pdf.
    img.fill(out, color: img.ColorRgba8(255, 255, 255, 255));

    final double r = size / 2.0;
    final double r2 = r * r;
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final double dx = x + 0.5 - r;
        final double dy = y + 0.5 - r;
        if (dx * dx + dy * dy <= r2) {
          final img.Pixel p = squared.getPixel(x, y);
          out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
        }
      }
    }
    return Uint8List.fromList(img.encodePng(out));
  } catch (e) {
    if (kDebugMode) {
      debugPrint('circularCropPngBytes failed: $e');
    }
    return null;
  }
}
