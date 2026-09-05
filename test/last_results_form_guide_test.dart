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
    expect(
      _innerDecoration(tester, 3).border?.top.color,
      lastResultsEmptyStrokeColor,
    );
    expect(_outerDecoration(tester, 2).border?.top.color, colors.success);
  });

  testWidgets('draw is grey, loss is red, empty is a black ring', (tester) async {
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

    expect(_innerDecoration(tester, 0).color, lastResultsDrawColor);
    expect(_innerDecoration(tester, 1).color, lastResultsDrawColor);
    expect(_innerDecoration(tester, 2).color, lastResultsLossColor);
    expect(_innerDecoration(tester, 3).color, isNull);
    expect(
      _innerDecoration(tester, 3).border?.top.color,
      lastResultsEmptyStrokeColor,
    );
    expect(find.byKey(LastResultsFormRow.highlightKey(2)), findsOneWidget);
    expect(_outerDecoration(tester, 2).border?.top.color, lastResultsLossColor);
  });

  testWidgets('empty rings use the outline color passed for dark headers',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const LastResultsFormRow(
          slots: <MatchOutcome?>[
            MatchOutcome.win,
            null,
            null,
            null,
            null,
          ],
          emptyRingColor: Colors.white,
        ),
      ),
    );

    expect(_innerDecoration(tester, 0).color, colors.success);
    expect(_innerDecoration(tester, 1).color, isNull);
    expect(_innerDecoration(tester, 1).border?.top.color, Colors.white);
  });

  testWidgets('hides when clubs[] is missing even if affiliation is set',
      (tester) async {
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
    expect(find.byType(LastResultsFormRow), findsNothing);
  });

  testWidgets('hides while the lastResults stream is loading', (tester) async {
    final controller = StreamController<LastResults?>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      _wrap(
        LastResultsFormGuide(
          match: Match(
            id: '56174440',
            affiliationTeam1: '500554',
            competitionID: '450652',
            clubs: ['club-a', 'club-b'],
          ),
          side: MatchSide.team1,
          resultsStream: controller.stream,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(LastResultsFormRow.guideKey), findsNothing);
    expect(find.byType(LastResultsFormRow), findsNothing);
  });

  testWidgets('keeps filled slots when the parent rebuilds before a new emit',
      (tester) async {
    final controller = StreamController<LastResults?>();
    addTearDown(controller.close);

    Widget guide() {
      return LastResultsFormGuide(
        match: Match(
          id: 'm2',
          affiliationTeam1: '500554',
          competitionID: '450652',
          clubs: ['club-a', 'club-b'],
        ),
        side: MatchSide.team1,
        resultsStream: controller.stream,
      );
    }

    await tester.pumpWidget(_wrap(guide()));
    controller.add(
      const LastResults(
        clubId: 'club-a',
        competitionId: '450652',
        results: <LastResultEntry>[
          LastResultEntry(outcome: MatchOutcome.win, matchId: 'm1'),
          LastResultEntry(outcome: MatchOutcome.loss, matchId: 'm2'),
        ],
      ),
    );
    await tester.pump();

    expect(_innerDecoration(tester, 0).color, colors.success);
    expect(_innerDecoration(tester, 1).color, lastResultsLossColor);

    await tester.pumpWidget(_wrap(guide()));
    await tester.pump();

    expect(_innerDecoration(tester, 0).color, colors.success);
    expect(_innerDecoration(tester, 1).color, lastResultsLossColor);
  });

  testWidgets('hides when the lastResults document is missing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LastResultsFormGuide(
          match: Match(
            competitionID: '450652',
            clubs: ['club-a', 'club-b'],
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
            clubs: ['club-a', 'club-b'],
          ),
          side: MatchSide.team1,
          resultsStream: Stream<LastResults?>.value(
            const LastResults(
              clubId: 'club-a',
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
    expect(_innerDecoration(tester, 0).color, lastResultsDrawColor);
    expect(_innerDecoration(tester, 1).color, lastResultsLossColor);
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
            clubs: ['club-a', 'club-b'],
          ),
          side: MatchSide.team1,
          resultsStream: Stream<LastResults?>.value(
            const LastResults(
              clubId: 'club-a',
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
