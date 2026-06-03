import 'package:flutter/widgets.dart';

/// Lets feature-discovery UI switch match-detail tabs from a descendant.
class MatchDetailTabNavigationScope extends InheritedWidget {
  const MatchDetailTabNavigationScope({
    super.key,
    required this.featureIdsByTabIndex,
    required this.onNavigateToTabIndex,
    required super.child,
  });

  final List<String> featureIdsByTabIndex;
  final void Function(int tabIndex) onNavigateToTabIndex;

  static MatchDetailTabNavigationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MatchDetailTabNavigationScope>();
  }

  static bool tryNavigateToFeature(
    BuildContext context,
    String featureId,
  ) {
    final scope = maybeOf(context);
    if (scope == null) return false;

    final int index = scope.featureIdsByTabIndex.indexOf(featureId);
    if (index < 0) return false;

    scope.onNavigateToTabIndex(index);
    return true;
  }

  @override
  bool updateShouldNotify(MatchDetailTabNavigationScope oldWidget) {
    return oldWidget.featureIdsByTabIndex != featureIdsByTabIndex ||
        oldWidget.onNavigateToTabIndex != onNavigateToTabIndex;
  }
}
