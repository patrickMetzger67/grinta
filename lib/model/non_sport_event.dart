import 'package:cloud_firestore/cloud_firestore.dart';

const String keyNonSportEventTitle = 'title';
const String keyNonSportEventStartAt = 'startAt';
const String keyNonSportEventEndAt = 'endAt';
const String keyNonSportEventAllDay = 'allDay';
const String keyNonSportEventLocation = 'location';
const String keyNonSportEventTeamIds = 'teamIds';
const String keyNonSportEventInviteeMemberIds = 'inviteeMemberIds';
const String keyNonSportEventAccessMemberIds = 'accessMemberIds';
const String keyNonSportEventInvitees = 'invitees';
const String keyNonSportEventCreatedByUserId = 'createdByUserId';
const String keyNonSportEventCreatedByMemberId = 'createdByMemberId';
const String keyNonSportEventSeasonId = 'seasonId';
const String keyNonSportEventClubId = 'clubId';
const String keyNonSportEventCreatedAt = 'createdAt';
const String keyNonSportEventUpdatedAt = 'updatedAt';

const String keyNonSportInviteeMemberId = 'memberId';
const String keyNonSportInviteeDisplayName = 'displayName';
const String keyNonSportInviteeTeamIds = 'teamIds';
const String keyNonSportInviteeStatus = 'status';
const String keyNonSportInviteeNotifiedUserIds = 'notifiedUserIds';

enum NonSportInviteStatus {
  pending,
  sent,
  noAccount,
  error,
}

class NonSportInvitee {
  final String memberId;
  final String displayName;
  final List<String> teamIds;
  final NonSportInviteStatus status;
  final List<String> notifiedUserIds;

  const NonSportInvitee({
    required this.memberId,
    required this.displayName,
    this.teamIds = const <String>[],
    this.status = NonSportInviteStatus.pending,
    this.notifiedUserIds = const <String>[],
  });

  NonSportInvitee copyWith({
    String? memberId,
    String? displayName,
    List<String>? teamIds,
    NonSportInviteStatus? status,
    List<String>? notifiedUserIds,
  }) {
    return NonSportInvitee(
      memberId: memberId ?? this.memberId,
      displayName: displayName ?? this.displayName,
      teamIds: teamIds ?? this.teamIds,
      status: status ?? this.status,
      notifiedUserIds: notifiedUserIds ?? this.notifiedUserIds,
    );
  }

  factory NonSportInvitee.fromMap(Map<String, dynamic>? map) {
    final String memberId =
        (map?[keyNonSportInviteeMemberId] ?? '').toString().trim();
    final String displayName =
        (map?[keyNonSportInviteeDisplayName] ?? '').toString().trim();

    final List<String> teamIds = <String>[];
    final dynamic rawTeamIds = map?[keyNonSportInviteeTeamIds];
    if (rawTeamIds is List) {
      for (final dynamic entry in rawTeamIds) {
        final String id = entry?.toString().trim() ?? '';
        if (id.isNotEmpty) {
          teamIds.add(id);
        }
      }
    }

    final List<String> notifiedUserIds = <String>[];
    final dynamic rawUserIds = map?[keyNonSportInviteeNotifiedUserIds];
    if (rawUserIds is List) {
      for (final dynamic entry in rawUserIds) {
        final String id = entry?.toString().trim() ?? '';
        if (id.isNotEmpty) {
          notifiedUserIds.add(id);
        }
      }
    }

    return NonSportInvitee(
      memberId: memberId,
      displayName: displayName,
      teamIds: teamIds,
      status: _inviteStatusFromString(
        map?[keyNonSportInviteeStatus]?.toString(),
      ),
      notifiedUserIds: notifiedUserIds,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      keyNonSportInviteeMemberId: memberId,
      keyNonSportInviteeDisplayName: displayName,
      keyNonSportInviteeTeamIds: teamIds,
      keyNonSportInviteeStatus: status.name,
      keyNonSportInviteeNotifiedUserIds: notifiedUserIds,
    };
  }
}

NonSportInviteStatus _inviteStatusFromString(String? raw) {
  switch (raw?.trim()) {
    case 'sent':
      return NonSportInviteStatus.sent;
    case 'noAccount':
      return NonSportInviteStatus.noAccount;
    case 'error':
      return NonSportInviteStatus.error;
    case 'pending':
    default:
      return NonSportInviteStatus.pending;
  }
}

class NonSportEvent {
  final String? id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;
  final String? location;
  final List<String> teamIds;
  final List<String> inviteeMemberIds;
  final List<String> accessMemberIds;
  final List<NonSportInvitee> invitees;
  final String? createdByUserId;
  final String? createdByMemberId;
  final String? seasonId;
  final String? clubId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final DocumentReference? ref;

