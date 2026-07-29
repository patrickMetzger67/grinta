import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/invitation.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/invitationService.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/player_positions.dart';

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
    TeamService? teamService,
  })  : _invitationService = invitationService ?? InvitationService(),
        _playerService = playerService ?? PlayerService(),
        _teamService = teamService ?? TeamService();

  final InvitationService _invitationService;
  final PlayerService _playerService;
  final TeamService _teamService;

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
  ///
  /// When the invite targets a staff row on [Invitation.teamId], also grants
  /// manager access so staff can open the team after accepting (same as when
  /// they were already linked at add time).
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
    await _grantStaffManagerRightsIfNeeded(
      invitation: invitation,
      memberId: memberId,
      uid: normalizedUid,
    );
  }

  Future<void> _grantStaffManagerRightsIfNeeded({
    required Invitation invitation,
    required String memberId,
    required String uid,
  }) async {
    final String? teamId = invitation.teamId?.trim();
    if (teamId == null || teamId.isEmpty) {
      return;
    }

    final Team? team = await _teamService.getTeamById(teamId);
    if (team == null) {
      return;
    }

    final bool isStaffOnTeam = (team.grintaPlayers ?? const <GrintaPlayer>[])
        .any((GrintaPlayer entry) {
      if (entry.playerId.trim() != memberId) {
        return false;
      }
      return isGrintaRosterStaff(
        positions: entry.positions,
        fonction: entry.fonction,
        listedInManagers: false,
      );
    });
    if (!isStaffOnTeam) {
      return;
    }

    await _teamService.addManager(teamId: teamId, managerId: uid);
    await _teamService.addUser(teamId: teamId, userId: uid);
  }
}
