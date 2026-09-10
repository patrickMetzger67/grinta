import 'package:cloud_firestore/cloud_firestore.dart';

const String keyTeamFineTypeTeamId = 'teamId';
const String keyTeamFineTypeName = 'name';
const String keyTeamFineTypeCreatedAt = 'createdAt';
const String keyTeamFineTypeUpdatedAt = 'updatedAt';

/// Fine / penalty category owned by a team (late, unexcused absence, …).
class TeamFineType {
  final String? id;
  final String teamId;
  final String name;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final DocumentReference? ref;

  const TeamFineType({
    this.id,
    required this.teamId,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.ref,
  });

  TeamFineType copyWith({
    String? id,
    String? teamId,
    String? name,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    DocumentReference? ref,
  }) {
    return TeamFineType(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ref: ref ?? this.ref,
    );
  }

  factory TeamFineType.fromSnapshot(DocumentSnapshot snapshot) {
    final Map<String, dynamic> map =
        (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return TeamFineType.fromMap(map, id: snapshot.id, ref: snapshot.reference);
  }

  factory TeamFineType.fromMap(
    Map<String, dynamic> map, {
    String? id,
    DocumentReference? ref,
  }) {
    return TeamFineType(
      id: id,
      teamId: (map[keyTeamFineTypeTeamId] ?? '').toString().trim(),
      name: (map[keyTeamFineTypeName] ?? '').toString().trim(),
      createdAt: map[keyTeamFineTypeCreatedAt] as Timestamp?,
      updatedAt: map[keyTeamFineTypeUpdatedAt] as Timestamp?,
      ref: ref,
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    final Map<String, dynamic> map = <String, dynamic>{
      keyTeamFineTypeTeamId: teamId,
      keyTeamFineTypeName: name,
    };
    if (includeTimestamps) {
      map[keyTeamFineTypeCreatedAt] = createdAt ?? FieldValue.serverTimestamp();
      map[keyTeamFineTypeUpdatedAt] = FieldValue.serverTimestamp();
    }
    return map;
  }
}
