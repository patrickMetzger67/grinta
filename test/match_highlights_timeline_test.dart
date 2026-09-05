import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/match_highlights_timeline.dart';

Widget _wrap({
  required double width,
  required MatchHighlightsTimeline child,
  double height = 900,
  double textScale = 1,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: Size(width, height),
      textScaler: TextScaler.linear(textScale),
    ),
    child: MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        extensions: const <ThemeExtension<dynamic>>[AppColors.dark],
      ),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: width,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

MatchStatHighLight _substitution({
  required int minute,
  required String outgoing,
  required String incoming,
  String team = 'NORDHOUSE US',
}) {
  return MatchStatHighLight(
    type: 'changement',
    time: minute,
    team: team,
    player: outgoing,
    incomingPlayer: incoming,
  );
}

MatchStatHighLight _longSubstitution() {
  return _substitution(
    minute: 30,
    outgoing: 'ARNAUD ABBAS',
    incoming: 'MEHDI BOUCHENTOUF',
  );
}

bool _isOverflow(FlutterErrorDetails details) {
  final text = '${details.exception}\n${details.toString()}'.toLowerCase();
  return text.contains('overflowed') || text.contains('overflow');
}

Future<List<FlutterErrorDetails>> _pumpAndCollectErrors(
  WidgetTester tester,
  Widget widget,
) async {
  final void Function(FlutterErrorDetails)? oldOnError = FlutterError.onError;
  final errors = <FlutterErrorDetails>[];
  FlutterError.onError = (details) {
    errors.add(details);
    oldOnError?.call(details);
  };

  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();

  FlutterError.onError = oldOnError;
  return errors;
}

void main() {
  testWidgets('wide timeline grows for a wrapping substitution without overflow',
      (tester) async {
    final errors = await _pumpAndCollectErrors(
      tester,
      _wrap(
        width: 700,
        child: MatchHighlightsTimeline(
          team1: 'NORDHOUSE US',
          team2: 'ERSTEIN AS',
          highlights: [_longSubstitution()],
        ),
      ),
    );

    expect(find.text('MEHDI BOUCHENTOUF remplace ARNAUD ABBAS'), findsOneWidget);
    expect(find.text('NORDHOUSE US'), findsWidgets);
    expect(errors.where(_isOverflow), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow timeline grows for a wrapping substitution without overflow',
      (tester) async {
    final errors = await _pumpAndCollectErrors(
      tester,
      _wrap(
        width: 360,
        child: MatchHighlightsTimeline(
          team1: 'NORDHOUSE US',
          team2: 'ERSTEIN AS',
          highlights: [_longSubstitution()],
        ),
      ),
    );

    expect(find.text('MEHDI BOUCHENTOUF remplace ARNAUD ABBAS'), findsOneWidget);
    expect(errors.where(_isOverflow), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card-type tap chevron plus wrapping names does not overflow',
      (tester) async {
    final errors = await _pumpAndCollectErrors(
      tester,
      _wrap(
        width: 700,
        child: MatchHighlightsTimeline(
          team1: 'NORDHOUSE US',
          team2: 'ERSTEIN AS',
          onCardHighlightTap: (_) {},
          highlights: [
            MatchStatHighLight(
              type: 'carton_jaune',
              time: 14,
              team: 'NORDHOUSE US',
              player: 'JEAN-PHILIPPE MONTPELLIER-DUPONT',
            ),
            _longSubstitution(),
          ],
        ),
      ),
    );

    expect(find.text('MEHDI BOUCHENTOUF remplace ARNAUD ABBAS'), findsOneWidget);
    expect(errors.where(_isOverflow), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'wrapping substitution card is taller than a one-line card and keeps the team pill',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const longLabel = 'MEHDI BOUCHENTOUF remplace ARNAUD ABBAS';
    const shortLabel = 'A remplace B';

    final errors = await _pumpAndCollectErrors(
      tester,
      _wrap(
        width: 600,
        child: MatchHighlightsTimeline(
          team1: 'NORDHOUSE US',
          team2: 'ERSTEIN AS',
          highlights: [
            _substitution(
              minute: 14,
              outgoing: 'NATHAN BRUCKERT',
              incoming: 'THOMAS CLAUSS',
            ),
            _longSubstitution(),
            _substitution(
              minute: 36,
              outgoing: 'B',
              incoming: 'A',
            ),
          ],
        ),
      ),
    );

    final longRect = tester.getRect(find.text(longLabel));
    final shortRect = tester.getRect(find.text(shortLabel));
    expect(
      longRect.height,
      greaterThan(shortRect.height),
      reason: 'Long substitution names must wrap and grow instead of clipping',
    );
    expect(find.text('Changement'), findsNWidgets(3));
    expect(find.text('NORDHOUSE US'), findsWidgets);
    expect(errors.where(_isOverflow), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text scale still grows the substitution card',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final errors = await _pumpAndCollectErrors(
      tester,
      _wrap(
        width: 390,
        textScale: 1.3,
        child: MatchHighlightsTimeline(
          team1: 'NORDHOUSE US',
          team2: 'ERSTEIN AS',
          highlights: [
            _longSubstitution(),
            _substitution(
              minute: 36,
              outgoing: 'GUILLAUME KNEY',
              incoming: 'COLIN CHARLOIS',
            ),
          ],
        ),
      ),
    );

    expect(find.text('MEHDI BOUCHENTOUF remplace ARNAUD ABBAS'), findsOneWidget);
    expect(find.text('COLIN CHARLOIS remplace GUILLAUME KNEY'), findsOneWidget);
    expect(errors.where(_isOverflow), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
