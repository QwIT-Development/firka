import Flutter
import ActivityKit
import Foundation

@available(iOS 16.2, *)
class LiveActivityMethodChannelManager: NSObject {
    private let channel: FlutterMethodChannel
    private var deviceToken: String?
    
    init(controller: FlutterViewController) {
        self.channel = FlutterMethodChannel(
            name: "firka.app/live_activity",
            binaryMessenger: controller.binaryMessenger
        )
        
        super.init()
        
        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handleMethodCall(call, result: result)
        }
    }
    
    func setDeviceToken(_ token: String) {
        self.deviceToken = token
    }
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(result: result)
            
        case "getDeviceToken":
            getDeviceToken(result: result)
            
        case "registerForPushNotifications":
            registerForPushNotifications(result: result)
            
        case "startActivity":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            startActivity(args: args, result: result)
            
        case "updateActivity":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            updateActivity(args: args, result: result)
            
        case "endActivity":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            endActivity(args: args, result: result)
            
        case "getActiveActivities":
            getActiveActivities(result: result)
            
        case "endAllActivities":
            endAllActivities(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize(result: @escaping FlutterResult) {
        if #available(iOS 16.2, *) {
            if ActivityAuthorizationInfo().areActivitiesEnabled {
                result(true)
            } else {
                result(FlutterError(
                    code: "NOT_SUPPORTED",
                    message: "Live Activities are not enabled on this device",
                    details: nil
                ))
            }
        } else {
            result(FlutterError(
                code: "NOT_SUPPORTED",
                message: "Live Activities require iOS 16.2 or later",
                details: nil
            ))
        }
    }
    
    private func getDeviceToken(result: @escaping FlutterResult) {
        if let token = deviceToken {
            result(token)
        } else {
            result(FlutterError(
                code: "NO_TOKEN",
                message: "Device token not available",
                details: nil
            ))
        }
    }
    
    private func registerForPushNotifications(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    if let token = self?.deviceToken {
                        result(token)
                    } else {
                        result(FlutterError(
                            code: "NO_TOKEN",
                            message: "Failed to get device token",
                            details: nil
                        ))
                    }
                }
            } else {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Push notification permission denied",
                    details: error?.localizedDescription
                ))
            }
        }
    }
    
    private func startActivity(args: [String: Any], result: @escaping FlutterResult) {
        guard let attributesJson = args["attributes"] as? String,
              let contentStateJson = args["contentState"] as? String,
              let attributesData = attributesJson.data(using: .utf8),
              let contentStateData = contentStateJson.data(using: .utf8) else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for startActivity", details: nil))
            return
        }

        Task {
            do {
                let attributes = try JSONDecoder().decode([String: String].self, from: attributesData)
                let contentState = try JSONDecoder().decode(TimetableActivityAttributes.ContentState.self, from: contentStateData)

                if let existingActivity = Activity<TimetableActivityAttributes>.activities.first {
                    await existingActivity.update(ActivityContent<TimetableActivityAttributes.ContentState>(state: contentState, staleDate: nil))
                    result(existingActivity.id)
                    return
                }

                guard let studentName = attributes["studentName"],
                      let schoolName = attributes["schoolName"] else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing student or school name", details: nil))
                    return
                }

                let activityAttributes = TimetableActivityAttributes(
                    studentName: studentName,
                    schoolName: schoolName
                )

                let newActivity = try Activity<TimetableActivityAttributes>.request(
                    attributes: activityAttributes,
                    content: .init(state: contentState, staleDate: nil),
                    pushType: .token
                )

                let activityId = newActivity.id

                Task {
                    for await pushToken in newActivity.pushTokenUpdates {
                        let token = pushToken.map { String(format: "%02x", $0) }.joined()
                        DispatchQueue.main.async { [weak self] in
                            self?.channel.invokeMethod("onPushTokenReceived", arguments: [
                                "activityId": activityId,
                                "pushToken": token
                            ])
                        }
                    }
                }
                result(activityId)
            } catch {
                result(FlutterError(
                    code: "START_FAILED",
                    message: "Failed to decode or start Live Activity: \(error.localizedDescription)",
                    details: nil
                ))
            }
        }
    }
    
    private func updateActivity(args: [String: Any], result: @escaping FlutterResult) {
        guard let activityId = args["activityId"] as? String,
              let contentStateJson = args["contentState"] as? String,
              let contentStateData = contentStateJson.data(using: .utf8) else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for updateActivity", details: nil))
            return
        }
        
        Task {
            guard let activity = Activity<TimetableActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
                result(FlutterError(code: "NOT_FOUND", message: "Activity with specified ID not found for update.", details: nil))
                return
            }
            
            do {
                let contentState = try JSONDecoder().decode(TimetableActivityAttributes.ContentState.self, from: contentStateData)
                await activity.update(ActivityContent<TimetableActivityAttributes.ContentState>(state: contentState, staleDate: nil))
                result(true)
            } catch {
                result(FlutterError(code: "UPDATE_FAILED", message: "Failed to decode or update Live Activity", details: error.localizedDescription))
            }
        }
    }
    
    private func endActivity(args: [String: Any], result: @escaping FlutterResult) {
        guard let activityId = args["activityId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for endActivity", details: nil))
            return
        }

        Task {
            guard let activity = Activity<TimetableActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
                result(true)
                return
            }
            await activity.end(nil, dismissalPolicy: .immediate)
            result(true)
        }
    }
    
    private func getActiveActivities(result: @escaping FlutterResult) {
        if #available(iOS 16.2, *) {
            let activityIds = Activity<TimetableActivityAttributes>.activities.map { $0.id }
            result(activityIds)
        } else {
            result([])
        }
    }

    private func endAllActivities(result: @escaping FlutterResult) {
        Task {
            let activities = Activity<TimetableActivityAttributes>.activities
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            result(true)
        }
    }
}