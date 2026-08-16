import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-readable Google Health Connect connection state (no OAuth tokens).
class GoogleHealthSyncConfig {
  const GoogleHealthSyncConfig({
    required this.connected,
    this.connectedAt,
    this.lastSyncedAt,
    this.recentWorkoutCount,
    this.mostRecentWorkoutAt,
    this.initiatedBy,
    this.coachUid,
    this.coachVisibility = const GoogleHealthCoachVisibility(),
  });

  final bool connected;
  final DateTime? connectedAt;
  final DateTime? lastSyncedAt;
  final int? recentWorkoutCount;
  final DateTime? mostRecentWorkoutAt;
  final String? initiatedBy;
  final String? coachUid;
  final GoogleHealthCoachVisibility coachVisibility;

  factory GoogleHealthSyncConfig.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return GoogleHealthSyncConfig(
      connected: data['connected'] == true,
      connectedAt: _readTimestamp(data['connectedAt']),
      lastSyncedAt: _readTimestamp(data['lastSyncedAt']),
      recentWorkoutCount: data['recentWorkoutCount'] as int?,
      mostRecentWorkoutAt: _readTimestamp(data['mostRecentWorkoutAt']),
      initiatedBy: data['initiatedBy'] as String?,
      coachUid: data['coachUid'] as String?,
      coachVisibility: GoogleHealthCoachVisibility.fromMap(
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
      if (recentWorkoutCount != null)
        'recentWorkoutCount': recentWorkoutCount,
      if (mostRecentWorkoutAt != null)
        'mostRecentWorkoutAt': Timestamp.fromDate(mostRecentWorkoutAt!),
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
///
/// Only metrics that Google Health Connect actually imports today.
/// Sleep is intentionally omitted — we do not request READ_SLEEP.
class GoogleHealthCoachVisibility {
  const GoogleHealthCoachVisibility({
    this.activity = false,
    this.heartrate = false,
    this.activeEnergy = false,
    this.sleep = false,
  });

  final bool activity;
  final bool heartrate;

  /// Calories associated with imported workouts (from Exercise / Total calories).
  final bool activeEnergy;

  /// Kept for Firestore backward compatibility; not shown in UI and not synced.
  final bool sleep;

  static const List<String> metricKeys = [
    'activity',
    'heartrate',
    'activeEnergy',
  ];

  factory GoogleHealthCoachVisibility.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return GoogleHealthCoachVisibility(
      activity: data['activity'] == true,
      heartrate: data['heartrate'] == true,
      activeEnergy: data['activeEnergy'] == true,
      sleep: data['sleep'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activity': activity,
      'heartrate': heartrate,
      'activeEnergy': activeEnergy,
      'sleep': sleep,
    };
  }

  GoogleHealthCoachVisibility copyWith({
    bool? activity,
    bool? heartrate,
    bool? activeEnergy,
    bool? sleep,
  }) {
    return GoogleHealthCoachVisibility(
      activity: activity ?? this.activity,
      heartrate: heartrate ?? this.heartrate,
      activeEnergy: activeEnergy ?? this.activeEnergy,
      sleep: sleep ?? this.sleep,
    );
  }

  bool valueForKey(String key) {
    switch (key) {
      case 'activity':
        return activity;
      case 'heartrate':
        return heartrate;
      case 'activeEnergy':
        return activeEnergy;
      case 'sleep':
        return sleep;
      default:
        return false;
    }
  }

  GoogleHealthCoachVisibility withKey(String key, bool value) {
    switch (key) {
      case 'activity':
        return copyWith(activity: value);
      case 'heartrate':
        return copyWith(heartrate: value);
      case 'activeEnergy':
        return copyWith(activeEnergy: value);
      case 'sleep':
        return copyWith(sleep: value);
      default:
        return this;
    }
  }
}
