import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/screen/admin/admin_player_hub_screen.dart';
import 'package:grinta/screen/admin/admin_players_screen.dart';
import 'package:grinta/services/admin_player_sensor_service.dart';
import 'package:grinta/util/app_theme.dart';

class _HangingSensorService extends AdminPlayerSensorService {
  @override
  Future<AdminPlayerSensorFlags> loadFlags(Player player) {
    return Completer<AdminPlayerSensorFlags>().future;
  }
}

class _ImmediateFlagsService extends AdminPlayerSensorService {
  _ImmediateFlagsService(this.flags);

  final AdminPlayerSensorFlags flags;

  @override
  Future<AdminPlayerSensorFlags> loadFlags(Player player) async => flags;
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

  Future<AppLocalizations> pumpPlayers(
    WidgetTester tester, {
    required AdminPlayerSensorService sensorService,
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

  testWidgets(
    'tapping a player opens the hub even when sensor flags never load',
    (tester) async {
      final l10n = await pumpPlayers(
        tester,
        sensorService: _HangingSensorService(),
      );

      members.add([
        Player(
          firstName: 'Aaron',
          lastName: 'ANTHONY',
          email: 'aaron@example.com',
          keyMember: 'p1',
        ),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Aaron ANTHONY'), findsOneWidget);
      expect(find.byType(AdminPlayerHubScreen), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('admin-player-card-p1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AdminPlayerHubScreen), findsOneWidget);
      expect(find.text(l10n.adminPlayerHubUsersTitle), findsOneWidget);
      expect(find.byKey(AdminPlayerHubScreen.usersTileKey), findsOneWidget);
      expect(find.byKey(AdminPlayerHubScreen.sessionsTileKey), findsOneWidget);
      expect(find.text(l10n.adminPlayerHubSessionsTitle), findsOneWidget);

      final sessionsInk = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(AdminPlayerHubScreen.sessionsTileKey),
          matching: find.byType(InkWell),
        ),
      );
      expect(sessionsInk.onTap, isNotNull);
    },
  );

  testWidgets(
    'Sessions stays tappable on the hub while sensor flags never load',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminPlayerHubScreen(
            player: Player(
              firstName: 'Mohamed-Amine',
              lastName: 'ABDESSAMAD',
              keyMember: 'mohamed',
            ),
            flags: AdminPlayerSensorFlags.none,
            sensorService: _HangingSensorService(),
            playerPhotoBuilder: _placeholderPhoto,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(AdminPlayerHubScreen.sessionsTileKey), findsOneWidget);
      expect(find.text(l10n.adminPlayerHubSessionsTitle), findsOneWidget);
      final sessionsInk = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(AdminPlayerHubScreen.sessionsTileKey),
          matching: find.byType(InkWell),
        ),
      );
      expect(sessionsInk.onTap, isNotNull);
    },
  );

  testWidgets(
    'hub shows Sessions when sensor flags are already known',
    (tester) async {
      final l10n = await pumpPlayers(
        tester,
        sensorService: _ImmediateFlagsService(
          const AdminPlayerSensorFlags(
            hasTeamKitSensor: true,
            hasConnectedDevices: false,
          ),
        ),
      );

      members.add([
        Player(
          firstName: 'Sofiane',
          lastName: 'ABDESSALEM',
          keyMember: 'p-sensor',
        ),
      ]);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey<String>('admin-player-card-p-sensor')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AdminPlayerHubScreen), findsOneWidget);
      expect(find.text(l10n.adminPlayerHubUsersTitle), findsOneWidget);
      expect(find.byKey(AdminPlayerHubScreen.sessionsTileKey), findsOneWidget);
      expect(find.text(l10n.adminPlayerHubSessionsTitle), findsOneWidget);
    },
  );
}
