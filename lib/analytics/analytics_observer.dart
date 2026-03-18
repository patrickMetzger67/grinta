import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AppAnalyticsObserver extends NavigatorObserver {
  final AnalyticsService analytics;

  AppAnalyticsObserver({required this.analytics});

  void _sendScreenView(Route<dynamic>? route) {
    if (route == null) return;

    final settings = route.settings;
    final routeName = settings.name;

    String? screenName;

    if (routeName != null && routeName.isNotEmpty) {
      screenName = routeName;
    } else {
      screenName = route.runtimeType.toString();
    }

    analytics.logScreen(
      screenName: screenName,
      screenClass: route.runtimeType.toString(),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _sendScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _sendScreenView(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _sendScreenView(previousRoute);
  }
}