import Firebase
import FirebaseMessaging
import Flutter
import PushKit
import UIKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, MessagingDelegate, FlutterImplicitEngineDelegate {
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    Messaging.messaging().delegate = self
    configureVoIPPush()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // UIScene lifecycle (iOS 27): implicit Flutter engine başlatıldığında plugin'leri
  // kaydet. GeneratedPluginRegistrant.register didFinishLaunchingWithOptions'tan
  // buraya taşındı; scene tabanlı yaşam döngüsünde doğru zamanlama budur.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // Required when FirebaseAppDelegateProxyEnabled = false
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Foundation.Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[FCM] Failed to register for remote notifications: \(error)")
  }

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }

  private func configureVoIPPush() {
    let registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate credentials: PKPushCredentials,
    for type: PKPushType
  ) {
    let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }

    var isCompleted = false
    let finish: () -> Void = {
      if isCompleted { return }
      isCompleted = true
      completion()
    }

    let raw = payload.dictionaryPayload
    let callKitId = (raw["callKitId"] as? String) ?? (raw["id"] as? String) ?? UUID().uuidString
    let callerName = (raw["callerDisplayName"] as? String) ??
      (raw["nameCaller"] as? String) ?? "Incoming Call"
    let callerHandle = (raw["callerId"] as? String) ?? (raw["handle"] as? String) ?? "unknown"

    let callData = flutter_callkit_incoming.Data(
      id: callKitId,
      nameCaller: callerName,
      handle: callerHandle,
      type: 0
    )

    var extra: [String: Any] = [:]
    if let callerId = raw["callerId"] { extra["callerId"] = callerId }
    if let callerDisplayName = raw["callerDisplayName"] { extra["callerDisplayName"] = callerDisplayName }
    if let callId = raw["callId"] { extra["callId"] = callId }
    if !extra.isEmpty {
      callData.extra = extra as NSDictionary
    }

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(
      callData,
      fromPushKit: true
    ) {
      finish()
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      finish()
    }
  }
}
