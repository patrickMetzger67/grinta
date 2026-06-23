/// Shopify Storefront API configuration for shop.grinta.io.
///
/// ## Shopify admin setup
/// 1. Shopify Admin → Settings → Apps and sales channels → Develop apps
/// 2. Create a custom app with Storefront API access
/// 3. Enable scopes: `unauthenticated_read_product_listings`,
///    `unauthenticated_read_product_inventory` (read products/collections)
/// 4. Install the app and copy the **Storefront API access token**
/// 5. Pass at build time (never commit):
///    `--dart-define=SHOPIFY_STOREFRONT_TOKEN=shpat_...`
/// 6. Create a collection (e.g. handle `promo`) with products on sale
library;

/// Public shop domain (custom domain or *.myshopify.com).
const String kShopifyShopDomain = 'shop.grinta.io';

/// Storefront API version segment in the GraphQL endpoint URL.
const String kShopifyStorefrontApiVersion = '2024-01';

/// Collection handle used for promo banner products.
const String kShopifyPromoCollectionHandle = 'promo';

/// Storefront API access token — pass via `--dart-define`, empty in dev (mock data).
const String kShopifyStorefrontAccessToken = String.fromEnvironment(
  'SHOPIFY_STOREFRONT_TOKEN',
  defaultValue: '',
);

/// Full shop URL for WebView browsing.
String get kShopifyShopUrl => 'https://$kShopifyShopDomain';

/// GraphQL endpoint for the Storefront API.
Uri get kShopifyStorefrontGraphqlUri => Uri.parse(
      'https://$kShopifyShopDomain/api/$kShopifyStorefrontApiVersion/graphql.json',
    );

/// Whether live Storefront API calls are configured.
bool get kShopifyStorefrontConfigured => kShopifyStorefrontAccessToken.isNotEmpty;
