import ActivityKit
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var liveActivityManager: Any?
  private var fallbackChannel: FlutterMethodChannel?
  private var deviceTokenString: String?
  private var notificationChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController

    notificationChannel = FlutterMethodChannel(
      name: "firka.app/notifications",
      binaryMessenger: controller.binaryMessenger
    )

    UNUserNotificationCenter.current().delegate = self

    if #available(iOS 16.2, *) {
      liveActivityManager = LiveActivityMethodChannelManager(controller: controller)
    } else {
      let channel = FlutterMethodChannel(
        name: "firka.app/live_activity",
        binaryMessenger: controller.binaryMessenger
      )
      self.fallbackChannel = channel

      channel.setMethodCallHandler {
        [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "registerForPushNotifications":
          UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
              if granted {
                DispatchQueue.main.async {
                  application.registerForRemoteNotifications()
                }
                result(self?.deviceTokenString)
              } else {
                result(
                  FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Push notification permission denied",
                    details: error?.localizedDescription
                  ))
              }
            }

        case "getDeviceToken":
          if let token = self?.deviceTokenString {
            result(token)
          } else {
            result(
              FlutterError(
                code: "NO_TOKEN",
                message: "Device token not available",
                details: nil
              ))
          }

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if granted {
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
          }
        } else if let error = error {
          print("Push authorization error: \(error)")
        }
      }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    self.deviceTokenString = tokenString
    print("APNs device token: \(tokenString)")

    if #available(iOS 16.2, *) {
      (liveActivityManager as? LiveActivityMethodChannelManager)?
        .setDeviceToken(tokenString)
    }
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error)")
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo

    UIApplication.shared.applicationIconBadgeNumber = 0

    var action = userInfo["action"] as? String
    if action == nil, let aps = userInfo["aps"] as? [String: Any] {
      action = aps["action"] as? String
    }

    if let action = action {
      notificationChannel?.invokeMethod(
        "onNotificationTapped",
        arguments: [
          "action": action,
          "data": userInfo,
        ])
    } else if let route = userInfo["route"] as? String {
      notificationChannel?.invokeMethod(
        "onNotificationTapped",
        arguments: [
          "route": route,
          "action": userInfo["action"] as? String ?? "",
          "data": userInfo,
        ])
    }

    completionHandler()
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if let aps = userInfo["aps"] as? [AnyHashable: Any] {
      if aps["content-state"] as? [AnyHashable: Any] != nil {
      }
    }

    completionHandler(.newData)
  }
}