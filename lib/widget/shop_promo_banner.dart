import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/screen/shop/shop_webview_screen.dart';
import 'package:grinta/services/monetization_banner_rotation_service.dart';
import 'package:grinta/services/shopify_storefront_service.dart';
import 'package:grinta/util/app_theme.dart';

/// Banner highlighting a promo product from shop.grinta.io.
class ShopPromoBanner extends StatefulWidget {
  const ShopPromoBanner({super.key});

  @override
  State<ShopPromoBanner> createState() => _ShopPromoBannerState();
}

class _ShopPromoBannerState extends State<ShopPromoBanner> {
  bool _loading = true;
  ShopifyProduct? _product;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    await MonetizationBannerRotationService.instance.ensureInitialized();
    final products =
        await ShopifyStorefrontService.instance.fetchPromoProducts(limit: 3);
    if (!mounted) return;

    if (products.isEmpty) {
      setState(() {
        _product = null;
        _loading = false;
      });
      return;
    }

    final index = MonetizationBannerRotationService.instance
        .promoProductIndex(products.length);

    setState(() {
      _product = products[index];
      _loading = false;
    });
  }

  Future<void> _openProduct() async {
    final product = _product;
    if (product == null) return;
    await ShopWebViewScreen.open(context, url: product.productUrl);
  }

  Future<void> _openShop() async {
    await ShopWebViewScreen.open(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _product == null) {
      return const SizedBox.shrink();
    }

    final product = _product!;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final price = product.formattedPrice(locale);
    final compareAt = product.formattedCompareAtPrice(locale);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.35)),
        ),
        child: InkWell(
          onTap: _openProduct,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductThumbnail(
                  imageUrl: product.imageUrl,
                  colors: colors,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.shopPromoTitle,
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.title,
                        style: textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            price,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (compareAt != null && product.isOnSale) ...[
                            const SizedBox(width: 8),
                            Text(
                              compareAt,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _openProduct,
                            style: TextButton.styleFrom(
                              foregroundColor: colors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(context.l10n.shopPromoCta),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _openShop,
                            style: TextButton.styleFrom(
                              foregroundColor: colors.textSecondary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(context.l10n.shopBrowseAll),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.shopBrowseAll,
                  onPressed: _openShop,
                  icon: Icon(
                    Icons.shopping_bag_outlined,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({
    required this.imageUrl,
    required this.colors,
  });

  final String? imageUrl;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final borderRadius = BorderRadius.circular(12);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: borderRadius,
        ),
        child: Icon(
          Icons.local_offer_outlined,
          color: colors.primary,
          size: 28,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: colors.primary.withValues(alpha: 0.08),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: size,
          height: size,
          color: colors.primary.withValues(alpha: 0.12),
          child: Icon(Icons.image_not_supported_outlined, color: colors.primary),
        ),
      ),
    );
  }
}
