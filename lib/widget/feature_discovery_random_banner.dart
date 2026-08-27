import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/feature_discovery/feature_discovery_catalog.dart';
import 'package:grinta/feature_discovery/feature_discovery_navigator.dart';
import 'package:grinta/feature_discovery/shell_navigation_scope.dart';
import 'package:grinta/model/feature_discovery_ids.dart';
import 'package:grinta/services/feature_discovery_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:provider/provider.dart';

import '../provider/appSession.dart';

/// Picks a random eligible discovery target and offers [Découvrir] navigation.
class FeatureDiscoveryRandomBanner extends StatefulWidget {
  const FeatureDiscoveryRandomBanner({
    super.key,
    required this.parentScreenId,
    this.includeBaseScreens = true,
    this.includeRelated = true,
    this.excludeCurrentBaseScreen = false,
    this.matchHasTracker = false,
    this.inactiveFor = const Duration(days: 7),
    this.random = Random.new,
  });

  final String parentScreenId;
  final bool includeBaseScreens;
  final bool includeRelated;
  final bool excludeCurrentBaseScreen;
  final bool matchHasTracker;
  final Duration inactiveFor;

  /// Injectable for tests; defaults to [Random].
  final Random Function() random;

  @override
  State<FeatureDiscoveryRandomBanner> createState() =>
      _FeatureDiscoveryRandomBannerState();
}

class _FeatureDiscoveryRandomBannerState
    extends State<FeatureDiscoveryRandomBanner> {
  FeatureDiscoveryEntry? _entry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pickEntry();
  }

  Future<void> _pickEntry() async {
    final service = FeatureDiscoveryService.instance;
    await service.ensureInitialized();
    if (!mounted) return;

    final shell = ShellNavigationScope.maybeOf(context);
    final appSession = context.read<AppSession>();
    final bool isManager =
        appSession.managedTeamsIdsForSelectedSeason.isNotEmpty;

    final catalogContext = FeatureDiscoveryCatalogContext(
      isWeb: kIsWeb,
      isManager: isManager,
      availableShellTabIds: shell?.availableTabFeatureIds ??
          const <String>{
            FeatureDiscoveryIds.tabAgenda,
            FeatureDiscoveryIds.tabDashboard,
            FeatureDiscoveryIds.tabTeams,
            FeatureDiscoveryIds.tabChat,
          },
      currentParentScreenId: widget.parentScreenId,
      excludeCurrentBaseScreen: widget.excludeCurrentBaseScreen,
      matchHasTracker: widget.matchHasTracker,
    );

    final candidates = FeatureDiscoveryCatalog.combinedCandidatesFor(
      context: catalogContext,
      includeBaseScreens: widget.includeBaseScreens,
      includeRelated: widget.includeRelated,
    );

    final eligible = <FeatureDiscoveryEntry>[];
    for (final entry in candidates) {
      final bool show = service.shouldShowPrompt(entry.id) ||
          service.shouldShowReengagementPrompt(
            entry.id,
            inactiveFor: widget.inactiveFor,
          );
      if (show) eligible.add(entry);
    }

    FeatureDiscoveryEntry? picked;
    if (eligible.isNotEmpty) {
      picked = eligible[widget.random().nextInt(eligible.length)];
      await service.logPromptShown(picked.id);
    }

    if (!mounted) return;
    setState(() {
      _entry = picked;
      _loading = false;
    });
  }

  Future<void> _hide() async {
    final id = _entry?.id;
    if (id == null) return;
    await FeatureDiscoveryService.instance.dismissPrompt(id);
    if (!mounted) return;
    setState(() => _entry = null);
  }

  Future<void> _dismiss() async {
    final id = _entry?.id;
    if (id == null) return;
    AnalyticsInteractions.logFeature(
      AnalyticsFeatures.featureDiscoveryDismiss,
      parameters: <String, Object>{'feature_id': id},
    );
    await _hide();
  }

  Future<void> _onDiscover() async {
    final entry = _entry;
    if (entry == null) return;

    navigateToDiscoveredFeature(context, entry.id);
    await _hide();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _entry == null) {
      return const SizedBox.shrink();
    }

    final copy = _entry!.copyBuilder(context.l10n);
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
                Icons.lightbulb_outline_rounded,
                color: colors.primary,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.title,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      copy.message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _onDiscover,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(context.l10n.featureDiscoveryDiscover),
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
