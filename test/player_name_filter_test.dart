import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/util/playerDisplayName.dart';

void main() {
  group('playerMatchesNameQuery', () {
    Player player({
      String? first,
      String? last,
    }) {
      return Player(firstName: first, lastName: last);
    }

    test('matches first name, last name and reversed order', () {
      final hugo = player(first: 'Hugo', last: 'Danguel');

      expect(playerMatchesNameQuery(hugo, 'hug'), isTrue);
      expect(playerMatchesNameQuery(hugo, 'DAN'), isTrue);
      expect(playerMatchesNameQuery(hugo, 'danguel hugo'), isTrue);
      expect(playerMatchesNameQuery(hugo, 'xyz'), isFalse);
    });

    test('is accent-insensitive for mobile keyboards', () {
      final erwan = player(first: 'Erwan', last: 'Baruthio');
      expect(playerMatchesNameQuery(erwan, 'baruthio'), isTrue);

      final stephane = player(first: 'Stéphane', last: 'Müller');
      expect(playerMatchesNameQuery(stephane, 'stephane'), isTrue);
      expect(playerMatchesNameQuery(stephane, 'muller'), isTrue);
      expect(playerMatchesNameQuery(stephane, 'STÉPH'), isTrue);
    });

    test('empty query matches everyone', () {
      expect(
        playerMatchesNameQuery(player(first: 'Lucas', last: 'Burg'), '  '),
        isTrue,
      );
    });
  });

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
