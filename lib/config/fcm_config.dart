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
/// (and ideally `packageName`) so sends only target the correct app
/// (see [NotificationFCMService.saveTokenToFirestore]).
/// Grinta collects `app == grinta` tokens and Grinta `packageName` docs.
/// Unbranded iOS/web tokens stay collectable only on Grinta-only accounts.
/// If the same uid also has an Aserstein-tagged token, unbranded leftovers
/// are skipped (they would show as AS Erstein). Naked unbranded Android
/// tokens are always skipped. `app: aserstein` and Aserstein packages are
/// always excluded.
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
/// | `brand`     | `data.icon` (small)                         | `notification.image` (large)                |
/// |-------------|---------------------------------------------|---------------------------------------------|
/// | `grinta`    | `https://grinta.web.app/icons/Icon-192.png` | `https://grinta.web.app/icons/Icon-512.png` |
/// | `aserstein` | Aserstein favicon / Storage asset           | same                                        |
///
/// Grinta always sends [FcmConfig.brandGrinta] with `clubId: "0"` (platform club).
/// The Cloud Function `sendPushFCMNotification` in `functions/send_push_fcm.js`
/// attaches Grinta icons when `brand == grinta` (or `clubId == "0"` if brand omitted).
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
  static const String brandAserstein = 'aserstein';

  /// Android / iOS application id for this app (APNs topic + token docs).
  static const String grintaPackageName = 'io.grinta.app';

  /// Legacy Aserstein Android package on the shared Firebase project.
  static const String asersteinAndroidPackage = 'com.tome4.asersteinv2';

  /// Absolute Grinta PWA icons used by the push Cloud Function / web SW.
  static const String icon192Url = 'https://grinta.web.app/icons/Icon-192.png';
  static const String icon512Url = 'https://grinta.web.app/icons/Icon-512.png';
}

/// Default push brand for Grinta clients calling `sendPushFCMNotification`.
const String kFcmDefaultBrand = FcmConfig.brandGrinta;

/// Relative path to the Grinta PWA icon (see `web/icons/Icon-192.png`).
const String kFcmGrintaWebIconPath = '/icons/Icon-192.png';

/// Absolute Grinta icon (web push / CF data.icon).
const String kFcmGrintaIconUrl = FcmConfig.icon192Url;

/// Absolute Grinta large image (CF notification.image).
const String kFcmGrintaImageUrl = FcmConfig.icon512Url;

/// Android drawable resource for foreground/local notification small icon.
const String kFcmAndroidNotificationIcon = '@drawable/ic_notification';
