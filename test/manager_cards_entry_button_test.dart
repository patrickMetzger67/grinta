import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/manager_cards_entry_button.dart';

Widget _harness({required Widget child}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      extensions: const <ThemeExtension<dynamic>>[AppColors.light],
    ),
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
    'manager with teams and zero cards still shows compact entry (no badge)',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      var taps = 0;

      await tester.pumpWidget(
        _harness(
          child: ManagerCardsEntryContent(
            compact: true,
            nonPurgedCount: 0,
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.byKey(const Key('manager-cards-entry-compact')), findsOneWidget);
      expect(find.byTooltip(l10n.managerCardsTooltip), findsOneWidget);
      expect(find.byIcon(Icons.style_rounded), findsOneWidget);
      expect(find.byType(Badge), findsNothing);
      expect(find.byKey(const Key('manager-cards-badge-loading')), findsNothing);

      await tester.tap(find.byKey(const Key('manager-cards-entry-compact')));
      expect(taps, 1);
    },
  );

  testWidgets(
    'entry shows immediately while badge is loading (no numeric badge yet)',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

      await tester.pumpWidget(
        _harness(
          child: ManagerCardsEntryContent(
            compact: true,
            nonPurgedCount: 0,
            isBadgeLoading: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('manager-cards-entry-compact')), findsOneWidget);
      expect(find.byTooltip(l10n.managerCardsTooltip), findsOneWidget);
      expect(find.byKey(const Key('manager-cards-badge-loading')), findsOneWidget);
      expect(find.byType(Badge), findsNothing);
    },
  );

  testWidgets(
    'dashboard entry shows title with zero cards and badge only when count > 0',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

      await tester.pumpWidget(
        _harness(
          child: ManagerCardsEntryContent(
            nonPurgedCount: 0,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('manager-cards-entry')), findsOneWidget);
      expect(find.text(l10n.managerCardsTitle), findsOneWidget);
      expect(find.byType(Badge), findsNothing);

      await tester.pumpWidget(
        _harness(
          child: ManagerCardsEntryContent(
            nonPurgedCount: 3,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('manager-cards-entry')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
    },
  );
}
