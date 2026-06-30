import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/legal_links_footer.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Whether the active member profile should see Coach (Entraîneur) offerings first.
bool prefersCoachSubscriptionOffering(AppSession session) {
  final player = session.selectedPlayer;
  if (player != null && player.isEducatorOrCoach) {
    return true;
  }
  return session.managedTeamsIdsForSelectedSeason.isNotEmpty ||
      session.hasManagedTeamsInSelectedSeason;
}

/// Which subscription catalog to emphasize in the paywall.
enum SubscriptionOfferingKind {
  coach,
  player,
}

/// Full-screen dialog / sheet presenting Coach and Player subscriptions.
class SubscriptionPaywall extends StatefulWidget {
  const SubscriptionPaywall({
    super.key,
    this.initialKind = SubscriptionOfferingKind.player,
    this.allowSkip = true,
    this.changePlanMode = false,
  });

  final SubscriptionOfferingKind initialKind;
  final bool allowSkip;

  /// Existing subscribers changing tier or billing period.
  final bool changePlanMode;

  /// Shows paywall as dialog (wide) or bottom sheet (narrow).
  static Future<bool?> show(
    BuildContext context, {
    SubscriptionOfferingKind? initialKind,
    bool allowSkip = true,
    bool changePlanMode = false,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final effectiveAllowSkip = changePlanMode ? false : allowSkip;
    final resolvedKind = initialKind ??
        (prefersCoachSubscriptionOffering(context.read<AppSession>())
            ? SubscriptionOfferingKind.coach
            : SubscriptionOfferingKind.player);
    final child = SubscriptionPaywall(
      initialKind: resolvedKind,
      allowSkip: effectiveAllowSkip,
      changePlanMode: changePlanMode,
    );

    if (width >= 600) {
      return showDialog<bool>(
        context: context,
        barrierDismissible: effectiveAllowSkip,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: SingleChildScrollView(child: child),
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
  SubscriptionBillingPeriod _billingPeriod = SubscriptionBillingPeriod.yearly;
  bool _busy = false;

  SubscriptionService get _service => SubscriptionService.instance;

  @override
  void initState() {
    super.initState();
    if (widget.changePlanMode) {
      _applyCurrentSubscriptionSelection();
    } else {
      _applyProfileOpeningDefaults();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshPaywallState());
    });
  }

  void _applyProfileOpeningDefaults() {
    if (widget.initialKind == SubscriptionOfferingKind.coach) {
      _billingPeriod = SubscriptionBillingPeriod.yearly;
    }
  }

  Future<void> _refreshPaywallState() async {
    await _service.refreshForActiveSession();
  }

  bool _isCurrentlyActivePlan({
    required SubscriptionOfferingKind kind,
    CoachTier? coachTier,
  }) {
    if (!_service.hasActivePaidSubscription) return false;
    return _isExactActivePlan(kind: kind, coachTier: coachTier);
  }

  void _applyCurrentSubscriptionSelection() {
    final state = _service.state;
    if (state.hasPlayerSubscription) {
      _kind = SubscriptionOfferingKind.player;
    } else if (state.coachTier != null) {
      _kind = SubscriptionOfferingKind.coach;
      _selectedCoachTier = state.coachTier!;
    }
    final period = state.billingPeriod;
    if (period != null) {
      _billingPeriod = period;
    }
  }

  bool _isExactActivePlan({
    required SubscriptionOfferingKind kind,
    CoachTier? coachTier,
  }) {
    final state = _service.state;
    if (!state.isSubscribed) return false;
    if (state.billingPeriod != _billingPeriod) return false;
    if (kind == SubscriptionOfferingKind.player) {
      return state.hasPlayerSubscription;
    }
    return state.coachTier == coachTier;
  }

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
                          widget.changePlanMode
                              ? l10n.subscriptionChangePlanTitle
                              : l10n.subscriptionPaywallTitle,
                          style: textTheme.headlineSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.changePlanMode
                              ? l10n.subscriptionChangePlanSubtitle
                              : l10n.subscriptionPaywallSubtitle,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.allowSkip || widget.changePlanMode)
                    IconButton(
                      tooltip: widget.changePlanMode
                          ? l10n.actionCancel
                          : l10n.subscriptionPaywallLater,
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
              SegmentedButton<SubscriptionBillingPeriod>(
                segments: [
                  ButtonSegment(
                    value: SubscriptionBillingPeriod.monthly,
                    label: Text(l10n.subscriptionBillingMonthly),
                  ),
                  ButtonSegment(
                    value: SubscriptionBillingPeriod.yearly,
                    label: Text(l10n.subscriptionBillingYearly),
                  ),
                ],
                selected: {_billingPeriod},
                onSelectionChanged: _busy
                    ? null
                    : (s) => setState(() => _billingPeriod = s.first),
              ),
              if (_billingPeriod == SubscriptionBillingPeriod.yearly) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.subscriptionAnnualSavings,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              if (_kind == SubscriptionOfferingKind.coach)
                ..._coachTierCards(context, offerings, state)
              else
                _playerCard(context, offerings, state),
              const SizedBox(height: 16),
              if (_service.hasActivePaidSubscription && !widget.changePlanMode)
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
              const SizedBox(height: 12),
              const LegalLinksFooter(),
              if (!_service.isPurchaseAvailable) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.subscriptionStoreUnavailable,
                  style: textTheme.bodySmall?.copyWith(color: colors.warning),
                  textAlign: TextAlign.center,
                ),
              ],
              if (widget.changePlanMode) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(l10n.actionBack),
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
    final l10n = l10nFor(context);
    final tiers = [
      (
        CoachTier.basic,
        l10n.subscriptionTierCoachBasic,
        l10n.subscriptionTierCoachBasicDesc,
        SubscriptionFallbackPrices.coachBasic,
        SubscriptionFallbackPrices.coachBasicYearly,
        SubscriptionProductIds.coachBasicMonthly,
        SubscriptionProductIds.coachBasicYearly,
      ),
      (
        CoachTier.elite,
        l10n.subscriptionTierCoachElite,
        l10n.subscriptionTierCoachEliteDesc,
        SubscriptionFallbackPrices.coachElite,
        SubscriptionFallbackPrices.coachEliteYearly,
        SubscriptionProductIds.coachEliteMonthly,
        SubscriptionProductIds.coachEliteYearly,
      ),
      (
        CoachTier.pro,
        l10n.subscriptionTierCoachPro,
        l10n.subscriptionTierCoachProDesc,
        SubscriptionFallbackPrices.coachPro,
        SubscriptionFallbackPrices.coachProYearly,
        SubscriptionProductIds.coachProMonthly,
        SubscriptionProductIds.coachProYearly,
      ),
    ];

