import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

final RouteObserver<PageRoute<dynamic>> appRouteObserver =
RouteObserver<PageRoute<dynamic>>();

mixin AnalyticsRouteAware<T extends StatefulWidget> on State<T>, RouteAware {
  String get screenName;

  AnalyticsService get analytics => AnalyticsService.instance;

  ModalRoute<dynamic>? _route;
  DateTime? _enteredAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route && route is PageRoute) {
      if (_route != null) {
        appRouteObserver.unsubscribe(this);
      }
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _logDurationOnLeave();
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  void _recordEnter() {
    _enteredAt = DateTime.now();
    analytics.logScreenView(
      screenName: screenName,
      screenClass: widget.runtimeType.toString(),
    );
  }

  void _logDurationOnLeave() {
    final enteredAt = _enteredAt;
    if (enteredAt == null) return;
    final seconds = DateTime.now().difference(enteredAt).inSeconds;
    _enteredAt = null;
    if (seconds > 0) {
      analytics.logFeatureDuration(feature: screenName, seconds: seconds);
    }
  }

  @override
  void didPush() => _recordEnter();

  @override
  void didPopNext() => _recordEnter();

  @override
  void didPop() => _logDurationOnLeave();

  @override
  void didPushNext() => _logDurationOnLeave();
}