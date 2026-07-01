import 'package:flutter/widgets.dart';

typedef ShellTabNavigator = bool Function(String featureId);

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

  static ShellTabNavigator? _globalNavigateToTab;

  /// Registers shell tab navigation for contexts above [ShellNavigationScope]
  /// (e.g. root navigator when handling cold-start deep links).
  static void registerGlobalNavigator(ShellTabNavigator? navigator) {
    _globalNavigateToTab = navigator;
  }

  static ShellNavigationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ShellNavigationScope>();
  }

  static bool tryNavigateToTab(BuildContext context, String featureId) {
    final scope = maybeOf(context);
    if (scope != null &&
        scope.availableTabFeatureIds.contains(featureId) &&
        scope.onNavigateToTab(featureId)) {
      return true;
    }
    return _globalNavigateToTab?.call(featureId) ?? false;
  }

  @override
  bool updateShouldNotify(ShellNavigationScope oldWidget) {
    return oldWidget.availableTabFeatureIds != availableTabFeatureIds ||
        oldWidget.currentTabFeatureId != currentTabFeatureId ||
        oldWidget.onNavigateToTab != onNavigateToTab;
  }
}