    return tiers
        .map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TierCard(
              title: t.$2,
              description: t.$3,
              price: _priceForBillingPeriod(
                    offerings,
                    _billingPeriod,
                    t.$6,
                    t.$7,
                  ) ??
                  (_billingPeriod == SubscriptionBillingPeriod.monthly
                      ? t.$4
                      : t.$5),
              priceSuffix: _billingPeriod == SubscriptionBillingPeriod.monthly
                  ? l10n.subscriptionPerMonth
                  : l10n.subscriptionPerYear,
              showAnnualSavings:
                  _billingPeriod == SubscriptionBillingPeriod.yearly,
              annualSavingsLabel: l10n.subscriptionAnnualSavings,
              selected: _selectedCoachTier == t.$1,
              active: _isCurrentlyActivePlan(
                kind: SubscriptionOfferingKind.coach,
                coachTier: t.$1,
              ),
              busy: _busy,
              changePlanMode: widget.changePlanMode,
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
      price: _priceForBillingPeriod(
            offerings,
            _billingPeriod,
            SubscriptionProductIds.playerMonthly,
            SubscriptionProductIds.playerYearly,
          ) ??
          (_billingPeriod == SubscriptionBillingPeriod.monthly
              ? SubscriptionFallbackPrices.player
              : SubscriptionFallbackPrices.playerYearly),
      priceSuffix: _billingPeriod == SubscriptionBillingPeriod.monthly
          ? l10n.subscriptionPerMonth
          : l10n.subscriptionPerYear,
      showAnnualSavings: _billingPeriod == SubscriptionBillingPeriod.yearly,
      annualSavingsLabel: l10n.subscriptionAnnualSavings,
      selected: true,
      active: _isCurrentlyActivePlan(kind: SubscriptionOfferingKind.player),
      busy: _busy,
      changePlanMode: widget.changePlanMode,
      onSelect: () {},
      onPurchase: () => _purchasePlayer(offerings),
    );
  }

  String? _priceForBillingPeriod(
    Offerings? offerings,
    SubscriptionBillingPeriod period,
    String monthlyProductId,
    String yearlyProductId,
  ) {
    final productId = period == SubscriptionBillingPeriod.monthly
        ? monthlyProductId
        : yearlyProductId;
    return _service.priceStringForProduct(productId) ??
        _priceForProduct(offerings, productId);
  }

  String? _priceForProduct(Offerings? offerings, String productId) {
    return _service.priceStringForProduct(productId) ??
        _priceFromOfferings(offerings, productId);
  }

  String? _priceFromOfferings(Offerings? offerings, String productId) {
    final fromService = _service.packageForProduct(productId);
    if (fromService != null) {
      return fromService.storeProduct.priceString;
    }
    if (offerings == null) return null;
    for (final offering in offerings.all.values) {
      for (final package in offering.availablePackages) {
        if (SubscriptionProductLookup.identifiersMatch(
          productId,
          package.storeProduct.identifier,
        )) {
          return package.storeProduct.priceString;
        }
      }
    }
    return null;
  }

  Package? _packageForProduct(String productId) {
    return _service.packageForProduct(productId);
  }

  Future<void> _purchaseCoach(CoachTier tier, Offerings? offerings) async {
    final productId = switch (tier) {
      CoachTier.basic => _billingPeriod == SubscriptionBillingPeriod.monthly
          ? SubscriptionProductIds.coachBasicMonthly
          : SubscriptionProductIds.coachBasicYearly,
      CoachTier.elite => _billingPeriod == SubscriptionBillingPeriod.monthly
          ? SubscriptionProductIds.coachEliteMonthly
          : SubscriptionProductIds.coachEliteYearly,
      CoachTier.pro => _billingPeriod == SubscriptionBillingPeriod.monthly
          ? SubscriptionProductIds.coachProMonthly
          : SubscriptionProductIds.coachProYearly,
    };
    await _purchase(productId, offerings);
  }

  Future<void> _purchasePlayer(Offerings? offerings) async {
    final productId = _billingPeriod == SubscriptionBillingPeriod.monthly
        ? SubscriptionProductIds.playerMonthly
        : SubscriptionProductIds.playerYearly;
    await _purchase(productId, offerings);
  }

  Future<void> _purchase(String productId, Offerings? offerings) async {
    if (!_service.isPurchaseAvailable) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.subscriptionStoreUnavailable,
        preferDialog: true,
      );
      return;
    }

    var package = _packageForProduct(productId);
    if (package == null) {
      await _service.refreshOfferings();
      if (!mounted) return;
      package = _packageForProduct(productId);
    }

    if (package == null) {
      if (!mounted) return;
      _service.logPackageLookupFailure(productId);

      final message = !_service.hasLoadedOfferings || !_service.hasAnyPackages
          ? context.l10n.subscriptionOfferingsUnavailable
          : context.l10n.subscriptionProductNotFound;
      AppSnackbar.show(
        context,
        message,
        preferDialog: true,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final info = await _service.purchasePackage(package);
      if (!mounted) return;
      if (info != null) {
        await _service.refreshForActiveSession();
      }
      if (!mounted) return;
      if (info != null && _service.hasActivePaidSubscription) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.subscriptionPurchaseFailed,
        preferDialog: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await _service.restorePurchases();
      if (!mounted) return;
      if (_service.hasActivePaidSubscription) {
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
    required this.priceSuffix,
    required this.selected,
    required this.active,
    required this.busy,
    required this.onSelect,
    required this.onPurchase,
    this.showAnnualSavings = false,
    this.annualSavingsLabel,
    this.changePlanMode = false,
  });

  final String title;
  final String description;
  final String price;
  final String priceSuffix;
  final bool selected;
  final bool active;
  final bool busy;
  final VoidCallback onSelect;
  final VoidCallback onPurchase;
  final bool showAnnualSavings;
  final String? annualSavingsLabel;
  final bool changePlanMode;

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
                    '$price$priceSuffix',
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (showAnnualSavings && annualSavingsLabel != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      annualSavingsLabel!,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
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
                  changePlanMode
                      ? l10n.subscriptionCurrentPlan
                      : l10n.subscriptionTierActive,
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
                        : Text(
                            changePlanMode
                                ? l10n.subscriptionChangePlanConfirm
                                : l10n.subscriptionSubscribe,
                          ),
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
