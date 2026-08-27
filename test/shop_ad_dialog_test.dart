import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/shop_ad.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/shop_ad_prompt.dart';

void main() {
  testWidgets('shop ad dialog shows name, CTA, and dismisses',
      (WidgetTester tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    final ad = ShopAd(
      id: 'ad-gps',
      name: 'GPS Insiders',
      url: 'https://shop.grinta.io/products/gps',
      target: ShopAdTarget.all,
    );

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
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => ShopAdDialog(ad: ad),
                  );
                },
                child: const Text('open-ad'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-ad'));
    await tester.pumpAndSettle();

    expect(find.text('GPS Insiders'), findsOneWidget);
    expect(find.text(l10n.shopAdCta), findsOneWidget);
    expect(find.text(l10n.actionClose), findsWidgets);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('GPS Insiders'), findsNothing);
  });
}
