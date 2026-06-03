import 'package:grinta/analytics/analytics_events.dart';
import 'package:grinta/services/analytics_service.dart';

/// Shared helpers for interaction analytics (tabs, taps).
abstract final class AnalyticsInteractions {
  AnalyticsInteractions._();

  static void logTabSelect({
    required String screen,
    required String tab,
  }) {
    AnalyticsService.instance.logFeatureEvent(
      name: AnalyticsEvents.tabSelect,
      parameters: <String, Object>{
        'screen': screen,
        'tab': tab,
      },
    );
  }

  static void logFeature(
    String feature, {
    Map<String, Object>? parameters,
  }) {
    AnalyticsService.instance.logFeatureUsed(
      feature: feature,
      parameters: parameters,
    );
  }
}
