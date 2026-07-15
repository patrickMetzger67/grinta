import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-readable Polar connection state (no tokens).
class PolarSyncConfig {
  const PolarSyncConfig({
    required this.connected,
    this.connectedAt,
    this.lastSyncedAt,
    this.polarUserId,
    this.memberId,
    this.initiatedBy,
    this.coachUid,
    this.coachVisibility = const PolarCoachVisibility(),
  });

  final bool connected;
  final DateTime? connectedAt;
  final DateTime? lastSyncedAt;
  final String? polarUserId;
  final String? memberId;
  final String? initiatedBy;
  final String? coachUid;
  final PolarCoachVisibility coachVisibility;

  factory PolarSyncConfig.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PolarSyncConfig(
      connected: data['connected'] == true,
      connectedAt: _readTimestamp(data['connectedAt']),
      lastSyncedAt: _readTimestamp(data['lastSyncedAt']),
      polarUserId: data['polarUserId'] as String?,
      memberId: data['memberId'] as String?,
      initiatedBy: data['initiatedBy'] as String?,
      coachUid: data['coachUid'] as String?,
      coachVisibility: PolarCoachVisibility.fromMap(
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
      if (polarUserId != null) 'polarUserId': polarUserId,
      if (memberId != null) 'memberId': memberId,
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
class PolarCoachVisibility {
  const PolarCoachVisibility({
    this.training = false,
    this.sleep = false,
    this.recoveryHr = false,
    this.profile = false,
    this.body = false,
  });

  final bool training;
  final bool sleep;
  final bool recoveryHr;
  final bool profile;
  final bool body;

  static const List<String> metricKeys = [
    'training',
    'sleep',
    'recovery_hr',
    'profile',
    'body',
  ];

  factory PolarCoachVisibility.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return PolarCoachVisibility(
      training: data['training'] == true,
      sleep: data['sleep'] == true,
      recoveryHr: data['recovery_hr'] == true,
      profile: data['profile'] == true,
      body: data['body'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'training': training,
      'sleep': sleep,
      'recovery_hr': recoveryHr,
      'profile': profile,
      'body': body,
    };
  }

  PolarCoachVisibility copyWith({
    bool? training,
    bool? sleep,
    bool? recoveryHr,
    bool? profile,
    bool? body,
  }) {
    return PolarCoachVisibility(
      training: training ?? this.training,
      sleep: sleep ?? this.sleep,
      recoveryHr: recoveryHr ?? this.recoveryHr,
      profile: profile ?? this.profile,
      body: body ?? this.body,
    );
  }

  bool valueForKey(String key) {
    switch (key) {
      case 'training':
        return training;
      case 'sleep':
        return sleep;
      case 'recovery_hr':
        return recoveryHr;
      case 'profile':
        return profile;
      case 'body':
        return body;
      default:
        return false;
    }
  }

  PolarCoachVisibility withKey(String key, bool value) {
    switch (key) {
      case 'training':
        return copyWith(training: value);
      case 'sleep':
        return copyWith(sleep: value);
      case 'recovery_hr':
        return copyWith(recoveryHr: value);
      case 'profile':
        return copyWith(profile: value);
      case 'body':
        return copyWith(body: value);
      default:
        return this;
    }
  }
}
