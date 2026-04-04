import Foundation
import UserNotifications

// MARK: - Notification categories & actions

enum NotifCategory: String {
    case scheduleArm     = "SCHED_ARM"
    case scheduleDisarm  = "SCHED_DISARM"
    case scheduleArmStay = "SCHED_ARM_STAY"
}

enum NotifAction: String {
    case execute = "EXECUTE"
    case dismiss = "DISMISS"
}

// MARK: - Payload keys

struct NotifPayload {
    static let ruleId       = "rule_id"
    static let action       = "sched_action"
    static let panelGroupId = "panel_group_id"   // nil → all panels
}

// MARK: - Manager

class ScheduleNotificationManager {
    static let shared = ScheduleNotificationManager()

    private let center = UNUserNotificationCenter.current()

    // MARK: Setup

    func registerCategories() {
        let execAction = UNNotificationAction(
            identifier: NotifAction.execute.rawValue,
            title: "Execute",
            options: [.foreground]          // opens the app to execute
        )
        let dismissAction = UNNotificationAction(
            identifier: NotifAction.dismiss.rawValue,
            title: "Skip",
            options: [.destructive]
        )

        let categories: [UNNotificationCategory] = [
            NotifCategory.scheduleArm, .scheduleDisarm, .scheduleArmStay
        ].map { cat in
            UNNotificationCategory(
                identifier: cat.rawValue,
                actions: [execAction, dismissAction],
                intentIdentifiers: [],
                options: []
            )
        }
        center.setNotificationCategories(Set(categories))
    }

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    // MARK: Schedule all rules

    func rescheduleAll(rules: [ScheduleRule]) {
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let schedIds = pending.filter { $0.identifier.hasPrefix("sched_") }.map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: schedIds)
            for rule in rules { self.schedule(rule: rule) }
        }
    }

    // MARK: Schedule one rule (one notification per weekday)

    private func schedule(rule: ScheduleRule) {
        let title      = actionTitle(rule.action)
        let body       = rule.panelGroupId != nil ? "GRANAT" : "GRANAT — all objects"
        let categoryId = category(for: rule.action).rawValue

        for day in rule.days {
            let requestId = "sched_\(rule.id)_\(day.rawValue)"

            var comps     = DateComponents()
            comps.hour    = rule.hour
            comps.minute  = rule.minute
            comps.second  = 0
            comps.weekday = day.calendarValue   // 1=Sun … 7=Sat

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

            let content = UNMutableNotificationContent()
            content.title              = title
            content.body               = body
            content.sound              = .default
            content.categoryIdentifier = categoryId
            content.userInfo = [
                NotifPayload.ruleId:       rule.id,
                NotifPayload.action:       rule.action.rawValue,
                NotifPayload.panelGroupId: rule.panelGroupId ?? "",
            ]

            let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
            center.add(request) { _ in }
        }
    }

    func removeRule(id: String) {
        center.getPendingNotificationRequests { [weak self] pending in
            let toRemove = pending
                .filter { $0.identifier.hasPrefix("sched_\(id)_") }
                .map { $0.identifier }
            self?.center.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
    }

    // MARK: Helpers

    private func actionTitle(_ action: ScheduleAction) -> String {
        switch action {
        case .arm:     return "🔒 Arm — scheduled"
        case .disarm:  return "🔓 Disarm — scheduled"
        case .armStay: return "🏠 Arm stay — scheduled"
        }
    }

    private func category(for action: ScheduleAction) -> NotifCategory {
        switch action {
        case .arm:     return .scheduleArm
        case .disarm:  return .scheduleDisarm
        case .armStay: return .scheduleArmStay
        }
    }
}
