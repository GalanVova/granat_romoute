import Foundation
import BackgroundTasks
import UserNotifications

// MARK: - Background schedule executor
// Uses BGProcessingTask — iOS runs it at or just after earliestBeginDate
// when the device has network. Works without any user interaction.

actor BackgroundScheduleRunner {
    static let shared = BackgroundScheduleRunner()
    static let taskID = "com.granat.remote.schedule"

    // MARK: - Registration (call once at app launch)

    nonisolated func registerTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskID, using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else { return }
            Task {
                await BackgroundScheduleRunner.shared.handle(task: processingTask)
            }
        }
    }

    // MARK: - Schedule the next BGProcessingTask run

    nonisolated func scheduleNextIfNeeded() {
        let rules = ScheduleStore.shared.rules
        guard !rules.isEmpty else { return }

        // Find the earliest upcoming fire date across all rules
        let next = rules.compactMap { nextFireDate(for: $0) }.min()
        guard let fireAt = next else { return }

        // Cancel any previously queued task
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskID)

        let request = BGProcessingTaskRequest(identifier: Self.taskID)
        request.earliestBeginDate    = fireAt
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower       = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Silently ignore — happens in simulator
        }
    }

    // MARK: - Task handler

    private func handle(task: BGProcessingTask) async {
        task.expirationHandler = { task.setTaskCompleted(success: false) }

        let store    = ScheduleStore.shared
        let rules    = store.rules
        let now      = Date()
        let window: TimeInterval = 20 * 60  // fire if we're within 20 min of scheduled time

        var executedAny = false

        for rule in rules {
            guard shouldFire(rule: rule, near: now, window: window) else { continue }
            guard !alreadyFiredToday(rule: rule) else { continue }

            let success = await execute(rule: rule)
            if success {
                markFiredToday(rule: rule)
                executedAny = true
                await showConfirmationNotification(rule: rule)
            }
        }

        // Schedule next run
        BackgroundScheduleRunner.shared.scheduleNextIfNeeded()
        task.setTaskCompleted(success: executedAny)
    }

    // MARK: - Execute one rule via WAMP

    private func execute(rule: ScheduleRule) async -> Bool {
        // Load saved credentials
        guard
            let login    = UserDefaults.standard.string(forKey: "saved_login"),
            let password = UserDefaults.standard.string(forKey: "saved_password"),
            let pcnId    = UserDefaults.standard.string(forKey: "saved_pcn_id"),
            let pcn      = demoPCNs.first(where: { $0.id == pcnId }) ?? demoPCNs.first
        else { return false }

        let uri = URL(string: "ws://\(pcn.host):\(pcn.port)/")!
        let client = WampV1Client(uri: uri)

        do {
            try await client.connect()
            let api = LunAPI(client: client)
            _ = try await api.signupRaw(login: login, password: password)

            let cmd = wampCmd(for: rule.action)

            if let gid = rule.panelGroupId {
                // Specific panel group — extract panelId / group from composite id
                let parts = gid.split(separator: "/", maxSplits: 1)
                if parts.count == 2, let grp = Int(parts[1]) {
                    try await api.remoteControl(cmd: cmd, panel: String(parts[0]), group: grp)
                }
            } else {
                // All panels
                let groups = try await api.getPanelGroups()
                for g in groups {
                    try await api.remoteControl(cmd: cmd, panel: g.panelId, group: g.group)
                }
            }

            await client.close()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Helpers

    nonisolated func nextFireDate(for rule: ScheduleRule) -> Date? {
        let cal       = Calendar.current
        let now       = Date()
        let weekdays  = rule.days.map { $0.calendarValue }

        for daysAhead in 0...7 {
            guard let candidate = cal.date(byAdding: .day, value: daysAhead, to: now) else { continue }
            let weekday = cal.component(.weekday, from: candidate)
            guard weekdays.contains(weekday) else { continue }

            guard let fireDate = cal.date(bySettingHour: rule.hour, minute: rule.minute,
                                          second: 0, of: candidate) else { continue }
            if fireDate > now { return fireDate }
        }
        return nil
    }

    private func shouldFire(rule: ScheduleRule, near now: Date, window: TimeInterval) -> Bool {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: now)
        guard rule.days.map({ $0.calendarValue }).contains(weekday) else { return false }

        guard let scheduled = cal.date(bySettingHour: rule.hour, minute: rule.minute,
                                       second: 0, of: now) else { return false }

        let diff = now.timeIntervalSince(scheduled)
        return diff >= 0 && diff <= window
    }

    // MARK: - Fired-today tracking

    private func firedKey(for rule: ScheduleRule) -> String {
        let cal = Calendar.current
        let day = cal.component(.day, from: Date())
        let month = cal.component(.month, from: Date())
        return "sched_fired_\(rule.id)_\(month)_\(day)"
    }

    private func alreadyFiredToday(rule: ScheduleRule) -> Bool {
        UserDefaults.standard.bool(forKey: firedKey(for: rule))
    }

    private func markFiredToday(rule: ScheduleRule) {
        UserDefaults.standard.set(true, forKey: firedKey(for: rule))
    }

    // MARK: - Confirmation notification

    private func showConfirmationNotification(rule: ScheduleRule) async {
        let content = UNMutableNotificationContent()
        content.title = actionEmoji(rule.action) + " GRANAT — schedule executed"
        content.body  = "\(rule.timeString) • \(actionName(rule.action))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "sched_confirm_\(rule.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil   // deliver immediately
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func wampCmd(for action: ScheduleAction) -> Int {
        switch action {
        case .arm:     return 52
        case .disarm:  return 53
        case .armStay: return 55
        }
    }

    private func actionName(_ action: ScheduleAction) -> String {
        switch action {
        case .arm:     return "Armed"
        case .disarm:  return "Disarmed"
        case .armStay: return "Arm stay (home)"
        }
    }

    private func actionEmoji(_ action: ScheduleAction) -> String {
        switch action {
        case .arm:     return "🔒 "
        case .disarm:  return "🔓 "
        case .armStay: return "🏠 "
        }
    }
}
