import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/services/monetization_banner_rotation_service.dart';
import 'package:grinta/services/shopify_storefront_service.dart';
import 'package:grinta/services/subscription_prompt_service.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/widget/shop_promo_banner.dart';
import 'package:grinta/widget/subscription_prompt_banner.dart';
import 'package:grinta/widget/trial_status_banner.dart';
import 'package:grinta/services/user_trial_service.dart';

/// Alternates subscription and shop promo banners for non-subscribers.
///
/// Subscribers see nothing. When the subscription prompt was dismissed, only
/// the shop promo is shown (if products are available).
class AlternatingMonetizationBanner extends StatefulWidget {
  const AlternatingMonetizationBanner({super.key});

  @override
  State<AlternatingMonetizationBanner> createState() =>
      _AlternatingMonetizationBannerState();
}

class _AlternatingMonetizationBannerState
    extends State<AlternatingMonetizationBanner> {
  bool _loading = true;
  MonetizationBannerKind? _kind;
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    _resolveBanner();
    SubscriptionService.instance.addListener(_onSubscriptionChanged);
    UserTrialService.instance.addListener(_onSubscriptionChanged);
  }

  @override
  void dispose() {
    SubscriptionService.instance.removeListener(_onSubscriptionChanged);
    UserTrialService.instance.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_resolveBanner());
    });
  }

  Future<void> _resolveBanner() async {
    final subscription = SubscriptionService.instance;
    final trial = UserTrialService.instance;
    await trial.ensureInitialized();

    if (subscription.hasActivePaidSubscription) {
      if (!mounted) return;
      setState(() {
        _subscribed = true;
        _kind = null;
        _loading = false;
      });
      return;
    }

    if (trial.shouldShowTrial) {
      if (!mounted) return;
      setState(() {
        _subscribed = false;
        _kind = MonetizationBannerKind.trialStatus;
        _loading = false;
      });
      return;
    }

    await SubscriptionPromptService.instance.ensureInitialized();
    final subscriptionVisible =
        SubscriptionPromptService.instance.shouldShowPrompt(
      isSubscribed: false,
    );

    final products =
        await ShopifyStorefrontService.instance.fetchPromoProducts(limit: 1);
    final shopVisible = products.isNotEmpty;

    if (!subscriptionVisible && !shopVisible) {
      if (!mounted) return;
      setState(() {
        _subscribed = false;
        _kind = null;
        _loading = false;
      });
      return;
    }

    await MonetizationBannerRotationService.instance.recordVisit();

    final MonetizationBannerKind kind;
    if (!subscriptionVisible) {
      kind = MonetizationBannerKind.shopPromo;
    } else if (!shopVisible) {
      kind = MonetizationBannerKind.subscription;
    } else {
      kind = MonetizationBannerRotationService.instance
          .bannerKindForCurrentVisit();
    }

    if (!mounted) return;
    setState(() {
      _subscribed = false;
      _kind = kind;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _subscribed || _kind == null) {
      return const SizedBox.shrink();
    }

    return switch (_kind!) {
      MonetizationBannerKind.trialStatus => const TrialStatusBanner(),
      MonetizationBannerKind.subscription => const SubscriptionPromptBanner(),
      MonetizationBannerKind.shopPromo => const ShopPromoBanner(),
    };
  }
}
