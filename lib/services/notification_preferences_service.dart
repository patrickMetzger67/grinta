import 'dart:async' show Future, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// User-level reminder preferences.
///
/// Document: `users/{firebaseUid}/app_state/notification_preferences`
class NotificationPreferences {
  const NotificationPreferences({
    this.remindersEnabled = true,
    this.quietDays = const <int>[],
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
    this.morningReminderHour = 8,
    this.timezone = 'Europe/Paris',
  });

  final bool remindersEnabled;
  final List<int> quietDays;
  final int quietHoursStart;
  final int quietHoursEnd;
  final int morningReminderHour;
  final String timezone;

  NotificationPreferences copyWith({
    bool? remindersEnabled,
    List<int>? quietDays,
    int? quietHoursStart,
    int? quietHoursEnd,
    int? morningReminderHour,
    String? timezone,
  }) {
    return NotificationPreferences(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      quietDays: quietDays ?? this.quietDays,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      morningReminderHour: morningReminderHour ?? this.morningReminderHour,
      timezone: timezone ?? this.timezone,
    );
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return NotificationPreferences(timezone: detectDefaultTimezone());
    }

    final rawDays = map['quietDays'];
    final quietDays = rawDays is List
        ? rawDays
            .map((value) => int.tryParse('$value') ?? 0)
            .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
            .toList()
        : const <int>[];

    return NotificationPreferences(
      remindersEnabled: map['remindersEnabled'] != false,
      quietDays: quietDays,
      quietHoursStart: _clampHour(map['quietHoursStart'], fallback: 22),
      quietHoursEnd: _clampHour(map['quietHoursEnd'], fallback: 7),
      morningReminderHour: _clampHour(map['morningReminderHour'], fallback: 8),
      timezone: (map['timezone']?.toString().trim().isNotEmpty ?? false)
          ? map['timezone'].toString().trim()
          : detectDefaultTimezone(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'remindersEnabled': remindersEnabled,
      'quietDays': quietDays,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'morningReminderHour': morningReminderHour,
      'timezone': timezone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool isQuietAt(DateTime localDateTime) {
    if (quietDays.contains(localDateTime.weekday)) {
      return true;
    }

    final hour = localDateTime.hour;
    if (quietHoursStart == quietHoursEnd) {
      return false;
    }
    if (quietHoursStart < quietHoursEnd) {
      return hour >= quietHoursStart && hour < quietHoursEnd;
    }
    return hour >= quietHoursStart || hour < quietHoursEnd;
  }

  static int _clampHour(Object? value, {required int fallback}) {
    final parsed = int.tryParse('$value');
    if (parsed == null) return fallback;
    return parsed.clamp(0, 23);
  }
}

String detectDefaultTimezone() {
  final offsetHours = DateTime.now().timeZoneOffset.inHours;
  switch (offsetHours) {
    case 0:
      return 'Europe/London';
    case 1:
      return 'Europe/Paris';
    case 2:
      return 'Europe/Berlin';
    default:
      return 'Europe/Paris';
  }
}

class NotificationPreferencesService extends ChangeNotifier {
  NotificationPreferencesService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  static final NotificationPreferencesService instance =
      NotificationPreferencesService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NotificationPreferences _preferences =
      NotificationPreferences(timezone: detectDefaultTimezone());
  bool _initialized = false;
  Future<void>? _initFuture;
  String? _loadedUid;

  NotificationPreferences get preferences => _preferences;

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('app_state')
      .doc('notification_preferences');

  void _onAuthChanged(User? user) {
    final uid = user?.uid;
    if (uid == _loadedUid) return;
    _preferences = NotificationPreferences(timezone: detectDefaultTimezone());
    _initialized = false;
    _initFuture = null;
    _loadedUid = null;
    notifyListeners();
    if (uid != null) {
      unawaited(ensureInitialized());
    }
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _load();
    await _initFuture;
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _initialized = true;
      return;
    }

    try {
      final snap = await _docRef(uid).get();
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;

      _preferences = NotificationPreferences.fromMap(snap.data());
      _loadedUid = uid;
      _initialized = true;
      notifyListeners();
    } catch (e, st) {
      debugPrint('NotificationPreferencesService load failed: $e\n$st');
      _initialized = true;
    }
  }

  Future<void> save(NotificationPreferences preferences) async {
    await ensureInitialized();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final merged = preferences.copyWith(
      timezone: preferences.timezone.trim().isNotEmpty
          ? preferences.timezone.trim()
          : detectDefaultTimezone(),
    );

    _preferences = merged;
    notifyListeners();

    try {
      await _docRef(uid).set(merged.toMap(), SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('NotificationPreferencesService save failed: $e\n$st');
      rethrow;
    }
  }
}
