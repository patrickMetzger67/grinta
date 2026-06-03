import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/feature_discovery_service.dart';
import 'package:grinta/util/app_theme.dart';

/// In-app hint for feature discovery or re-engagement.
///
/// When [inactiveFor] is null, uses [FeatureDiscoveryService.shouldShowPrompt]
/// (first visit / onboarding). When set, uses
/// [FeatureDiscoveryService.shouldShowReengagementPrompt] (inactive for X).
/// Dismissal records a separate "prompt dismissed" flag (not a visit).
class FeatureDiscoveryBanner extends StatefulWidget {
  const FeatureDiscoveryBanner({
    super.key,
    required this.featureId,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.leadingIcon = Icons.lightbulb_outline_rounded,
    this.inactiveFor,
  });

  final String featureId;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData leadingIcon;

  /// When set, show the banner if the user has not visited this feature within
  /// this duration (re-engagement). When null, show only on first visit.
  final Duration? inactiveFor;

  @override
  State<FeatureDiscoveryBanner> createState() => _FeatureDiscoveryBannerState();
}

class _FeatureDiscoveryBannerState extends State<FeatureDiscoveryBanner> {
  bool _visible = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _evaluateVisibility();
  }

  Future<void> _evaluateVisibility() async {
    final service = FeatureDiscoveryService.instance;
    await service.ensureInitialized();

    if (!mounted) return;

    final Duration? inactiveFor = widget.inactiveFor;
    final bool show = inactiveFor == null
        ? service.shouldShowPrompt(widget.featureId)
        : service.shouldShowReengagementPrompt(
            widget.featureId,
            inactiveFor: inactiveFor,
          );
    if (show) {
      await service.logPromptShown(widget.featureId);
    }

    if (!mounted) return;

    setState(() {
      _visible = show;
      _loading = false;
    });
  }

  Future<void> _hide() async {
    await FeatureDiscoveryService.instance.dismissPrompt(widget.featureId);
    if (!mounted) return;
    setState(() => _visible = false);
  }

  Future<void> _dismiss() async {
    AnalyticsInteractions.logFeature(
      AnalyticsFeatures.featureDiscoveryDismiss,
      parameters: <String, Object>{'feature_id': widget.featureId},
    );
    await _hide();
  }

  void _onActionTap() {
    AnalyticsInteractions.logFeature(
      AnalyticsFeatures.featureDiscoveryAction,
      parameters: <String, Object>{'feature_id': widget.featureId},
    );
    widget.onAction?.call();
    _hide();
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
              Icon(widget.leadingIcon, color: colors.primary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    if (widget.actionLabel != null &&
                        widget.onAction != null) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _onActionTap,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(widget.actionLabel!),
                      ),
                    ],
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
