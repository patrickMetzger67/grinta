import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/screen/coach_workload_analysis/coach_workload_analysis_screen.dart';
import 'package:grinta/screen/coach_workload_analysis/coach_workload_teaser_screen.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/util/team_tracker_access.dart';

/// Opens coach workload analysis (Pro) or the frozen teaser upsell.
Future<void> openCoachWorkloadAnalysis(BuildContext context) async {
  await SubscriptionService.instance.refreshForActiveSession();
  if (!context.mounted) return;

  final hasPro = TeamTrackerAccess.hasCoachProTrackerAccess();
  AnalyticsInteractions.logFeature(
    hasPro
        ? AnalyticsFeatures.openCoachWorkloadAnalysis
        : AnalyticsFeatures.openCoachWorkloadAnalysisTeaser,
  );

  await Navigator.of(context).push<void>(
    analyticsMaterialRoute<void>(
      screenName: hasPro
          ? AnalyticsScreenNames.coachWorkloadAnalysis
          : AnalyticsScreenNames.coachWorkloadAnalysisTeaser,
      builder: (_) => hasPro
          ? const CoachWorkloadAnalysisScreen()
          : const CoachWorkloadTeaserScreen(),
    ),
  );
}
