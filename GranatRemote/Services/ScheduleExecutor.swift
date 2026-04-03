import Foundation
import UserNotifications

// MARK: - Executes a scheduled WAMP command after notification tap

@MainActor
class ScheduleExecutor: ObservableObject {
    static let shared = ScheduleExecutor()

    @Published var lastResult: String?

    /// Called from AppDelegate / scene when user taps "Execute" on a schedule notification.
    func execute(userInfo: [AnyHashable: Any], appState: AppState) async {
        guard
            let actionRaw  = userInfo[NotifPayload.action] as? String,
            let action     = ScheduleAction(rawValue: actionRaw)
        else { return }

        let panelGroupId = userInfo[NotifPayload.panelGroupId] as? String ?? ""

        // Ensure we have an active API connection
        let api: LunAPI
        if let existing = appState.api {
            api = existing
        } else {
            // Reconnect
            guard let session = appState.session else { return }
            let uri = URL(string: "ws://\(session.host):\(session.port)/")!
            let client = WampV1Client(uri: uri)
            do {
                try await client.connect()
                let a = LunAPI(client: client)
                _ = try await a.signupRaw(login: session.login, password: session.password)
                appState.api = a
                api = a
            } catch {
                lastResult = "Connection failed: \(error.localizedDescription)"
                return
            }
        }

        let cmd = wampCmd(for: action)

        // Determine target groups
        let targetGroups: [PanelGroup]
        if panelGroupId.isEmpty {
            // All panels — need to fetch if not loaded
            if appState.session != nil {
                do {
                    let fetched = try await api.getPanelGroups()
                    targetGroups = fetched
                } catch {
                    lastResult = "Failed to fetch groups: \(error.localizedDescription)"
                    return
                }
            } else {
                return
            }
        } else {
            // Split "panelId/group" composite id
            let parts = panelGroupId.split(separator: "/", maxSplits: 1)
            guard parts.count == 2,
                  let grp = Int(parts[1]) else { return }
            let pid = String(parts[0])
            // Create a lightweight stub — remoteControl only needs panelId + group
            let stub = PanelGroup(id: panelGroupId, panelId: pid, group: grp, name: "", address: nil, state: nil)
            targetGroups = [stub]
        }

        var errors: [String] = []
        for group in targetGroups {
            do {
                try await api.remoteControl(cmd: cmd, panel: group.panelId, group: group.group)
            } catch {
                errors.append("\(group.panelId): \(error.localizedDescription)")
            }
        }

        lastResult = errors.isEmpty ? "Done" : errors.joined(separator: "\n")
    }

    private func wampCmd(for action: ScheduleAction) -> Int {
        switch action {
        case .arm:     return 52
        case .disarm:  return 53
        case .armStay: return 55
        }
    }
}
