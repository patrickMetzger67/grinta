import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'player_task_type.dart';

const String keyPlayerTaskTitle = 'title';
const String keyPlayerTaskTypeId = 'typeId';
const String keyPlayerTaskTypeName = 'typeName';
const String keyPlayerTaskTypeColor = 'typeColor';
const String keyPlayerTaskStartAt = 'startAt';
const String keyPlayerTaskEndAt = 'endAt';
const String keyPlayerTaskTeamId = 'teamId';
const String keyPlayerTaskAssigneeMemberIds = 'assigneeMemberIds';
const String keyPlayerTaskAssigneeNames = 'assigneeNames';
const String keyPlayerTaskAccessMemberIds = 'accessMemberIds';
const String keyPlayerTaskCreatedByUserId = 'createdByUserId';
const String keyPlayerTaskCreatedByMemberId = 'createdByMemberId';
const String keyPlayerTaskSeasonId = 'seasonId';
const String keyPlayerTaskClubId = 'clubId';
const String keyPlayerTaskCreatedAt = 'createdAt';
const String keyPlayerTaskUpdatedAt = 'updatedAt';

/// Multi-day duty a manager assigns to one or more players.
class PlayerTask {
  final String? id;
  final String title;
  final String typeId;
  final String typeName;
  final int typeColor;
  final DateTime startAt;
  final DateTime endAt;
  final String teamId;
  final List<String> assigneeMemberIds;
  final List<String> assigneeNames;
  final List<String> accessMemberIds;
  final String createdByUserId;
  final String? createdByMemberId;
  final String? seasonId;
  final String? clubId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final DocumentReference? ref;

  const PlayerTask({
    this.id,
    this.title = '',
    required this.typeId,
    required this.typeName,
    required this.typeColor,
    required this.startAt,
    required this.endAt,
    required this.teamId,
    this.assigneeMemberIds = const <String>[],
    this.assigneeNames = const <String>[],
    this.accessMemberIds = const <String>[],
    required this.createdByUserId,
    this.createdByMemberId,
    this.seasonId,
    this.clubId,
    this.createdAt,
    this.updatedAt,
    this.ref,
  });

  Color get colorValue => Color(typeColor | 0xFF000000);

  DateTime get startDay => DateUtils.dateOnly(startAt);

  DateTime get endDay => DateUtils.dateOnly(endAt);

  /// Label shown on the agenda bar (type, plus optional note).
  String get barLabel {
    final String note = title.trim();
    if (note.isEmpty) {
      return typeName;
    }
    if (typeName.isEmpty) {
      return note;
    }
    return '$typeName · $note';
  }

  bool occursOnDay(DateTime day) {
    final DateTime d = DateUtils.dateOnly(day);
    return !d.isBefore(startDay) && !d.isAfter(endDay);
  }

  bool overlapsRange(DateTime rangeStart, DateTime rangeEnd) {
    final DateTime start = DateUtils.dateOnly(rangeStart);
    final DateTime end = DateUtils.dateOnly(rangeEnd);
    return !endDay.isBefore(start) && !startDay.isAfter(end);
  }

  PlayerTask copyWith({
    String? id,
    String? title,
    String? typeId,
    String? typeName,
    int? typeColor,
    DateTime? startAt,
    DateTime? endAt,
    String? teamId,
    List<String>? assigneeMemberIds,
    List<String>? assigneeNames,
    List<String>? accessMemberIds,
    String? createdByUserId,
    String? createdByMemberId,
    String? seasonId,
    String? clubId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    DocumentReference? ref,
  }) {
    return PlayerTask(
      id: id ?? this.id,
      title: title ?? this.title,
      typeId: typeId ?? this.typeId,
      typeName: typeName ?? this.typeName,
      typeColor: typeColor ?? this.typeColor,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      teamId: teamId ?? this.teamId,
      assigneeMemberIds: assigneeMemberIds ?? this.assigneeMemberIds,
      assigneeNames: assigneeNames ?? this.assigneeNames,
      accessMemberIds: accessMemberIds ?? this.accessMemberIds,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByMemberId: createdByMemberId ?? this.createdByMemberId,
      seasonId: seasonId ?? this.seasonId,
      clubId: clubId ?? this.clubId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ref: ref ?? this.ref,
    );
  }

