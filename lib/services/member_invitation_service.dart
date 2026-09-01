import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/invitation.dart';
import 'package:grinta/model/notification.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/invitationService.dart';
import 'package:grinta/services/invitation_email_builder.dart';
import 'package:grinta/services/invitation_email_service.dart';
import 'package:grinta/services/invitation_link_builder.dart';
import 'package:grinta/services/invitation_whatsapp_service.dart';
import 'package:grinta/services/notificationService.dart';
import 'package:grinta/services/notification_fcm_service.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/player_profile_validator.dart';
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
    this.emailSent = false,
    this.whatsappSent = false,
    this.notificationSent = false,
    this.error,
  });

  /// `true` when the flow finished without error (including intentional skips).
  final bool success;

  /// `true` when no invitation, email, WhatsApp, or push was attempted.
  final bool skipped;

  /// Machine-readable skip reason, e.g. `noContact`, `linkedAccount`.
  final String? skipReason;

  /// Full invitation code (`contactPrefixCode` + 4 digits) when created.
  final String? invitationCode;

  /// Firestore invitations document id when created.
  final String? invitationId;

  final bool invitationCreated;
  final bool emailSent;
  final bool whatsappSent;
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
    bool emailSent = false,
    bool whatsappSent = false,
  }) {
    return MemberInvitationResult(
      success: true,
      invitationCode: invitationCode,
      invitationId: invitationId,
      invitationCreated: true,
      emailSent: emailSent,
      whatsappSent: whatsappSent,
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
    bool emailSent = false,
    bool whatsappSent = false,
  }) {
    return MemberInvitationResult(
      success: false,
      invitationCode: invitationCode,
      invitationId: invitationId,
      invitationCreated: invitationCreated,
      emailSent: emailSent,
      whatsappSent: whatsappSent,
      error: error,
    );
  }

  @override
  String toString() {
    return 'MemberInvitationResult(success=$success skipped=$skipped '
        'skipReason=$skipReason invitationCode=$invitationCode '
        'invitationId=$invitationId invitationCreated=$invitationCreated '
        'emailSent=$emailSent whatsappSent=$whatsappSent '
        'notificationSent=$notificationSent error=$error)';
  }
}

/// Creates Firestore member invitations, sends onboarding email / WhatsApp,
/// or notifies linked app users when they are added to a team.
///
/// Usage after adding or updating a roster member:
/// ```dart
/// final result = await MemberInvitationService.instance.notifyOrInviteMember(
///   l10n: context.l10n,
///   member: selected,
///   memberId: member.keyMember!,
///   email: details.email ?? '',
///   phoneE164: details.phoneE164,
///   teamId: team.keyTeam,
///   seasonId: seasonId,
///   teamName: team.name ?? '',
/// );
/// ```
class MemberInvitationService {
  MemberInvitationService._({
    InvitationService? invitationService,
    InvitationEmailService? invitationEmailService,
    InvitationWhatsAppService? invitationWhatsAppService,
    NotificationService? notificationService,
    UserService? userService,
    PlayerService? playerService,
  })  : _invitationService = invitationService ?? InvitationService(),
        _invitationEmailService =
            invitationEmailService ?? InvitationEmailService(),
        _invitationWhatsAppService =
            invitationWhatsAppService ?? InvitationWhatsAppService(),
        _notificationService = notificationService ?? NotificationService(),
        _userService = userService ?? UserService(),
        _playerService = playerService ?? PlayerService();

  static final MemberInvitationService instance = MemberInvitationService._();

  @visibleForTesting
  factory MemberInvitationService.forTest({
    InvitationService? invitationService,
    InvitationEmailService? invitationEmailService,
    InvitationWhatsAppService? invitationWhatsAppService,
    NotificationService? notificationService,
    UserService? userService,
    PlayerService? playerService,
  }) {
    return MemberInvitationService._(
      invitationService: invitationService,
      invitationEmailService: invitationEmailService,
      invitationWhatsAppService: invitationWhatsAppService,
      notificationService: notificationService,
      userService: userService,
      playerService: playerService,
    );
  }

  final InvitationService _invitationService;
  final InvitationEmailService _invitationEmailService;
  final InvitationWhatsAppService _invitationWhatsAppService;
  final NotificationService _notificationService;
  final UserService _userService;
  final PlayerService _playerService;

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

