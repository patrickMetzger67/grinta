/// Legal document URLs (App Store / Play Store compliance).
///
/// Prefer the Firebase Hosting URLs shipped with the web app (`web/privacy`,
/// `web/terms`). After `./deploy_web.sh grinta`, these pages are live at
/// https://grinta.web.app/privacy/ and https://grinta.web.app/terms/.
///
/// Optionally mirror the same content on Squarespace at
/// https://grinta.io/privacy and https://grinta.io/terms, then switch these
/// constants back to the marketing domain.
abstract final class LegalConfig {
  /// Public marketing / product website.
  static const String websiteUrl = 'https://www.grinta.io';

  /// Host shown in settings Infos (without scheme).
  static const String websiteDisplayHost = 'www.grinta.io';

  /// Support contact email shown in settings Infos.
  static const String supportEmail = 'info@grinta.io';

  /// Privacy policy (must stay publicly reachable for Play / App Store).
  static const String privacyPolicyUrl = 'https://grinta.web.app/privacy/';

  /// Terms of service / EULA link shown in-app and in store listings.
  static const String termsOfServiceUrl = 'https://grinta.web.app/terms/';
}
