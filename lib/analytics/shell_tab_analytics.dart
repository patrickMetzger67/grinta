import '../services/analytics_service.dart';

/// Tracks shell tab screen views and time-on-tab without duplicate rebuild logs.
class ShellTabAnalytics {
  String? _currentScreen;
  DateTime? _enteredAt;

  void onTabSelected(String screenName) {
    if (_currentScreen == screenName) return;
    _leaveCurrentTab();
    _currentScreen = screenName;
    _enteredAt = DateTime.now();
    AnalyticsService.instance.logScreenView(screenName: screenName);
  }

  void dispose() => _leaveCurrentTab();

  void _leaveCurrentTab() {
    final screen = _currentScreen;
    final enteredAt = _enteredAt;
    if (screen == null || enteredAt == null) return;

    final seconds = DateTime.now().difference(enteredAt).inSeconds;
    if (seconds > 0) {
      AnalyticsService.instance.logFeatureDuration(
        feature: screen,
        seconds: seconds,
      );
    }
    _currentScreen = null;
    _enteredAt = null;
  }
}
