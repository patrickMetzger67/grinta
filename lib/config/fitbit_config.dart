/// Fitbit Web API integration configuration (Phase 1 OAuth scaffolding).
library;

/// Firebase Functions region for Fitbit callables.
const String kFitbitFunctionsRegion = 'europe-west1';

const String kFitbitOAuthStartFunctionName = 'fitbitOAuthStart';
const String kFitbitDisconnectFunctionName = 'fitbitDisconnect';

/// Deep link opened after OAuth completes (via Cloud Function redirect).
const String kFitbitOAuthDeepLinkHost = 'fitbit';
const String kFitbitOAuthDeepLinkPath = '/callback';

/// HTTPS redirect URI registered in the Fitbit developer portal.
String fitbitOAuthCallbackUrl({String projectId = 'aserstein-2453e'}) {
  return 'https://$kFitbitFunctionsRegion-$projectId.cloudfunctions.net/fitbitOAuthCallback';
}
