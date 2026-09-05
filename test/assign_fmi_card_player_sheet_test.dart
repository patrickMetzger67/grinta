import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_cards_helper.dart';
import 'package:grinta/widget/assign_fmi_card_player_sheet.dart';

void main() {
  testWidgets('lists convoked players and pops the selected member id',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    String? selectedId;

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
                  selectedId = await showAssignFmiCardPlayerSheet(
                    context,
                    cardType: playerCardTypeYellow,
                    minute: 41,
                    players: const [
                      AssignFmiCardPlayerOption(
                        memberId: 'm-alice',
                        label: 'Alice Martin',
                      ),
                      AssignFmiCardPlayerOption(
                        memberId: 'm-bruno',
                        label: 'Bruno Durand',
                      ),
                    ],
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

    expect(find.byKey(AssignFmiCardPlayerSheet.sheetKey), findsOneWidget);
    expect(find.text(l10n.fmiCardPickPlayerTitle), findsOneWidget);
    expect(
      find.text(l10n.fmiCardPickPlayerSubtitle(l10n.highlightTypeYellowCard, 41)),
      findsOneWidget,
    );
    expect(find.text('Alice Martin'), findsOneWidget);
    expect(find.text('Bruno Durand'), findsOneWidget);

    await tester.tap(find.byKey(AssignFmiCardPlayerSheet.playerKey('m-bruno')));
    await tester.pumpAndSettle();

    expect(selectedId, 'm-bruno');
    expect(find.byKey(AssignFmiCardPlayerSheet.sheetKey), findsNothing);
  });

  testWidgets('shows an empty state when no convoked players', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          extensions: const <ThemeExtension<dynamic>>[AppColors.light],
        ),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: AssignFmiCardPlayerSheet(
            cardType: playerCardTypeRed,
            minute: 88,
            players: [],
          ),
        ),
      ),
    );

    expect(find.text(l10n.fmiCardNoConvokedPlayers), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('filters convoked players as the user types', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          extensions: const <ThemeExtension<dynamic>>[AppColors.light],
        ),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: AssignFmiCardPlayerSheet(
            cardType: playerCardTypeYellow,
            minute: 47,
            players: [
              AssignFmiCardPlayerOption(
                memberId: 'm-achille',
                label: 'Achille SCHMITT',
              ),
              AssignFmiCardPlayerOption(
                memberId: 'm-erwan',
                label: 'Erwan Baruthio',
              ),
              AssignFmiCardPlayerOption(
                memberId: 'm-lucas',
                label: 'Lucas Burg',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text(l10n.teamDetailFilterPlayerHint), findsOneWidget);
    expect(find.text('Achille SCHMITT'), findsOneWidget);
    expect(find.text('Erwan Baruthio'), findsOneWidget);
    expect(find.text('Lucas Burg'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('player-name-filter-field')),
      'baruth',
    );
    await tester.pump();

    expect(find.text('Erwan Baruthio'), findsOneWidget);
    expect(find.text('Achille SCHMITT'), findsNothing);
    expect(find.text('Lucas Burg'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('player-name-filter-field')),
      'zzz',
    );
    await tester.pump();

    expect(find.text(l10n.emptyNoPlayerForTeam), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('player-name-filter-field')),
      '',
    );
    await tester.pump();

    expect(find.text('Achille SCHMITT'), findsOneWidget);
    expect(find.text('Erwan Baruthio'), findsOneWidget);
    expect(find.text('Lucas Burg'), findsOneWidget);
  });
}
