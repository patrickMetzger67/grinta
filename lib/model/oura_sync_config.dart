import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-readable Oura connection state (no tokens).
class OuraSyncConfig {
  const OuraSyncConfig({
    required this.connected,
    this.connectedAt,
    this.lastSyncedAt,
    this.ouraUserId,
    this.ouraAccountHint,
    this.initiatedBy,
    this.coachUid,
    this.coachVisibility = const OuraCoachVisibility(),
  });

  final bool connected;
  final DateTime? connectedAt;
  final DateTime? lastSyncedAt;
  final String? ouraUserId;
  /// User-entered Oura email before OAuth (guidance only).
  final String? ouraAccountHint;
  final String? initiatedBy;
  final String? coachUid;
  final OuraCoachVisibility coachVisibility;

  factory OuraSyncConfig.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return OuraSyncConfig(
      connected: data['connected'] == true,
      connectedAt: _readTimestamp(data['connectedAt']),
      lastSyncedAt: _readTimestamp(data['lastSyncedAt']),
      ouraUserId: data['ouraUserId'] as String?,
      ouraAccountHint: data['ouraAccountHint'] as String?,
      initiatedBy: data['initiatedBy'] as String?,
      coachUid: data['coachUid'] as String?,
      coachVisibility: OuraCoachVisibility.fromMap(
        data['coachVisibility'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'connected': connected,
      if (connectedAt != null)
        'connectedAt': Timestamp.fromDate(connectedAt!),
      if (lastSyncedAt != null)
        'lastSyncedAt': Timestamp.fromDate(lastSyncedAt!),
      if (ouraUserId != null) 'ouraUserId': ouraUserId,
      if (ouraAccountHint != null) 'ouraAccountHint': ouraAccountHint,
      if (initiatedBy != null) 'initiatedBy': initiatedBy,
      if (coachUid != null) 'coachUid': coachUid,
      'coachVisibility': coachVisibility.toMap(),
    };
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}

/// Per-metric coach visibility toggles (player-controlled).
class OuraCoachVisibility {
  const OuraCoachVisibility({
    this.readiness = false,
    this.sleep = false,
    this.activity = false,
    this.workout = false,
    this.personal = false,
    this.heartrate = false,
    this.spo2 = false,
  });

  final bool readiness;
  final bool sleep;
  final bool activity;
  final bool workout;
  final bool personal;
  final bool heartrate;
  final bool spo2;

  static const List<String> metricKeys = [
    'readiness',
    'sleep',
    'activity',
    'workout',
    'personal',
    'heartrate',
    'spo2',
  ];

  factory OuraCoachVisibility.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return OuraCoachVisibility(
      readiness: data['readiness'] == true,
      sleep: data['sleep'] == true,
      activity: data['activity'] == true,
      workout: data['workout'] == true,
      personal: data['personal'] == true,
      heartrate: data['heartrate'] == true,
      spo2: data['spo2'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'readiness': readiness,
      'sleep': sleep,
      'activity': activity,
      'workout': workout,
      'personal': personal,
      'heartrate': heartrate,
      'spo2': spo2,
    };
  }

  OuraCoachVisibility copyWith({
    bool? readiness,
    bool? sleep,
    bool? activity,
    bool? workout,
    bool? personal,
    bool? heartrate,
    bool? spo2,
  }) {
    return OuraCoachVisibility(
      readiness: readiness ?? this.readiness,
      sleep: sleep ?? this.sleep,
      activity: activity ?? this.activity,
      workout: workout ?? this.workout,
      personal: personal ?? this.personal,
      heartrate: heartrate ?? this.heartrate,
      spo2: spo2 ?? this.spo2,
    );
  }

  bool valueForKey(String key) {
    switch (key) {
      case 'readiness':
        return readiness;
      case 'sleep':
        return sleep;
      case 'activity':
        return activity;
      case 'workout':
        return workout;
      case 'personal':
        return personal;
      case 'heartrate':
        return heartrate;
      case 'spo2':
        return spo2;
      default:
        return false;
    }
  }

  OuraCoachVisibility withKey(String key, bool value) {
    switch (key) {
      case 'readiness':
        return copyWith(readiness: value);
      case 'sleep':
        return copyWith(sleep: value);
      case 'activity':
        return copyWith(activity: value);
      case 'workout':
        return copyWith(workout: value);
      case 'personal':
        return copyWith(personal: value);
      case 'heartrate':
        return copyWith(heartrate: value);
      case 'spo2':
        return copyWith(spo2: value);
      default:
        return this;
    }
  }
}
