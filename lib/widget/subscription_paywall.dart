import 'package:flutter/material.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Which subscription catalog to emphasize in the paywall.
enum SubscriptionOfferingKind {
  coach,
  player,
}

/// Full-screen dialog / sheet presenting Coach and Player subscriptions.
class SubscriptionPaywall extends StatefulWidget {
  const SubscriptionPaywall({
    super.key,
    this.initialKind = SubscriptionOfferingKind.coach,
    this.allowSkip = true,
  });

  final SubscriptionOfferingKind initialKind;
  final bool allowSkip;

  /// Shows paywall as dialog (wide) or bottom sheet (narrow).
  static Future<bool?> show(
    BuildContext context, {
    SubscriptionOfferingKind initialKind = SubscriptionOfferingKind.coach,
    bool allowSkip = true,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final child = SubscriptionPaywall(
      initialKind: initialKind,
      allowSkip: allowSkip,
    );

    if (width >= 600) {
      return showDialog<bool>(
        context: context,
        barrierDismissible: allowSkip,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
            child: child,
          ),
        ),
      );
    }

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: child,
        ),
      ),
    );
  }

  @override
  State<SubscriptionPaywall> createState() => _SubscriptionPaywallState();
}

class _SubscriptionPaywallState extends State<SubscriptionPaywall> {
  late SubscriptionOfferingKind _kind = widget.initialKind;
  CoachTier _selectedCoachTier = CoachTier.elite;
  bool _busy = false;

