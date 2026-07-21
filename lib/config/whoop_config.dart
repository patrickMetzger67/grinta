/// Whoop integration configuration (Phase 1 OAuth scaffolding).
library;

/// Firebase Functions region for Whoop callables.
const String kWhoopFunctionsRegion = 'europe-west1';

const String kWhoopOAuthStartFunctionName = 'whoopOAuthStart';
const String kWhoopDisconnectFunctionName = 'whoopDisconnect';
const String kWhoopRepairPlayerSyncFunctionName = 'whoopRepairPlayerSync';

/// Deep link opened after OAuth completes (via Cloud Function redirect).
const String kWhoopOAuthDeepLinkHost = 'whoop';
const String kWhoopOAuthDeepLinkPath = '/callback';

/// HTTPS redirect URI registered in the Whoop developer dashboard.
String whoopOAuthCallbackUrl({String projectId = 'aserstein-2453e'}) {
  return 'https://$kWhoopFunctionsRegion-$projectId.cloudfunctions.net/whoopOAuthCallback';
}