  const NonSportEvent({
    this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.allDay = false,
    this.location,
    this.teamIds = const <String>[],
    this.inviteeMemberIds = const <String>[],
    this.accessMemberIds = const <String>[],
    this.invitees = const <NonSportInvitee>[],
    this.createdByUserId,
    this.createdByMemberId,
    this.seasonId,
    this.clubId,
    this.createdAt,
    this.updatedAt,
    this.ref,
  });

  NonSportEvent copyWith({
    String? id,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    String? location,
    List<String>? teamIds,
    List<String>? inviteeMemberIds,
    List<String>? accessMemberIds,
    List<NonSportInvitee>? invitees,
    String? createdByUserId,
    String? createdByMemberId,
    String? seasonId,
    String? clubId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    DocumentReference? ref,
  }) {
    return NonSportEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      teamIds: teamIds ?? this.teamIds,
      inviteeMemberIds: inviteeMemberIds ?? this.inviteeMemberIds,
      accessMemberIds: accessMemberIds ?? this.accessMemberIds,
      invitees: invitees ?? this.invitees,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByMemberId: createdByMemberId ?? this.createdByMemberId,
      seasonId: seasonId ?? this.seasonId,
      clubId: clubId ?? this.clubId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ref: ref ?? this.ref,
    );
  }

  factory NonSportEvent.fromSnapshot(DocumentSnapshot snapshot) {
    final Map<String, dynamic> map =
        (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return NonSportEvent.fromMap(map, id: snapshot.id, ref: snapshot.reference);
  }

  factory NonSportEvent.fromMap(
    Map<String, dynamic> map, {
    String? id,
    DocumentReference? ref,
  }) {
    final Timestamp? startTs = map[keyNonSportEventStartAt] as Timestamp?;
    final Timestamp? endTs = map[keyNonSportEventEndAt] as Timestamp?;
    final DateTime startAt = startTs?.toDate() ?? DateTime.now();
    final DateTime endAt = endTs?.toDate() ?? startAt;

    final List<String> teamIds = _stringList(map[keyNonSportEventTeamIds]);
    final List<String> inviteeMemberIds =
        _stringList(map[keyNonSportEventInviteeMemberIds]);
    final List<String> accessMemberIds =
        _stringList(map[keyNonSportEventAccessMemberIds]);

    final List<NonSportInvitee> invitees = <NonSportInvitee>[];
    final dynamic rawInvitees = map[keyNonSportEventInvitees];
    if (rawInvitees is List) {
      for (final dynamic entry in rawInvitees) {
        if (entry is Map<String, dynamic>) {
          final NonSportInvitee invitee = NonSportInvitee.fromMap(entry);
          if (invitee.memberId.isNotEmpty) {
            invitees.add(invitee);
          }
        } else if (entry is Map) {
          final NonSportInvitee invitee = NonSportInvitee.fromMap(
            Map<String, dynamic>.from(entry),
          );
          if (invitee.memberId.isNotEmpty) {
            invitees.add(invitee);
          }
        }
      }
    }

    return NonSportEvent(
      id: id,
      title: (map[keyNonSportEventTitle] ?? '').toString().trim(),
      startAt: startAt,
      endAt: endAt,
      allDay: map[keyNonSportEventAllDay] == true,
      location: _nullableString(map[keyNonSportEventLocation]),
      teamIds: teamIds,
      inviteeMemberIds: inviteeMemberIds,
      accessMemberIds: accessMemberIds,
      invitees: invitees,
      createdByUserId: _nullableString(map[keyNonSportEventCreatedByUserId]),
      createdByMemberId:
          _nullableString(map[keyNonSportEventCreatedByMemberId]),
      seasonId: _nullableString(map[keyNonSportEventSeasonId]),
      clubId: _nullableString(map[keyNonSportEventClubId]),
      createdAt: map[keyNonSportEventCreatedAt] as Timestamp?,
      updatedAt: map[keyNonSportEventUpdatedAt] as Timestamp?,
      ref: ref,
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    final Map<String, dynamic> map = <String, dynamic>{
      keyNonSportEventTitle: title,
      keyNonSportEventStartAt: Timestamp.fromDate(startAt),
      keyNonSportEventEndAt: Timestamp.fromDate(endAt),
      keyNonSportEventAllDay: allDay,
      keyNonSportEventLocation: location,
      keyNonSportEventTeamIds: teamIds,
      keyNonSportEventInviteeMemberIds: inviteeMemberIds,
      keyNonSportEventAccessMemberIds: accessMemberIds,
      keyNonSportEventInvitees:
          invitees.map((NonSportInvitee e) => e.toMap()).toList(),
      keyNonSportEventCreatedByUserId: createdByUserId,
      keyNonSportEventCreatedByMemberId: createdByMemberId,
      keyNonSportEventSeasonId: seasonId,
      keyNonSportEventClubId: clubId,
    };

    if (includeTimestamps) {
      map[keyNonSportEventCreatedAt] = createdAt ?? FieldValue.serverTimestamp();
      map[keyNonSportEventUpdatedAt] = FieldValue.serverTimestamp();
    }

    return map;
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
