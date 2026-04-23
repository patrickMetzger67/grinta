import 'package:cloud_firestore/cloud_firestore.dart';

class TeamSpeedZone {
  final String zoneId;
  final String label;
  final double minKmh;
  final double? maxKmh;

  const TeamSpeedZone({
    required this.zoneId,
    required this.label,
    required this.minKmh,
    this.maxKmh,
  });

  bool contains(double speedKmh) {
    return speedKmh >= minKmh && (maxKmh == null || speedKmh < maxKmh!);
  }

  Map<String, dynamic> toMap() {
    return {
      'zoneId': zoneId,
      'label': label,
      'minKmh': minKmh,
      'maxKmh': maxKmh,
    };
  }

  factory TeamSpeedZone.fromMap(Map<String, dynamic> map) {
    return TeamSpeedZone(
      zoneId: (map['zoneId'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      minKmh: _toDouble(map['minKmh']),
      maxKmh: map['maxKmh'] == null ? null : _toDouble(map['maxKmh']),
    );
  }

  TeamSpeedZone copyWith({
    String? zoneId,
    String? label,
    double? minKmh,
    double? maxKmh,
    bool clearMaxKmh = false,
  }) {
    return TeamSpeedZone(
      zoneId: zoneId ?? this.zoneId,
      label: label ?? this.label,
      minKmh: minKmh ?? this.minKmh,
      maxKmh: clearMaxKmh ? null : (maxKmh ?? this.maxKmh),
    );
  }

  static List<TeamSpeedZone> defaultZones() {
    return const [
      TeamSpeedZone(zoneId: 'Z1', label: 'Marche', minKmh: 0.0, maxKmh: 7.0),
      TeamSpeedZone(zoneId: 'Z2', label: 'Jogging', minKmh: 7.0, maxKmh: 13.0),
      TeamSpeedZone(zoneId: 'Z3', label: 'Course', minKmh: 13.0, maxKmh: 18.0),
      TeamSpeedZone(zoneId: 'Z4', label: 'Haute intensité', minKmh: 18.0, maxKmh: 21.0),
      TeamSpeedZone(zoneId: 'Z5', label: 'Sprint', minKmh: 21.0, maxKmh: null),
    ];
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }
}

class TeamParam {
  static const String defaultTeamId = '0';

  final String teamId;

  final double sprintThresholdKmh;
  final double minSprintAccelerationMps2;
  final double maxAcceptedStepDistanceMeters;

  final int sprintMinDurationMs;
  final double highAccelerationThresholdMps2;
  final int highAccelerationMinDurationMs;

  final double maxPlausibleSpeedMps;
  final double maxPlausibleAccelerationMps2;

  final int minDtMs;
  final int maxDtMs;
  final int smoothingWindow;
  final int validatedSpeedMinDurationMs;
  final int timelineBucketMs;

  final List<TeamSpeedZone> speedZones;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TeamParam({
    required this.teamId,
    required this.sprintThresholdKmh,
    required this.minSprintAccelerationMps2,
    required this.maxAcceptedStepDistanceMeters,
    required this.sprintMinDurationMs,
    required this.highAccelerationThresholdMps2,
    required this.highAccelerationMinDurationMs,
    required this.maxPlausibleSpeedMps,
    required this.maxPlausibleAccelerationMps2,
    required this.minDtMs,
    required this.maxDtMs,
    required this.smoothingWindow,
    required this.validatedSpeedMinDurationMs,
    required this.timelineBucketMs,
    required this.speedZones,
    this.createdAt,
    this.updatedAt,
  });

  factory TeamParam.defaultConfig({String teamId = defaultTeamId}) {
    return TeamParam(
      teamId: teamId,
      sprintThresholdKmh: 20.0,
      minSprintAccelerationMps2: 2.0,
      maxAcceptedStepDistanceMeters: 50.0,
      sprintMinDurationMs: 1200,
      highAccelerationThresholdMps2: 3.5,
      highAccelerationMinDurationMs: 300,
      maxPlausibleSpeedMps: 10.5,
      maxPlausibleAccelerationMps2: 8.0,
      minDtMs: 80,
      maxDtMs: 3000,
      smoothingWindow: 5,
      validatedSpeedMinDurationMs: 800,
      timelineBucketMs: 5 * 60 * 1000,
      speedZones: TeamSpeedZone.defaultZones(),
    );
  }

  double get sprintThresholdMps => sprintThresholdKmh / 3.6;

  bool get isDefault => teamId == defaultTeamId;

  List<TeamSpeedZone> get orderedSpeedZones {
    final list = [...speedZones];
    list.sort((a, b) => a.minKmh.compareTo(b.minKmh));
    return list;
  }

  TeamSpeedZone resolveSpeedZone(double speedKmh) {
    final zones = orderedSpeedZones;
    for (final zone in zones) {
      if (zone.contains(speedKmh)) return zone;
    }
    return zones.isNotEmpty
        ? zones.last
        : const TeamSpeedZone(
      zoneId: 'Z1',
      label: 'Marche',
      minKmh: 0.0,
      maxKmh: null,
    );
  }

  double get walkingMaxKmh {
    final zones = orderedSpeedZones;
    if (zones.isEmpty) return 7.0;
    return zones[0].maxKmh ?? 7.0;
  }

  double get joggingMaxKmh {
    final zones = orderedSpeedZones;
    if (zones.length < 2) return 13.0;
    return zones[1].maxKmh ?? 13.0;
  }

  double get runningMaxKmh {
    final zones = orderedSpeedZones;
    if (zones.length < 3) return 18.0;
    return zones[2].maxKmh ?? 18.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'sprintThresholdKmh': sprintThresholdKmh,
      'minSprintAccelerationMps2': minSprintAccelerationMps2,
      'maxAcceptedStepDistanceMeters': maxAcceptedStepDistanceMeters,
      'sprintMinDurationMs': sprintMinDurationMs,
      'highAccelerationThresholdMps2': highAccelerationThresholdMps2,
      'highAccelerationMinDurationMs': highAccelerationMinDurationMs,
      'maxPlausibleSpeedMps': maxPlausibleSpeedMps,
      'maxPlausibleAccelerationMps2': maxPlausibleAccelerationMps2,
      'minDtMs': minDtMs,
      'maxDtMs': maxDtMs,
      'smoothingWindow': smoothingWindow,
      'validatedSpeedMinDurationMs': validatedSpeedMinDurationMs,
      'timelineBucketMs': timelineBucketMs,
      'speedZones': speedZones.map((e) => e.toMap()).toList(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory TeamParam.fromMap(Map<String, dynamic> map) {
    final defaultValue = TeamParam.defaultConfig(
      teamId: (map['teamId'] ?? defaultTeamId).toString(),
    );

    return TeamParam(
      teamId: (map['teamId'] ?? defaultValue.teamId).toString(),
      sprintThresholdKmh: map['sprintThresholdKmh'] != null
          ? _toDouble(map['sprintThresholdKmh'])
          : defaultValue.sprintThresholdKmh,
      minSprintAccelerationMps2: map['minSprintAccelerationMps2'] != null
          ? _toDouble(map['minSprintAccelerationMps2'])
          : defaultValue.minSprintAccelerationMps2,
      maxAcceptedStepDistanceMeters: map['maxAcceptedStepDistanceMeters'] != null
          ? _toDouble(map['maxAcceptedStepDistanceMeters'])
          : defaultValue.maxAcceptedStepDistanceMeters,
      sprintMinDurationMs: map['sprintMinDurationMs'] != null
          ? _toInt(map['sprintMinDurationMs'])
          : defaultValue.sprintMinDurationMs,
      highAccelerationThresholdMps2: map['highAccelerationThresholdMps2'] != null
          ? _toDouble(map['highAccelerationThresholdMps2'])
          : defaultValue.highAccelerationThresholdMps2,
      highAccelerationMinDurationMs: map['highAccelerationMinDurationMs'] != null
          ? _toInt(map['highAccelerationMinDurationMs'])
          : defaultValue.highAccelerationMinDurationMs,
      maxPlausibleSpeedMps: map['maxPlausibleSpeedMps'] != null
          ? _toDouble(map['maxPlausibleSpeedMps'])
          : defaultValue.maxPlausibleSpeedMps,
      maxPlausibleAccelerationMps2: map['maxPlausibleAccelerationMps2'] != null
          ? _toDouble(map['maxPlausibleAccelerationMps2'])
          : defaultValue.maxPlausibleAccelerationMps2,
      minDtMs: map['minDtMs'] != null
          ? _toInt(map['minDtMs'])
          : defaultValue.minDtMs,
      maxDtMs: map['maxDtMs'] != null
          ? _toInt(map['maxDtMs'])
          : defaultValue.maxDtMs,
      smoothingWindow: map['smoothingWindow'] != null
          ? _toInt(map['smoothingWindow'])
          : defaultValue.smoothingWindow,
      validatedSpeedMinDurationMs: map['validatedSpeedMinDurationMs'] != null
          ? _toInt(map['validatedSpeedMinDurationMs'])
          : defaultValue.validatedSpeedMinDurationMs,
      timelineBucketMs: map['timelineBucketMs'] != null
          ? _toInt(map['timelineBucketMs'])
          : defaultValue.timelineBucketMs,
      speedZones: (map['speedZones'] as List<dynamic>? ?? [])
          .map((e) => TeamSpeedZone.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList()
          .isNotEmpty
          ? (map['speedZones'] as List<dynamic>)
          .map((e) => TeamSpeedZone.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList()
          : defaultValue.speedZones,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  TeamParam copyWith({
    String? teamId,
    double? sprintThresholdKmh,
    double? minSprintAccelerationMps2,
    double? maxAcceptedStepDistanceMeters,
    int? sprintMinDurationMs,
    double? highAccelerationThresholdMps2,
    int? highAccelerationMinDurationMs,
    double? maxPlausibleSpeedMps,
    double? maxPlausibleAccelerationMps2,
    int? minDtMs,
    int? maxDtMs,
    int? smoothingWindow,
    int? validatedSpeedMinDurationMs,
    int? timelineBucketMs,
    List<TeamSpeedZone>? speedZones,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamParam(
      teamId: teamId ?? this.teamId,
      sprintThresholdKmh: sprintThresholdKmh ?? this.sprintThresholdKmh,
      minSprintAccelerationMps2:
      minSprintAccelerationMps2 ?? this.minSprintAccelerationMps2,
      maxAcceptedStepDistanceMeters:
      maxAcceptedStepDistanceMeters ?? this.maxAcceptedStepDistanceMeters,
      sprintMinDurationMs: sprintMinDurationMs ?? this.sprintMinDurationMs,
      highAccelerationThresholdMps2:
      highAccelerationThresholdMps2 ?? this.highAccelerationThresholdMps2,
      highAccelerationMinDurationMs:
      highAccelerationMinDurationMs ?? this.highAccelerationMinDurationMs,
      maxPlausibleSpeedMps:
      maxPlausibleSpeedMps ?? this.maxPlausibleSpeedMps,
      maxPlausibleAccelerationMps2:
      maxPlausibleAccelerationMps2 ?? this.maxPlausibleAccelerationMps2,
      minDtMs: minDtMs ?? this.minDtMs,
      maxDtMs: maxDtMs ?? this.maxDtMs,
      smoothingWindow: smoothingWindow ?? this.smoothingWindow,
      validatedSpeedMinDurationMs:
      validatedSpeedMinDurationMs ?? this.validatedSpeedMinDurationMs,
      timelineBucketMs: timelineBucketMs ?? this.timelineBucketMs,
      speedZones: speedZones ?? this.speedZones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}