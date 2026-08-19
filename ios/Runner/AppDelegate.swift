import Flutter
import GoogleMaps
import UIKit
import UserNotifications
import app_links

#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private func provideGoogleMapsApiKey() {
    let fromPlist = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String
    let fromEnv = ProcessInfo.processInfo.environment["GMS_API_KEY"]
    let apiKey = [fromPlist, fromEnv].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .first { !$0.isEmpty }

    guard let apiKey else {
      NSLog("Grinta: GMSApiKey manquant dans Info.plist — Google Maps plantera à l’ouverture.")
      return
    }

    GMSServices.provideAPIKey(apiKey)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Doit être appelé avant super (cf. exemple google_maps_flutter_ios).
    provideGoogleMapsApiKey()
    UNUserNotificationCenter.current().delegate = self
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    application.registerForRemoteNotifications()
    // Cold-start custom scheme / universal link (required for app_links).
    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      AppLinks.shared.handleLink(url: url)
    }
    return result
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    #if canImport(FirebaseMessaging)
    Messaging.messaging().apnsToken = deviceToken
    #endif
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Show every remote notification (convocation, RPE, invite, chat…) while the
  // app is in the foreground. Closed-app delivery uses the APNs alert payload.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    #if canImport(FirebaseMessaging)
    Messaging.messaging().appDidReceiveMessage(notification.request.content.userInfo)
    #endif
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    #if canImport(FirebaseMessaging)
    Messaging.messaging().appDidReceiveMessage(response.notification.request.content.userInfo)
    #endif
    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    PlayerDetectionChannel.register(
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
  }
}