  factory PlayerTask.fromSnapshot(DocumentSnapshot snapshot) {
    final Map<String, dynamic> map =
        (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return PlayerTask.fromMap(map, id: snapshot.id, ref: snapshot.reference);
  }

  factory PlayerTask.fromMap(
    Map<String, dynamic> map, {
    String? id,
    DocumentReference? ref,
  }) {
    final DateTime startAt = _readDate(map[keyPlayerTaskStartAt]) ?? DateTime.now();
    final DateTime endAt = _readDate(map[keyPlayerTaskEndAt]) ?? startAt;

    return PlayerTask(
      id: id,
      title: (map[keyPlayerTaskTitle] ?? '').toString().trim(),
      typeId: (map[keyPlayerTaskTypeId] ?? '').toString().trim(),
      typeName: (map[keyPlayerTaskTypeName] ?? '').toString().trim(),
      typeColor: playerTaskColorFrom(map[keyPlayerTaskTypeColor]),
      startAt: startAt,
      endAt: endAt,
      teamId: (map[keyPlayerTaskTeamId] ?? '').toString().trim(),
      assigneeMemberIds: _stringList(map[keyPlayerTaskAssigneeMemberIds]),
      assigneeNames: _stringList(map[keyPlayerTaskAssigneeNames]),
      accessMemberIds: _stringList(map[keyPlayerTaskAccessMemberIds]),
      createdByUserId:
          (map[keyPlayerTaskCreatedByUserId] ?? '').toString().trim(),
      createdByMemberId: _nullableString(map[keyPlayerTaskCreatedByMemberId]),
      seasonId: _nullableString(map[keyPlayerTaskSeasonId]),
      clubId: _nullableString(map[keyPlayerTaskClubId]),
      createdAt: map[keyPlayerTaskCreatedAt] as Timestamp?,
      updatedAt: map[keyPlayerTaskUpdatedAt] as Timestamp?,
      ref: ref,
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    final Map<String, dynamic> map = <String, dynamic>{
      keyPlayerTaskTitle: title,
      keyPlayerTaskTypeId: typeId,
      keyPlayerTaskTypeName: typeName,
      keyPlayerTaskTypeColor: typeColor,
      keyPlayerTaskStartAt: Timestamp.fromDate(startAt),
      keyPlayerTaskEndAt: Timestamp.fromDate(endAt),
      keyPlayerTaskTeamId: teamId,
      keyPlayerTaskAssigneeMemberIds: assigneeMemberIds,
      keyPlayerTaskAssigneeNames: assigneeNames,
      keyPlayerTaskAccessMemberIds: accessMemberIds,
      keyPlayerTaskCreatedByUserId: createdByUserId,
      keyPlayerTaskCreatedByMemberId: createdByMemberId,
      keyPlayerTaskSeasonId: seasonId,
      keyPlayerTaskClubId: clubId,
    };
    if (includeTimestamps) {
      map[keyPlayerTaskCreatedAt] = createdAt ?? FieldValue.serverTimestamp();
      map[keyPlayerTaskUpdatedAt] = FieldValue.serverTimestamp();
    }
    return map;
  }

  static DateTime? _readDate(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    return null;
  }

  static List<String> _stringList(dynamic raw) {
    final List<String> values = <String>[];
    if (raw is! List) {
      return values;
    }
    for (final dynamic entry in raw) {
      final String id = entry?.toString().trim() ?? '';
      if (id.isNotEmpty) {
        values.add(id);
      }
    }
    return values;
  }

  static String? _nullableString(dynamic raw) {
    final String value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }
}
