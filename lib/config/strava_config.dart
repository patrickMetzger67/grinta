/// Strava integration configuration (Phase 1 OAuth scaffolding).
library;

/// Firebase Functions region for Strava callables.
const String kStravaFunctionsRegion = 'europe-west1';

const String kStravaOAuthStartFunctionName = 'stravaOAuthStart';
const String kStravaDisconnectFunctionName = 'stravaDisconnect';
const String kStravaListActivitiesFunctionName = 'stravaListActivities';
const String kStravaImportActivityFunctionName = 'stravaImportActivity';

/// Deep link opened after OAuth completes (via Cloud Function redirect).
const String kStravaOAuthDeepLinkHost = 'strava';
const String kStravaOAuthDeepLinkPath = '/callback';

/// HTTPS redirect URI registered in the Strava API application settings.
String stravaOAuthCallbackUrl({String projectId = 'aserstein-2453e'}) {
  return 'https://$kStravaFunctionsRegion-$projectId.cloudfunctions.net/stravaOAuthCallback';
}
