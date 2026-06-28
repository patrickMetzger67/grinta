import 'package:cloud_firestore/cloud_firestore.dart';

String keyInvitationCode = 'code';
String keyInvitationType = 'type';
String keyInvitationExtId = 'extId';
String keyInvitationUid = 'uid';
String keyInvitationCreatedAt = 'createdAt';
String keyInvitationValidateUid = 'validateUid';
String keyInvitationValidateAt = 'validateAt';
String keyInvitationTeamId = 'teamId';
String keyInvitationSeasonId = 'seasonId';

const int invitationTypeMember = 1;
const int invitationTypeContact = 2;

class Invitation {
  final String id;
  final String code;
  final int type;
  final String extId;
  final String uid;
  final Timestamp createdAt;
  final String? validateUid;
  final Timestamp? validateAt;
  final String? teamId;
  final String? seasonId;

  DocumentReference? ref;

  Invitation({
    required this.id,
    required this.code,
    required this.type,
    required this.extId,
    required this.uid,
    required this.createdAt,
    this.validateUid,
    this.validateAt,
    this.teamId,
    this.seasonId,
    this.ref,
  });

  Invitation copyWith({
    String? id,
    String? code,
    int? type,
    String? extId,
    String? uid,
    Timestamp? createdAt,
    String? validateUid,
    Timestamp? validateAt,
    String? teamId,
    String? seasonId,
    DocumentReference? ref,
  }) {
    return Invitation(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      extId: extId ?? this.extId,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      validateUid: validateUid ?? this.validateUid,
      validateAt: validateAt ?? this.validateAt,
      teamId: teamId ?? this.teamId,
      seasonId: seasonId ?? this.seasonId,
      ref: ref ?? this.ref,
    );
  }

  factory Invitation.fromMap(Map<String, dynamic> map, {required String id}) {
    return Invitation(
      id: id,
      code: map[keyInvitationCode]?.toString() ?? '',
      type: map[keyInvitationType] is int
          ? map[keyInvitationType] as int
          : int.tryParse(map[keyInvitationType]?.toString() ?? '') ??
              invitationTypeMember,
      extId: map[keyInvitationExtId]?.toString() ?? '',
      uid: map[keyInvitationUid]?.toString() ?? '',
      createdAt: map[keyInvitationCreatedAt] is Timestamp
          ? map[keyInvitationCreatedAt] as Timestamp
          : Timestamp.now(),
      validateUid: map[keyInvitationValidateUid]?.toString(),
      validateAt: map[keyInvitationValidateAt] is Timestamp
          ? map[keyInvitationValidateAt] as Timestamp
          : null,
      teamId: map[keyInvitationTeamId]?.toString(),
      seasonId: map[keyInvitationSeasonId]?.toString(),
    );
  }

  factory Invitation.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final map = snapshot.data() as Map<String, dynamic>? ?? {};
    final invitation = Invitation.fromMap(map, id: snapshot.id);
    invitation.ref = snapshot.reference;
    return invitation;
  }

  Map<String, dynamic> toMap() {
    return {
      keyInvitationCode: code,
      keyInvitationType: type,
      keyInvitationExtId: extId,
      keyInvitationUid: uid,
      keyInvitationCreatedAt: createdAt,
      if (validateUid != null && validateUid!.trim().isNotEmpty)
        keyInvitationValidateUid: validateUid!.trim(),
      if (validateAt != null) keyInvitationValidateAt: validateAt,
      if (teamId != null && teamId!.trim().isNotEmpty)
        keyInvitationTeamId: teamId!.trim(),
      if (seasonId != null && seasonId!.trim().isNotEmpty)
        keyInvitationSeasonId: seasonId!.trim(),
    };
  }

  bool get isValidated => validateUid != null && validateAt != null;

  @override
  String toString() {
    return 'Invitation => id=$id code=$code type=$type extId=$extId uid=$uid '
        'createdAt=$createdAt validateUid=$validateUid validateAt=$validateAt '
        'teamId=$teamId seasonId=$seasonId';
  }
}
