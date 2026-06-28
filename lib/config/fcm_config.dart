/// Firebase Cloud Messaging configuration.
///
/// ## Web push (VAPID)
/// Web clients need a **Web Push certificate** public key before [FirebaseMessaging.getToken]
/// can return a token.
///
/// 1. Firebase Console → Project settings → Cloud Messaging → Web configuration
/// 2. Web Push certificates → Generate key pair (or use existing)
/// 3. Copy the **public** key into `dart_defines.json`:
///    `"FCM_WEB_VAPID_KEY": "B…your-public-key…"`
/// 4. Run/build web with `--dart-define-from-file=dart_defines.json`
///
/// The private key stays in Firebase; never commit it.
///
/// ## Dual branding (Grinta + Aserstein, shared `aserstein-2453e` project)
///
/// Grinta and Aserstein share the same Firebase project and `users/{uid}/fcmTokens`
/// collection. Each token document must include `app: "grinta"` or `app: "aserstein"`
/// so sends only target the correct app (see [NotificationFCMService.saveTokenToFirestore]).
/// Grinta reads tokens with a strict `app == grinta` filter; legacy documents without
/// `app` are ignored until the user opens Grinta again and the token is re-registered.
///
/// Push icons must be chosen per app. The Cloud Function `sendPushFCMNotification`
/// (region `europe-west1`, not in this repo) should accept a `brand` field:
///
/// ```json
/// {
///   "title": "…",
///   "body": "…",
///   "fcmTokens": ["…"],
///   "type": "convocation",
///   "payload": { "id": "…" },
///   "clubId": "…",
///   "brand": "grinta"
/// }
/// ```
///
/// Recommended server-side icon/image URLs (host on Firebase Storage or CDN):
///
/// | `brand`     | `data.icon` (small)              | `notification.image` (large, optional) |
/// |-------------|----------------------------------|----------------------------------------|
/// | `grinta`    | `https://…/grinta-icon-192.png`  | `https://…/grinta-icon-512.png`        |
/// | `aserstein` | `https://…/aserstein-icon.png`   | `https://…/aserstein-banner.png`       |
///
/// - **Android**: system tray icon comes from the app manifest
///   (`@drawable/ic_notification`); `notification.image` is the expanded large icon.
/// - **Web**: service worker uses `data.icon`, then falls back to [kFcmGrintaWebIconPath].
///   Do not rely on `/favicon.png` (legacy Aserstein asset).
/// - **iOS**: uses the app icon from Xcode; no per-push small icon override.
library;

/// Public VAPID key for FCM on Flutter web (`--dart-define=FCM_WEB_VAPID_KEY=…`).
const String kFcmWebVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');

/// Whether web token registration can run (VAPID key provided at build time).
bool get fcmWebVapidKeyConfigured => kFcmWebVapidKey.isNotEmpty;

/// Grinta FCM constants (this app always sends [FcmConfig.brandGrinta]).
abstract final class FcmConfig {
  static const String brandGrinta = 'grinta';
}

/// Default push brand for Grinta clients calling `sendPushFCMNotification`.
const String kFcmDefaultBrand = FcmConfig.brandGrinta;

/// Relative path to the Grinta PWA icon (see `web/icons/Icon-192.png`).
const String kFcmGrintaWebIconPath = '/icons/Icon-192.png';

/// Android drawable resource for foreground/local notification small icon.
const String kFcmAndroidNotificationIcon = '@drawable/ic_notification';
