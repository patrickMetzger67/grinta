import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Rasterizes an SVG string to PNG bytes for embedding in PDF reports.
Future<Uint8List?> svgStringToPngBytes(
  String svg, {
  double targetWidth = 720,
}) async {
  final String trimmed = svg.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  try {
    final PictureInfo pictureInfo = await vg.loadPicture(
      SvgStringLoader(trimmed),
      null,
    );
    try {
      final ui.Size size = pictureInfo.size;
      if (size.width <= 0 || size.height <= 0) {
        return null;
      }

      final double scale = targetWidth / size.width;
      final int width = targetWidth.round().clamp(1, 2048);
      final int height =
          (size.height * scale).round().clamp(1, 2048);

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.scale(width / size.width, height / size.height);
      canvas.drawPicture(pictureInfo.picture);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(width, height);
      try {
        final ByteData? bytes = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        return bytes?.buffer.asUint8List();
      } finally {
        image.dispose();
        picture.dispose();
      }
    } finally {
      pictureInfo.picture.dispose();
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('svgStringToPngBytes failed: $e\n$st');
    }
    return null;
  }
}
