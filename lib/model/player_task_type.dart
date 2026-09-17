import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const String keyPlayerTaskTypeOwnerUserId = 'ownerUserId';
const String keyPlayerTaskTypeName = 'name';
const String keyPlayerTaskTypeColor = 'color';
const String keyPlayerTaskTypeCreatedAt = 'createdAt';
const String keyPlayerTaskTypeUpdatedAt = 'updatedAt';

/// Palette offered when a manager creates a personal task type.
const List<int> kPlayerTaskTypePalette = <int>[
  0xFFF95C1B,
  0xFF1FA971,
  0xFF3B82F6,
  0xFF8B5CF6,
  0xFFF5A524,
  0xFFE53935,
  0xFF06B6D4,
  0xFFEC4899,
];

/// Personal task category owned by one manager (matériel, maillots, …).
class PlayerTaskType {
  final String? id;
  final String ownerUserId;
  final String name;
  final int color;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final DocumentReference? ref;

  const PlayerTaskType({
    this.id,
    required this.ownerUserId,
    required this.name,
    required this.color,
    this.createdAt,
    this.updatedAt,
    this.ref,
  });

  Color get colorValue => Color(color | 0xFF000000);

  PlayerTaskType copyWith({
    String? id,
    String? ownerUserId,
    String? name,
    int? color,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    DocumentReference? ref,
  }) {
    return PlayerTaskType(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ref: ref ?? this.ref,
    );
  }

  factory PlayerTaskType.fromSnapshot(DocumentSnapshot snapshot) {
    final Map<String, dynamic> map =
        (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return PlayerTaskType.fromMap(map, id: snapshot.id, ref: snapshot.reference);
  }

  factory PlayerTaskType.fromMap(
    Map<String, dynamic> map, {
    String? id,
    DocumentReference? ref,
  }) {
    return PlayerTaskType(
      id: id,
      ownerUserId: _nullableString(map[keyPlayerTaskTypeOwnerUserId]) ?? '',
      name: (map[keyPlayerTaskTypeName] ?? '').toString().trim(),
      color: playerTaskColorFrom(map[keyPlayerTaskTypeColor]),
      createdAt: map[keyPlayerTaskTypeCreatedAt] as Timestamp?,
      updatedAt: map[keyPlayerTaskTypeUpdatedAt] as Timestamp?,
      ref: ref,
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    final Map<String, dynamic> map = <String, dynamic>{
      keyPlayerTaskTypeOwnerUserId: ownerUserId,
      keyPlayerTaskTypeName: name,
      keyPlayerTaskTypeColor: color,
    };
    if (includeTimestamps) {
      map[keyPlayerTaskTypeCreatedAt] =
          createdAt ?? FieldValue.serverTimestamp();
      map[keyPlayerTaskTypeUpdatedAt] = FieldValue.serverTimestamp();
    }
    return map;
  }

  static String? _nullableString(dynamic raw) {
    final String value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }
}

int playerTaskColorFrom(dynamic raw) {
  if (raw is int) {
    return raw | 0xFF000000;
  }
  if (raw is num) {
    return raw.toInt() | 0xFF000000;
  }
  return kPlayerTaskTypePalette.first;
}
