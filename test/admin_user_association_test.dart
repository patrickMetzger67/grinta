import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/screen/admin/admin_player_hub_screen.dart';
import 'package:grinta/screen/admin/admin_user_players_screen.dart';
import 'package:grinta/screen/admin/admin_users_screen.dart';
import 'package:grinta/services/admin_player_sensor_service.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/admin_player_association.dart';
import 'package:grinta/util/app_theme.dart';

class _HangingSensorService extends AdminPlayerSensorService {
  @override
  Future<AdminPlayerSensorFlags> loadFlags(Player player) {
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

  group('adminAssociationPlayerCount', () {
    test('is null until the association stream has data', () {
      expect(
        adminAssociationPlayerCount(hasData: false, players: null),
        isNull,
      );
      expect(
        adminAssociationPlayerCount(hasData: false, players: const []),
        isNull,
      );
    });

    test('is 1 when the association stream already has one player', () {
      final player = Player(
        firstName: 'Mohamed-Amine',
        lastName: 'ABDESSAMAD',
        keyMember: 'mohamed-player',
        userID: 'mohamed-uid',
        users: const ['mohamed-uid'],
      );
      expect(
        adminAssociationPlayerCount(hasData: true, players: [player]),
        1,
      );
      expect(
        adminPlayerCountsByUserId([player])['mohamed-uid'],
        1,
      );
    });
  });

  group('mergePlayersByMemberId', () {
    test('dedupes users-array and userID hits', () {
      final fromUsers = Player(
        firstName: 'Mohamed-Amine',
        lastName: 'ABDESSAMAD',
        keyMember: 'mohamed-player',
        users: const ['mohamed-uid'],
      );
      final fromPrimary = Player(
        firstName: 'Mohamed-Amine',
        lastName: 'ABDESSAMAD',
        keyMember: 'mohamed-player',
        userID: 'mohamed-uid',
      );
      final merged = mergePlayersByMemberId([fromUsers], [fromPrimary]);
      expect(merged, hasLength(1));
    });
  });

  group('AdminUsersScreen association', () {
    testWidgets(
      'user with 1 player shows 1 immediately from the association stream',
      (tester) async {
        final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
        const uid = 'mohamed-uid';
        final user = UserProfile(
          uid: uid,
          firstName: 'Mohamed-Amine',
          lastName: 'ABDESSAMAD',
          email: 'mohamed@example.com',
        );
        final player = Player(
          firstName: 'Mohamed-Amine',
          lastName: 'ABDESSAMAD',
          keyMember: 'mohamed-player',
          userID: uid,
          users: const [uid],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AdminUsersScreen(
              usersStream: Stream<List<UserProfile>>.value([user]),
              playersForUser: (userId) => Stream<List<Player>>.value(
                userId == uid ? [player] : const <Player>[],
              ),
              sensorService: _HangingSensorService(),
              playerPhotoBuilder: _placeholderPhoto,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Mohamed-Amine ABDESSAMAD'), findsOneWidget);
        expect(find.text(l10n.adminUsersPlayerCount(1)), findsOneWidget);
        expect(find.text(l10n.adminUsersPlayerCount(0)), findsNothing);
      },
    );

    testWidgets(
      'does not flash Aucun joueur while the association stream has not emitted',
      (tester) async {
        final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
        final pending = StreamController<List<Player>>();
        addTearDown(pending.close);

        final user = const UserProfile(
          uid: 'mohamed-uid',
          firstName: 'Mohamed-Amine',
          lastName: 'ABDESSAMAD',
          email: 'mohamed@example.com',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AdminUsersScreen(
              usersStream: Stream<List<UserProfile>>.value([user]),
              playersForUser: (_) => pending.stream,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Mohamed-Amine ABDESSAMAD'), findsOneWidget);
        expect(find.text(l10n.adminUsersPlayerCount(0)), findsNothing);
        expect(find.text(l10n.adminUsersPlayersEmpty), findsNothing);
      },
    );

    testWidgets('hides anonymous users from the list', (tester) async {
      final named = const UserProfile(
        uid: 'mohamed-uid',
        firstName: 'Mohamed-Amine',
        lastName: 'ABDESSAMAD',
        email: 'mohamed@example.com',
      );
      final anonymous = const UserProfile(
        uid: 'anon-uid',
        firstName: '',
        lastName: '',
        email: '',
        isAnonymous: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminUsersScreen(
            usersStream: Stream<List<UserProfile>>.value([named, anonymous]),
            playersForUser: (_) => Stream<List<Player>>.value(const []),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Mohamed-Amine ABDESSAMAD'), findsOneWidget);
      expect(find.text('anon-uid'), findsNothing);
    });
  });

  group('AdminUserPlayersScreen', () {
    testWidgets(
      'shows the associated player immediately from existing association data',
      (tester) async {
        final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
        const uid = 'mohamed-uid';
        final user = UserProfile(
          uid: uid,
          firstName: 'Mohamed-Amine',
          lastName: 'ABDESSAMAD',
          email: 'mohamed@example.com',
        );
        final player = Player(
          firstName: 'Mohamed-Amine',
          lastName: 'ABDESSAMAD',
          keyMember: 'mohamed-player',
          userID: uid,
          users: const [uid],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AdminUserPlayersScreen(
              user: user,
              initialPlayers: [player],
              playersStream: Completer<List<Player>>().future.asStream(),
              sensorService: _HangingSensorService(),
              playerPhotoBuilder: _placeholderPhoto,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Mohamed-Amine ABDESSAMAD'), findsWidgets);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text(l10n.adminUsersPlayersEmpty), findsNothing);
      },
    );

    testWidgets(
      'tapping the associated player opens the hub without waiting for flags',
      (tester) async {
        const uid = 'mohamed-uid';
        final user = UserProfile(
          uid: uid,
          firstName: 'Mohamed-Amine',
          lastName: 'ABDESSAMAD',
          email: 'mohamed@example.com',
        );
        final player = Player(
          firstName: 'Mohamed-Amine',
          lastName: 'ABDESSAMAD',
          keyMember: 'mohamed-player',
          userID: uid,
          users: const [uid],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AdminUserPlayersScreen(
              user: user,
              initialPlayers: [player],
              playersStream: Stream<List<Player>>.value([player]),
              sensorService: _HangingSensorService(),
              playerPhotoBuilder: _placeholderPhoto,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        await tester.tap(
          find.byKey(const ValueKey<String>('admin-linked-player-mohamed-player')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(AdminPlayerHubScreen), findsOneWidget);
        expect(find.byKey(AdminPlayerHubScreen.sessionsTileKey), findsOneWidget);
      },
    );
  });
}
