import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Native (iOS / Android) platform helpers for FCM token metadata.
class NotificationFcmPlatform {
  NotificationFcmPlatform._();

  static bool get isAndroid => Platform.isAndroid;

  static bool get isIOS => Platform.isIOS;

  static String get platformLabel => Platform.isIOS
      ? 'ios'
      : Platform.isAndroid
          ? 'android'
          : 'other';

  static Future<String> deviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return info.model;
    }
    if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return '${info.name} ${info.systemVersion}';
    }
    return 'unknown';
  }
}
