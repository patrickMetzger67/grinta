import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// iPad / Mac popover origin that stays inside the Flutter view.
///
/// share_plus rejects a [sharePositionOrigin] that is empty or larger than
/// the root view (e.g. a scrollable synthèse card). A 1×1 point on the
/// share button, clamped to the screen, is always valid.
Rect shareSheetOrigin(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final maxX = size.width > 2 ? size.width - 1 : 1.0;
  final maxY = size.height > 2 ? size.height - 1 : 1.0;

  var x = size.width / 2;
  var y = size.height / 2;
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    final global = box.localToGlobal(box.size.center(Offset.zero));
    x = global.dx;
    y = global.dy;
  }

  return Rect.fromLTWH(
    x.clamp(1.0, maxX),
    y.clamp(1.0, maxY),
    1,
    1,
  );
}

/// Shares a PNG only so iOS presents « 1 image » (not text + document).
///
/// Writes a `.png` file: in-memory [XFile.fromData] is often typed as a
/// generic document, which hides WhatsApp / Instagram on the share sheet.
Future<ShareResult> sharePng({
  required Uint8List pngBytes,
  required String fileName,
  Rect? sharePositionOrigin,
}) async {
  if (pngBytes.isEmpty) {
    throw StateError('sharePng: empty PNG');
  }

  final name = fileName.toLowerCase().endsWith('.png')
      ? fileName
      : '$fileName.png';
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(pngBytes, flush: true);

  return SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(file.path, mimeType: 'image/png', name: name),
      ],
      fileNameOverrides: <String>[name],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
