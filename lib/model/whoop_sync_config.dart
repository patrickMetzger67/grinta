import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-readable Whoop connection state (no tokens).
class WhoopSyncConfig {
  const WhoopSyncConfig({
    required this.connected,
    this.connectedAt,
    this.lastSyncedAt,
    this.whoopUserId,
    this.whoopAccountHint,
    this.initiatedBy,
    this.coachUid,
    this.coachVisibility = const WhoopCoachVisibility(),
  });

  final bool connected;
  final DateTime? connectedAt;
  final DateTime? lastSyncedAt;
  final String? whoopUserId;
  /// User-entered Whoop email before OAuth (guidance only).
  final String? whoopAccountHint;
  final String? initiatedBy;
  final String? coachUid;
  final WhoopCoachVisibility coachVisibility;

  factory WhoopSyncConfig.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return WhoopSyncConfig(
      connected: data['connected'] == true,
      connectedAt: _readTimestamp(data['connectedAt']),
      lastSyncedAt: _readTimestamp(data['lastSyncedAt']),
      whoopUserId: data['whoopUserId'] as String?,
      whoopAccountHint: data['whoopAccountHint'] as String?,
      initiatedBy: data['initiatedBy'] as String?,
      coachUid: data['coachUid'] as String?,
      coachVisibility: WhoopCoachVisibility.fromMap(
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
      if (whoopUserId != null) 'whoopUserId': whoopUserId,
      if (whoopAccountHint != null) 'whoopAccountHint': whoopAccountHint,
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
class WhoopCoachVisibility {
  const WhoopCoachVisibility({
    this.recovery = false,
    this.cycles = false,
    this.sleep = false,
    this.workout = false,
    this.profile = false,
    this.bodyMeasurement = false,
  });

  final bool recovery;
  final bool cycles;
  final bool sleep;
  final bool workout;
  final bool profile;
  final bool bodyMeasurement;

  static const List<String> metricKeys = [
    'recovery',
    'cycles',
    'sleep',
    'workout',
    'profile',
    'body_measurement',
  ];

  factory WhoopCoachVisibility.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return WhoopCoachVisibility(
      recovery: data['recovery'] == true,
      cycles: data['cycles'] == true,
      sleep: data['sleep'] == true,
      workout: data['workout'] == true,
      profile: data['profile'] == true,
      bodyMeasurement: data['body_measurement'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recovery': recovery,
      'cycles': cycles,
      'sleep': sleep,
      'workout': workout,
      'profile': profile,
      'body_measurement': bodyMeasurement,
    };
  }

  WhoopCoachVisibility copyWith({
    bool? recovery,
    bool? cycles,
    bool? sleep,
    bool? workout,
    bool? profile,
    bool? bodyMeasurement,
  }) {
    return WhoopCoachVisibility(
      recovery: recovery ?? this.recovery,
      cycles: cycles ?? this.cycles,
      sleep: sleep ?? this.sleep,
      workout: workout ?? this.workout,
      profile: profile ?? this.profile,
      bodyMeasurement: bodyMeasurement ?? this.bodyMeasurement,
    );
  }

  bool valueForKey(String key) {
    switch (key) {
      case 'recovery':
        return recovery;
      case 'cycles':
        return cycles;
      case 'sleep':
        return sleep;
      case 'workout':
        return workout;
      case 'profile':
        return profile;
      case 'body_measurement':
        return bodyMeasurement;
      default:
        return false;
    }
  }

  WhoopCoachVisibility withKey(String key, bool value) {
    switch (key) {
      case 'recovery':
        return copyWith(recovery: value);
      case 'cycles':
        return copyWith(cycles: value);
      case 'sleep':
        return copyWith(sleep: value);
      case 'workout':
        return copyWith(workout: value);
      case 'profile':
        return copyWith(profile: value);
      case 'body_measurement':
        return copyWith(bodyMeasurement: value);
      default:
        return this;
    }
  }
}
