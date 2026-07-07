import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:grinta/config/fcm_config.dart';
import 'package:grinta/services/notification_fcm_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local reminder notifications (native only).
class LocalReminderScheduler {
  LocalReminderScheduler._();

  static final LocalReminderScheduler instance = LocalReminderScheduler._();

  static const String androidChannelId = 'grinta_reminders';
  static const String androidChannelName = 'Rappels';

  bool _initialized = false;

  FlutterLocalNotificationsPlugin get _plugin =>
      NotificationFCMService.localNotificationsPlugin;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Paris'));
    } catch (e, st) {
      debugPrint('LocalReminderScheduler timezone init: $e\n$st');
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        androidChannelId,
        androidChannelName,
        description: 'Rappels entraînement et match',
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  Future<void> cancelReminder(String reminderKey) async {
    if (kIsWeb) return;
    await _plugin.cancel(_notificationIdFor(reminderKey));
  }

  Future<void> scheduleReminder({
    required String reminderKey,
    required DateTime scheduledAtLocal,
    required String timezoneName,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    if (kIsWeb) return;
    if (scheduledAtLocal.isBefore(DateTime.now())) return;

    await init();

    tz.Location location;
    try {
      location = tz.getLocation(timezoneName);
    } catch (_) {
      location = tz.local;
    }

    final scheduled = tz.TZDateTime.from(scheduledAtLocal, location);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        androidChannelName,
        icon: kFcmAndroidNotificationIcon,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      _notificationIdFor(reminderKey),
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode(payload),
    );
  }

  int _notificationIdFor(String reminderKey) {
    return reminderKey.hashCode & 0x7fffffff;
  }
}
