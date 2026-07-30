import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Registers and builds an HTML iframe YouTube embed for Flutter Web.
Widget buildYoutubeEmbedView({
  required String videoId,
  required String viewType,
}) {
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = web.HTMLIFrameElement()
      ..src =
          'https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1&rel=0&modestbranding=1&origin=${Uri.encodeComponent('https://www.grinta.io')}'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true
      ..setAttribute(
        'allow',
        'accelerometer; autoplay; clipboard-write; encrypted-media; '
            'gyroscope; picture-in-picture; web-share',
      )
      ..setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
    return iframe;
  });

  return HtmlElementView(viewType: viewType);
}
