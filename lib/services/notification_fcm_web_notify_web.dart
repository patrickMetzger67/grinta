import 'package:grinta/config/fcm_config.dart';
import 'package:web/web.dart' as web;

/// Shows a foreground push via the browser [Notification] API (web only).
Future<void> showWebForegroundNotification({
  required String? title,
  required String? body,
  String? icon,
}) async {
  final trimmedTitle = title?.trim();
  if (trimmedTitle == null || trimmedTitle.isEmpty) return;
  if (web.Notification.permission != 'granted') return;

  final iconUrl = icon?.trim();
  final options = web.NotificationOptions(
    body: body?.trim() ?? '',
    icon: (iconUrl != null && iconUrl.isNotEmpty)
        ? iconUrl
        : kFcmGrintaWebIconPath,
  );

  web.Notification(trimmedTitle, options);
}
