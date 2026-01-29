import Flutter
import UIKit
import ActivityKit
import UserNotifications
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var liveActivityManager: Any?
  private var fallbackChannel: FlutterMethodChannel?
  private var deviceTokenString: String?
  private var notificationChannel: FlutterMethodChannel?
  private var backgroundFetchChannel: FlutterMethodChannel?
  private var widgetDeepLinkChannel: FlutterMethodChannel?
  private var pendingWidgetDeepLink: String?

  private let backgroundTaskIdentifier = "app.firka.timetable.refresh"
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController

    HomeWidgetMethodChannel.register(with: controller.binaryMessenger)

    widgetDeepLinkChannel = FlutterMethodChannel(name: "firka.app/widget_deep_link", binaryMessenger: controller.binaryMessenger)
    widgetDeepLinkChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getPendingDeepLink" {
        if let controlNav = UserDefaults(suiteName: "group.app.firka.firkaa")?.string(forKey: "controlNavigation") {
          UserDefaults(suiteName: "group.app.firka.firkaa")?.removeObject(forKey: "controlNavigation")
          result(controlNav)
        } else if let link = self?.pendingWidgetDeepLink {
          self?.pendingWidgetDeepLink = nil
          result(link)
        } else {
          result(nil)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    backgroundFetchChannel = FlutterMethodChannel(name: "firka.app/background_fetch", binaryMessenger: controller.binaryMessenger)

    backgroundFetchChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
        return
      }

      if #available(iOS 13.0, *) {
        switch call.method {
        case "scheduleBackgroundFetch":
          self.scheduleBackgroundRefresh()
          result(true)
        case "cancelBackgroundFetch":
          BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: self.backgroundTaskIdentifier)
          print("[AppDelegate] Background fetch cancelled from Flutter")
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      } else {
        result(FlutterError(code: "UNAVAILABLE", message: "Background fetch requires iOS 13+", details: nil))
      }
    }

    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
        self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
      }
    }

    notificationChannel = FlutterMethodChannel(name: "firka.app/notifications", binaryMessenger: controller.binaryMessenger)
    
    UNUserNotificationCenter.current().delegate = self
    
    if #available(iOS 16.2, *) {
      liveActivityManager = LiveActivityMethodChannelManager(controller: controller)
    } else {
      let channel = FlutterMethodChannel(name: "firka.app/live_activity", binaryMessenger: controller.binaryMessenger)
      self.fallbackChannel = channel
      channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "registerForPushNotifications":
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
              DispatchQueue.main.async {
                application.registerForRemoteNotifications()
              }
              result(self?.deviceTokenString)
            } else {
              result(FlutterError(code: "PERMISSION_DENIED", message: "Push notification permission denied", details: error?.localizedDescription))
            }
          }
        case "getDeviceToken":
          if let token = self?.deviceTokenString {
            result(token)
          } else {
            result(FlutterError(code: "NO_TOKEN", message: "Device token not available", details: nil))
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if granted {
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    self.deviceTokenString = tokenString
    if #available(iOS 16.2, *) {
      (liveActivityManager as? LiveActivityMethodChannelManager)?.setDeviceToken(tokenString)
    }
  }
  
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error)")
  }
  

  override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo

    UIApplication.shared.applicationIconBadgeNumber = 0

    var action = userInfo["action"] as? String
    if action == nil, let aps = userInfo["aps"] as? [String: Any] {
      action = aps["action"] as? String
    }

    if let action = action {
      notificationChannel?.invokeMethod("onNotificationTapped", arguments: [
        "action": action,
        "data": userInfo
      ])
    } else if let route = userInfo["route"] as? String {
      notificationChannel?.invokeMethod("onNotificationTapped", arguments: [
        "route": route,
        "action": userInfo["action"] as? String ?? "",
        "data": userInfo
      ])
    }

    completionHandler()
  }
  
  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if let aps = userInfo["aps"] as? [AnyHashable: Any] {
      if let contentState = aps["content-state"] {
        if let contentStateDict = contentState as? [AnyHashable: Any] {
          // iOS automatically handles the Live Activity update
        }
      }
    }

    completionHandler(.newData)
  }

  // MARK: - Background Refresh

  @available(iOS 13.0, *)
  private func handleBackgroundRefresh(task: BGAppRefreshTask) {
    scheduleBackgroundRefresh()

    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1

    let operation = BlockOperation {
      DispatchQueue.main.async {
        self.backgroundFetchChannel?.invokeMethod("performBackgroundFetch", arguments: nil) { result in
          if let success = result as? Bool, success {
            task.setTaskCompleted(success: true)
          } else {
            task.setTaskCompleted(success: false)
          }
        }
      }
    }

    task.expirationHandler = {
      queue.cancelAllOperations()
      task.setTaskCompleted(success: false)
    }

    queue.addOperation(operation)
  }

  @available(iOS 13.0, *)
  func scheduleBackgroundRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)

    // IMPORTANT: iOS may delay this based on system conditions and user behavior
    // The default setting is 30 minutes
    request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)

    do {
      try BGTaskScheduler.shared.submit(request)
      print("[AppDelegate] Background refresh scheduled for ~30 minutes from now")
    } catch {
      print("[AppDelegate] Could not schedule background refresh: \(error)")
    }
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    // Background fetch will be scheduled from Flutter side when needed
    // No automatic scheduling here to give Flutter full control
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if url.scheme == "firka" && url.host == "widget" {
      let path = url.path.replacingOccurrences(of: "/", with: "")
      pendingWidgetDeepLink = path
      widgetDeepLinkChannel?.invokeMethod("onWidgetDeepLink", arguments: path)
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
