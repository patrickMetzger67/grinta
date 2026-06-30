import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarSyncConfig {
  final bool enabled;
  final String? calendarExternalId;
  final String? calendarDisplayName;
  final DateTime? lastSyncedAt;
  final String? platform;

  const CalendarSyncConfig({
    required this.enabled,
    this.calendarExternalId,
    this.calendarDisplayName,
    this.lastSyncedAt,
    this.platform,
  });

  factory CalendarSyncConfig.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final lastSynced = data['lastSyncedAt'];
    return CalendarSyncConfig(
      enabled: data['enabled'] == true,
      calendarExternalId: data['calendarExternalId'] as String?,
      calendarDisplayName: data['calendarDisplayName'] as String?,
      lastSyncedAt: lastSynced is Timestamp ? lastSynced.toDate() : null,
      platform: data['platform'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
      if (calendarExternalId != null) 'calendarExternalId': calendarExternalId,
      if (calendarDisplayName != null)
        'calendarDisplayName': calendarDisplayName,
      if (lastSyncedAt != null)
        'lastSyncedAt': Timestamp.fromDate(lastSyncedAt!),
      if (platform != null) 'platform': platform,
    };
  }
}

class CalendarSyncEventMapEntry {
  final String grintaEventId;
  final String externalEventId;
  final String eventType;
  final String contentHash;
  final DateTime? syncedAt;

  const CalendarSyncEventMapEntry({
    required this.grintaEventId,
    required this.externalEventId,
    required this.eventType,
    required this.contentHash,
    this.syncedAt,
  });

  factory CalendarSyncEventMapEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final syncedAt = data['syncedAt'];
    return CalendarSyncEventMapEntry(
      grintaEventId: doc.id,
      externalEventId: data['externalEventId'] as String? ?? '',
      eventType: data['eventType'] as String? ?? '',
      contentHash: data['contentHash'] as String? ?? '',
      syncedAt: syncedAt is Timestamp ? syncedAt.toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'externalEventId': externalEventId,
      'eventType': eventType,
      'contentHash': contentHash,
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }
}
