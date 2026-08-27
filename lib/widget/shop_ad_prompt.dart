import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/shop_ad.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/shop_ads_preferences_service.dart';
import 'package:grinta/services/shop_ads_service.dart';
import 'package:grinta/services/social_onboarding_coordinator.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/youtube_top_video_prompt.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows at most one shop-ad overlay per local calendar day.
///
/// Triggers: session start ([maybeShow]) and feature/tab changes
/// ([maybeShow] with [fromFeatureChange] — debounced).
class ShopAdPrompt {
  ShopAdPrompt._();

  static bool _dialogOpen = false;
  static DateTime? _lastFeatureTriggerAt;
  static const Duration _featureDebounce = Duration(seconds: 2);

  static bool get isDialogOpen => _dialogOpen;

  /// Safe to invoke multiple times. No-ops when a dialog is already visible,
  /// the user opted out, the global kill switch is off, or an ad was already
  /// shown today.
  ///
  /// Never throws: ads must not abort login, home, or team loading.
  static Future<void> maybeShow({bool fromFeatureChange = false}) async {
    try {
      await _maybeShowBody(fromFeatureChange: fromFeatureChange);
    } catch (e, st) {
      debugPrint('ShopAdPrompt.maybeShow failed: $e\n$st');
      _dialogOpen = false;
    }
  }

  static Future<void> _maybeShowBody({required bool fromFeatureChange}) async {
    if (_dialogOpen) return;

    if (fromFeatureChange) {
      final now = DateTime.now();
      final last = _lastFeatureTriggerAt;
      if (last != null && now.difference(last) < _featureDebounce) {
        return;
      }
      _lastFeatureTriggerAt = now;
    }

    if (SocialOnboardingCoordinator.instance.isProfileOnboardingActive) {
      return;
    }

    for (var i = 0; i < 20 && YoutubeTopVideoPrompt.isDialogOpen; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (YoutubeTopVideoPrompt.isDialogOpen || _dialogOpen) return;

    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) return;

    AppSession session;
    try {
      session = rootContext.read<AppSession>();
    } catch (_) {
      return;
    }
    if (session.selectedPlayer == null) return;

    final ad = await ShopAdsService.instance.pickAdToShow(session);
    if (ad == null) return;
    if (!rootContext.mounted || _dialogOpen) return;
    if (YoutubeTopVideoPrompt.isDialogOpen) return;

    _dialogOpen = true;
    try {
      await ShopAdsPreferencesService.instance.markShownToday();
      await ShopAdsService.instance.incrementDisplay(ad.id);
      if (!rootContext.mounted) return;
      await showDialog<void>(
        context: rootContext,
        useRootNavigator: true,
        barrierDismissible: true,
        builder: (ctx) => ShopAdDialog(ad: ad),
      );
    } finally {
      _dialogOpen = false;
    }
  }
}

class ShopAdDialog extends StatefulWidget {
  const ShopAdDialog({super.key, required this.ad});

  final ShopAd ad;

  @override
  State<ShopAdDialog> createState() => _ShopAdDialogState();
}

class _ShopAdDialogState extends State<ShopAdDialog> {
  bool _busy = false;

  Future<void> _dismiss() async {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _openShop() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final url = widget.ad.url.trim();
      await ShopAdsService.instance.incrementClicks(widget.ad.id);
      final uri = Uri.tryParse(url);
      var launched = false;
      if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.shopAdOpenFailed)),
        );
      }
    } catch (e, st) {
      debugPrint('ShopAdDialog._openShop failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.shopAdOpenFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = MediaQuery.sizeOf(context).width.clamp(280.0, 520.0);
    final imageUrl = widget.ad.resolvedImageUrl;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.storefront_outlined, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.ad.name,
                        style: textTheme.titleLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.actionClose,
                      onPressed: _busy ? null : _dismiss,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                if (imageUrl != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => ColoredBox(
                          color: colors.background,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: colors.background,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _openShop,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l10n.shopAdCta),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _busy ? null : _dismiss,
                  child: Text(l10n.actionClose),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
