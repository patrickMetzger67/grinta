import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/last_results.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/widget/last_results_form_guide.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      extensions: const <ThemeExtension<dynamic>>[AppColors.light],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

BoxDecoration _innerDecoration(WidgetTester tester, int index) {
  final boxes = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(LastResultsFormRow.slotKey(index)),
          matching: find.byType(DecoratedBox),
        ),
      )
      .toList();
  return boxes.last.decoration as BoxDecoration;
}

BoxDecoration _outerDecoration(WidgetTester tester, int index) {
  final boxes = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(LastResultsFormRow.slotKey(index)),
          matching: find.byType(DecoratedBox),
        ),
      )
      .toList();
  return boxes.first.decoration as BoxDecoration;
}

void main() {
  const colors = AppColors.light;

  testWidgets('renders 5 slots with win, draw, loss, empties and highlight',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const LastResultsFormRow(
          slots: <MatchOutcome?>[
            MatchOutcome.win,
            MatchOutcome.win,
            MatchOutcome.win,
            null,
            null,
          ],
          highlightIndex: 2,
        ),
      ),
    );

    expect(find.byKey(LastResultsFormRow.guideKey), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(LastResultsFormRow.slotKey(i)), findsOneWidget);
    }
    expect(find.byKey(LastResultsFormRow.highlightKey(2)), findsOneWidget);
    expect(find.byKey(LastResultsFormRow.highlightKey(0)), findsNothing);

    expect(_innerDecoration(tester, 0).color, colors.success);
    expect(_innerDecoration(tester, 1).color, colors.success);
    expect(_innerDecoration(tester, 2).color, colors.success);
    expect(_innerDecoration(tester, 3).color, isNull);
    expect(_innerDecoration(tester, 4).color, isNull);
    expect(_innerDecoration(tester, 3).border, isNotNull);
    expect(_outerDecoration(tester, 2).border?.top.color, colors.success);
  });

  testWidgets('draw is grey with a dash, loss is red with a ring',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const LastResultsFormRow(
          slots: <MatchOutcome?>[
            MatchOutcome.draw,
            MatchOutcome.draw,
            MatchOutcome.loss,
            null,
            null,
          ],
          highlightIndex: 2,
        ),
      ),
    );

    expect(_innerDecoration(tester, 0).color, colors.textSecondary);
    expect(_innerDecoration(tester, 1).color, colors.textSecondary);
    expect(_innerDecoration(tester, 2).color, colors.danger);
    expect(_innerDecoration(tester, 3).color, isNull);
    expect(find.byKey(LastResultsFormRow.highlightKey(2)), findsOneWidget);
    expect(_outerDecoration(tester, 2).border?.top.color, colors.danger);
  });

  testWidgets('hides when clubId or competitionId is missing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LastResultsFormGuide(
          match: Match(affiliationTeam1: '500554'),
          side: MatchSide.team1,
          resultsStream: Stream<LastResults?>.value(null),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(LastResultsFormRow.guideKey), findsNothing);
    expect(find.byType(LastResultsFormRow), findsNothing);
  });

  testWidgets('shows 5 empty slots while the lastResults stream is loading',
      (tester) async {
    final controller = StreamController<LastResults?>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      _wrap(
        LastResultsFormGuide(
          match: Match(
            id: '56174440',
            affiliationTeam1: '500554',
            competitionID: '450652',
          ),
          side: MatchSide.team1,
          resultsStream: controller.stream,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(LastResultsFormRow.guideKey), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(LastResultsFormRow.slotKey(i)), findsOneWidget);
      expect(_innerDecoration(tester, i).color, isNull);
    }
    expect(find.byKey(LastResultsFormRow.highlightKey(0)), findsNothing);
  });

  testWidgets('hides when the lastResults document is missing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LastResultsFormGuide(
          match: Match(
            affiliationTeam1: '500554',
            competitionID: '450652',
          ),
          side: MatchSide.team1,
          resultsStream: Stream<LastResults?>.value(null),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(LastResultsFormRow.guideKey), findsNothing);
  });

  testWidgets('reads lastResults and highlights the current match',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        LastResultsFormGuide(
          match: Match(
            id: 'm2',
            affiliationTeam1: '500554',
            competitionID: '450652',
          ),
          side: MatchSide.team1,
          resultsStream: Stream<LastResults?>.value(
            const LastResults(
              clubId: '500554',
              competitionId: '450652',
              results: <LastResultEntry>[
                LastResultEntry(outcome: MatchOutcome.draw, matchId: 'm1'),
                LastResultEntry(outcome: MatchOutcome.loss, matchId: 'm2'),
                LastResultEntry(outcome: MatchOutcome.win, matchId: 'm3'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(LastResultsFormRow.guideKey), findsOneWidget);
    expect(_innerDecoration(tester, 0).color, colors.textSecondary);
    expect(_innerDecoration(tester, 1).color, colors.danger);
    expect(_innerDecoration(tester, 2).color, colors.success);
    expect(_innerDecoration(tester, 3).color, isNull);
    expect(_innerDecoration(tester, 4).color, isNull);
    expect(find.byKey(LastResultsFormRow.highlightKey(1)), findsOneWidget);
  });

  testWidgets('highlights the most recent result when match is not in the list',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        LastResultsFormGuide(
          match: Match(
            id: 'upcoming',
            affiliationTeam1: '500554',
            competitionID: '450652',
          ),
          side: MatchSide.team1,
          resultsStream: Stream<LastResults?>.value(
            const LastResults(
              clubId: '500554',
              competitionId: '450652',
              results: <LastResultEntry>[
                LastResultEntry(outcome: MatchOutcome.win, matchId: 'm1'),
                LastResultEntry(outcome: MatchOutcome.win, matchId: 'm2'),
                LastResultEntry(outcome: MatchOutcome.win, matchId: 'm3'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(LastResultsFormRow.highlightKey(2)), findsOneWidget);
    expect(_innerDecoration(tester, 0).color, colors.success);
    expect(_innerDecoration(tester, 4).color, isNull);
  });
}
