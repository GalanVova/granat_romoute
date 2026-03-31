import Foundation
import CryptoKit

class LunAPI {
    private let client: WampV1Client

    init(client: WampV1Client) {
        self.client = client
    }

    func generateNonce(login: String) async throws -> String {
        let res = try await client.call("GenerateNonce", args: [login])
        // Server returns nonce as JSON string: "{\"nonce\":\"XXX\"}" or as dict
        let m = try parseDict(res)
        if let nonce = m["nonce"] { return "\(nonce)" }
        if let inner = m["result"] as? [String: Any], let nonce = inner["nonce"] { return "\(nonce)" }
        throw WampError.missingField("nonce")
    }

    static func hmacSHA512Base64(password: String, nonce: String) -> String {
        // msg = nonce + password  (matches the working Python/Windows desktop app)
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
        // Server may also return panels inside Signup body under "panel" key
        let list = extractList(res)
        return list.compactMap { PanelGroup.from(json: $0) }
    }

    /// Parse panels directly from Signup response (server returns them there too)
    func parsePanelsFromSignup(_ res: Any?) -> [PanelGroup] {
        guard let m = try? parseDict(res),
              let panel = m["panel"] as? [Any] else { return [] }
        return panel.compactMap { PanelGroup.from(json: $0) }
    }

    func remoteControl(cmd: Int, panel: String, group: Int, num: Int = 0) async throws {
        _ = try await client.call("RemoteControl", args: [cmd, panel, group, num])
    }

    // MARK: - Helpers

    /// Parse result that may be a [String:Any] dict OR a JSON string encoding such a dict.
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
            if let list = m["pnls"] as? [Any] { return list }
            if let inner = m["result"] as? [String: Any], let list = inner["pnls"] as? [Any] { return list }
        }
        // May arrive as JSON string
        if let s = res as? String,
           let data = s.data(using: .utf8),
           let m = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let list = m["pnls"] as? [Any] { return list }
        if let list = res as? [Any] { return list }
        return []
    }
}
