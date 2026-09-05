import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';

/// Keyboard height in logical pixels.
///
/// Reads the platform view inset so it still works *inside* a [Scaffold]
/// that already consumed [MediaQuery.viewInsets] via
/// `resizeToAvoidBottomInset`.
double softKeyboardInset(BuildContext context) {
  final FlutterView view = View.of(context);
  return view.viewInsets.bottom / view.devicePixelRatio;
}

/// True when the software keyboard is open enough to steal vertical space
/// on a phone (match header + filter would otherwise be pushed off-screen).
bool isSoftKeyboardOpen(BuildContext context, {double minInset = 80}) {
  // Register a MediaQuery dependency so the caller rebuilds as the
  // keyboard animates (View.of alone does not).
  MediaQuery.maybeViewInsetsOf(context);
  return softKeyboardInset(context) > minInset;
}
