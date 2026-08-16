import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/app_shell_layout.dart';

void main() {
  group('useSidebarNavigationShell', () {
    test('web always uses the sidebar shell', () {
      expect(
        useSidebarNavigationShell(
          isWeb: true,
          isMobileNative: false,
          shortestSide: 390,
        ),
        isTrue,
      );
    });

    test('phone native uses the mobile bottom-tab shell', () {
      expect(
        useSidebarNavigationShell(
          isWeb: false,
          isMobileNative: true,
          shortestSide: 390,
        ),
        isFalse,
      );
    });

    test('tablet native uses the same sidebar shell as web', () {
      expect(
        useSidebarNavigationShell(
          isWeb: false,
          isMobileNative: true,
          shortestSide: 768,
        ),
        isTrue,
      );
    });

    test('breakpoint is inclusive at 600', () {
      expect(
        useSidebarNavigationShell(
          isWeb: false,
          isMobileNative: true,
          shortestSide: 600,
        ),
        isTrue,
      );
      expect(
        useSidebarNavigationShell(
          isWeb: false,
          isMobileNative: true,
          shortestSide: 599,
        ),
        isFalse,
      );
    });
  });
}
