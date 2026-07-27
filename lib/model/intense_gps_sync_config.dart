import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-readable GPS Insiders Intense claim state for a player profile.
class IntenseGpsSyncConfig {
  const IntenseGpsSyncConfig({
    required this.connected,
    this.connectedAt,
    this.serialNumber,
    this.deviceId,
    this.ownerId,
    this.deviceOwnerId,
    this.initiatedBy,
    this.coachUid,
  });

  final bool connected;
  final DateTime? connectedAt;
  final String? serialNumber;
  final String? deviceId;
  final String? ownerId;
  final String? deviceOwnerId;
  final String? initiatedBy;
  final String? coachUid;

  factory IntenseGpsSyncConfig.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return IntenseGpsSyncConfig(
      connected: data['connected'] == true,
      connectedAt: _readTimestamp(data['connectedAt']),
      serialNumber: data['serialNumber'] as String?,
      deviceId: data['deviceId'] as String?,
      ownerId: data['ownerId'] as String?,
      deviceOwnerId: data['deviceOwnerId'] as String?,
      initiatedBy: data['initiatedBy'] as String?,
      coachUid: data['coachUid'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'connected': connected,
      if (connectedAt != null)
        'connectedAt': Timestamp.fromDate(connectedAt!),
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (deviceId != null) 'deviceId': deviceId,
      if (ownerId != null) 'ownerId': ownerId,
      if (deviceOwnerId != null) 'deviceOwnerId': deviceOwnerId,
      if (initiatedBy != null) 'initiatedBy': initiatedBy,
      if (coachUid != null) 'coachUid': coachUid,
    };
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
