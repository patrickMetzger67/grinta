/// Stable snake_case feature ids for [AnalyticsService.logFeatureUsed].
abstract final class AnalyticsFeatures {
  // Auth
  static const loginAttempt = 'login_attempt';
  static const loginSuccess = 'login_success';
  static const logout = 'logout';

  // Navigation / opens
  static const openMatchDetail = 'open_match_detail';
  static const openTeamDetail = 'open_team_detail';
  static const openTeamPlayers = 'open_team_players';
  static const openTeamParam = 'open_team_param';
  static const openTrackerStats = 'open_tracker_stats';
  static const openPlayerAnalysis = 'open_player_analysis';

  // Tracker kit & sync
  static const trackerKitTap = 'tracker_kit_tap';
  static const syncTrackerHub = 'sync_tracker_hub';

  // Feature discovery
  static const featureDiscoveryDismiss = 'feature_discovery_dismiss';
  static const featureDiscoveryAction = 'feature_discovery_action';

  // Dashboard filters
  static const dashboardPeriodSelect = 'dashboard_period_select';
  static const dashboardStatsTypeSelect = 'dashboard_stats_type_select';
  static const dashboardStatsWhereSelect = 'dashboard_stats_where_select';

  // Player analysis sub-tabs (used as `tab` in tab_select)
  static const playerAnalysisTabSynthesis = 'synthesis';
  static const playerAnalysisTabSpeedZones = 'speed_zones';
  static const playerAnalysisTabFieldZones = 'field_zones';
  static const playerAnalysisTabHalfTime = 'half_time';
  static const playerAnalysisTabDistanceTimeline = 'distance_timeline';
  static const playerAnalysisTabHeatmap = 'heatmap';
}
