import Flutter
import PushKit
import UIKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    configureVoIPPush()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
      callData.extra = extra
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
