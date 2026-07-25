import 'package:grinta/model/invitation.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/invitationService.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/player_photo_resolver.dart';

enum InvitationLookupError {
  notFound,
  alreadyUsed,
  invalidType,
  memberMissing,
  memberAlreadyLinked,
}

class InvitationLookupResult {
  const InvitationLookupResult._({
    this.invitation,
    this.member,
    this.error,
  });

  factory InvitationLookupResult.success({
    required Invitation invitation,
    required Player member,
  }) {
    return InvitationLookupResult._(
      invitation: invitation,
      member: member,
    );
  }

  factory InvitationLookupResult.failure(InvitationLookupError error) {
    return InvitationLookupResult._(error: error);
  }

  final Invitation? invitation;
  final Player? member;
  final InvitationLookupError? error;

  bool get isSuccess => error == null && invitation != null && member != null;
}

/// Shared invitation-code lookup and acceptance for signup + logged-in users.
class InvitationAcceptanceService {
  InvitationAcceptanceService({
    InvitationService? invitationService,
    PlayerService? playerService,
  })  : _invitationService = invitationService ?? InvitationService(),
        _playerService = playerService ?? PlayerService();

  final InvitationService _invitationService;
  final PlayerService _playerService;

  Future<InvitationLookupResult> lookupMemberInvitation(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) {
      return InvitationLookupResult.failure(InvitationLookupError.notFound);
    }

    final invitation = await _invitationService.findByCode(code);
    if (invitation == null) {
      return InvitationLookupResult.failure(InvitationLookupError.notFound);
    }

    if (invitation.isValidated) {
      return InvitationLookupResult.failure(InvitationLookupError.alreadyUsed);
    }

    if (invitation.type != invitationTypeMember) {
      return InvitationLookupResult.failure(InvitationLookupError.invalidType);
    }

    final memberId = invitation.extId.trim();
    if (memberId.isEmpty) {
      return InvitationLookupResult.failure(InvitationLookupError.notFound);
    }

    final member = await _playerService.getPlayerById(memberId);
    if (member == null) {
      return InvitationLookupResult.failure(InvitationLookupError.memberMissing);
    }

    if (isMemberLinkedToAppAccount(member)) {
      return InvitationLookupResult.failure(
        InvitationLookupError.memberAlreadyLinked,
      );
    }

    return InvitationLookupResult.success(
      invitation: invitation,
      member: member,
    );
  }

  /// Links the invited member fiche to [uid] and marks the invitation validated.
  Future<void> acceptForUser({
    required Invitation invitation,
    required String uid,
  }) async {
    final memberId = invitation.extId.trim();
    final normalizedUid = uid.trim();
    if (memberId.isEmpty || normalizedUid.isEmpty) {
      throw StateError('invitation member id or uid missing');
    }

    await _playerService.linkUserToMember(
      memberId: memberId,
      uid: normalizedUid,
    );
    await _invitationService.validateInvitation(invitation.id, normalizedUid);
  }
}
