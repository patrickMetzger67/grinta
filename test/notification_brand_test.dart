import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/config/fcm_config.dart';
import 'package:grinta/model/notification.dart';
import 'package:grinta/services/notificationService.dart';

void main() {
  test('Grinta notification writes always stamp brand=grinta', () {
    final notification = NotificationApp(
      userId: 'uid-1',
      type: NotifType.convocation,
      sendBy: SendBy.notification,
      title: 'Match',
      body: 'Samedi',
      objectId: 'match-1',
      clubId: '500554',
      playerId: 'member-1',
    );

    expect(notification.toMap()[keyNotifBrand], kNotificationBrandGrinta);
    expect(notification.toMap()[keyNotifApp], kNotificationBrandGrinta);
  });

  test('explicit brand is preserved when set', () {
    final notification = NotificationApp(
      userId: 'uid-1',
      type: NotifType.event,
      sendBy: SendBy.notification,
      brand: 'aserstein',
    );

    expect(notification.toMap()[keyNotifBrand], 'aserstein');
  });

  test('Grinta writes go to grinta_notification, not the shared collection', () {
    expect(NotificationService.collectionName, 'grinta_notification');
    expect(NotificationService.legacyCollectionName, 'notification');
    expect(FcmConfig.pushCallable, 'sendGrintaPushFCMNotification');
  });
}
