import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_cards_helper.dart';
import 'package:grinta/widget/assign_fmi_goal_player_sheet.dart';

void main() {
  testWidgets('picks scorer then assister and pops the selection',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    AssignFmiGoalPlayerSelection? selected;

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
                  selected = await showAssignFmiGoalPlayerSheet(
                    context,
                    goalType: GoalType.normal,
                    minute: 23,
                    players: const [
                      AssignFmiCardPlayerOption(
                        memberId: 'm-alice',
                        label: 'Alice Martin',
                      ),
                      AssignFmiCardPlayerOption(
                        memberId: 'm-bruno',
                        label: 'Bruno Durand',
                      ),
                      AssignFmiCardPlayerOption(
                        memberId: 'm-claire',
                        label: 'Claire Petit',
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

    expect(find.byKey(AssignFmiGoalPlayerSheet.sheetKey), findsOneWidget);
    expect(find.text(l10n.fmiGoalPickScorerTitle), findsOneWidget);
    expect(
      find.text(
        l10n.fmiGoalPickScorerSubtitle(l10n.highlightTypeGoal, 23),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(AssignFmiGoalPlayerSheet.scorerKey('m-bruno')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.fmiGoalPickAssisterTitle), findsOneWidget);
    expect(find.text(l10n.fmiGoalNoAssister), findsOneWidget);
    expect(find.byKey(AssignFmiGoalPlayerSheet.scorerKey('m-bruno')), findsNothing);
    expect(
      find.byKey(AssignFmiGoalPlayerSheet.assisterKey('m-bruno')),
      findsNothing,
    );
    expect(find.text('Bruno Durand'), findsNothing);

    await tester.tap(
      find.byKey(AssignFmiGoalPlayerSheet.assisterKey('m-claire')),
    );
    await tester.pumpAndSettle();

    expect(selected?.scorerMemberId, 'm-bruno');
    expect(selected?.assisterMemberId, 'm-claire');
    expect(find.byKey(AssignFmiGoalPlayerSheet.sheetKey), findsNothing);
  });

  testWidgets('allows finishing without an assister', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    AssignFmiGoalPlayerSelection? selected;

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
                  selected = await showAssignFmiGoalPlayerSheet(
                    context,
                    goalType: GoalType.penalty,
                    minute: 90,
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

    expect(
      find.text(
        l10n.fmiGoalPickScorerSubtitle(l10n.highlightTypePenalty, 90),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(AssignFmiGoalPlayerSheet.scorerKey('m-alice')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AssignFmiGoalPlayerSheet.noAssisterKey));
    await tester.pumpAndSettle();

    expect(selected?.scorerMemberId, 'm-alice');
    expect(selected?.assisterMemberId, isNull);
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
          body: AssignFmiGoalPlayerSheet(
            goalType: GoalType.normal,
            minute: 12,
            players: [],
          ),
        ),
      ),
    );

    expect(find.text(l10n.fmiGoalNoConvokedPlayers), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('filters scorer list as the user types', (tester) async {
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
          body: AssignFmiGoalPlayerSheet(
            goalType: GoalType.normal,
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

    await tester.enterText(
      find.byKey(const ValueKey('player-name-filter-field')),
      'baruth',
    );
    await tester.pump();

    expect(find.text('Erwan Baruthio'), findsOneWidget);
    expect(find.text('Achille SCHMITT'), findsNothing);
    expect(find.text('Lucas Burg'), findsNothing);
  });
}
