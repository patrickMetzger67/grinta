/// Firebase Analytics event names used across the app.
abstract final class AnalyticsEvents {
  static const featureUsed = 'feature_used';
  static const screenDuration = 'screen_duration';
  static const tabSelect = 'tab_select';

  /// Legacy event name; prefer [tabSelect] for new tab logging.
  static const matchDetailTab = 'match_detail_tab';

  static const openProduct = 'open_product';
}
