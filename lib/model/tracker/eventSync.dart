import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceSync {
  final String deviceId;
  bool dataDownloaded;
  Timestamp? dataDownloadedAt;
  String? dataDownloadedUid;
  bool erased;
  Timestamp? erasedAt;
  String? erasedUid;
  bool withAsiFile;
  Timestamp? withAsiFileAt;
  String? withAsiFileUid;

  DeviceSync({
    required this.deviceId,
    this.dataDownloaded = false,
    this.dataDownloadedAt,
    this.dataDownloadedUid,
    this.erased = false,
    this.erasedAt,
    this.erasedUid,
    this.withAsiFile = false,
    this.withAsiFileAt,
    this.withAsiFileUid,
  });

  factory DeviceSync.fromMap(Map<String, dynamic> map) {
    return DeviceSync(
      deviceId: map['deviceId'] ?? '',
      dataDownloaded: map['dataDownloaded'] ?? false,
      dataDownloadedAt: map['dataDownloadedAt'],
      dataDownloadedUid: map['dataDownloadedUid'],
      erased: map['erased'] ?? false,
      erasedAt: map['erasedAt'],
      erasedUid: map['erasedUid'],
      withAsiFile: map['withAsiFile'] ?? false,
      withAsiFileAt: map['withAsiFileAt'],
      withAsiFileUid: map['withAsiFileUid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'dataDownloaded': dataDownloaded,
      'dataDownloadedAt': dataDownloadedAt,
      'dataDownloadedUid': dataDownloadedUid,
      'erased': erased,
      'erasedAt': erasedAt,
      'erasedUid': erasedUid,
      'withAsiFile': withAsiFile,
      'withAsiFileAt': withAsiFileAt,
      'withAsiFileUid': withAsiFileUid,
    };
  }

  /// Device is considered synced when USB download+erase completed, or ASI path done.
  bool get isSynced => (dataDownloaded && erased) || withAsiFile;

  DeviceSync copyWith({
    String? deviceId,
    bool? dataDownloaded,
    Timestamp? dataDownloadedAt,
    String? dataDownloadedUid,
    bool? erased,
    Timestamp? erasedAt,
    String? erasedUid,
    bool? withAsiFile,
    Timestamp? withAsiFileAt,
    String? withAsiFileUid,
  }) {
    return DeviceSync(
      deviceId: deviceId ?? this.deviceId,
      dataDownloaded: dataDownloaded ?? this.dataDownloaded,
      dataDownloadedAt: dataDownloadedAt ?? this.dataDownloadedAt,
      dataDownloadedUid: dataDownloadedUid ?? this.dataDownloadedUid,
      erased: erased ?? this.erased,
      erasedAt: erasedAt ?? this.erasedAt,
      erasedUid: erasedUid ?? this.erasedUid,
      withAsiFile: withAsiFile ?? this.withAsiFile,
      withAsiFileAt: withAsiFileAt ?? this.withAsiFileAt,
      withAsiFileUid: withAsiFileUid ?? this.withAsiFileUid,
    );
  }
}

class EventSync {
  /// Firestore document id (`TRACKER_Sync/{docId}`).
  final String? docId;

  /// Business event id (training / match). Often equals [docId].
  final String eventId;

  /// `true` when every expected device for this event is fully synced.
  bool isFullySynced;

  Timestamp? syncStartAt;
  String? syncStartUid;
  Timestamp? syncEndAt;
  String? syncEndUid;
  Map<String, DeviceSync> devices;

  EventSync({
    this.docId,
    required this.eventId,
    this.isFullySynced = false,
    this.syncStartAt,
    this.syncStartUid,
    this.syncEndAt,
    this.syncEndUid,
    this.devices = const {},
  });

  factory EventSync.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final rawDevices = data['devices'] as Map<String, dynamic>? ?? {};
    final parsedDevices = rawDevices.map(
      (key, value) => MapEntry(
        key,
        DeviceSync.fromMap(Map<String, dynamic>.from(value)),
      ),
    );

    final storedEventId = data['eventId']?.toString().trim();

    return EventSync(
      docId: doc.id,
      eventId: (storedEventId != null && storedEventId.isNotEmpty)
          ? storedEventId
          : doc.id,
      isFullySynced: data['isFullySynced'] ?? false,
      syncStartAt: data['syncStartAt'],
      syncStartUid: data['syncStartUid'],
      syncEndAt: data['syncEndAt'],
      syncEndUid: data['syncEndUid'],
      devices: parsedDevices,
    );
  }

  factory EventSync.fromMap(
    Map<String, dynamic> map, {
    required String eventId,
    String? docId,
  }) {
    final rawDevices = map['devices'] as Map<String, dynamic>? ?? {};
    final parsedDevices = rawDevices.map(
      (key, value) => MapEntry(
        key,
        DeviceSync.fromMap(Map<String, dynamic>.from(value)),
      ),
    );

    final storedEventId = map['eventId']?.toString().trim();

    return EventSync(
      docId: docId,
      eventId: (storedEventId != null && storedEventId.isNotEmpty)
          ? storedEventId
          : eventId,
      isFullySynced: map['isFullySynced'] ?? false,
      syncStartAt: map['syncStartAt'],
      syncStartUid: map['syncStartUid'],
      syncEndAt: map['syncEndAt'],
      syncEndUid: map['syncEndUid'],
      devices: parsedDevices,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'isFullySynced': isFullySynced,
      'syncStartAt': syncStartAt,
      'syncStartUid': syncStartUid,
      'syncEndAt': syncEndAt,
      'syncEndUid': syncEndUid,
      'devices': devices.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  EventSync copyWith({
    String? docId,
    String? eventId,
    bool? isFullySynced,
    Timestamp? syncStartAt,
    String? syncStartUid,
    Timestamp? syncEndAt,
    String? syncEndUid,
    Map<String, DeviceSync>? devices,
  }) {
    return EventSync(
      docId: docId ?? this.docId,
      eventId: eventId ?? this.eventId,
      isFullySynced: isFullySynced ?? this.isFullySynced,
      syncStartAt: syncStartAt ?? this.syncStartAt,
      syncStartUid: syncStartUid ?? this.syncStartUid,
      syncEndAt: syncEndAt ?? this.syncEndAt,
      syncEndUid: syncEndUid ?? this.syncEndUid,
      devices: devices ?? this.devices,
    );
  }
}
