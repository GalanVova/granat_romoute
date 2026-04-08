import Foundation
import UserNotifications

// MARK: - Executes a scheduled WAMP command after notification tap
// Connects independently from saved credentials — works even if app was terminated.

actor ScheduleExecutor {
    static let shared = ScheduleExecutor()

    func execute(userInfo: [AnyHashable: Any]) async {
        NSLog("[ScheduleExecutor] execute called, userInfo=%@", "\(userInfo)")
        guard
            let actionRaw  = userInfo[NotifPayload.action] as? String,
            let action     = ScheduleAction(rawValue: actionRaw),
            let login      = UserDefaults.standard.string(forKey: "saved_login"),
            let password   = UserDefaults.standard.string(forKey: "saved_password"),
            let pcnId      = UserDefaults.standard.string(forKey: "saved_pcn_id")
        else {
            NSLog("[ScheduleExecutor] guard failed: action=%@ login=%@ pcnId=%@",
                  userInfo[NotifPayload.action] as? String ?? "nil",
                  UserDefaults.standard.string(forKey: "saved_login") ?? "nil",
                  UserDefaults.standard.string(forKey: "saved_pcn_id") ?? "nil")
            return
        }
        guard let pcn = demoPCNs.first(where: { $0.id == pcnId }) ?? demoPCNs.first
        else {
            NSLog("[ScheduleExecutor] no PCN found for id=%@", pcnId)
            return
        }

        let panelGroupId = userInfo[NotifPayload.panelGroupId] as? String ?? ""
        let uri = URL(string: "ws://\(pcn.host):\(pcn.port)/")!
        let client = WampV1Client(uri: uri)

        NSLog("[ScheduleExecutor] connecting to %@:%d as %@ action=%@", pcn.host, pcn.port, login, "\(action)")
        do {
            try await client.connect()
            let api = LunAPI(client: client)
            _ = try await api.signupRaw(login: login, password: password)
            NSLog("[ScheduleExecutor] signed in, sending command")

            let cmd = wampCmd(for: action)

            if panelGroupId.isEmpty {
                let groups = try await api.getPanelGroups()
                NSLog("[ScheduleExecutor] got %d groups, sending to all", groups.count)
                for g in groups {
                    try await api.remoteControl(cmd: cmd, panel: g.panelId, group: g.group)
                }
            } else {
                let parts = panelGroupId.split(separator: "/", maxSplits: 1)
                NSLog("[ScheduleExecutor] panelGroupId=%@ parts=%@", panelGroupId, "\(parts)")
                if parts.count == 2, let grp = Int(parts[1]) {
                    try await api.remoteControl(cmd: cmd, panel: String(parts[0]), group: grp)
                }
            }

            await client.close()
            await sendConfirmation(action: action)
            NSLog("[ScheduleExecutor] done, confirmation sent")
        } catch {
            NSLog("[ScheduleExecutor] error: %@", error.localizedDescription)
        }
    }

    private func sendConfirmation(action: ScheduleAction) async {
        let (icon, label): (String, String)
        switch action {
        case .arm:     (icon, label) = ("🔒", "Armed")
        case .disarm:  (icon, label) = ("🔓", "Disarmed")
        case .armStay: (icon, label) = ("🏠", "Arm stay")
        }
        let content = UNMutableNotificationContent()
        content.title = "\(icon) GRANAT — \(label)"
        content.body  = "Schedule executed"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "sched_done_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
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
}
