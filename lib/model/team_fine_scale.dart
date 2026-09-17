import 'package:cloud_firestore/cloud_firestore.dart';

const String keyTeamFineScaleTeamId = 'teamId';
const String keyTeamFineScaleTypeId = 'typeId';
const String keyTeamFineScaleTypeName = 'typeName';
const String keyTeamFineScaleAmount = 'amount';
const String keyTeamFineScaleCreatedByUserId = 'createdByUserId';
const String keyTeamFineScaleCreatedByMemberId = 'createdByMemberId';
const String keyTeamFineScaleCreatedAt = 'createdAt';
const String keyTeamFineScaleUpdatedAt = 'updatedAt';

/// Amount associated with a [team] fine type (the team's fine schedule).
class TeamFineScale {
  final String? id;
  final String teamId;
  final String typeId;
  final String typeName;
  final double amount;
  final String createdByUserId;
  final String? createdByMemberId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final DocumentReference? ref;

  const TeamFineScale({
    this.id,
    required this.teamId,
    required this.typeId,
    required this.typeName,
    required this.amount,
    required this.createdByUserId,
    this.createdByMemberId,
    this.createdAt,
    this.updatedAt,
    this.ref,
  });

  TeamFineScale copyWith({
    String? id,
    String? teamId,
    String? typeId,
    String? typeName,
    double? amount,
    String? createdByUserId,
    String? createdByMemberId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    DocumentReference? ref,
  }) {
    return TeamFineScale(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      typeId: typeId ?? this.typeId,
      typeName: typeName ?? this.typeName,
      amount: amount ?? this.amount,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByMemberId: createdByMemberId ?? this.createdByMemberId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ref: ref ?? this.ref,
    );
  }

  factory TeamFineScale.fromSnapshot(DocumentSnapshot snapshot) {
    final Map<String, dynamic> map =
        (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return TeamFineScale.fromMap(map, id: snapshot.id, ref: snapshot.reference);
  }

  factory TeamFineScale.fromMap(
    Map<String, dynamic> map, {
    String? id,
    DocumentReference? ref,
  }) {
    return TeamFineScale(
      id: id,
      teamId: (map[keyTeamFineScaleTeamId] ?? '').toString().trim(),
      typeId: (map[keyTeamFineScaleTypeId] ?? '').toString().trim(),
      typeName: (map[keyTeamFineScaleTypeName] ?? '').toString().trim(),
      amount: fineAmountFrom(map[keyTeamFineScaleAmount]),
      createdByUserId:
          (map[keyTeamFineScaleCreatedByUserId] ?? '').toString().trim(),
      createdByMemberId: _nullableString(map[keyTeamFineScaleCreatedByMemberId]),
      createdAt: map[keyTeamFineScaleCreatedAt] as Timestamp?,
      updatedAt: map[keyTeamFineScaleUpdatedAt] as Timestamp?,
      ref: ref,
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    final Map<String, dynamic> map = <String, dynamic>{
      keyTeamFineScaleTeamId: teamId,
      keyTeamFineScaleTypeId: typeId,
      keyTeamFineScaleTypeName: typeName,
      keyTeamFineScaleAmount: amount,
      keyTeamFineScaleCreatedByUserId: createdByUserId,
      keyTeamFineScaleCreatedByMemberId: createdByMemberId,
    };
    if (includeTimestamps) {
      map[keyTeamFineScaleCreatedAt] = createdAt ?? FieldValue.serverTimestamp();
      map[keyTeamFineScaleUpdatedAt] = FieldValue.serverTimestamp();
    }
    return map;
  }

  static String? _nullableString(dynamic raw) {
    final String value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }
}

double fineAmountFrom(dynamic raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  if (raw is String) {
    return double.tryParse(raw.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}
