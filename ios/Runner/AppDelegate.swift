import Flutter
import GoogleMaps
import UIKit
import UserNotifications
import Vision
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
    // Force FCM token generation as soon as APNs arrives (UIScene often
    // delivers the APNs token after Flutter's first getToken() attempt).
    Messaging.messaging().token { token, error in
      if let error {
        NSLog("Grinta: FCM token after APNs failed: \(error.localizedDescription)")
      } else if token != nil {
        NSLog("Grinta: FCM token ready after APNs")
      }
    }
    #endif
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("Grinta: APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
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

/// Vision person detection for Flutter (`io.grinta.app/player_detection`).
/// Kept in this file so Xcode always compiles it with the Runner target.
enum PlayerDetectionChannel {
  static let name = "io.grinta.app/player_detection"

  static func register(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "detectPeople" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let typed = args["bytes"] as? FlutterStandardTypedData
      else {
        result(FlutterError(code: "bad_args", message: "bytes required", details: nil))
        return
      }

      DispatchQueue.global(qos: .userInitiated).async {
        let boxes = detectPeople(in: typed.data)
        DispatchQueue.main.async {
          result(boxes)
        }
      }
    }
  }

  private static func detectPeople(in data: Data) -> [[String: Double]] {
    guard let image = UIImage(data: data), let cgImage = image.cgImage else {
      return []
    }

    let request = VNDetectHumanRectanglesRequest()
    if #available(iOS 15.0, *) {
      request.upperBodyOnly = false
    }
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
    do {
      try handler.perform([request])
    } catch {
      return []
    }

    let observations = request.results ?? []
    return observations.compactMap { observation in
      let box = observation.boundingBox
      let height = Double(box.height)
      let width = Double(box.width)
      if width <= 0 || height <= 0 { return nil }
      return [
        "left": Double(box.origin.x),
        "top": 1.0 - Double(box.origin.y) - height,
        "width": width,
        "height": height,
        "score": Double(observation.confidence),
      ]
    }
  }
}
