import 'package:cloud_firestore/cloud_firestore.dart';

/// Cardio-oriented session analysis for Polar team-kit sensors
/// (Verity Sense, Loop, …) — **not** pitch GPS.
///
/// Stored in `TRACKER_PolarAnalysis/{eventId}_{trackerId}`.
/// Parallel to [TrackerAnalysisResult] in `TRACKER_Analysis` (GNSS kits).
class PolarSessionAnalysis {
  const PolarSessionAnalysis({
    required this.eventId,
    required this.playerId,
    required this.trackerId,
    required this.polarDeviceId,
    required this.deviceType,
    required this.duration,
    this.startedAt,
    this.endedAt,
    this.avgHrBpm,
    this.maxHrBpm,
    this.minHrBpm,
    this.hrSamplesCount = 0,
    this.hrZoneSeconds = const <String, int>{},
    this.caloriesKcal,
    this.distanceMeters,
    this.steps,
    this.importChannel = PolarImportChannel.bleMobile,
    this.importedAt,
    this.importedUid,
    this.sourceFirmware,
    this.createdAt,
    this.updatedAt,
  });

  /// Training / match id.
  final String eventId;

  /// Grinta player id.
  final String playerId;

  /// `TRACKER_DeviceOwner` doc id (same key as `PlayerTraining.deviceId`).
  final String trackerId;

  /// Polar BLE device id (`TRACKER_Device.id`).
  final String polarDeviceId;

  /// e.g. `Verity Sense`, `Loop`, `H10`.
  final String deviceType;

  final Duration duration;
  final DateTime? startedAt;
  final DateTime? endedAt;

  final int? avgHrBpm;
  final int? maxHrBpm;
  final int? minHrBpm;
  final int hrSamplesCount;

  /// Seconds spent in each HR zone (`z1`…`z5` or custom keys).
  final Map<String, int> hrZoneSeconds;

  /// Loop / activity extras (usually null on Verity Sense).
  final double? caloriesKcal;
  final double? distanceMeters;
  final int? steps;

  final PolarImportChannel importChannel;
  final DateTime? importedAt;
  final String? importedUid;
  final String? sourceFirmware;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const String provider = 'polar';
  static const String kind = 'cardio';

  /// Firestore doc id convention (mirrors GPS `{eventId}_{trackerId}`).
  static String docIdFor({
    required String eventId,
    required String trackerId,
  }) =>
      '${eventId.trim()}_${trackerId.trim()}';

