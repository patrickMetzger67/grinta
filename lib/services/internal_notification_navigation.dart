import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/services/eshop_config_service.dart';
import 'package:grinta/feature_discovery/shell_navigation_scope.dart';
import 'package:grinta/model/feature_discovery_ids.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/team.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/match_detail_screen.dart';
import 'package:grinta/screen/prediction_game/prediction_game_screen.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/screen/team_stats/team_stats_screen.dart';
import 'package:grinta/services/calendar_deep_link_service.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:provider/provider.dart';

/// Shared navigation for internal reminders (local notifications + in-app).
class InternalNotificationNavigation {
  InternalNotificationNavigation._();

  static Future<void> handlePayload(Map<String, dynamic> data) async {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final rawType = data['type']?.toString().trim() ?? '';
    final type = rawType.startsWith('NotifType.')
        ? rawType.substring('NotifType.'.length)
        : rawType;
    if (!EshopConfigService.instance.commerceNotificationsEnabled &&
        isCommerceNotificationPayloadType(type)) {
      return;
    }
    switch (type) {
      case 'trainingReminder':
        await _openTrainingAgenda(context, data);
        break;
      case 'matchOpponentStatsReminder':
        await _openOpponentStats(context, data);
        break;
      case 'predictionGame':
        await _openPredictionGame(context, data);
        break;
      default:
        ShellNavigationScope.tryNavigateToTab(
          context,
          FeatureDiscoveryIds.tabDashboard,
        );
    }
  }

  static Future<void> handlePayloadJson(String payload) async {
    try {
      final data = Map<String, dynamic>.from(jsonDecode(payload));
      await handlePayload(data);
    } catch (_) {
      return;
    }
  }

  static Future<void> _openTrainingAgenda(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final trainingId = (data['trainingId'] ?? data['id'] ?? '').toString();
    DateTime? trainingDate;
    if (trainingId.isNotEmpty) {
      final training = await TrainingService().getTrainingById(trainingId);
      trainingDate = training?.dateTime?.toDate();
    }

    if (trainingDate != null) {
      CalendarDeepLinkService.instance.pendingAgendaDate.value =
          DateUtils.dateOnly(trainingDate);
    }

    if (!context.mounted) return;
    ShellNavigationScope.tryNavigateToTab(
      context,
      FeatureDiscoveryIds.tabAgenda,
    );
  }

  static Future<void> _openOpponentStats(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    await UserTrialService.instance.ensureInitialized();
    if (!UserTrialService.instance.hasPremiumAccess) return;

    var teamId = (data['teamId'] ?? '').toString().trim();
    var competitionUrl = (data['competitionUrl'] ?? '').toString().trim();
    var opponentKey = (data['opponentKey'] ?? '').toString().trim();
    var opponentName = (data['opponentName'] ?? '').toString().trim();
    final matchId = (data['matchId'] ?? data['id'] ?? '').toString().trim();

    models.Match? match;
    if (matchId.isNotEmpty) {
      match = await MatchService().getMatchById(matchId);
    }

    final session = context.read<AppSession>();
    if ((teamId.isEmpty || opponentKey.isEmpty) && match != null) {
      teamId = match.teamID?.trim() ?? teamId;
      final teamForMatch = _teamForId(session, teamId);
      if (teamForMatch != null) {
        final opponent = opponentForMatch(
          match: match,
          teamId: teamForMatch.keyTeam ?? '',
          clubId: teamForMatch.clubId,
        );
        opponentKey = opponentKey.isNotEmpty ? opponentKey : (opponent?.key ?? '');
        opponentName = opponentName.isNotEmpty
            ? opponentName
            : (opponent?.displayName ?? '');
        if (competitionUrl.isEmpty) {
          competitionUrl = await resolveTeamStatsCompetitionUrlForMatch(
                team: teamForMatch,
                match: match,
                fallbackSeasonId: session.selectedSeason?.ref?.id,
              ) ??
              '';
        }
      }
    }

    Team? team = _teamForId(session, teamId);
    team ??= session.teamsForAgendaSelectedSeason.isNotEmpty
        ? session.teamsForAgendaSelectedSeason.first
        : null;

    if (team == null) return;

    final resolvedTeamId = team.keyTeam;
    final isManager = resolvedTeamId != null &&
        session.managedTeamsIdsForSelectedSeason.contains(resolvedTeamId);

    if (!context.mounted) return;

    await Navigator.of(context).push<void>(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.teamStats,
        builder: (_) => TeamStatsScreen(
          team: team!,
          isManager: isManager,
          fallbackSeasonId: session.selectedSeason?.ref?.id,
          initialTabIndex: 2,
          initialCompetitionUrl:
              competitionUrl.isNotEmpty ? competitionUrl : null,
          initialOpponentKey: opponentKey.isNotEmpty ? opponentKey : null,
          initialOpponentName: opponentName.isNotEmpty ? opponentName : null,
          initialMatchIdForViewTracking:
              matchId.isNotEmpty ? matchId : null,
        ),
      ),
    );
  }

  static Future<void> _openPredictionGame(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final contestId = (data['predGameDayId'] ??
            data['objectId'] ??
            data['id'] ??
            '')
        .toString()
        .trim();
    if (contestId.isEmpty) return;
    if (!context.mounted) return;

    await openPredictionGameScreen(
      context,
      predGameDayId: contestId,
    );
  }

  static Team? _teamForId(AppSession session, String teamId) {
    for (final candidate in session.teamsForAgendaSelectedSeason) {
      if (candidate.keyTeam == teamId) {
        return candidate;
      }
    }
    return null;
  }

  static Future<void> openMatchOpponentStatsFromMatchDetail(
    BuildContext context, {
    required models.Match match,
    required Team team,
    required bool isManager,
    String? competitionUrl,
    String? opponentKey,
    String? opponentName,
  }) async {
    await UserTrialService.instance.ensureInitialized();
    if (!UserTrialService.instance.hasPremiumAccess) return;

    final session = context.read<AppSession>();
    if (!context.mounted) return;

    await Navigator.of(context).push<void>(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.teamStats,
        builder: (_) => TeamStatsScreen(
          team: team,
          isManager: isManager,
          fallbackSeasonId: session.selectedSeason?.ref?.id,
          initialTabIndex: 2,
          initialCompetitionUrl: competitionUrl,
          initialOpponentKey: opponentKey,
          initialOpponentName: opponentName,
          initialMatchIdForViewTracking: match.id,
        ),
      ),
    );
  }
}
