/// Polar AccessLink integration configuration (Phase 1 OAuth scaffolding).
library;

/// Firebase Functions region for Polar callables.
const String kPolarFunctionsRegion = 'europe-west1';

const String kPolarOAuthStartFunctionName = 'polarOAuthStart';
const String kPolarDisconnectFunctionName = 'polarDisconnect';

/// Deep link opened after OAuth completes (via Cloud Function redirect).
const String kPolarOAuthDeepLinkHost = 'polar';
const String kPolarOAuthDeepLinkPath = '/callback';

/// HTTPS redirect URI registered in the Polar AccessLink developer portal.
String polarOAuthCallbackUrl({String projectId = 'aserstein-2453e'}) {
  return 'https://$kPolarFunctionsRegion-$projectId.cloudfunctions.net/polarOAuthCallback';
}
