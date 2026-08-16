/// Layout helpers for choosing the app navigation shell.
///
/// Web always uses the persistent lateral sidebar. On iOS/Android, tablets
/// ([shortestSide] >= [tabletBreakpoint], default 600) use the same sidebar
/// shell; phones keep the bottom-tab mobile shell.
bool useSidebarNavigationShell({
  required bool isWeb,
  required bool isMobileNative,
  required double shortestSide,
  double tabletBreakpoint = 600,
}) {
  if (isWeb) return true;
  return isMobileNative && shortestSide >= tabletBreakpoint;
}
