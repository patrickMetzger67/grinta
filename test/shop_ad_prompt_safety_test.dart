import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/widget/shop_ad_prompt.dart';

void main() {
  testWidgets('ShopAdPrompt.maybeShow never throws without a navigator',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await expectLater(ShopAdPrompt.maybeShow(), completes);
    await expectLater(
      ShopAdPrompt.maybeShow(fromFeatureChange: true),
      completes,
    );
  });

  test('ads catch-all exclusion matches collection, not document id', () {
    // Mirrors firestore.rules isAdsCollection(): request.path[3] == 'ads'
    // for /databases/(default)/documents/{collection}/{docId}.
    bool isAdsCollection(List<String> path) =>
        path.length >= 4 && path[3] == 'ads';

    const team = <String>['databases', '(default)', 'documents', 'team', 'abc'];
    const member = <String>[
      'databases',
      '(default)',
      'documents',
      'member',
      'xyz',
    ];
    const ads = <String>['databases', '(default)', 'documents', 'ads', 'ad1'];
    const teamDocNamedAds = <String>[
      'databases',
      '(default)',
      'documents',
      'team',
      'ads',
    ];

    expect(isAdsCollection(team), isFalse);
    expect(isAdsCollection(member), isFalse);
    expect(isAdsCollection(ads), isTrue);
    expect(isAdsCollection(teamDocNamedAds), isFalse,
        reason: 'a team whose id is "ads" must stay readable');
  });
}
