import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:grinta/config/shopify_config.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// A product surfaced from the Shopify Storefront API or dev mock data.
class ShopifyProduct {
  const ShopifyProduct({
    required this.id,
    required this.title,
    required this.handle,
    required this.imageUrl,
    required this.priceAmount,
    required this.priceCurrency,
    this.compareAtPriceAmount,
    this.compareAtPriceCurrency,
    this.onlineStoreUrl,
  });

  final String id;
  final String title;
  final String handle;
  final String? imageUrl;
  final String priceAmount;
  final String priceCurrency;
  final String? compareAtPriceAmount;
  final String? compareAtPriceCurrency;
  final String? onlineStoreUrl;

  String get productUrl =>
      onlineStoreUrl ?? '$kShopifyShopUrl/products/$handle';

  bool get isOnSale =>
      compareAtPriceAmount != null &&
      compareAtPriceAmount!.isNotEmpty &&
      _parseAmount(compareAtPriceAmount!) > _parseAmount(priceAmount);

  String formattedPrice([String? locale]) {
    return _formatMoney(priceAmount, priceCurrency, locale);
  }

  String? formattedCompareAtPrice([String? locale]) {
    if (compareAtPriceAmount == null || compareAtPriceAmount!.isEmpty) {
      return null;
    }
    return _formatMoney(
      compareAtPriceAmount!,
      compareAtPriceCurrency ?? priceCurrency,
      locale,
    );
  }

  static double _parseAmount(String amount) => double.tryParse(amount) ?? 0;

  static String _formatMoney(String amount, String currency, String? locale) {
    final value = double.tryParse(amount);
    if (value == null) return '$amount $currency';
    final format = NumberFormat.simpleCurrency(
      name: currency,
      locale: locale ?? 'fr_FR',
    );
    return format.format(value);
  }

  factory ShopifyProduct.fromGraphQlNode(Map<String, dynamic> node) {
    final featuredImage = node['featuredImage'] as Map<String, dynamic>?;
    final priceRange = node['priceRange'] as Map<String, dynamic>?;
    final minPrice =
        priceRange?['minVariantPrice'] as Map<String, dynamic>? ?? {};
    final compareRange = node['compareAtPriceRange'] as Map<String, dynamic>?;
    final minCompare =
        compareRange?['minVariantPrice'] as Map<String, dynamic>?;

    return ShopifyProduct(
      id: node['id'] as String? ?? '',
      title: node['title'] as String? ?? '',
      handle: node['handle'] as String? ?? '',
      imageUrl: featuredImage?['url'] as String?,
      priceAmount: minPrice['amount'] as String? ?? '0',
      priceCurrency: minPrice['currencyCode'] as String? ?? 'EUR',
      compareAtPriceAmount: minCompare?['amount'] as String?,
      compareAtPriceCurrency: minCompare?['currencyCode'] as String?,
      onlineStoreUrl: node['onlineStoreUrl'] as String?,
    );
  }
}

/// Fetches promo products from Shopify Storefront API with caching.
class ShopifyStorefrontService {
  ShopifyStorefrontService._();

  static final ShopifyStorefrontService instance = ShopifyStorefrontService._();

  static const _cacheDuration = Duration(minutes: 30);

  List<ShopifyProduct>? _cachedProducts;
  DateTime? _cachedAt;
  Future<List<ShopifyProduct>>? _inFlight;

  static const _collectionProductsQuery = r'''
query PromoCollectionProducts($handle: String!, $first: Int!) {
  collection(handle: $handle) {
    products(first: $first) {
      edges {
        node {
          id
          title
          handle
          onlineStoreUrl
          featuredImage {
            url
          }
          priceRange {
            minVariantPrice {
              amount
              currencyCode
            }
          }
          compareAtPriceRange {
            minVariantPrice {
              amount
              currencyCode
            }
          }
        }
      }
    }
  }
}
''';

