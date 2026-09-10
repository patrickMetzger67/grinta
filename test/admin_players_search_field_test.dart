import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/screen/admin/admin_players_screen.dart';
import 'package:grinta/services/admin_player_sensor_service.dart';
import 'package:grinta/util/app_theme.dart';

class _CountingHangingSensorService extends AdminPlayerSensorService {
  int calls = 0;

  @override
  Future<AdminPlayerSensorFlags> loadFlags(Player player) {
    calls++;
    return Completer<AdminPlayerSensorFlags>().future;
  }
}

Widget _placeholderPhoto(Player player, double radius) {
  return SizedBox(
    width: radius * 2,
    height: radius * 2,
    child: const ColoredBox(color: Colors.grey),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<List<Player>> members;

  setUp(() {
    members = StreamController<List<Player>>.broadcast();
  });

  tearDown(() async {
    await members.close();
  });

  Future<AppLocalizations> pumpScreen(
    WidgetTester tester, {
    AdminPlayerSensorService? sensorService,
  }) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminPlayersScreen(
          membersStream: members.stream,
          sensorService: sensorService,
          playerPhotoBuilder: _placeholderPhoto,
        ),
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

  testWidgets('search abdess / Mohamed finds the named player without flags',
      (tester) async {
    final sensor = _CountingHangingSensorService();
    final l10n = await pumpScreen(tester, sensorService: sensor);

    members.add([
      Player(
        firstName: 'Mohamed-Amine',
        lastName: 'ABDESSAMAD',
        email: 'mohamed@example.com',
        keyMember: 'mohamed-player',
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

    expect(find.text('Mohamed-Amine ABDESSAMAD'), findsOneWidget);
    expect(sensor.calls, 0);

    await tester.enterText(
      find.byKey(AdminPlayersScreen.searchFieldKey),
      'abdess',
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mohamed-Amine ABDESSAMAD'), findsOneWidget);
    expect(find.text('Hugo Danguel'), findsNothing);
    expect(find.text(l10n.adminPlayersSearchEmpty), findsNothing);
    expect(sensor.calls, 0);

    await tester.enterText(
      find.byKey(AdminPlayersScreen.searchFieldKey),
      'Mohamed',
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mohamed-Amine ABDESSAMAD'), findsOneWidget);
    expect(find.text('Hugo Danguel'), findsNothing);
    expect(sensor.calls, 0);
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
