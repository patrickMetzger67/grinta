/// Web stub — [NotificationFcmPlatform] is unused on web (`kIsWeb` branch).
class NotificationFcmPlatform {
  NotificationFcmPlatform._();

  static bool get isAndroid => false;

  static bool get isIOS => false;

  static String get platformLabel => 'web';

  static Future<String> deviceName() async => 'browser';
}
