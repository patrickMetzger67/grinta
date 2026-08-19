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

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    PlayerDetectionChannel.register(
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
  }
}
