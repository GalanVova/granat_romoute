import Foundation
import CryptoKit

struct PanelEvent: Identifiable {
    let id: String
    let panelId: String
    let group: Int
    let text: String
    let time: String

    static func from(json: Any) -> PanelEvent? {
        guard let m = json as? [String: Any] else { return nil }
        let eid = "\(m["id"] ?? m["eid"] ?? UUID().uuidString)"
        let panelId = "\(m["pid"] ?? m["panel"] ?? m["pnl"] ?? "")"
        let gr = Int("\(m["gr"] ?? 0)") ?? 0
        let text = m["msg"] as? String ?? m["text"] as? String ?? m["nm"] as? String ?? m["dsc"] as? String ?? ""
        let time = m["time"] as? String ?? m["dt"] as? String ?? m["date"] as? String ?? ""
        guard !text.isEmpty else { return nil }
        return PanelEvent(id: eid, panelId: panelId, group: gr, text: text, time: time)
    }
}

class LunAPI {
    private let client: WampV1Client

    init(client: WampV1Client) {
        self.client = client
    }

    func generateNonce(login: String) async throws -> String {
        let res = try await client.call("GenerateNonce", args: [login])
        let m = try parseDict(res)
        if let nonce = m["nonce"] { return "\(nonce)" }
        if let inner = m["result"] as? [String: Any], let nonce = inner["nonce"] { return "\(nonce)" }
        throw WampError.missingField("nonce")
    }

    static func hmacSHA512Base64(password: String, nonce: String) -> String {
        let key = SymmetricKey(data: Data(password.utf8))
        let msg = Data((nonce + password).utf8)
        let mac = HMAC<SHA512>.authenticationCode(for: msg, using: key)
        return Data(mac).base64EncodedString()
    }

    func signup(login: String, password: String) async throws {
        _ = try await signupRaw(login: login, password: password)
    }

    func signupRaw(login: String, password: String) async throws -> Any? {
        let nonce = try await generateNonce(login: login)
        let p = Self.hmacSHA512Base64(password: password, nonce: nonce)
        return try await client.call("Signup", args: [login, p, "LunWeb", "", 1, "ru", "ios", "1.0"])
    }

    func getPanelGroups() async throws -> [PanelGroup] {
        let res = try await client.call("GetPanelGroups", args: [])
        let list = extractList(res)
        return deduplicatedGroups(list.compactMap { PanelGroup.from(json: $0) })
    }

    func parsePanelsFromSignup(_ res: Any?) -> [PanelGroup] {
        guard let m = try? parseDict(res),
              let panel = m["panel"] as? [Any] else { return [] }
        return deduplicatedGroups(panel.compactMap { PanelGroup.from(json: $0) })
    }

    private func deduplicatedGroups(_ groups: [PanelGroup]) -> [PanelGroup] {
        var seen = Set<String>()
        return groups.filter { seen.insert($0.id).inserted }
    }

    func getPanelState(panel: String, group: Int) async throws -> PanelState? {
        let res = try await client.call("GetPanelState", args: [panel, group])
        return PanelState.from(json: res)
    }

    func getBalanceRaw() async throws -> Any? {
        return try await client.call("GetBalance", args: [])
    }

    func remoteControl(cmd: Int, panel: String, group: Int, num: Int = 0) async throws {
        _ = try await client.call("RemoteControl", args: [cmd, panel, group, num])
    }

    func getBalance() async throws -> String {
        let res = try await getBalanceRaw()
        func extractFromDict(_ m: [String: Any]) throws -> String? {
            if let err = m["error"] as? String { throw WampError.callError(err) }
            // bal is an array of account objects
            if let balList = m["bal"] as? [[String: Any]] {
                let parts = balList.compactMap { item -> String? in
                    guard let sum = item["sum"] else { return nil }
                    let cn = item["cn"] as? String ?? ""
                    return cn.isEmpty ? "\(sum)" : "\(sum) (\(cn))"
                }
                if !parts.isEmpty { return parts.joined(separator: "\n") }
            }
            // scalar keys
            for key in ["balance", "sum", "amount"] {
                if let v = m[key] { return "\(v)" }
            }
            return nil
        }
        if let m = res as? [String: Any] {
            if let s = try extractFromDict(m) { return s }
            if let inner = m["result"] as? [String: Any], let s = try extractFromDict(inner) { return s }
        }
        if let s = res as? String {
            if s.hasPrefix("{"), let data = s.data(using: .utf8),
               let m = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let result = try extractFromDict(m) { return result }
            }
            if !s.isEmpty { return s }
        }
        return "—"
    }

    func getHelpText() async throws -> String {
        let res = try await client.call("GetHelpText", args: [])
        var raw = ""
        if let m = res as? [String: Any] {
            let inner = (m["result"] as? [String: Any]) ?? m
            for key in ["text", "help", "info", "body"] {
                if let t = inner[key] as? String { raw = t; break }
            }
        } else if let s = res as? String {
            raw = s
        }
        // If raw looks like a JSON object, try to extract a string value
        if raw.hasPrefix("{"), let data = raw.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            raw = obj.values.compactMap { $0 as? String }.first ?? raw
        }
        // Decode HTML entities and fix escaped newlines
        raw = raw
            .replacingOccurrences(of: "&#160;", with: " ")
            .replacingOccurrences(of: "&amp;#160;", with: " ")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\t", with: "    ")
        return raw
    }

    func getEvents(panel: String, group: Int, fromDate: Date, toDate: Date = Date(), count: Int = 200) async throws -> [PanelEvent] {
        let fromTs = Int(fromDate.timeIntervalSince1970)
        let toTs   = Int(toDate.timeIntervalSince1970)
        let res = try await client.call("GetEvents", args: [panel, group, fromTs, toTs, count, 0])
        if let m = res as? [String: Any], let err = m["error"] as? String {
            throw WampError.callError(err)
        }
        let list = extractList(res)
        return list.compactMap { PanelEvent.from(json: $0) }
    }

    // MARK: - Helpers

    private func parseDict(_ value: Any?) throws -> [String: Any] {
        if let m = value as? [String: Any] { return m }
        if let s = value as? String,
           let data = s.data(using: .utf8),
           let m = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return m
        }
        return [:]
    }

    private func extractList(_ res: Any?) -> [Any] {
        if let m = res as? [String: Any] {
            for key in ["evn", "pnls", "groups", "events", "items", "list"] {
                if let list = m[key] as? [Any] { return list }
            }
            if let inner = m["result"] as? [String: Any] {
                for key in ["evn", "pnls", "groups", "events", "items", "list"] {
                    if let list = inner[key] as? [Any] { return list }
                }
            }
        }
        if let s = res as? String,
           let data = s.data(using: .utf8),
           let m = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let list = m["pnls"] as? [Any] { return list }
        if let list = res as? [Any] { return list }
        return []
    }
}
