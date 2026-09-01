/// Meta (Instagram Business + Facebook Page) OAuth / publish callables.
library;

const String kMetaFunctionsRegion = 'europe-west1';

const String kMetaOAuthStartFunctionName = 'metaOAuthStart';
const String kMetaDisconnectFunctionName = 'metaDisconnect';
const String kMetaPublishFunctionName = 'publishShareToMeta';

const String kMetaOAuthDeepLinkHost = 'meta';
const String kMetaOAuthDeepLinkPath = '/callback';

String metaOAuthCallbackUrl({String projectId = 'aserstein-2453e'}) {
  return 'https://$kMetaFunctionsRegion-$projectId.cloudfunctions.net/metaOAuthCallback';
}
