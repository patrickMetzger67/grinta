import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/invitation.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/invitationService.dart';
import 'package:grinta/services/notification_fcm_service.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:uuid/uuid.dart';

/// Outcome of [MemberInvitationService.notifyOrInviteMember] /
/// [MemberInvitationService.inviteMember].
class MemberInvitationResult {
  const MemberInvitationResult({
    required this.success,
    this.skipped = false,
    this.skipReason,
    this.invitationCode,
    this.invitationId,
    this.invitationCreated = false,
    this.smsSent = false,
    this.notificationSent = false,
    this.error,
  });

  /// `true` when the flow finished without error (including intentional skips).
  final bool success;

  /// `true` when no invitation, SMS, or push was attempted.
  final bool skipped;

  /// Machine-readable skip reason, e.g. `noPhone`, `linkedAccount`.
  final String? skipReason;

  /// Full invitation code (`contactPrefixCode` + 4 digits) when created.
  final String? invitationCode;

  /// Firestore invitations document id when created.
  final String? invitationId;

  final bool invitationCreated;
  final bool smsSent;
  final bool notificationSent;
  final String? error;

  factory MemberInvitationResult.skipped(String reason) {
    return MemberInvitationResult(
      success: true,
      skipped: true,
      skipReason: reason,
    );
  }

  factory MemberInvitationResult.sent({
    required String invitationCode,
    required String invitationId,
  }) {
    return MemberInvitationResult(
      success: true,
      invitationCode: invitationCode,
      invitationId: invitationId,
      invitationCreated: true,
      smsSent: true,
    );
  }

  factory MemberInvitationResult.notified() {
    return const MemberInvitationResult(
      success: true,
      notificationSent: true,
    );
  }

  factory MemberInvitationResult.failed({
    required String? invitationCode,
    required bool invitationCreated,
    required String error,
    String? invitationId,
  }) {
    return MemberInvitationResult(
      success: false,
      invitationCode: invitationCode,
      invitationId: invitationId,
      invitationCreated: invitationCreated,
      smsSent: false,
      error: error,
    );
  }

  @override
  String toString() {
    return 'MemberInvitationResult(success=$success skipped=$skipped '
        'skipReason=$skipReason invitationCode=$invitationCode '
        'invitationId=$invitationId invitationCreated=$invitationCreated '
        'smsSent=$smsSent notificationSent=$notificationSent error=$error)';
  }
}

/// Creates Firestore member invitations, sends onboarding SMS, or notifies linked
/// app users when they are added to a team.
///
/// Usage after adding or updating a roster member:
/// ```dart
/// final result = await MemberInvitationService.instance.notifyOrInviteMember(
///   l10n: context.l10n,
///   member: selected,
///   memberId: member.keyMember!,
///   phoneE164: details.phoneE164,
///   teamId: team.keyTeam,
///   seasonId: seasonId,
///   teamName: team.name ?? '',
/// );
/// if (!result.success && result.invitationCreated && !result.smsSent) {
///   AppSnackbar.show(context, l10n.memberInvitationSmsFailed, isError: true);
/// }
/// ```
class MemberInvitationService {
  MemberInvitationService._({
    InvitationService? invitationService,
  }) : _invitationService = invitationService ?? InvitationService();

  static final MemberInvitationService instance = MemberInvitationService._();

  final InvitationService _invitationService;

  static final Random _random = Random.secure();
  static const Uuid _uuid = Uuid();

  /// Generates a zero-padded 4-digit numeric suffix.
  static String generate4DigitCode() {
    return _random.nextInt(10000).toString().padLeft(4, '0');
  }

  /// Builds a full invitation code: [InvitationConfig.contactPrefixCode] + 4 digits.
  static Future<String> buildInvitationCode() async {
    final config = await InvitationConfig.resolve();
    return '${config.contactPrefixCode}${generate4DigitCode()}';
  }

  /// Linked app account → push notification only; otherwise invitation + SMS.
  ///
  /// When [notifyIfLinked] is `false` and the member is linked, the flow is
  /// skipped (e.g. phone update on an onboarded member).
  Future<MemberInvitationResult> notifyOrInviteMember({
    required AppLocalizations l10n,
    required Player member,
    required String memberId,
    required String phoneE164,
    required String teamId,
    String? seasonId,
    required String teamName,
    int type = invitationTypeMember,
    bool notifyIfLinked = true,
  }) async {
    if (isMemberLinkedToAppAccount(member)) {
      if (!notifyIfLinked) {
        debugPrint(
          'MemberInvitationService.notifyOrInviteMember skipped: linkedAccount '
          'memberId=$memberId',
        );
        return MemberInvitationResult.skipped('linkedAccount');
      }
      return notifyMemberAddedToTeam(
        l10n: l10n,
        member: member,
        memberId: memberId,
        teamId: teamId,
        seasonId: seasonId,
        teamName: teamName,
      );
    }

    return inviteMember(
      l10n: l10n,
      memberId: memberId,
      phoneE164: phoneE164,
      type: type,
      teamId: teamId,
      seasonId: seasonId,
    );
  }

