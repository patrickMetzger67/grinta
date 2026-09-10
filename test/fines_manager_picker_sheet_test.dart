import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/fines_manager_picker_sheet.dart';

void main() {
  Player player({
    required String id,
    required String first,
    required String last,
  }) {
    return Player(keyMember: id, firstName: first, lastName: last);
  }

  Future<AppLocalizations> loadFr() {
    return AppLocalizations.delegate.load(const Locale('fr'));
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        extensions: const <ThemeExtension<dynamic>>[AppColors.light],
      ),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('lists Non désigné then all players with a search field',
      (tester) async {
    final l10n = await loadFr();
    const Size phone = Size(390, 844);

    await tester.binding.setSurfaceSize(phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        MediaQuery(
          data: const MediaQueryData(size: phone),
          child: FinesManagerPickerSheet(
            players: [
              player(id: 'p-matheo', first: 'Matheo', last: 'Zuber Munch'),
              player(id: 'p-hugo', first: 'Hugo', last: 'Danguel'),
              player(id: 'p-lucas', first: 'Lucas', last: 'Ibanez'),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(FinesManagerPickerSheet.sheetKey), findsOneWidget);
    expect(find.text(l10n.teamFinesManagerTitle), findsOneWidget);
    expect(find.text(l10n.teamDetailFilterPlayerHint), findsOneWidget);
    expect(find.byKey(const ValueKey('player-name-filter-field')), findsOneWidget);
    expect(find.byKey(FinesManagerPickerSheet.noneKey), findsOneWidget);
    expect(find.text(l10n.teamFinesManagerNone), findsOneWidget);
    expect(find.text('Matheo Zuber Munch'), findsOneWidget);
    expect(find.text('Hugo Danguel'), findsOneWidget);
    expect(find.text('Lucas Ibanez'), findsOneWidget);
  });

  testWidgets('filters by first and last name in memory', (tester) async {
    final l10n = await loadFr();
    const Size phone = Size(390, 844);

    await tester.binding.setSurfaceSize(phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        MediaQuery(
          data: const MediaQueryData(size: phone),
          child: FinesManagerPickerSheet(
            players: [
              player(id: 'p-matheo', first: 'Matheo', last: 'Zuber Munch'),
              player(id: 'p-hugo', first: 'Hugo', last: 'Danguel'),
              player(id: 'p-lucas', first: 'Lucas', last: 'Ibanez'),
            ],
          ),
        ),
      ),
    );

    final Finder field = find.byKey(const ValueKey('player-name-filter-field'));
    await tester.enterText(field, 'hugo');
    await tester.pump();

    expect(find.text('Hugo Danguel'), findsOneWidget);
    expect(find.text('Matheo Zuber Munch'), findsNothing);
    expect(find.text('Lucas Ibanez'), findsNothing);
    expect(find.text(l10n.teamFinesManagerNone), findsOneWidget);

    await tester.enterText(field, 'ibanez');
    await tester.pump();

    expect(find.text('Lucas Ibanez'), findsOneWidget);
    expect(find.text('Hugo Danguel'), findsNothing);
  });

  testWidgets('keeps Non désigné while the roster is filtered',
      (tester) async {
    final l10n = await loadFr();
    const Size phone = Size(390, 844);

    await tester.binding.setSurfaceSize(phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        MediaQuery(
          data: const MediaQueryData(size: phone),
          child: FinesManagerPickerSheet(
            players: [
              player(id: 'p-hugo', first: 'Hugo', last: 'Danguel'),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(FinesManagerPickerSheet.noneKey), findsOneWidget);
    expect(find.text(l10n.teamFinesManagerNone), findsOneWidget);

    final Finder field = find.byKey(const ValueKey('player-name-filter-field'));
    await tester.enterText(field, 'hugo');
    await tester.pump();

    expect(find.byKey(FinesManagerPickerSheet.noneKey), findsOneWidget);
    expect(find.text(l10n.teamFinesManagerNone), findsOneWidget);
    expect(find.text('Hugo Danguel'), findsOneWidget);

    await tester.enterText(field, 'xyz');
    await tester.pump();
    expect(find.byKey(FinesManagerPickerSheet.noneKey), findsOneWidget);
    expect(find.text('Hugo Danguel'), findsNothing);

    await tester.enterText(field, '');
    await tester.pump();
    expect(find.byKey(FinesManagerPickerSheet.noneKey), findsOneWidget);
    expect(find.text('Hugo Danguel'), findsOneWidget);
  });

  testWidgets('keeps the search field mounted and focused while typing',
      (tester) async {
    const Size phone = Size(390, 844);

    await tester.binding.setSurfaceSize(phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        MediaQuery(
          data: const MediaQueryData(size: phone),
          child: FinesManagerPickerSheet(
            players: [
              player(id: 'p-matheo', first: 'Matheo', last: 'Zuber Munch'),
              player(id: 'p-hugo', first: 'Hugo', last: 'Danguel'),
            ],
          ),
        ),
      ),
    );

    final Finder field = find.byKey(const ValueKey('player-name-filter-field'));
    await tester.tap(field);
    await tester.pump();

    final TextField textField = tester.widget<TextField>(field);
    expect(textField.focusNode?.hasFocus, isTrue);

    await tester.enterText(field, 'Ma');
    await tester.pump();
    expect(find.byKey(const ValueKey('player-name-filter-field')), findsOneWidget);
    expect(tester.widget<TextField>(field).focusNode?.hasFocus, isTrue);
    expect(find.text('Matheo Zuber Munch'), findsOneWidget);
    expect(find.text('Hugo Danguel'), findsNothing);

    await tester.enterText(field, 'Matheo');
    await tester.pump();
    expect(find.byKey(const ValueKey('player-name-filter-field')), findsOneWidget);
    expect(tester.widget<TextField>(field).focusNode?.hasFocus, isTrue);
    expect(find.text('Matheo Zuber Munch'), findsOneWidget);
  });

  testWidgets('pops empty string when Non désigné is tapped', (tester) async {
    const Size phone = Size(390, 844);
    String? selected = 'pending';

    await tester.binding.setSurfaceSize(phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          extensions: const <ThemeExtension<dynamic>>[AppColors.light],
        ),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  selected = await showFinesManagerPickerSheet(
                    context,
                    players: [
                      player(id: 'p-hugo', first: 'Hugo', last: 'Danguel'),
                    ],
                    currentId: 'p-hugo',
                  );
                },
                child: const Text('open-picker'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-picker'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(FinesManagerPickerSheet.noneKey));
    await tester.pumpAndSettle();

    expect(selected, '');
  });
}
