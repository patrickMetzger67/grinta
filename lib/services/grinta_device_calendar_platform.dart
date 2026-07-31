import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android helpers to make the Grinta local calendar visible in calendar apps.
///
/// No-ops on iOS / web / desktop.
class GrintaDeviceCalendarPlatform {
  GrintaDeviceCalendarPlatform._();

  static const MethodChannel _channel = MethodChannel('io.grinta.app/calendar');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Sets `VISIBLE=1` and `SYNC_EVENTS=1` on the calendar so Google Calendar
  /// and OEM apps can list it under device/local calendars.
  static Future<bool> ensureCalendarVisible(String calendarId) async {
    if (!_isAndroid) return false;
    final id = calendarId.trim();
    if (id.isEmpty) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'ensureCalendarVisible',
        {'calendarId': id},
      );
      return result == true;
    } catch (e) {
      debugPrint('GrintaDeviceCalendarPlatform.ensureCalendarVisible: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCalendarVisibility(
    String calendarId,
  ) async {
    if (!_isAndroid) return null;
    final id = calendarId.trim();
    if (id.isEmpty) return null;
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'getCalendarVisibility',
        {'calendarId': id},
      );
      if (result is Map) {
        return result.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } catch (e) {
      debugPrint('GrintaDeviceCalendarPlatform.getCalendarVisibility: $e');
      return null;
    }
  }

  static Future<bool> openCalendarApp() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('openCalendarApp');
      return result == true;
    } catch (e) {
      debugPrint('GrintaDeviceCalendarPlatform.openCalendarApp: $e');
      return false;
    }
  }
}
