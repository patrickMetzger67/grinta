import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/share.dart';
import 'package:grinta/services/share_record_service.dart';
import 'package:grinta/util/share_sheet.dart';
import 'package:share_plus/share_plus.dart' hide Share;

void main() {
  group('shareNetworkFromActivity', () {
    test('maps common iOS activity ids', () {
      expect(
        shareNetworkFromActivity('net.whatsapp.WhatsApp.ShareExtension'),
        'whatsapp',
      );
      expect(
        shareNetworkFromActivity('com.burbn.instagram.shareextension'),
        'instagram',
      );
      expect(
        shareNetworkFromActivity('com.apple.UIKit.activity.PostToFacebook'),
        'facebook',
      );
      expect(
        shareNetworkFromActivity('com.apple.UIKit.activity.PostToTwitter'),
        'twitter',
      );
      expect(
        shareNetworkFromActivity('com.apple.UIKit.activity.Mail'),
        'mail',
      );
      expect(
        shareNetworkFromActivity('com.apple.UIKit.activity.Message'),
        'messages',
      );
    });

    test('unknown or empty activity', () {
      expect(shareNetworkFromActivity(''), 'unknown');
      expect(shareNetworkFromActivity(null), 'unknown');
      expect(shareNetworkFromActivity('com.apple.UIKit.activity.CopyToPasteboard'),
          'other');
    });
  });

  group('shouldPersistShareResult', () {
    test('persists success and unavailable, not dismissed', () {
      expect(
        shouldPersistShareResult(
          const ShareResult('whatsapp', ShareResultStatus.success),
        ),
        isTrue,
      );
      expect(
        shouldPersistShareResult(ShareResult.unavailable),
        isTrue,
      );
      expect(
        shouldPersistShareResult(
          const ShareResult('', ShareResultStatus.dismissed),
        ),
        isFalse,
      );
    });
  });

  group('Share', () {
    test('toCreateMap starts views/interactions at zero for the batch', () {
      final share = buildShare(
        userId: 'u1',
        statId: 'event_player',
        statType: ShareStatType.sessionSynthesis,
        where: 'whatsapp',
        platformShareId: 'net.whatsapp.WhatsApp.ShareExtension',
      );
      final doc = share.toCreateMap();
      expect(doc[keyShareUserId], 'u1');
      expect(doc[keyShareStatId], 'event_player');
      expect(doc[keyShareStatType], ShareStatType.sessionSynthesis);
      expect(doc[keyShareWhere], 'whatsapp');
      expect(doc[keySharePlatformShareId], 'net.whatsapp.WhatsApp.ShareExtension');
      expect(doc[keyShareViews], 0);
      expect(doc[keyShareInteractions], 0);
      expect(doc.containsKey(keyShareLastSyncedAt), isFalse);
      expect(doc[keyShareStatus], ShareStatus.shared);
    });

    test('fromMap / toMap keep typed fields', () {
      final shareAt = Timestamp.fromMillisecondsSinceEpoch(0);
      final share = Share.fromMap(<String, dynamic>{
        keyShareUserId: 'u1',
        keyShareShareAt: shareAt,
        keyShareWhere: 'instagram',
        keySharePlatformShareId: 'com.burbn.instagram.shareextension',
        keyShareStatId: 'event_player',
        keyShareStatType: ShareStatType.sessionSynthesis,
        keyShareStatus: ShareStatus.shared,
        keyShareViews: 3,
        keyShareInteractions: 1,
        keySharePostUrl: 'https://example.test/p',
      });
      expect(share.userId, 'u1');
      expect(share.shareAt, shareAt);
      expect(share.where, 'instagram');
      expect(share.views, 3);
      expect(share.interactions, 1);
      expect(share.postUrl, 'https://example.test/p');

      final map = share.toMap();
      expect(map[keyShareWhere], 'instagram');
      expect(map[keyShareViews], 3);
      expect(map[keySharePostUrl], 'https://example.test/p');
    });
  });

  group('ShareScorePoints', () {
    test('create payload awards per-share points only', () {
      final created = buildShareScoreCreate(userId: 'u1');
      expect(created['shareCount'], 1);
      expect(created['sharePoints'], ShareScorePoints.perShare);
      expect(created['totalPoints'], ShareScorePoints.perShare);
      expect(created['views'], 0);
      expect(created['interactions'], 0);
    });
  });

  testWidgets('shareSheetOrigin is a 1x1 point inside the screen',
      (tester) async {
    late Rect origin;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return IconButton(
                  onPressed: () {
                    origin = shareSheetOrigin(context);
                  },
                  icon: const Icon(Icons.ios_share_outlined),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    expect(origin.width, 1);
    expect(origin.height, 1);
    expect(origin.left, greaterThanOrEqualTo(1));
    expect(origin.top, greaterThanOrEqualTo(1));
    expect(origin.left, lessThan(390));
    expect(origin.top, lessThan(844));
  });
}
