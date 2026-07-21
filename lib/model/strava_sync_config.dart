import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-readable Strava connection state (no tokens).
class StravaSyncConfig {
  const StravaSyncConfig({
    required this.connected,
    this.connectedAt,
    this.lastSyncedAt,
    this.stravaAthleteId,
    this.stravaAccountHint,
    this.initiatedBy,
    this.coachUid,
    this.coachVisibility = const StravaCoachVisibility(),
  });

  final bool connected;
  final DateTime? connectedAt;
  final DateTime? lastSyncedAt;
  final String? stravaAthleteId;
  /// User-entered Strava email or username before OAuth (guidance only).
  final String? stravaAccountHint;
  final String? initiatedBy;
  final String? coachUid;
  final StravaCoachVisibility coachVisibility;

  factory StravaSyncConfig.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return StravaSyncConfig(
      connected: data['connected'] == true,
      connectedAt: _readTimestamp(data['connectedAt']),
      lastSyncedAt: _readTimestamp(data['lastSyncedAt']),
      stravaAthleteId: data['stravaAthleteId'] as String?,
      stravaAccountHint: data['stravaAccountHint'] as String?,
      initiatedBy: data['initiatedBy'] as String?,
      coachUid: data['coachUid'] as String?,
      coachVisibility: StravaCoachVisibility.fromMap(
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
      if (stravaAthleteId != null) 'stravaAthleteId': stravaAthleteId,
      if (stravaAccountHint != null) 'stravaAccountHint': stravaAccountHint,
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

/// Per-data-type coach visibility toggles (player-controlled).
class StravaCoachVisibility {
  const StravaCoachVisibility({
    this.activities = false,
    this.profile = false,
  });

  final bool activities;
  final bool profile;

  static const List<String> metricKeys = [
    'activities',
    'profile',
  ];

  factory StravaCoachVisibility.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return StravaCoachVisibility(
      activities: data['activities'] == true,
      profile: data['profile'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activities': activities,
      'profile': profile,
    };
  }

  StravaCoachVisibility copyWith({
    bool? activities,
    bool? profile,
  }) {
    return StravaCoachVisibility(
      activities: activities ?? this.activities,
      profile: profile ?? this.profile,
    );
  }

  bool valueForKey(String key) {
    switch (key) {
      case 'activities':
        return activities;
      case 'profile':
        return profile;
      default:
        return false;
    }
  }

  StravaCoachVisibility withKey(String key, bool value) {
    switch (key) {
      case 'activities':
        return copyWith(activities: value);
      case 'profile':
        return copyWith(profile: value);
      default:
        return this;
    }
  }
}
