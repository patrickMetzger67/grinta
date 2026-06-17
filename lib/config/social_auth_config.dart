/// Configuration des fournisseurs d'authentification sociale (projet Firebase
/// `aserstein-2453e`).
///
/// Identifiants natifs Grinta :
/// - iOS / macOS : `io.grinta.app` (GoogleService-Info.plist)
/// - Android : `io.grinta.app` (google-services.json)
///
/// Renseignez [facebookAppId] avec l'identifiant de votre application Meta
/// (developers.facebook.com) et activez le fournisseur Facebook dans Firebase Auth.
class SocialAuthConfig {
  SocialAuthConfig._();

  static const String firebaseProjectId = 'aserstein-2453e';

  static const String bundleId = 'io.grinta.app';

  /// Client OAuth Web (type 3) — utilisé pour le web et comme serverClientId Android.
  static const String webGoogleClientId =
      '626293600533-f0b98hpalojmvalqgjuam24jjbsa43o4.apps.googleusercontent.com';

  /// Client OAuth iOS (`io.grinta.app`) — lu nativement via GoogleService-Info.plist
  /// et GIDClientID dans Info.plist ; documenté ici pour référence.
  static const String iosGoogleClientId =
      '626293600533-mo43u2rcr958qudvq7gfgn578pua44j3.apps.googleusercontent.com';

  /// Identifiant de l'application Meta / Facebook.
  /// Laisser vide tant que l'app Meta n'est pas configurée.
  static const String facebookAppId = '';

  static const String facebookDisplayName = 'Grinta';
}