  /// Dev fallback when no Storefront token is configured.
  static List<ShopifyProduct> get mockPromoProducts => const [
        ShopifyProduct(
          id: 'mock-gps',
          title: 'Capteur GPS Grinta',
          handle: 'capteur-gps-grinta',
          imageUrl: null,
          priceAmount: '89.00',
          priceCurrency: 'EUR',
          compareAtPriceAmount: '109.00',
          compareAtPriceCurrency: 'EUR',
        ),
        ShopifyProduct(
          id: 'mock-supplement',
          title: 'Pack récupération',
          handle: 'pack-recuperation',
          imageUrl: null,
          priceAmount: '24.90',
          priceCurrency: 'EUR',
          compareAtPriceAmount: '29.90',
          compareAtPriceCurrency: 'EUR',
        ),
        ShopifyProduct(
          id: 'mock-accessory',
          title: 'Brassard porte-capteur',
          handle: 'brassard-porte-capteur',
          imageUrl: null,
          priceAmount: '14.90',
          priceCurrency: 'EUR',
          compareAtPriceAmount: '19.90',
          compareAtPriceCurrency: 'EUR',
        ),
      ];

  Future<List<ShopifyProduct>> fetchPromoProducts({int limit = 3}) async {
    if (_cachedProducts != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheDuration) {
      return _cachedProducts!.take(limit).toList();
    }

    _inFlight ??= _fetchPromoProducts(limit);
    try {
      return await _inFlight!;
    } finally {
      _inFlight = null;
    }
  }

  Future<List<ShopifyProduct>> _fetchPromoProducts(int limit) async {
    if (!kShopifyStorefrontConfigured) {
      _cachedProducts = mockPromoProducts;
      _cachedAt = DateTime.now();
      return mockPromoProducts.take(limit).toList();
    }

    try {
      final response = await http.post(
        kShopifyStorefrontGraphqlUri,
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Storefront-Access-Token': kShopifyStorefrontAccessToken,
        },
        body: jsonEncode({
          'query': _collectionProductsQuery,
          'variables': {
            'handle': kShopifyPromoCollectionHandle,
            'first': limit,
          },
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ShopifyStorefrontService HTTP ${response.statusCode}: ${response.body}',
        );
        return _fallbackToMock(limit);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final errors = decoded['errors'];
      if (errors != null) {
        debugPrint('ShopifyStorefrontService GraphQL errors: $errors');
        return _fallbackToMock(limit);
      }

      final data = decoded['data'] as Map<String, dynamic>?;
      final collection = data?['collection'] as Map<String, dynamic>?;
      if (collection == null) {
        debugPrint(
          'ShopifyStorefrontService: collection "$kShopifyPromoCollectionHandle" not found',
        );
        return _fallbackToMock(limit);
      }

      final products = collection['products'] as Map<String, dynamic>?;
      final edges = products?['edges'] as List<dynamic>? ?? [];
      final items = edges
          .map((edge) {
            final node = (edge as Map<String, dynamic>)['node'];
            if (node is! Map<String, dynamic>) return null;
            return ShopifyProduct.fromGraphQlNode(node);
          })
          .whereType<ShopifyProduct>()
          .where((p) => p.title.isNotEmpty)
          .toList();

      if (items.isEmpty) {
        return _fallbackToMock(limit);
      }

      _cachedProducts = items;
      _cachedAt = DateTime.now();
      return items.take(limit).toList();
    } catch (e, st) {
      debugPrint('ShopifyStorefrontService fetch failed: $e\n$st');
      return _fallbackToMock(limit);
    }
  }

  List<ShopifyProduct> _fallbackToMock(int limit) {
    _cachedProducts = mockPromoProducts;
    _cachedAt = DateTime.now();
    return mockPromoProducts.take(limit).toList();
  }

  void clearCache() {
    _cachedProducts = null;
    _cachedAt = null;
  }
}
