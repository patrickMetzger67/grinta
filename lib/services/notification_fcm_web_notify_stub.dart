/// No-op on non-web platforms.
Future<void> showWebForegroundNotification({
  required String? title,
  required String? body,
  String? icon,
}) async {}
