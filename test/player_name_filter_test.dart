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

    test('matches email and searchOptions prefixes', () {
      final raed = Player.fromMap(<String, dynamic>{
        'firstName': 'Raed',
        'lastName': 'Jerou',
        'email': 'jerou10@yahoo.com',
        'keyMember': 'XFh395VVAwRRvnAX6m9s',
        'phoneE164': '+330641265756',
        'statut': 1,
        'searchOptions': <String>[
          'r',
          'ra',
          'rae',
          'raed',
          'j',
          'je',
          'jer',
          'jero',
          'jerou',
          'jerou1',
          'jerou10',
          'jerou10@',
          'jerou10@yahoo.com',
        ],
      });

      expect(playerMatchesMemberSearchQuery(raed, 'Raed'), isTrue);
      expect(playerMatchesMemberSearchQuery(raed, 'Raëd'), isTrue);
      expect(playerMatchesMemberSearchQuery(raed, 'Jérou'), isTrue);
      expect(playerMatchesMemberSearchQuery(raed, 'Raed Jerou'), isTrue);
      expect(playerMatchesMemberSearchQuery(raed, 'jerou10'), isTrue);
      expect(playerMatchesMemberSearchQuery(raed, 'jerou10@yahoo.com'), isTrue);
      expect(playerMatchesMemberSearchQuery(raed, '0641265756'), isTrue);
      expect(playerMatchesMemberSearchQuery(raed, 'xyz'), isFalse);
    });
  });

  group('playerLabelMatchesNameQuery', () {
    test('matches first name, last name and reversed tokens', () {
      const label = 'Achille SCHMITT';

      expect(playerLabelMatchesNameQuery(label, ''), isTrue);
      expect(playerLabelMatchesNameQuery(label, '  '), isTrue);
      expect(playerLabelMatchesNameQuery(label, 'ach'), isTrue);
      expect(playerLabelMatchesNameQuery(label, 'SCHMITT'), isTrue);
      expect(playerLabelMatchesNameQuery(label, 'schmitt achille'), isTrue);
      expect(playerLabelMatchesNameQuery(label, 'xyz'), isFalse);
    });

    test('is accent-insensitive', () {
      expect(
        playerLabelMatchesNameQuery('Stéphane Müller', 'stephane muller'),
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
