import Foundation
import ActivityKit

@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    func startActivity(id: String, title: String, progress: Int, emoji: String) -> String? {
        let attributes = FirkaActivityAttributes(id: id)
        let state = FirkaActivityAttributes.ContentState(title: title, progress: progress, emoji: emoji)

        do {
            let activity = try Activity<FirkaActivityAttributes>.request(
                attributes: attributes,
                contentState: state,
                pushType: nil)
            return activity.id
        } catch (let error) {
            print("Error starting activity: \(error.localizedDescription)")
            return nil
        }
    }

    func updateActivity(id: String, title: String?, progress: Int?, emoji: String?) {
        Task {
            for activity in Activity<FirkaActivityAttributes>.activities {
                if activity.attributes.id == id {
                    var state = activity.contentState
                    if let title = title { state.title = title }
                    if let progress = progress { state.progress = progress }
                    if let emoji = emoji { state.emoji = emoji }
                    await activity.update(using: state)
                }
            }
        }
    }

    func endActivity(id: String) {
        Task {
            for activity in Activity<FirkaActivityAttributes>.activities {
                if activity.attributes.id == id {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }
    }
}