import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

final RouteObserver<PageRoute<dynamic>> appRouteObserver =
RouteObserver<PageRoute<dynamic>>();

mixin AnalyticsRouteAware<T extends StatefulWidget> on State<T>, RouteAware {
  String get screenName;

  AnalyticsService get analytics => AnalyticsService.instance;

  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route && route is PageRoute) {
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    analytics.logScreen(
      screenName: screenName,
      screenClass: widget.runtimeType.toString(),
    );
  }

  @override
  void didPopNext() {
    analytics.logScreen(
      screenName: screenName,
      screenClass: widget.runtimeType.toString(),
    );
  }
}