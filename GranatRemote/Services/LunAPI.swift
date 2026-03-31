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
        let key = SymmetricKey(data: Data(password.utf8))
        let mac = HMAC<SHA512>.authenticationCode(for: Data(nonce.utf8), using: key)
        return Data(mac).base64EncodedString()
    }

    func signup(login: String, password: String) async throws {
        let nonce = try await generateNonce(login: login)
        let p = Self.hmacSHA512Base64(password: password, nonce: nonce)
        let res = try await client.call("Signup", args: [login, p, "PhoenixMK", "", 1, "ru", "ios", "1.0"])
        // Flutter ignores the Signup response body — we do the same
    }

    func getPanelGroups() async throws -> [PanelGroup] {
        let res = try await client.call("GetPanelGroups", args: [])
        let list = extractList(res)
        return list.compactMap { PanelGroup.from(json: $0) }
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
