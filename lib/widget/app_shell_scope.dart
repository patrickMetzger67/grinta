import 'package:flutter/widgets.dart';

/// Indique que l'écran est affiché dans le shell mobile (barre haute + navigation basse).
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.isMobileShell,
    required super.child,
  });

  final bool isMobileShell;

  static AppShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>();
  }

  static bool hidesChildAppBar(BuildContext context) {
    return maybeOf(context)?.isMobileShell ?? false;
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) {
    return oldWidget.isMobileShell != isMobileShell;
  }
}
