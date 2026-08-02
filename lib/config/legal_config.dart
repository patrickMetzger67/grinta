/// Legal document URLs (App Store / Play Store compliance).
abstract final class LegalConfig {
  /// Public marketing / product website.
  static const String websiteUrl = 'https://www.grinta.io';

  /// Host shown in settings Infos (without scheme).
  static const String websiteDisplayHost = 'www.grinta.io';

  /// Support contact email shown in settings Infos.
  static const String supportEmail = 'info@grinta.io';

  /// Privacy policy on grinta.io — verify page is live before store submission.
  static const String privacyPolicyUrl = 'https://grinta.io/privacy';

  /// Terms of service — TODO: confirm URL when page is published on grinta.io.
  static const String termsOfServiceUrl = 'https://grinta.io/terms';
}
