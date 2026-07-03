import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/notification.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/notificationService.dart';
import 'package:grinta/services/notification_fcm_service.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/match_convocation_helper.dart';
import 'package:grinta/util/player_photo_resolver.dart';

class MatchConvocationSendResult {
  const MatchConvocationSendResult({
    required this.notificationsCreated,
    required this.pushNotificationsSent,
    required this.skippedNoLinkedAccount,
    required this.skippedNoFcmToken,
  });

  final int notificationsCreated;
  final int pushNotificationsSent;
  final int skippedNoLinkedAccount;
  final int skippedNoFcmToken;

  bool get hasAnySuccess => notificationsCreated > 0;
}

class MatchConvocationService {
  MatchConvocationService({
    NotificationService? notificationService,
    MatchService? matchService,
    PlayerService? playerService,
  })  : _notificationService = notificationService ?? NotificationService(),
        _matchService = matchService ?? MatchService(),
        _playerService = playerService ?? PlayerService();

  final NotificationService _notificationService;
  final MatchService _matchService;
  final PlayerService _playerService;

  Future<MatchConvocationSendResult> sendConvocations({
    required AppLocalizations l10n,
    required models.Match match,
    required List<Player> convokedPlayers,
    required String message,
    required DateTime convocationDateTime,
    required String address,
    required String managerUserId,
  }) async {
    final matchId = match.id?.trim() ?? '';
    if (matchId.isEmpty) {
      throw StateError('missingMatchId');
    }

    final trimmedManagerId = managerUserId.trim();
    if (trimmedManagerId.isEmpty) {
      throw StateError('missingAuth');
    }

    final clubId =
        resolveMatchClubId(match) ?? InvitationConfig.grintaInvitationClubId;

    final notificationBody = buildConvocationNotificationBody(
      l10n: l10n,
      message: message,
      convocationDateTime: convocationDateTime,
      address: address,
      match: match,
    );

    final pushTitle = l10n.matchConvocationNotificationTitle(
      matchConvocationOpponentLabel(match),
    );

    final pushBody = buildConvocationPushBody(
      l10n: l10n,
      message: message,
      convocationDateTime: convocationDateTime,
      match: match,
    );

    var notificationsCreated = 0;
    var pushNotificationsSent = 0;
    var skippedNoLinkedAccount = 0;
    var skippedNoFcmToken = 0;

    for (final player in convokedPlayers) {
      final memberId = effectiveMemberId(player);
      final Player playerForSend = memberId != null
          ? await _playerService.getPlayerById(memberId) ?? player
          : player;

      final linkedUids = collectMemberLinkedUserIds(playerForSend);
      if (linkedUids.isEmpty) {
        debugPrint(
          'MatchConvocationService.sendConvocations skipped player '
          'memberId=$memberId: noLinkedUids',
        );
        skippedNoLinkedAccount++;
        continue;
      }

      for (final uid in linkedUids) {
        final notification = NotificationApp(
          userId: uid,
          type: NotifType.convocation,
          sendBy: SendBy.notification,
          title: pushTitle,
          body: notificationBody,
          objectId: matchId,
          createdUserId: trimmedManagerId,
          clubId: clubId,
          dateTimeCreated: Timestamp.now(),
        );

        await _notificationService.createNotification(notification);
        notificationsCreated++;
      }

      final tokens =
          await NotificationFCMService.fetchFcmTokensForUsers(linkedUids);
      if (tokens.isEmpty) {
        debugPrint(
          'MatchConvocationService.sendConvocations skipped push '
          'memberId=$memberId linkedUids=$linkedUids: noFcmTokens',
        );
        skippedNoFcmToken++;
        continue;
      }

      final pushSent = await NotificationFCMService.instance.postNotification(
        tokens: tokens,
        title: pushTitle,
        body: pushBody,
        type: 'convocation',
        payload: {
          'id': matchId,
          'type': 'convocation',
          'body': notificationBody,
        },
        clubId: clubId,
      );
      if (pushSent) {
        pushNotificationsSent++;
      } else {
        debugPrint(
          'MatchConvocationService.sendConvocations push failed '
          'memberId=$memberId linkedUids=$linkedUids tokenCount=${tokens.length}',
        );
        skippedNoFcmToken++;
      }
    }

    await _matchService.updateConvo(
      matchId: matchId,
      dateTimeConvo: Timestamp.fromDate(convocationDateTime),
      messageConvo: message.trim(),
      addressConvo: address.trim(),
    );

    debugPrint(
      'MatchConvocationService.sendConvocations complete matchId=$matchId '
      'notifications=$notificationsCreated push=$pushNotificationsSent '
      'skippedNoAccount=$skippedNoLinkedAccount skippedNoToken=$skippedNoFcmToken',
    );

    return MatchConvocationSendResult(
      notificationsCreated: notificationsCreated,
      pushNotificationsSent: pushNotificationsSent,
      skippedNoLinkedAccount: skippedNoLinkedAccount,
      skippedNoFcmToken: skippedNoFcmToken,
    );
  }
}
