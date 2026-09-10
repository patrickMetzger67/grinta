import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/screen/admin/admin_players_screen.dart';
import 'package:grinta/util/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<List<Player>> members;

  setUp(() {
    members = StreamController<List<Player>>.broadcast();
  });

  tearDown(() async {
    await members.close();
  });

  Future<AppLocalizations> pumpScreen(WidgetTester tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminPlayersScreen(membersStream: members.stream),
      ),
    );
    await tester.pump();
    return l10n;
  }

  testWidgets('has a single typeable search field without a floating label',
      (tester) async {
    final l10n = await pumpScreen(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(AdminPlayersScreen.searchFieldKey), findsOneWidget);

    final field = tester.widget<TextField>(
      find.byKey(AdminPlayersScreen.searchFieldKey),
    );
    expect(field.enabled, isTrue);
    expect(field.readOnly, isFalse);
    expect(field.decoration?.labelText, isNull);
    expect(field.decoration?.hintText, l10n.adminPlayersSearchHint);
    expect(find.text(l10n.adminPlayersSearchHint), findsOneWidget);

    await tester.tap(find.byKey(AdminPlayersScreen.searchFieldKey));
    await tester.pump();
    await tester.enterText(
      find.byKey(AdminPlayersScreen.searchFieldKey),
      'Aaron',
    );
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Aaron'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(AdminPlayersScreen.searchFieldKey))
          .controller
          ?.text,
      'Aaron',
    );
  });

  testWidgets('filters the player list as the user types', (tester) async {
    final l10n = await pumpScreen(tester);

    await tester.enterText(
      find.byKey(AdminPlayersScreen.searchFieldKey),
      'zzz-no-match',
    );
    await tester.pump(const Duration(milliseconds: 300));

    members.add([
      Player(
        firstName: 'Aaron',
        lastName: 'ANTHONY',
        email: 'aaron@example.com',
        keyMember: 'p1',
      ),
      Player(
        firstName: 'Hugo',
        lastName: 'Danguel',
        email: 'hugo@example.com',
        keyMember: 'p2',
      ),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(l10n.adminPlayersSearchEmpty), findsOneWidget);
    expect(find.text('Aaron ANTHONY'), findsNothing);
    expect(find.text('Hugo Danguel'), findsNothing);
  });

  testWidgets('keeps typed search text when the member stream rebuilds',
      (tester) async {
    await pumpScreen(tester);
    members.add(<Player>[]);
    await tester.pump();

    await tester.enterText(
      find.byKey(AdminPlayersScreen.searchFieldKey),
      'Aaron',
    );
    await tester.pump();

    members.add(<Player>[]);
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(AdminPlayersScreen.searchFieldKey))
          .controller
          ?.text,
      'Aaron',
    );
    expect(find.text('Aaron'), findsOneWidget);
  });
}
