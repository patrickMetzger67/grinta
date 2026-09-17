import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/screen/admin/admin_players_screen.dart';
import 'package:grinta/services/admin_player_sensor_service.dart';
import 'package:grinta/util/app_theme.dart';

class _NoneSensorService extends AdminPlayerSensorService {
  @override
  Future<AdminPlayerSensorFlags> loadFlags(Player player) async =>
      AdminPlayerSensorFlags.none;
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

  testWidgets(
    'shows player email when there is no linked user and no name',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminPlayersScreen(
            membersStream: members.stream,
            sensorService: _NoneSensorService(),
            playerPhotoBuilder: _placeholderPhoto,
          ),
        ),
      );
      await tester.pump();

      members.add([
        Player(
          firstName: '',
          lastName: '',
          email: 'orphan@example.com',
          keyMember: 'orphan-1',
          userID: '',
          users: const <dynamic>[],
        ),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('orphan@example.com'), findsOneWidget);
      expect(find.text(l10n.adminPlayersUserCount(0)), findsOneWidget);
      expect(find.text(l10n.adminNoEmail), findsNothing);
    },
  );
}
