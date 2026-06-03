/// Stable ids for [FeatureDiscoveryService] (tabs, screens, flows).
abstract final class FeatureDiscoveryIds {
  static const String tabAgenda = 'tab_agenda';
  static const String tabDashboard = 'tab_dashboard';
  static const String tabChat = 'tab_chat';
  static const String tabSync = 'tab_sync';
  static const String tabTeams = 'tab_teams';
  static const String tabFields = 'tab_fields';
  static const String tabCompo = 'tab_compo';

  /// Match detail sub-tabs (cross-device visited tracking).
  static const String matchDetailTabCompo = 'match_detail_tab_compo';
  static const String matchDetailTabTacticalSchema =
      'match_detail_tab_tactical_schema';
  static const String matchDetailTabHighlights = 'match_detail_tab_highlights';
  static const String matchDetailTabStats = 'match_detail_tab_stats';

  /// Parent screen id for match-detail related discovery prompts.
  static const String screenMatchDetail = 'screen_match_detail';
}
