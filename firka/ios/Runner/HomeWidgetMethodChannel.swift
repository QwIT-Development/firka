import Flutter
import WidgetKit

class HomeWidgetMethodChannel {
    static let channelName = "app.firka/home_widgets"

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "getAppGroupDirectory":
                if let containerURL = FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: "group.app.firka.firka"
                ) {
                    result(containerURL.path)
                } else {
                    result(FlutterError(code: "NO_APP_GROUP", message: "App Group not available", details: nil))
                }

            case "reloadAllWidgets":
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                    result(nil)
                } else {
                    result(FlutterError(code: "UNSUPPORTED", message: "Widgets require iOS 14+", details: nil))
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
