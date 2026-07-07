import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/feature_discovery/shell_navigation_scope.dart';
import 'package:grinta/model/chat_action.dart';
import 'package:grinta/model/feature_discovery_ids.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/match_detail_screen.dart';
import 'package:grinta/screen/team_stats/team_stats_screen.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/widget/subscription_paywall.dart';
import 'package:provider/provider.dart';

/// Executes navigation actions returned by the Gemini assistant.
///
/// Add a `case` here only when Ask Diego needs a new in-app route.
/// Question wording and intents live in `functions/ask_diego_prompt.js`.
class ChatNavigationService {
  ChatNavigationService._();

  static final ChatNavigationService instance = ChatNavigationService._();

  final MatchService _matchService = MatchService();

  Future<void> handleActions(
    BuildContext context,
    List<ChatAction> actions,
  ) async {
    for (final action in actions) {
      if (action is! ChatNavigateAction) continue;
      await navigate(context, action.route, action.params);
    }
  }

  Future<bool> navigate(
    BuildContext context,
    String route,
    Map<String, dynamic> params,
  ) async {
    final normalized = route.trim().toLowerCase();

    switch (normalized) {
      case 'agenda':
        return _openAgenda(context, params);
      case 'dashboard':
        return _openDashboard(context);
      case 'match_detail':
        return _openMatchDetail(context, params);
      case 'team_stats':
        return _openTeamStats(context, params, opponentsTab: false);
      case 'team_stats_opponents':
        return _openTeamStats(context, params, opponentsTab: true);
      default:
        if (context.mounted) {
          AppSnackbar.show(
            context,
            context.l10n.askDiegoNavigationUnknown(route),
          );
        }
        return false;
    }
  }

  bool _openAgenda(BuildContext context, Map<String, dynamic> params) {
    final navigated = ShellNavigationScope.tryNavigateToTab(
      context,
      FeatureDiscoveryIds.tabAgenda,
    );
    if (!navigated && context.mounted) {
      AppSnackbar.show(context, context.l10n.askDiegoNavigationAgendaHint, isError: false);
    }
    return navigated;
  }

  bool _openDashboard(BuildContext context) {
    return ShellNavigationScope.tryNavigateToTab(
      context,
      FeatureDiscoveryIds.tabDashboard,
    );
  }

  Future<bool> _openMatchDetail(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final matchId = (params['matchId'] ?? '').toString().trim();
    if (matchId.isEmpty) {
      if (context.mounted) {
        AppSnackbar.show(context, context.l10n.askDiegoNavigationMatchMissing);
      }
      return false;
    }

    final match = await _matchService.getMatchById(matchId);
    if (!context.mounted) return false;

    if (match == null) {
      AppSnackbar.show(context, context.l10n.askDiegoNavigationMatchNotFound);
      return false;
    }

    final session = context.read<AppSession>();
    final teamId = match.teamID?.trim();
    final isManager = teamId != null &&
        session.managedTeamsIdsForSelectedSeason.contains(teamId);

    await Navigator.of(context).push<void>(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.matchDetail,
        builder: (_) => MatchDetailScreen(
          match: match,
          isManager: isManager,
          playerId: session.selectedPlayerId,
        ),
      ),
    );
    return true;
  }

  Future<bool> _openTeamStats(
    BuildContext context,
    Map<String, dynamic> params, {
    required bool opponentsTab,
  }) async {
    final session = context.read<AppSession>();
    final teams = session.teamsForAgendaSelectedSeason;
    if (teams.isEmpty) {
      if (context.mounted) {
        AppSnackbar.show(context, context.l10n.askDiegoNavigationNoTeam);
      }
      return false;
    }

    final requestedTeamId = (params['teamId'] ?? '').toString().trim();
    Team? team;
    if (requestedTeamId.isNotEmpty) {
      for (final Team candidate in teams) {
        if (candidate.keyTeam == requestedTeamId) {
          team = candidate;
          break;
        }
      }
    }
    team ??= teams.first;

    final teamId = team.keyTeam;
    final isManager = teamId != null &&
        session.managedTeamsIdsForSelectedSeason.contains(teamId);

    await UserTrialService.instance.ensureInitialized();

    if (opponentsTab && !UserTrialService.instance.hasPremiumAccess) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          context.l10n.askDiegoNavigationOpponentsPremiumOnly,
        );
        await SubscriptionPaywall.show(
          context,
          allowSkip: true,
          initialKind: SubscriptionOfferingKind.player,
        );
      }
      return false;
    }

    final showOpponentsTab =
        isManager || UserTrialService.instance.hasPremiumAccess;
    final opponentsTabIndex = showOpponentsTab ? 2 : 0;

    final competitionUrl = (params['competitionUrl'] ?? '').toString().trim();
    final opponentKey = (params['opponentKey'] ?? '').toString().trim();
    final opponentName = (params['opponentName'] ?? '').toString().trim();

    await Navigator.of(context).push<void>(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.teamStats,
        builder: (_) => TeamStatsScreen(
          team: team!,
          isManager: isManager,
          fallbackSeasonId: session.selectedSeason?.ref?.id,
          initialTabIndex: opponentsTab ? opponentsTabIndex : 0,
          initialCompetitionUrl:
              competitionUrl.isNotEmpty ? competitionUrl : null,
          initialOpponentKey: opponentKey.isNotEmpty ? opponentKey : null,
          initialOpponentName:
              opponentName.isNotEmpty ? opponentName : null,
        ),
      ),
    );
    return true;
  }
}
