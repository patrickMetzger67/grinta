/// Oura Ring integration configuration (Phase 1 OAuth + workout import).
library;

/// Firebase Functions region for Oura callables.
const String kOuraFunctionsRegion = 'europe-west1';

const String kOuraOAuthStartFunctionName = 'ouraOAuthStart';
const String kOuraDisconnectFunctionName = 'ouraDisconnect';
const String kOuraRepairPlayerSyncFunctionName = 'ouraRepairPlayerSync';
const String kOuraListActivitiesFunctionName = 'ouraListActivities';
const String kOuraImportActivityFunctionName = 'ouraImportActivity';

/// Deep link opened after OAuth completes (via Cloud Function redirect).
const String kOuraOAuthDeepLinkHost = 'oura';
const String kOuraOAuthDeepLinkPath = '/callback';

/// HTTPS redirect URI registered in the Oura developer dashboard.
String ouraOAuthCallbackUrl({String projectId = 'aserstein-2453e'}) {
  return 'https://$kOuraFunctionsRegion-$projectId.cloudfunctions.net/ouraOAuthCallback';
}
