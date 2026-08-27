import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/settings_close_button.dart';

void main() {
  testWidgets('compact and full-width close buttons invoke onPressed',
      (tester) async {
    var compactTaps = 0;
    var fullWidthTaps = 0;

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
          body: Column(
            children: [
              SettingsCloseButton(onPressed: () => compactTaps++),
              SettingsCloseButton(
                fullWidth: true,
                onPressed: () => fullWidthTaps++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Fermer'), findsNWidgets(2));
    await tester.tap(find.byType(TextButton));
    await tester.tap(find.byType(OutlinedButton));
    expect(compactTaps, 1);
    expect(fullWidthTaps, 1);
  });
}
