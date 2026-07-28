import 'package:cloud_firestore/cloud_firestore.dart';

enum PersonalSportVisibility {
  private,
  coach,
  team,
}

enum PersonalSportEntryMode {
  manual,
  import,
}

extension PersonalSportVisibilityX on PersonalSportVisibility {
  String get firestoreValue => name;

  static PersonalSportVisibility fromFirestore(Object? value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    return PersonalSportVisibility.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => PersonalSportVisibility.private,
    );
  }
}

extension PersonalSportEntryModeX on PersonalSportEntryMode {
  String get firestoreValue => name;

  static PersonalSportEntryMode fromFirestore(Object? value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    return PersonalSportEntryMode.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => PersonalSportEntryMode.manual,
    );
  }
}

/// Player-owned personal sports activity (manual entry or device import).
class PersonalSportActivity {
  const PersonalSportActivity({
    this.id,
    required this.memberId,
    required this.createdByUserId,
    required this.startAt,
    required this.endAt,
    required this.typeId,
    required this.visibility,
    required this.entryMode,
    this.title,
    this.notes,
    this.feeling,
    this.durationSeconds,
    this.distanceMeters,
    this.paceSecondsPerKm,
    this.caloriesKcal,
    this.averageHeartRateBpm,
    this.maxHeartRateBpm,
    this.strain,
    this.altitudeGainMeters,
    this.hrZoneSeconds = const <String, int>{},
    this.hrMaxUsedBpm,
    this.distanceUnit = 'km',
    this.paceUnit = '/km',
    this.externalSource,
    this.externalId,
    this.externalDevice,
    this.seasonId,
    this.teamIds = const <String>[],
    this.accessMemberIds = const <String>[],
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String memberId;
  final String createdByUserId;
  final DateTime startAt;
  final DateTime endAt;
  final String typeId;
  final PersonalSportVisibility visibility;
  final PersonalSportEntryMode entryMode;
  final String? title;
  final String? notes;
  final int? feeling;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? paceSecondsPerKm;
  final double? caloriesKcal;
  final int? averageHeartRateBpm;
  final int? maxHeartRateBpm;
  /// Whoop activity Strain (0–21).
  final double? strain;
  final double? altitudeGainMeters;
  /// Seconds per HR zone key (`z0`…`z5` for Whoop, `z1`…`z5` for Polar).
  final Map<String, int> hrZoneSeconds;
  /// HRmax used to label Whoop %-based zone BPM ranges.
  final int? hrMaxUsedBpm;
  final String distanceUnit;
  final String paceUnit;
  final String? externalSource;
  final String? externalId;
  final String? externalDevice;
  final String? seasonId;
  final List<String> teamIds;
  final List<String> accessMemberIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasHrZones => hrZoneSeconds.values.any((seconds) => seconds > 0);

  bool get isWhoopImport =>
      (externalSource ?? '').trim().toLowerCase() == 'whoop';

  factory PersonalSportActivity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PersonalSportActivity(
      id: doc.id,
      memberId: (data['memberId'] ?? '').toString().trim(),
      createdByUserId: (data['createdByUserId'] ?? '').toString().trim(),
      startAt: _readDate(data['startAt']) ?? DateTime.now(),
      endAt: _readDate(data['endAt']) ?? DateTime.now(),
      typeId: (data['typeId'] ?? '').toString().trim(),
      visibility: PersonalSportVisibilityX.fromFirestore(data['visibility']),
      entryMode: PersonalSportEntryModeX.fromFirestore(data['entryMode']),
      title: _optionalString(data['title']),
      notes: _optionalString(data['notes']),
      feeling: _readInt(data['feeling']),
      durationSeconds: _readInt(data['durationSeconds']),
      distanceMeters: _readDouble(data['distanceMeters']),
      paceSecondsPerKm: _readInt(data['paceSecondsPerKm']),
      caloriesKcal: _readDouble(data['caloriesKcal']),
      averageHeartRateBpm: _readInt(data['averageHeartRateBpm']),
      maxHeartRateBpm: _readInt(data['maxHeartRateBpm']),
      strain: _readDouble(data['strain']),
      altitudeGainMeters: _readDouble(data['altitudeGainMeters']),
      hrZoneSeconds: _readIntMap(data['hrZoneSeconds']),
      hrMaxUsedBpm: _readInt(data['hrMaxUsedBpm']),
      distanceUnit: _optionalString(data['distanceUnit']) ?? 'km',
      paceUnit: _optionalString(data['paceUnit']) ?? '/km',
      externalSource: _optionalString(data['externalSource']),
      externalId: _optionalString(data['externalId']),
      externalDevice: _optionalString(data['externalDevice']),
      seasonId: _optionalString(data['seasonId']),
      teamIds: _readStringList(data['teamIds']),
      accessMemberIds: _readStringList(data['accessMemberIds']),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool forCreate = false}) {
    return {
      'kind': 'personalSport',
      'memberId': memberId,
      'createdByUserId': createdByUserId,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'typeId': typeId,
      'visibility': visibility.firestoreValue,
      'entryMode': entryMode.firestoreValue,
      'title': title,
      'notes': notes,
      'feeling': feeling,
      'durationSeconds': durationSeconds,
      'distanceMeters': distanceMeters,
      'paceSecondsPerKm': paceSecondsPerKm,
      'caloriesKcal': caloriesKcal,
      'averageHeartRateBpm': averageHeartRateBpm,
      'maxHeartRateBpm': maxHeartRateBpm,
      'strain': strain,
      'altitudeGainMeters': altitudeGainMeters,
      'hrZoneSeconds': hrZoneSeconds,
      'hrMaxUsedBpm': hrMaxUsedBpm,
      'distanceUnit': distanceUnit,
      'paceUnit': paceUnit,
      'externalSource': externalSource,
      'externalId': externalId,
      'externalDevice': externalDevice,
      if (seasonId != null) 'seasonId': seasonId,
      'teamIds': teamIds,
      'accessMemberIds': accessMemberIds,
      'updatedAt': FieldValue.serverTimestamp(),
      if (forCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _readDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim().replaceAll(',', '.'));
    }
    return null;
  }

  static String? _optionalString(Object? value) {
    final trimmed = value?.toString().trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return const <String>[];
    return [
      for (final entry in value)
        if ((entry?.toString().trim() ?? '').isNotEmpty) entry.toString().trim(),
    ];
  }

  static Map<String, int> _readIntMap(Object? value) {
    if (value is! Map) return const <String, int>{};
    final out = <String, int>{};
    value.forEach((key, raw) {
      final parsed = _readInt(raw);
      if (parsed != null) out[key.toString()] = parsed;
    });
    return out;
  }
}
