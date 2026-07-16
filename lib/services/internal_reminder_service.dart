import 'dart:async' show Timer, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/services/eshop_config_service.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/notification.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/agenda_service.dart';
import 'package:grinta/services/answerService.dart';
import 'package:grinta/services/calendar_sync_service.dart';
import 'package:grinta/services/internal_notification_navigation.dart';
import 'package:grinta/services/local_reminder_scheduler.dart';
import 'package:grinta/services/notification_preferences_service.dart';
import 'package:grinta/services/notificationService.dart';
import 'package:grinta/services/opponent_stats_view_tracker.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/screen/team_players/training_team_players_presence.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Orchestrates local reminders and in-app notification docs (no FCM).
class InternalReminderService with WidgetsBindingObserver {
  InternalReminderService._();

  static final InternalReminderService instance = InternalReminderService._();

  final AgendaService _agendaService = AgendaService();
  final AnswerService _answerService = AnswerService();
  final NotificationService _notificationService = NotificationService();

  Timer? _agendaDebounceTimer;
  bool _initialized = false;
  bool _rescheduleInProgress = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    InternalReminderServiceBridge.onStatsViewed = (_) => reschedule();
    InternalReminderServiceBridge.onPresenceConfirmed = () => reschedule();

    WidgetsBinding.instance.addObserver(this);
    await NotificationPreferencesService.instance.ensureInitialized();
    if (!kIsWeb) {
      await LocalReminderScheduler.instance.init();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(reschedule());
    }
  }

  void onAgendaChanged() {
    _agendaDebounceTimer?.cancel();
    _agendaDebounceTimer = Timer(CalendarSyncService.syncDebounce, () {
      unawaited(reschedule());
    });
  }

  void onPreferencesSaved() {
    unawaited(reschedule());
  }

  void onSessionReady() {
    unawaited(reschedule());
  }

  Future<void> reschedule() async {
    if (_rescheduleInProgress) return;
    _rescheduleInProgress = true;

    try {
      await NotificationPreferencesService.instance.ensureInitialized();
      await UserTrialService.instance.ensureInitialized();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final context = appNavigatorKey.currentContext;
      if (context == null) return;

      final session = context.read<AppSession>();
      if (session.user?.uid != uid) return;

      final preferences =
          NotificationPreferencesService.instance.preferences;
      if (!preferences.remindersEnabled) {
        await LocalReminderScheduler.instance.cancelAll();
        return;
      }

      if (!UserTrialService.instance.hasPremiumAccess) {
        await LocalReminderScheduler.instance.cancelAll();
        return;
      }

      final now = DateTime.now();
      final start = DateUtils.dateOnly(now);
      final end = start.add(const Duration(days: 8));

      final items = await _agendaService.loadAgendaItems(
        teams: session.teamsForAgendaSelectedSeason,
        seasonId: session.selectedSeason?.ref?.id,
        start: start,
        end: end,
        memberId: session.selectedPlayerId,
      );

      await LocalReminderScheduler.instance.cancelAll();

      final l10n = context.l10n;
      final player = session.selectedPlayer;
      final seasonId = session.selectedSeason?.ref?.id;

      for (final item in items) {
        if (item.type == AgendaItemType.entrainement ||
            item.type == AgendaItemType.preparationPhysique) {
          await _maybeScheduleTrainingReminder(
            item: item,
            preferences: preferences,
            player: player,
            seasonId: seasonId,
            uid: uid,
            l10n: l10n,
          );
        } else if (item.type == AgendaItemType.match) {
          await _maybeScheduleMatchOpponentStatsReminder(
            item: item,
            preferences: preferences,
            session: session,
            uid: uid,
            l10n: l10n,
          );
        }
      }
    } catch (e, st) {
      debugPrint('InternalReminderService.reschedule error: $e\n$st');
    } finally {
      _rescheduleInProgress = false;
    }
  }

  Future<void> _maybeScheduleTrainingReminder({
    required AgendaItem item,
    required NotificationPreferences preferences,
    required Player? player,
    required String? seasonId,
    required String uid,
    required AppLocalizations l10n,
  }) async {
    final training = item.training;
    final trainingId = training?.trainingId?.trim() ?? item.id.trim();
    if (trainingId.isEmpty || item.isDone) return;
    if (!DateUtils.isSameDay(item.startAt, DateTime.now()) &&
        item.startAt.isBefore(DateTime.now())) {
      return;
    }
    if (!DateUtils.isSameDay(item.startAt, DateTime.now())) return;

    if (player != null &&
        isPlayerUnavailableOnTrainingDate(
          player,
          item.startAt,
          seasonId: seasonId,
        )) {
      return;
    }

    final playerId = player?.ref?.id?.trim() ?? '';
    if (playerId.isNotEmpty) {
      final answer = await _answerService.getFirstAnswerByObjectIdAndUserId(
        objectId: trainingId,
        userId: playerId,
      );
      if (answer != null) return;
    }

    final scheduledAt = DateTime(
      item.startAt.year,
      item.startAt.month,
      item.startAt.day,
      preferences.morningReminderHour,
    );
    if (preferences.isQuietAt(scheduledAt)) return;
    if (scheduledAt.isBefore(DateTime.now())) return;

    final timeLabel = DateFormat.Hm().format(item.startAt);
    final title = l10n.reminderTrainingTitle;
    final body = l10n.reminderTrainingBody(timeLabel);
    final reminderKey = 'training_$trainingId';

    final payload = <String, dynamic>{
      'type': 'trainingReminder',
      'id': trainingId,
      'trainingId': trainingId,
      'teamId': training?.teamId ?? '',
    };

    await _createInAppNotificationIfNeeded(
      uid: uid,
      type: NotifType.trainingReminder,
      objectId: trainingId,
      title: title,
      body: body,
      playerId: playerId.isEmpty ? null : playerId,
    );

    await LocalReminderScheduler.instance.scheduleReminder(
      reminderKey: reminderKey,
      scheduledAtLocal: scheduledAt,
      timezoneName: preferences.timezone,
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> _maybeScheduleMatchOpponentStatsReminder({
    required AgendaItem item,
    required NotificationPreferences preferences,
    required AppSession session,
    required String uid,
    required AppLocalizations l10n,
  }) async {
    final match = item.match;
    final matchId = match?.id?.trim() ?? item.id.trim();
    if (matchId.isEmpty || item.isDone) return;
    if (!DateUtils.isSameDay(item.startAt, DateTime.now())) return;

    if (await OpponentStatsViewTracker.instance.hasViewed(matchId)) {
      return;
    }

    final teamId = match?.teamID?.trim() ?? '';
    Team? team;
    for (final candidate in session.teamsForAgendaSelectedSeason) {
      if (candidate.keyTeam == teamId) {
        team = candidate;
        break;
      }
    }
    if (team == null) return;

    final opponent = opponentForMatch(
      match: match!,
      teamId: team.keyTeam ?? '',
      clubId: team.clubId,
    );
    final opponentName = opponent?.displayName ??
        _opponentNameForMatch(match, team.keyTeam) ??
        item.subtitle ??
        item.title;

    final competitionUrl = await resolveTeamStatsCompetitionUrlForMatch(
      team: team,
      match: match,
      fallbackSeasonId: session.selectedSeason?.ref?.id,
    );

    final scheduledAt = DateTime(
      item.startAt.year,
      item.startAt.month,
      item.startAt.day,
      preferences.morningReminderHour,
    );
    if (preferences.isQuietAt(scheduledAt)) return;
    if (scheduledAt.isBefore(DateTime.now())) return;

    final timeLabel = DateFormat.Hm().format(item.startAt);
    final title = l10n.reminderMatchOpponentStatsTitle;
    final body = l10n.reminderMatchOpponentStatsBody(timeLabel, opponentName);
    final reminderKey = 'match_stats_$matchId';

    final payload = <String, dynamic>{
      'type': 'matchOpponentStatsReminder',
      'id': matchId,
      'matchId': matchId,
      'teamId': team.keyTeam ?? '',
      if (competitionUrl != null && competitionUrl.isNotEmpty)
        'competitionUrl': competitionUrl,
      if (opponent?.key != null) 'opponentKey': opponent!.key,
      'opponentName': opponentName,
    };

    await _createInAppNotificationIfNeeded(
      uid: uid,
      type: NotifType.matchOpponentStatsReminder,
      objectId: matchId,
      title: title,
      body: body,
      playerId: session.selectedPlayerId,
    );

    await LocalReminderScheduler.instance.scheduleReminder(
      reminderKey: reminderKey,
      scheduledAtLocal: scheduledAt,
      timezoneName: preferences.timezone,
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> _createInAppNotificationIfNeeded({
    required String uid,
    required NotifType type,
    required String objectId,
    required String title,
    required String body,
    String? playerId,
  }) async {
    if (!EshopConfigService.instance.commerceNotificationsEnabled &&
        isCommerceNotifType(type)) {
      return;
    }

    final todayKey =
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dedupeId = '${type.name}_${objectId}_$todayKey';

    try {
      final existing = await _notificationService.getNotificationById(dedupeId);
      if (existing != null) return;

      await _notificationService.setNotification(
        dedupeId,
        NotificationApp(
          userId: uid,
          type: type,
          sendBy: SendBy.notification,
          title: title,
          body: body,
          objectId: objectId,
          playerId: playerId,
          isViewed: false,
          dateTimeCreated: Timestamp.now(),
        ),
      );
    } catch (e, st) {
      debugPrint(
        'InternalReminderService._createInAppNotificationIfNeeded: $e\n$st',
      );
    }
  }

  static String? _opponentNameForMatch(
    grinta_match.Match match,
    String? teamId,
  ) {
    final home = match.team1?.trim() ?? '';
    final away = match.team2?.trim() ?? '';
    if (teamId != null && home == teamId) return away.isEmpty ? null : away;
    if (teamId != null && away == teamId) return home.isEmpty ? null : home;
    return away.isNotEmpty ? away : (home.isNotEmpty ? home : null);
  }
}
