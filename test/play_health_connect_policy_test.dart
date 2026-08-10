import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/config/legal_config.dart';
import 'package:grinta/model/google_health_sync_config.dart';

void main() {
  test('LegalConfig privacy/terms URLs are https and non-empty', () {
    expect(LegalConfig.privacyPolicyUrl.startsWith('https://'), isTrue);
    expect(LegalConfig.termsOfServiceUrl.startsWith('https://'), isTrue);
    expect(LegalConfig.privacyPolicyUrl.contains('privacy'), isTrue);
    expect(LegalConfig.termsOfServiceUrl.contains('terms'), isTrue);
  });

  test('Google Health coach visibility omits sleep from UI keys', () {
    expect(GoogleHealthCoachVisibility.metricKeys, isNot(contains('sleep')));
    expect(
      GoogleHealthCoachVisibility.metricKeys,
      containsAll(['activity', 'heartrate', 'activeEnergy']),
    );
  });
}
