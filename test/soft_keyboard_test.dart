import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/soft_keyboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isSoftKeyboardOpen', () {
    testWidgets('is false without view insets', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = FakeViewPadding.zero;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: _KeyboardProbe())),
      );

      expect(find.text('closed'), findsOneWidget);
    });

    testWidgets('is true when the platform keyboard inset is large',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: _KeyboardProbe())),
      );

      expect(find.text('open'), findsOneWidget);
    });
  });

  testWidgets(
    'name filter stays on screen and focused when the keyboard opens',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = FakeViewPadding.zero;
      addTearDown(tester.view.reset);

      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _KeyboardAwareMatchChrome(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(find.text('HEADER'), findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('HEADER'), findsNothing);

      final Rect field = tester.getRect(find.byType(TextField));
      expect(field.top, greaterThanOrEqualTo(0));
      expect(field.bottom, lessThan(844 - 320 + 8));
    },
  );
}

class _KeyboardProbe extends StatelessWidget {
  const _KeyboardProbe();

  @override
  Widget build(BuildContext context) {
    return Text(isSoftKeyboardOpen(context) ? 'open' : 'closed');
  }
}

/// Mirrors match-detail chrome: huge header above the filter, collapsed
/// when the software keyboard is open so the field stays visible.
class _KeyboardAwareMatchChrome extends StatefulWidget {
  const _KeyboardAwareMatchChrome({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<_KeyboardAwareMatchChrome> createState() =>
      _KeyboardAwareMatchChromeState();
}

class _KeyboardAwareMatchChromeState extends State<_KeyboardAwareMatchChrome>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = isSoftKeyboardOpen(context);
    return Column(
      children: [
        if (!compact)
          const SizedBox(
            height: 320,
            child: Center(child: Text('HEADER')),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            key: const ValueKey('match-convocations-name-filter'),
            controller: widget.controller,
            focusNode: widget.focusNode,
            decoration: const InputDecoration(hintText: 'Filtrer par nom'),
          ),
        ),
        const Expanded(child: SizedBox.expand()),
      ],
    );
  }
}
