import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/notification.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/services/event_sync_service.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/notificationService.dart';
import 'package:grinta/services/notification_fcm_service.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/match_convocation_helper.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/player_photo_resolver.dart';

enum SessionFeelingEventType { training, match }

bool _isPresentOrDefaultPresence(PresenceType? presenceType) {
  return presenceType == null || presenceType == PresenceType.present;
}

bool _isTrainingFinished(Training training) {
  return training.isFinish == true || training.trainingEndAt != null;
}

/// Sends post-sync "Comment te sens-tu ?" notifications to present players
/// who have tracker data in [TeamWorkloadSummary.playerScores].
class SessionFeelingNotificationService {
  SessionFeelingNotificationService({
    TrainingService? trainingService,
    MatchService? matchService,
    MatchCompoService? matchCompoService,
    PlayerService? playerService,
    NotificationService? notificationService,
    EventSyncService? eventSyncService,
    TeamWorkloadSummaryService? teamWorkloadSummaryService,
  })  : _trainingService = trainingService ?? TrainingService(),
        _matchService = matchService ?? MatchService(),
        _matchCompoService = matchCompoService ?? MatchCompoService(),
        _playerService = playerService ?? PlayerService(),
        _notificationService = notificationService ?? NotificationService(),
        _eventSyncService = eventSyncService ?? EventSyncService(),
        _teamWorkloadSummaryService =
            teamWorkloadSummaryService ?? TeamWorkloadSummaryService();

  final TrainingService _trainingService;
  final MatchService _matchService;
  final MatchCompoService _matchCompoService;
  final PlayerService _playerService;
  final NotificationService _notificationService;
  final EventSyncService _eventSyncService;
  final TeamWorkloadSummaryService _teamWorkloadSummaryService;

