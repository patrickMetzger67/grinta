import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/match_highlights_timeline.dart';

Widget _wrap({
  required double width,
  required MatchHighlightsTimeline child,
}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      extensions: const <ThemeExtension<dynamic>>[AppColors.light],
    ),
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

MatchStatHighLight _longSubstitution() {
  return MatchStatHighLight(
    type: 'changement',
    time: 30,
    team: 'NORDHOUSE US',
    player: 'ARNAUD ABBAS',
    incomingPlayer: 'MEHDI BOUCHENTOUF',
  );
}

void main() {
  testWidgets('wide timeline grows for a wrapping substitution without overflow',
      (tester) async {
    final FlutterExceptionHandler? oldOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;

    await tester.pumpWidget(
      _wrap(
        width: 700,
        child: MatchHighlightsTimeline(
          team1: 'NORDHOUSE US',
          team2: 'ERSTEIN AS',
          highlights: [_longSubstitution()],
        ),
      ),
    );
    await tester.pumpAndSettle();
    FlutterError.onError = oldOnError;

    expect(find.text('MEHDI BOUCHENTOUF remplace ARNAUD ABBAS'), findsOneWidget);
    expect(find.text('NORDHOUSE US'), findsWidgets);
    expect(
      errors.where((e) => e.toString().contains('OVERFLOWED')),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow timeline grows for a wrapping substitution without overflow',
      (tester) async {
    final FlutterExceptionHandler? oldOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;

    await tester.pumpWidget(
      _wrap(
        width: 360,
        child: MatchHighlightsTimeline(
          team1: 'NORDHOUSE US',
          team2: 'ERSTEIN AS',
          highlights: [_longSubstitution()],
        ),
      ),
    );
    await tester.pumpAndSettle();
    FlutterError.onError = oldOnError;

    expect(find.text('MEHDI BOUCHENTOUF remplace ARNAUD ABBAS'), findsOneWidget);
    expect(
      errors.where((e) => e.toString().contains('OVERFLOWED')),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('card-type tap chevron plus wrapping names does not overflow',
      (tester) async {
    final FlutterExceptionHandler? oldOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;

    await tester.pumpWidget(
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
    await tester.pumpAndSettle();
    FlutterError.onError = oldOnError;

    expect(find.text('MEHDI BOUCHENTOUF remplace ARNAUD ABBAS'), findsOneWidget);
    expect(
      errors.where((e) => e.toString().contains('OVERFLOWED')),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
