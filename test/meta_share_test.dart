import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/meta_sync_config.dart';

void main() {
  group('MetaSyncConfig', () {
    test('canPublish only when connected with IG or FB Page', () {
      expect(
        const MetaSyncConfig(connected: true, hasInstagram: true).canPublish,
        isTrue,
      );
      expect(
        const MetaSyncConfig(connected: true, hasFacebookPage: true).canPublish,
        isTrue,
      );
      expect(
        const MetaSyncConfig(connected: false, hasInstagram: true).canPublish,
        isFalse,
      );
      expect(const MetaSyncConfig(connected: true).canPublish, isFalse);
    });

    test('fromMap reads client metadata without tokens', () {
      final config = MetaSyncConfig.fromMap(<String, dynamic>{
        'connected': true,
        'pageName': 'Grinta FC',
        'instagramUsername': 'grinta',
        'hasInstagram': true,
        'hasFacebookPage': true,
      });
      expect(config.connected, isTrue);
      expect(config.pageName, 'Grinta FC');
      expect(config.instagramUsername, 'grinta');
      expect(config.canPublish, isTrue);
    });
  });
}
