import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-readable Fitbit connection state (no tokens).
class FitbitSyncConfig {
  const FitbitSyncConfig({
    required this.connected,
    this.connectedAt,
    this.lastSyncedAt,
    this.fitbitUserId,
    this.initiatedBy,
    this.coachUid,
    this.coachVisibility = const FitbitCoachVisibility(),
  });

  final bool connected;
  final DateTime? connectedAt;
  final DateTime? lastSyncedAt;
  final String? fitbitUserId;
  final String? initiatedBy;
  final String? coachUid;
  final FitbitCoachVisibility coachVisibility;

  factory FitbitSyncConfig.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return FitbitSyncConfig(
      connected: data['connected'] == true,
      connectedAt: _readTimestamp(data['connectedAt']),
      lastSyncedAt: _readTimestamp(data['lastSyncedAt']),
      fitbitUserId: data['fitbitUserId'] as String?,
      initiatedBy: data['initiatedBy'] as String?,
      coachUid: data['coachUid'] as String?,
      coachVisibility: FitbitCoachVisibility.fromMap(
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
      if (fitbitUserId != null) 'fitbitUserId': fitbitUserId,
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
class FitbitCoachVisibility {
  const FitbitCoachVisibility({
    this.activity = false,
    this.heartrate = false,
    this.sleep = false,
    this.profile = false,
    this.body = false,
  });

  final bool activity;
  final bool heartrate;
  final bool sleep;
  final bool profile;
  final bool body;

  static const List<String> metricKeys = [
    'activity',
    'heartrate',
    'sleep',
    'profile',
    'body',
  ];

  factory FitbitCoachVisibility.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return FitbitCoachVisibility(
      activity: data['activity'] == true,
      heartrate: data['heartrate'] == true,
      sleep: data['sleep'] == true,
      profile: data['profile'] == true,
      body: data['body'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activity': activity,
      'heartrate': heartrate,
      'sleep': sleep,
      'profile': profile,
      'body': body,
    };
  }

  FitbitCoachVisibility copyWith({
    bool? activity,
    bool? heartrate,
    bool? sleep,
    bool? profile,
    bool? body,
  }) {
    return FitbitCoachVisibility(
      activity: activity ?? this.activity,
      heartrate: heartrate ?? this.heartrate,
      sleep: sleep ?? this.sleep,
      profile: profile ?? this.profile,
      body: body ?? this.body,
    );
  }

  bool valueForKey(String key) {
    switch (key) {
      case 'activity':
        return activity;
      case 'heartrate':
        return heartrate;
      case 'sleep':
        return sleep;
      case 'profile':
        return profile;
      case 'body':
        return body;
      default:
        return false;
    }
  }

  FitbitCoachVisibility withKey(String key, bool value) {
    switch (key) {
      case 'activity':
        return copyWith(activity: value);
      case 'heartrate':
        return copyWith(heartrate: value);
      case 'sleep':
        return copyWith(sleep: value);
      case 'profile':
        return copyWith(profile: value);
      case 'body':
        return copyWith(body: value);
      default:
        return this;
    }
  }
}
