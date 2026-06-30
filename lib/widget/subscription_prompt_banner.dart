import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/subscription_prompt_service.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/subscription_paywall.dart';

/// Home-page banner prompting non-subscribers to open the paywall.
/// Dismissible; state persisted via [SubscriptionPromptService].
class SubscriptionPromptBanner extends StatefulWidget {
  const SubscriptionPromptBanner({super.key});

  @override
  State<SubscriptionPromptBanner> createState() =>
      _SubscriptionPromptBannerState();
}

class _SubscriptionPromptBannerState extends State<SubscriptionPromptBanner> {
  bool _loading = true;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _evaluateVisibility();
    SubscriptionService.instance.addListener(_onSubscriptionChanged);
  }

  @override
  void dispose() {
    SubscriptionService.instance.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_evaluateVisibility());
    });
  }

  Future<void> _evaluateVisibility() async {
    final service = SubscriptionService.instance;
    await SubscriptionPromptService.instance.ensureInitialized();

    final show = SubscriptionPromptService.instance.shouldShowPrompt(
      isSubscribed: service.hasActivePaidSubscription,
    );

    if (!mounted) return;
    setState(() {
      _visible = show;
      _loading = false;
    });
  }

  Future<void> _dismiss() async {
    await SubscriptionPromptService.instance.dismiss();
    if (!mounted) return;
    setState(() => _visible = false);
  }

  Future<void> _openPaywall() async {
    await SubscriptionService.instance.refreshForActiveSession();
    if (!mounted) return;

    await SubscriptionPaywall.show(
      context,
      allowSkip: true,
    );

    if (!mounted) return;
    await _evaluateVisibility();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_visible) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: colors.primary,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.subscriptionPromptTitle,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.subscriptionPromptMessage,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _openPaywall,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(context.l10n.subscriptionPromptAction),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.featureDiscoveryDismiss,
                onPressed: _dismiss,
                icon: Icon(
                  Icons.close_rounded,
                  color: colors.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
