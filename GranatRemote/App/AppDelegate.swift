import UIKit
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /// Weak ref to AppState so the notification delegate can reach it.
    @MainActor static weak var appState: AppState?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Register background processing task
        BackgroundScheduleRunner.shared.registerTask()

        // Register notification categories (for manual-confirm path, kept as fallback UI)
        ScheduleNotificationManager.shared.registerCategories()

        return true
    }

    // MARK: - Show banner even when app is in the foreground

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Handle notification taps

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        // Fire on banner tap (default) OR explicit "Execute" button
        let isExecute = response.actionIdentifier == NotifAction.execute.rawValue
            || response.actionIdentifier == UNNotificationDefaultActionIdentifier
        guard isExecute else { return }   // "Skip" dismissal — do nothing
        let userInfo = response.notification.request.content.userInfo
        guard userInfo[NotifPayload.action] != nil else { return }  // not a schedule notification
        Task {
            await ScheduleExecutor.shared.execute(userInfo: userInfo)
        }
    }
}
