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
    this.workout = false,
    this.heartrate = false,
    this.daily = false,
    this.personal = false,
    this.email = false,
  });

  final bool workout;
  final bool heartrate;
  final bool daily;
  final bool personal;
  final bool email;

  static const List<String> metricKeys = [
    'workout',
    'heartrate',
    'daily',
    'personal',
    'email',
  ];

  factory OuraCoachVisibility.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return OuraCoachVisibility(
      workout: data['workout'] == true,
      heartrate: data['heartrate'] == true,
      daily: data['daily'] == true,
      personal: data['personal'] == true,
      email: data['email'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workout': workout,
      'heartrate': heartrate,
      'daily': daily,
      'personal': personal,
      'email': email,
    };
  }

  OuraCoachVisibility copyWith({
    bool? workout,
    bool? heartrate,
    bool? daily,
    bool? personal,
    bool? email,
  }) {
    return OuraCoachVisibility(
      workout: workout ?? this.workout,
      heartrate: heartrate ?? this.heartrate,
      daily: daily ?? this.daily,
      personal: personal ?? this.personal,
      email: email ?? this.email,
    );
  }

  bool valueForKey(String key) {
    switch (key) {
      case 'workout':
        return workout;
      case 'heartrate':
        return heartrate;
      case 'daily':
        return daily;
      case 'personal':
        return personal;
      case 'email':
        return email;
      default:
        return false;
    }
  }

  OuraCoachVisibility withKey(String key, bool value) {
    switch (key) {
      case 'workout':
        return copyWith(workout: value);
      case 'heartrate':
        return copyWith(heartrate: value);
      case 'daily':
        return copyWith(daily: value);
      case 'personal':
        return copyWith(personal: value);
      case 'email':
        return copyWith(email: value);
      default:
        return this;
    }
  }
}