  /// Entry point after training finish and/or tracker sync.
  Future<void> maybeNotifyAfterTrainingSynced({
    required Training training,
    required AppLocalizations l10n,
  }) async {
    if (!_isTrainingFinished(training) ||
        training.isTrackerDataUploaded != true) {
      return;
    }

    final eventId =
        training.docId?.trim() ?? training.trainingId?.trim() ?? '';
    if (eventId.isEmpty) return;

    final candidates = training.playerTraining
        .where((pt) => _isPresentOrDefaultPresence(pt.presenceType))
        .map((pt) => pt.playerId?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final playerIds = await _filterPlayerIdsWithTrackerData(
      eventId: eventId,
      candidates: candidates,
    );
    if (playerIds.isEmpty) {
      debugPrint(
        'SessionFeelingNotificationService: no tracker data for training '
        '$eventId — skip (not claimed, can retry later)',
      );
      return;
    }

    final claimed = await _eventSyncService.claimFeelingNotifSent(eventId);
    if (!claimed) {
      debugPrint(
        'SessionFeelingNotificationService: already sent for training $eventId',
      );
      return;
    }

    await _notifyPlayers(
      eventId: eventId,
      eventType: SessionFeelingEventType.training,
      playerIds: playerIds,
      clubId: training.clubId,
      teamId: training.teamId,
      createdUserId: training.ownerId,
      l10n: l10n,
    );
  }

  /// Entry point after match tracker sync (and match played).
  Future<void> maybeNotifyAfterMatchSynced({
    required models.Match match,
    required AppLocalizations l10n,
  }) async {
    if (match.isMatchPlayed != true || match.isTrackerDataUploaded != true) {
      return;
    }

    final eventId = match.id?.trim() ?? match.ref?.id.trim() ?? '';
    if (eventId.isEmpty) return;

    final teamId = match.teamID?.trim() ?? '';
    MatchCompo? compo;
    if (teamId.isNotEmpty) {
      compo = await _matchCompoService.getMatchCompoByMatchAndTeamId(
        eventId,
        teamId,
      );
    }
    if (compo == null) {
      final compos = await _matchCompoService.getMatchComposByMatchId(eventId);
      if (compos.isNotEmpty) compo = compos.first;
    }

    final candidates = <String>{};
    if (compo != null) {
      for (final player in allPlayersFromCompo(compo)) {
        final id = player.playerID?.trim() ?? '';
        if (id.isNotEmpty) candidates.add(id);
      }
    }

    final playerIds = await _filterPlayerIdsWithTrackerData(
      eventId: eventId,
      candidates: candidates,
    );
    if (playerIds.isEmpty) {
      debugPrint(
        'SessionFeelingNotificationService: no tracker data for match '
        '$eventId — skip (not claimed, can retry later)',
      );
      return;
    }

    final claimed = await _eventSyncService.claimFeelingNotifSent(eventId);
    if (!claimed) {
      debugPrint(
        'SessionFeelingNotificationService: already sent for match $eventId',
      );
      return;
    }

    await _notifyPlayers(
      eventId: eventId,
      eventType: SessionFeelingEventType.match,
      playerIds: playerIds,
      clubId: resolveMatchClubId(match),
      teamId: compo?.teamID ?? teamId,
      createdUserId: match.highLightsManagerUid,
      l10n: l10n,
    );
  }

  /// Keeps only candidates that appear in [TeamWorkloadSummary.playerScores].
  Future<List<String>> _filterPlayerIdsWithTrackerData({
    required String eventId,
    required Set<String> candidates,
  }) async {
    if (candidates.isEmpty) return const [];

    final summary =
        await _teamWorkloadSummaryService.getByEventId(eventId);
    if (summary == null || summary.playerScores.isEmpty) {
      return const [];
    }

    final scoredIds = summary.playerScores
        .map((score) => score.playerId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (scoredIds.isEmpty) return const [];

    return candidates.where(scoredIds.contains).toList();
  }

  /// Convenience: reload training by id then notify if finished+synced.
  Future<void> maybeNotifyTrainingById({
    required String trainingId,
    required AppLocalizations l10n,
  }) async {
    final training = await _trainingService.getTrainingById(trainingId);
    if (training == null) return;
    await maybeNotifyAfterTrainingSynced(training: training, l10n: l10n);
  }

  /// Convenience: reload match by id then notify if played+synced.
  Future<void> maybeNotifyMatchById({
    required String matchId,
    required AppLocalizations l10n,
  }) async {
    final match = await _matchService.getMatchById(matchId);
    if (match == null) return;
    await maybeNotifyAfterMatchSynced(match: match, l10n: l10n);
  }

  Future<void> _notifyPlayers({
    required String eventId,
    required SessionFeelingEventType eventType,
    required List<String> playerIds,
    required AppLocalizations l10n,
    String? clubId,
    String? teamId,
    String? createdUserId,
  }) async {
    if (playerIds.isEmpty) {
      debugPrint(
        'SessionFeelingNotificationService: no players for $eventId',
      );
      return;
    }

    final pushTitle = l10n.playerFeelingNotifTitle;
    final notificationBody = l10n.playerFeelingNotifBody;
    final eventTypeKey =
        eventType == SessionFeelingEventType.training ? 'training' : 'match';

    var notificationsCreated = 0;
    var pushNotificationsSent = 0;

    for (final rawPlayerId in playerIds) {
      final Player? player = await _playerService.getPlayerById(rawPlayerId);
      if (player == null) continue;

      final memberId = effectiveMemberId(player) ?? rawPlayerId;
      final Player playerForSend =
          await _playerService.getPlayerById(memberId) ?? player;
      final linkedUids = collectMemberLinkedUserIds(playerForSend);

      // Always create an in-app notification (cloche), even without FCM tokens
      // or linked accounts — the inbox queries by playerId.
      if (linkedUids.isEmpty) {
        await _notificationService.createNotification(
          NotificationApp(
            userId: '',
            type: NotifType.RPEAfter,
            sendBy: SendBy.notification,
            title: pushTitle,
            body: notificationBody,
            objectId: eventId,
            createdUserId: createdUserId,
            clubId: clubId,
            playerId: memberId,
            dateTimeCreated: Timestamp.now(),
          ),
        );
        notificationsCreated++;
        debugPrint(
          'SessionFeelingNotificationService: in-app only for '
          'memberId=$memberId (no linked account / no FCM)',
        );
        continue;
      }

      for (final uid in linkedUids) {
        await _notificationService.createNotification(
          NotificationApp(
            userId: uid,
            type: NotifType.RPEAfter,
            sendBy: SendBy.notification,
            title: pushTitle,
            body: notificationBody,
            objectId: eventId,
            createdUserId: createdUserId,
            clubId: clubId,
            playerId: memberId,
            dateTimeCreated: Timestamp.now(),
          ),
        );
        notificationsCreated++;
      }

      final tokens =
          await NotificationFCMService.fetchFcmTokensForUsers(linkedUids);
      if (tokens.isEmpty) {
        debugPrint(
          'SessionFeelingNotificationService: in-app created, push skipped '
          'memberId=$memberId (no fcmTokens)',
        );
        continue;
      }

      final pushSent = await NotificationFCMService.instance.postNotification(
        tokens: tokens,
        title: pushTitle,
        body: notificationBody,
        type: 'RPEAfter',
        payload: {
          'id': eventId,
          'type': 'RPEAfter',
          'eventType': eventTypeKey,
          'playerId': memberId,
          if (teamId != null && teamId.trim().isNotEmpty) 'teamId': teamId.trim(),
          'body': notificationBody,
        },
        clubId: clubId,
      );
      if (pushSent) {
        pushNotificationsSent++;
      } else {
        debugPrint(
          'SessionFeelingNotificationService: in-app created, push failed '
          'memberId=$memberId',
        );
      }
    }

    debugPrint(
      'SessionFeelingNotificationService: event=$eventId type=$eventTypeKey '
      'notifications=$notificationsCreated push=$pushNotificationsSent',
    );
  }
}
