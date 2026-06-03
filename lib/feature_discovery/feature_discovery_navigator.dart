import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/feature_discovery/match_detail_tab_navigation_scope.dart';
import 'package:grinta/feature_discovery/shell_navigation_scope.dart';
import 'package:grinta/model/feature_discovery_ids.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/compo_screen.dart';
import 'package:grinta/screen/field_localization_screen.dart';
import 'package:grinta/screen/syncScreen.dart';
import 'package:grinta/screen/teamDetailScreen.dart';
import 'package:grinta/screen/teamsListScreen.dart';
import 'package:provider/provider.dart';

/// Navigates to a catalog [featureId] (shell tab, match-detail tab, or push).
bool navigateToDiscoveredFeature(BuildContext context, String featureId) {
  AnalyticsInteractions.logFeature(
    AnalyticsFeatures.featureDiscoveryAction,
    parameters: <String, Object>{'feature_id': featureId},
  );

  if (MatchDetailTabNavigationScope.tryNavigateToFeature(context, featureId)) {
    return true;
  }
  if (ShellNavigationScope.tryNavigateToTab(context, featureId)) {
    return true;
  }
  return _pushOffShellRoute(context, featureId);
}

bool _pushOffShellRoute(BuildContext context, String featureId) {
  final appSession = context.read<AppSession>();
  final managedTeamsIds = appSession.managedTeamsIdsForSelectedSeason;
  final navigator = Navigator.of(context);

  switch (featureId) {
    case FeatureDiscoveryIds.tabSync:
      navigator.push(
        analyticsMaterialRoute<void>(
          screenName: AnalyticsScreenNames.sync,
          builder: (_) => const SyncScreen(),
        ),
      );
      return true;
    case FeatureDiscoveryIds.tabTeams:
      if (managedTeamsIds.isEmpty) return false;
      navigator.push(
        analyticsMaterialRoute<void>(
          screenName: AnalyticsScreenNames.teamsList,
          builder: (_) => TeamsListScreen(
            managedTeamsIds: managedTeamsIds,
            onTeamTap: (ctx, team, isManager) {
              AnalyticsInteractions.logFeature(
                AnalyticsFeatures.openTeamDetail,
                parameters: <String, Object>{
                  'is_manager': isManager,
                  'source': 'feature_discovery',
                },
              );
              Navigator.of(ctx).push(
                analyticsMaterialRoute<void>(
                  screenName: AnalyticsScreenNames.teamDetail,
                  builder: (_) => TeamDetailScreen(
                    team: team,
                    seasonId: ctx.read<AppSession>().selectedSeason?.ref?.id,
                    isManager: isManager,
                  ),
                ),
              );
            },
          ),
        ),
      );
      return true;
    case FeatureDiscoveryIds.tabFields:
      if (managedTeamsIds.isEmpty) return false;
      navigator.push(
        analyticsMaterialRoute<void>(
          screenName: AnalyticsScreenNames.fields,
          builder: (_) => const FootballFieldLocalizationScreen(),
        ),
      );
      return true;
    case FeatureDiscoveryIds.tabCompo:
      if (managedTeamsIds.isEmpty) return false;
      navigator.push(
        analyticsMaterialRoute<void>(
          screenName: AnalyticsScreenNames.compo,
          builder: (_) => const CompoScreen(),
        ),
      );
      return true;
    default:
      return false;
  }
}