  SubscriptionService get _service => SubscriptionService.instance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final state = _service.state;
        final offerings = _service.offerings;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.subscriptionPaywallTitle,
                          style: textTheme.headlineSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.subscriptionPaywallSubtitle,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.allowSkip)
                    IconButton(
                      tooltip: l10n.subscriptionPaywallLater,
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SegmentedButton<SubscriptionOfferingKind>(
                segments: [
                  ButtonSegment(
                    value: SubscriptionOfferingKind.coach,
                    label: Text(l10n.subscriptionOfferingCoach),
                  ),
                  ButtonSegment(
                    value: SubscriptionOfferingKind.player,
                    label: Text(l10n.subscriptionOfferingPlayer),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: _busy
                    ? null
                    : (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 20),
              if (_kind == SubscriptionOfferingKind.coach)
                ..._coachTierCards(context, offerings, state)
              else
                _playerCard(context, offerings, state),
              const SizedBox(height: 16),
              if (state.isSubscribed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.subscriptionAlreadyActive,
                    style: textTheme.bodyMedium?.copyWith(color: colors.success),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_service.isNativeStoreAvailable) ...[
                OutlinedButton(
                  onPressed: _busy ? null : _restore,
                  child: Text(l10n.subscriptionRestorePurchases),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                l10n.subscriptionAutoRenewLegal,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              if (! _service.isNativeStoreAvailable) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.subscriptionStoreUnavailable,
                  style: textTheme.bodySmall?.copyWith(color: colors.warning),
                  textAlign: TextAlign.center,
                ),
              ],
              if (widget.allowSkip) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(l10n.subscriptionPaywallLater),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _coachTierCards(
    BuildContext context,
    Offerings? offerings,
    SubscriptionState state,
  ) {
    final tiers = [
      (CoachTier.basic, l10nFor(context).subscriptionTierCoachBasic,
          l10nFor(context).subscriptionTierCoachBasicDesc,
          SubscriptionFallbackPrices.coachBasic,
          SubscriptionProductIds.coachBasicMonthly),
      (CoachTier.elite, l10nFor(context).subscriptionTierCoachElite,
          l10nFor(context).subscriptionTierCoachEliteDesc,
          SubscriptionFallbackPrices.coachElite,
          SubscriptionProductIds.coachEliteMonthly),
      (CoachTier.pro, l10nFor(context).subscriptionTierCoachPro,
          l10nFor(context).subscriptionTierCoachProDesc,
          SubscriptionFallbackPrices.coachPro,
          SubscriptionProductIds.coachProMonthly),
    ];

    return tiers
        .map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TierCard(
              title: t.$2,
              description: t.$3,
              price: _priceForProduct(offerings, t.$5) ?? t.$4,
              selected: _selectedCoachTier == t.$1,
              active: state.coachTier == t.$1,
              busy: _busy,
              onSelect: () => setState(() => _selectedCoachTier = t.$1),
              onPurchase: () => _purchaseCoach(t.$1, offerings),
            ),
          ),
        )
        .toList();
  }

  Widget _playerCard(
    BuildContext context,
    Offerings? offerings,
    SubscriptionState state,
  ) {
    final l10n = context.l10n;
    return _TierCard(
      title: l10n.subscriptionTierPlayer,
      description: l10n.subscriptionTierPlayerDesc,
      price: _priceForProduct(
            offerings,
            SubscriptionProductIds.playerMonthly,
          ) ??
          SubscriptionFallbackPrices.player,
      selected: true,
      active: state.hasPlayerSubscription,
      busy: _busy,
      onSelect: () {},
      onPurchase: () => _purchasePlayer(offerings),
    );
  }

  String? _priceForProduct(Offerings? offerings, String productId) {
    if (offerings == null) return null;
    for (final offering in offerings.all.values) {
      for (final package in offering.availablePackages) {
        if (package.storeProduct.identifier == productId) {
          return package.storeProduct.priceString;
        }
      }
    }
    return null;
  }

  Package? _packageForProduct(Offerings? offerings, String productId) {
    if (offerings == null) return null;
    for (final offering in offerings.all.values) {
      for (final package in offering.availablePackages) {
        if (package.storeProduct.identifier == productId) {
          return package;
        }
      }
    }
    return null;
  }

  Future<void> _purchaseCoach(CoachTier tier, Offerings? offerings) async {
    final productId = switch (tier) {
      CoachTier.basic => SubscriptionProductIds.coachBasicMonthly,
      CoachTier.elite => SubscriptionProductIds.coachEliteMonthly,
      CoachTier.pro => SubscriptionProductIds.coachProMonthly,
    };
    await _purchase(productId, offerings);
  }

  Future<void> _purchasePlayer(Offerings? offerings) async {
    await _purchase(SubscriptionProductIds.playerMonthly, offerings);
  }

  Future<void> _purchase(String productId, Offerings? offerings) async {
    if (!_service.isNativeStoreAvailable) return;

    final package = _packageForProduct(offerings, productId);
    if (package == null) {
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.subscriptionProductNotFound);
      return;
    }

    setState(() => _busy = true);
    try {
      final info = await _service.purchasePackage(package);
      if (!mounted) return;
      if (info != null && _service.isSubscribed) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.subscriptionPurchaseFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await _service.restorePurchases();
      if (!mounted) return;
      if (_service.isSubscribed) {
        Navigator.of(context).pop(true);
      } else {
        AppSnackbar.show(context, context.l10n.subscriptionRestoreNone);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.subscriptionRestoreFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

AppLocalizations l10nFor(BuildContext context) => context.l10n;

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.title,
    required this.description,
    required this.price,
    required this.selected,
    required this.active,
    required this.busy,
    required this.onSelect,
    required this.onPurchase,
  });

  final String title;
  final String description;
  final String price;
  final bool selected;
  final bool active;
  final bool busy;
  final VoidCallback onSelect;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Material(
      color: selected ? colors.primary.withValues(alpha: 0.08) : colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? colors.primary : colors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: busy ? null : onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$price${l10n.subscriptionPerMonth}',
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.3,
                ),
              ),
              if (active) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.subscriptionTierActive,
                  style: textTheme.labelMedium?.copyWith(color: colors.success),
                ),
              ] else ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (busy || !selected) ? null : onPurchase,
                    child: busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.subscriptionSubscribe),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
