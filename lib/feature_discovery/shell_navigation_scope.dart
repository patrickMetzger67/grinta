import 'package:flutter/widgets.dart';

/// Exposes shell tab switching for feature-discovery navigation.
class ShellNavigationScope extends InheritedWidget {
  const ShellNavigationScope({
    super.key,
    required this.availableTabFeatureIds,
    required this.currentTabFeatureId,
    required this.onNavigateToTab,
    required super.child,
  });

  final Set<String> availableTabFeatureIds;
  final String? currentTabFeatureId;
  final bool Function(String featureId) onNavigateToTab;

  static ShellNavigationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ShellNavigationScope>();
  }

  static bool tryNavigateToTab(BuildContext context, String featureId) {
    final scope = maybeOf(context);
    if (scope == null) return false;
    if (!scope.availableTabFeatureIds.contains(featureId)) return false;
    return scope.onNavigateToTab(featureId);
  }

  @override
  bool updateShouldNotify(ShellNavigationScope oldWidget) {
    return oldWidget.availableTabFeatureIds != availableTabFeatureIds ||
        oldWidget.currentTabFeatureId != currentTabFeatureId ||
        oldWidget.onNavigateToTab != onNavigateToTab;
  }
}
