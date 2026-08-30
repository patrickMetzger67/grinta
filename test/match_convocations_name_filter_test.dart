import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduces the convocations name-filter focus contract:
/// the TextField must stay mounted/focused across keystrokes even when the
/// clear suffix visibility changes (the prior regression rebuilt the field
/// inside a ValueListenableBuilder and dropped mobile focus).
void main() {
  testWidgets(
    'name filter keeps focus when the clear suffix becomes visible',
    (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const ValueKey('match-convocations-name-filter'),
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Filtrer par nom',
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final bool hasQuery = value.text.trim().isNotEmpty;
                      return IconButton(
                        onPressed: hasQuery ? controller.clear : null,
                        icon: Icon(
                          Icons.clear_rounded,
                          color: hasQuery ? Colors.black54 : Colors.transparent,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final field = find.byKey(
        const ValueKey('match-convocations-name-filter'),
      );
      await tester.tap(field);
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.enterText(field, 'Du');
      await tester.pump();

      expect(controller.text, 'Du');
      expect(focusNode.hasFocus, isTrue);

      await tester.enterText(field, 'Dupont');
      await tester.pump();

      expect(controller.text, 'Dupont');
      expect(focusNode.hasFocus, isTrue);
    },
  );
}
