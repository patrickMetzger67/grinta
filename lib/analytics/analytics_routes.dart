import 'package:flutter/material.dart';

/// Material page route with a stable [RouteSettings.name] for analytics observers.
MaterialPageRoute<T> analyticsMaterialRoute<T>({
  required String screenName,
  required WidgetBuilder builder,
  bool fullscreenDialog = false,
  bool maintainState = true,
}) {
  return MaterialPageRoute<T>(
    settings: RouteSettings(name: screenName),
    builder: builder,
    fullscreenDialog: fullscreenDialog,
    maintainState: maintainState,
  );
}