  String get docId => docIdFor(eventId: eventId, trackerId: trackerId);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'eventId': eventId,
      'playerId': playerId,
      'trackerId': trackerId,
      'polarDeviceId': polarDeviceId,
      'deviceType': deviceType,
      'provider': provider,
      'kind': kind,
      'durationMs': duration.inMilliseconds,
      'startedAt':
          startedAt != null ? Timestamp.fromDate(startedAt!.toUtc()) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!.toUtc()) : null,
      'avgHrBpm': avgHrBpm,
      'maxHrBpm': maxHrBpm,
      'minHrBpm': minHrBpm,
      'hrSamplesCount': hrSamplesCount,
      'hrZoneSeconds': hrZoneSeconds,
      'caloriesKcal': caloriesKcal,
      'distanceMeters': distanceMeters,
      'steps': steps,
      'importChannel': importChannel.wireValue,
      'importedAt':
          importedAt != null ? Timestamp.fromDate(importedAt!.toUtc()) : null,
      'importedUid': importedUid,
      'sourceFirmware': sourceFirmware,
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!.toUtc()) : null,
      'updatedAt':
          updatedAt != null ? Timestamp.fromDate(updatedAt!.toUtc()) : null,
    };
  }

  factory PolarSessionAnalysis.fromMap(Map<String, dynamic> map) {
    return PolarSessionAnalysis(
      eventId: (map['eventId'] ?? '').toString(),
      playerId: (map['playerId'] ?? '').toString(),
      trackerId: (map['trackerId'] ?? '').toString(),
      polarDeviceId: (map['polarDeviceId'] ?? '').toString(),
      deviceType: (map['deviceType'] ?? 'other').toString(),
      duration: Duration(milliseconds: _toInt(map['durationMs'])),
      startedAt: _toDateTime(map['startedAt']),
      endedAt: _toDateTime(map['endedAt']),
      avgHrBpm: _toNullableInt(map['avgHrBpm']),
      maxHrBpm: _toNullableInt(map['maxHrBpm']),
      minHrBpm: _toNullableInt(map['minHrBpm']),
      hrSamplesCount: _toInt(map['hrSamplesCount']),
      hrZoneSeconds: _toIntMap(map['hrZoneSeconds']),
      caloriesKcal: _toNullableDouble(map['caloriesKcal']),
      distanceMeters: _toNullableDouble(map['distanceMeters']),
      steps: _toNullableInt(map['steps']),
      importChannel:
          PolarImportChannel.fromWire(map['importChannel']?.toString()),
      importedAt: _toDateTime(map['importedAt']),
      importedUid: map['importedUid']?.toString(),
      sourceFirmware: map['sourceFirmware']?.toString(),
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  factory PolarSessionAnalysis.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return PolarSessionAnalysis.fromMap(doc.data() ?? <String, dynamic>{});
  }

  PolarSessionAnalysis copyWith({
    String? eventId,
    String? playerId,
    String? trackerId,
    String? polarDeviceId,
    String? deviceType,
    Duration? duration,
    DateTime? startedAt,
    DateTime? endedAt,
    int? avgHrBpm,
    int? maxHrBpm,
    int? minHrBpm,
    int? hrSamplesCount,
    Map<String, int>? hrZoneSeconds,
    double? caloriesKcal,
    double? distanceMeters,
    int? steps,
    PolarImportChannel? importChannel,
    DateTime? importedAt,
    String? importedUid,
    String? sourceFirmware,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PolarSessionAnalysis(
      eventId: eventId ?? this.eventId,
      playerId: playerId ?? this.playerId,
      trackerId: trackerId ?? this.trackerId,
      polarDeviceId: polarDeviceId ?? this.polarDeviceId,
      deviceType: deviceType ?? this.deviceType,
      duration: duration ?? this.duration,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      avgHrBpm: avgHrBpm ?? this.avgHrBpm,
      maxHrBpm: maxHrBpm ?? this.maxHrBpm,
      minHrBpm: minHrBpm ?? this.minHrBpm,
      hrSamplesCount: hrSamplesCount ?? this.hrSamplesCount,
      hrZoneSeconds: hrZoneSeconds ?? this.hrZoneSeconds,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      steps: steps ?? this.steps,
      importChannel: importChannel ?? this.importChannel,
      importedAt: importedAt ?? this.importedAt,
      importedUid: importedUid ?? this.importedUid,
      sourceFirmware: sourceFirmware ?? this.sourceFirmware,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  static int? _toNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString());
  }

  static double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  static Map<String, int> _toIntMap(dynamic v) {
    if (v is! Map) return <String, int>{};
    final out = <String, int>{};
    v.forEach((key, value) {
      out[key.toString()] = _toInt(value);
    });
    return out;
  }
}

/// How the Polar session file / samples were pulled into Grinta.
enum PolarImportChannel {
  bleMobile,
  bleChrome,
  manual;

  String get wireValue {
    switch (this) {
      case PolarImportChannel.bleMobile:
        return 'ble_mobile';
      case PolarImportChannel.bleChrome:
        return 'ble_chrome';
      case PolarImportChannel.manual:
        return 'manual';
    }
  }

  static PolarImportChannel fromWire(String? value) {
    switch ((value ?? '').trim()) {
      case 'ble_chrome':
        return PolarImportChannel.bleChrome;
      case 'manual':
        return PolarImportChannel.manual;
      case 'ble_mobile':
      default:
        return PolarImportChannel.bleMobile;
    }
  }
}