  /// Linked app account → push notification only; otherwise invitation + channels.
  ///
  /// When [notifyIfLinked] is `false` and the member is linked, the flow is
  /// skipped (e.g. email update on an onboarded member).
  Future<MemberInvitationResult> notifyOrInviteMember({
    required AppLocalizations l10n,
    required Player member,
    required String memberId,
    required String email,
    String phoneE164 = '',
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
      email: email,
      phoneE164: phoneE164,
      type: type,
      teamId: teamId,
      seasonId: seasonId,
      teamName: teamName,
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
        'MemberInvitationService.notifyMemberAddedToTeam no client fcmTokens '
        'memberId=$memberId linkedUids=$linkedUids — CF will load '
        'users/{uid}/fcmTokens',
      );
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
      recipientUserIds: linkedUids.toList(),
    );

    debugPrint(
      'MemberInvitationService.notifyMemberAddedToTeam complete memberId=$memberId '
      'linkedUids=$linkedUids tokenCount=${tokens.length}',
    );

    return MemberInvitationResult.notified();
  }

  /// Creates a Firestore invitation and queues email and/or WhatsApp.
  ///
  /// When [email] already matches an existing Grinta user account, also creates
  /// in-app [NotifType.pendingInvitation] notifications on that user's profiles.
  ///
  /// Skips when both [email] and [phoneE164] are empty/invalid.
  /// Fails when the current user is not signed in.
  Future<MemberInvitationResult> inviteMember({
    required AppLocalizations l10n,
    required String memberId,
    required String email,
    String phoneE164 = '',
    int type = invitationTypeMember,
    String? teamId,
    String? seasonId,
    String? teamName,
  }) async {
    debugPrint(
      'MemberInvitationService.inviteMember start memberId=$memberId '
      'email=$email phone=$phoneE164 teamId=$teamId seasonId=$seasonId',
    );

    final String normalizedEmail = email.trim();
    final String normalizedPhone = phoneE164.trim();
    final bool hasEmail = normalizedEmail.isNotEmpty &&
        isValidEmailFormat(normalizedEmail);
    final bool hasPhone = normalizedPhone.isNotEmpty &&
        isValidE164Phone(normalizedPhone);

    if (!hasEmail && !hasPhone) {
      final String reason = normalizedEmail.isEmpty && normalizedPhone.isEmpty
          ? 'noContact'
          : 'invalidContact';
      debugPrint(
        'MemberInvitationService.inviteMember skipped: $reason '
        'memberId=$memberId',
      );
      return MemberInvitationResult.skipped(reason);
    }

    if (normalizedEmail.isNotEmpty && !hasEmail) {
      debugPrint(
        'MemberInvitationService.inviteMember skipped: invalidEmail '
        'memberId=$memberId email=$normalizedEmail',
      );
      // Continue if phone is valid; otherwise already returned above.
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
    final String code =
        '${config.contactPrefixCode}${generate4DigitCode()}';
    final String invitationId = _uuid.v4();
    final String normalizedMemberId = memberId.trim();
    final String inviteUrl = InvitationLinkBuilder.inviteUrl(
      config: config,
      invitationCode: code,
    );

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

    bool emailSent = false;
    bool whatsappSent = false;
    final List<String> channelErrors = <String>[];

    if (hasEmail) {
      final InvitationEmailContent emailContent = InvitationEmailBuilder.build(
        l10n: l10n,
        config: config,
        invitationCode: code,
        inviteUrl: inviteUrl,
      );

      debugPrint(
        'MemberInvitationService.inviteMember sending email memberId=$memberId '
        'invitationId=$invitationId',
      );

      final String? emailError = await _invitationEmailService.send(
        toEmail: normalizedEmail,
        subject: emailContent.subject,
        text: emailContent.text,
        html: emailContent.html,
      );

      if (emailError != null) {
        debugPrint(
          'MemberInvitationService.inviteMember email failed memberId=$memberId '
          'invitationId=$invitationId email=$normalizedEmail error=$emailError',
        );
        channelErrors.add(emailError);
      } else {
        emailSent = true;
      }
    }

    if (hasPhone) {
      debugPrint(
        'MemberInvitationService.inviteMember sending WhatsApp memberId=$memberId '
        'invitationId=$invitationId',
      );
      final String? whatsappError = await _invitationWhatsAppService.sendTemplate(
        toPhoneE164: normalizedPhone,
        templateName: config.whatsappTemplateName,
        languageCode: config.whatsappTemplateLanguage,
        bodyParameters: <String>[
          config.appDisplayName.trim(),
          code,
          inviteUrl,
        ],
        invitationId: invitationId,
        invitationCode: code,
      );

      if (whatsappError != null) {
        debugPrint(
          'MemberInvitationService.inviteMember WhatsApp failed memberId=$memberId '
          'invitationId=$invitationId phone=$normalizedPhone error=$whatsappError',
        );
        channelErrors.add(whatsappError);
      } else {
        whatsappSent = true;
      }
    }

    if (hasEmail) {
      await _createPendingInvitationNotifications(
        l10n: l10n,
        inviteeEmail: normalizedEmail,
        invitedMemberId: normalizedMemberId,
        invitationId: invitationId,
        teamId: teamId?.trim(),
        teamName: teamName,
        createdByUid: uid.trim(),
      );
    }

    if (!emailSent && !whatsappSent) {
      return MemberInvitationResult.failed(
        invitationCode: code,
        invitationCreated: true,
        invitationId: invitationId,
        emailSent: false,
        whatsappSent: false,
        error: channelErrors.isEmpty
            ? 'noChannelDelivered'
            : channelErrors.join('; '),
      );
    }

    debugPrint(
      'MemberInvitationService.inviteMember complete memberId=$memberId '
      'invitationId=$invitationId emailSent=$emailSent whatsappSent=$whatsappSent',
    );

    return MemberInvitationResult.sent(
      invitationCode: code,
      invitationId: invitationId,
      emailSent: emailSent,
      whatsappSent: whatsappSent,
    );
  }

  /// Re-sends the onboarding invitation for an unlinked roster member.
  Future<MemberInvitationResult> resendInvitation({
    required AppLocalizations l10n,
    required String memberId,
    required String email,
    String phoneE164 = '',
    required String teamId,
    String? seasonId,
    String? teamName,
    int type = invitationTypeMember,
  }) {
    return inviteMember(
      l10n: l10n,
      memberId: memberId,
      email: email,
      phoneE164: phoneE164,
      type: type,
      teamId: teamId,
      seasonId: seasonId,
      teamName: teamName,
    );
  }

  /// Creates/updates unread pending-invitation notifications for an existing
  /// account matching [inviteeEmail], so they appear in the notifications panel.
  Future<void> _createPendingInvitationNotifications({
    required AppLocalizations l10n,
    required String inviteeEmail,
    required String invitedMemberId,
    required String invitationId,
    required String? teamId,
    required String? teamName,
    required String createdByUid,
  }) async {
    try {
      final inviteeUid = await _userService.getUidByEmail(inviteeEmail);
      if (inviteeUid == null || inviteeUid.isEmpty) {
        debugPrint(
          'MemberInvitationService.pendingInvitationNotif skipped: noUser '
          'email=$inviteeEmail',
        );
        return;
      }

      final players = await _playerService.getPlayersByUserId(inviteeUid);
      final playerIds = <String>{};
      for (final player in players) {
        final id = effectiveMemberId(player)?.trim() ?? '';
        if (id.isNotEmpty) {
          playerIds.add(id);
        }
      }

      if (playerIds.isEmpty) {
        debugPrint(
          'MemberInvitationService.pendingInvitationNotif skipped: noPlayers '
          'uid=$inviteeUid',
        );
        return;
      }

      final displayTeamName =
          (teamName?.trim().isNotEmpty ?? false)
              ? teamName!.trim()
              : l10n.entityTeam;
      final title = l10n.pendingInvitationNotificationTitle;
      final body = l10n.pendingInvitationNotificationBody(displayTeamName);

      for (final playerId in playerIds) {
        final docId =
            'pendingInv_${inviteeUid}_${playerId}_$invitedMemberId';
        await _notificationService.setNotification(
          docId,
          NotificationApp(
            userId: inviteeUid,
            playerId: playerId,
            type: NotifType.pendingInvitation,
            sendBy: SendBy.notification,
            title: title,
            body: body,
            objectId: invitationId,
            isViewed: false,
            dateTimeCreated: Timestamp.now(),
            createdUserId: createdByUid,
            clubId: InvitationConfig.grintaInvitationClubId,
          ),
        );
      }

      debugPrint(
        'MemberInvitationService.pendingInvitationNotif created '
        'uid=$inviteeUid playerCount=${playerIds.length} '
        'invitationId=$invitationId teamId=$teamId',
      );
    } catch (e, st) {
      debugPrint(
        'MemberInvitationService.pendingInvitationNotif failed: $e\n$st',
      );
    }
  }
}