  /// Sends a push notification to a linked member added to a team.
  Future<MemberInvitationResult> notifyMemberAddedToTeam({
    required AppLocalizations l10n,
    required Player member,
    required String memberId,
    required String teamId,
    String? seasonId,
    required String teamName,
  }) async {
    debugPrint(
      'MemberInvitationService.notifyMemberAddedToTeam start memberId=$memberId '
      'teamId=$teamId seasonId=$seasonId',
    );

    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      debugPrint(
        'MemberInvitationService.notifyMemberAddedToTeam failed: missingAuth '
        'memberId=$memberId',
      );
      return MemberInvitationResult.failed(
        invitationCode: null,
        invitationCreated: false,
        error: 'missingAuth',
      );
    }

    final Set<String> linkedUids = collectMemberLinkedUserIds(member);
    if (linkedUids.isEmpty) {
      debugPrint(
        'MemberInvitationService.notifyMemberAddedToTeam skipped: noLinkedUids '
        'memberId=$memberId',
      );
      return MemberInvitationResult.skipped('noLinkedUids');
    }

    final List<String> tokens =
        await NotificationFCMService.fetchFcmTokensForUsers(linkedUids);
    if (tokens.isEmpty) {
      debugPrint(
        'MemberInvitationService.notifyMemberAddedToTeam skipped: noFcmTokens '
        'memberId=$memberId linkedUids=$linkedUids',
      );
      return MemberInvitationResult.skipped('noFcmTokens');
    }

    final String displayTeamName =
        teamName.trim().isEmpty ? l10n.entityTeam : teamName.trim();

    await NotificationFCMService.instance.postNotification(
      tokens: tokens,
      title: l10n.memberAddedToTeamNotificationTitle,
      body: l10n.memberAddedToTeamNotificationBody(displayTeamName),
      type: 'teamDetail',
      payload: {
        'id': teamId.trim(),
        if (seasonId != null && seasonId.trim().isNotEmpty)
          'seasonId': seasonId.trim(),
      },
      clubId: InvitationConfig.grintaInvitationClubId,
    );

    debugPrint(
      'MemberInvitationService.notifyMemberAddedToTeam complete memberId=$memberId '
      'linkedUids=$linkedUids tokenCount=${tokens.length}',
    );

    return MemberInvitationResult.notified();
  }

  /// Creates a Firestore invitation and sends the onboarding SMS.
  ///
  /// Skips when [phoneE164] is empty. Fails when the current user is not signed in.
  Future<MemberInvitationResult> inviteMember({
    required AppLocalizations l10n,
    required String memberId,
    required String phoneE164,
    int type = invitationTypeMember,
    String? teamId,
    String? seasonId,
  }) async {
    debugPrint(
      'MemberInvitationService.inviteMember start memberId=$memberId '
      'phoneE164=$phoneE164 teamId=$teamId seasonId=$seasonId',
    );

    final String phone = phoneE164.trim();
    if (phone.isEmpty) {
      debugPrint(
        'MemberInvitationService.inviteMember skipped: noPhone memberId=$memberId',
      );
      return MemberInvitationResult.skipped('noPhone');
    }

    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      debugPrint(
        'MemberInvitationService.inviteMember failed: missingAuth memberId=$memberId',
      );
      return MemberInvitationResult.failed(
        invitationCode: null,
        invitationCreated: false,
        error: 'missingAuth',
      );
    }

    final InvitationRuntimeConfig config = await InvitationConfig.resolve();
    const String invitationClubId = InvitationConfig.grintaInvitationClubId;
    final String code =
        '${config.contactPrefixCode}${generate4DigitCode()}';
    final String invitationId = _uuid.v4();
    final String normalizedMemberId = memberId.trim();

    debugPrint(
      'MemberInvitationService.inviteMember creating invitation '
      'invitationId=$invitationId code=$code extId=$normalizedMemberId uid=$uid',
    );

    try {
      await _invitationService.createInvitation(
        code: code,
        type: type,
        extId: normalizedMemberId,
        uid: uid.trim(),
        teamId: teamId?.trim(),
        seasonId: seasonId?.trim(),
        documentId: invitationId,
      );
      debugPrint(
        'MemberInvitationService.inviteMember invitation created '
        'invitationId=$invitationId',
      );
    } catch (e, st) {
      debugPrint('MemberInvitationService.createInvitation failed: $e\n$st');
      return MemberInvitationResult.failed(
        invitationCode: null,
        invitationCreated: false,
        error: e.toString(),
      );
    }

    final String textMessage = l10n.invitationSmsMessage(
      config.appDisplayName,
      code,
      config.appleStoreUrl,
      config.googlePlayUrl,
    );

    debugPrint(
      'MemberInvitationService.inviteMember sending SMS memberId=$memberId '
      'invitationId=$invitationId',
    );

    final String? smsError =
        await NotificationFCMService.instance.sendSmsFromFlutter(
      toNumber: phone,
      textMessage: textMessage,
      clubId: invitationClubId,
    );

    if (smsError != null) {
      debugPrint(
        'MemberInvitationService.inviteMember SMS failed memberId=$memberId '
        'invitationId=$invitationId clubId=$invitationClubId phone=$phone '
        'error=$smsError',
      );
      return MemberInvitationResult.failed(
        invitationCode: code,
        invitationCreated: true,
        invitationId: invitationId,
        error: smsError,
      );
    }

    debugPrint(
      'MemberInvitationService.inviteMember complete memberId=$memberId '
      'invitationId=$invitationId smsSent=true',
    );

    return MemberInvitationResult.sent(
      invitationCode: code,
      invitationId: invitationId,
    );
  }
}
