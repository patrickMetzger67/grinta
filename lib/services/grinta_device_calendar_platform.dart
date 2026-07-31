import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenCalendarResult {
  const OpenCalendarResult({
    required this.ok,
    this.via,
    this.detail,
  });

  final bool ok;
  final String? via;
  final String? detail;

  static const OpenCalendarResult unsupported = OpenCalendarResult(
    ok: false,
    detail: 'unsupported',
  );
}

/// Android helpers to make the Grinta local calendar visible in calendar apps.
///
/// No-ops on web/desktop. On iOS opens the system Calendar via `calshow:`.
class GrintaDeviceCalendarPlatform {
  GrintaDeviceCalendarPlatform._();

  static const MethodChannel _channel = MethodChannel('io.grinta.app/calendar');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

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

  /// Opens the device calendar app focused on [calendarId] when possible.
  static Future<OpenCalendarResult> openCalendarApp({String? calendarId}) async {
    if (kIsWeb) return OpenCalendarResult.unsupported;

    if (_isAndroid) {
      try {
        final raw = await _channel.invokeMethod<dynamic>(
          'openCalendarApp',
          {
            if (calendarId != null && calendarId.trim().isNotEmpty)
              'calendarId': calendarId.trim(),
          },
        );
        final map = raw is Map
            ? raw.map((key, value) => MapEntry(key.toString(), value))
            : null;
        if (map?['ok'] == true) {
          return OpenCalendarResult(
            ok: true,
            via: map?['via']?.toString(),
          );
        }
        debugPrint(
          'GrintaDeviceCalendarPlatform.openCalendarApp native failed: $map',
        );
      } catch (e) {
        debugPrint('GrintaDeviceCalendarPlatform.openCalendarApp: $e');
      }

      final launched = await _launchAndroidCalendarUrl();
      if (launched) {
        return const OpenCalendarResult(ok: true, via: 'url_launcher');
      }
      return const OpenCalendarResult(ok: false, detail: 'android_failed');
    }

    if (_isIOS) {
      // Apple Absolute Time seconds since 2001-01-01.
      final seconds =
          (DateTime.now().millisecondsSinceEpoch / 1000) - 978307200;
      try {
        final ok = await launchUrl(
          Uri.parse('calshow:${seconds.round()}'),
          mode: LaunchMode.externalApplication,
        );
        return ok
            ? const OpenCalendarResult(ok: true, via: 'calshow')
            : const OpenCalendarResult(ok: false, detail: 'calshow_failed');
      } catch (e) {
        debugPrint('GrintaDeviceCalendarPlatform.openCalendarApp iOS: $e');
        return OpenCalendarResult(ok: false, detail: '$e');
      }
    }

    return OpenCalendarResult.unsupported;
  }

  static Future<bool> _launchAndroidCalendarUrl() async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    try {
      return await launchUrl(
        Uri.parse('content://com.android.calendar/time/$ms'),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('GrintaDeviceCalendarPlatform.url_launcher fallback: $e');
      return false;
    }
  }
}
