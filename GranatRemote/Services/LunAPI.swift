import Foundation
import CryptoKit

class LunAPI {
    private let client: WampV1Client

    init(client: WampV1Client) {
        self.client = client
    }

    func generateNonce(login: String) async throws -> String {
        let res = try await client.call("GenerateNonce", args: [login])
        if let m = res as? [String: Any] {
            if let nonce = m["nonce"] { return "\(nonce)" }
            if let inner = m["result"] as? [String: Any], let nonce = inner["nonce"] { return "\(nonce)" }
        }
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
        _ = try await client.call("Signup", args: [login, p, "PhoenixMK", "", 1, "ru", "ios", "1.0"])
    }

    func getPanelGroups() async throws -> [PanelGroup] {
        let res = try await client.call("GetPanelGroups", args: [])
        let list = extractList(res)
        return list.compactMap { PanelGroup.from(json: $0) }
    }

    func remoteControl(cmd: Int, panel: String, group: Int, num: Int = 0) async throws {
        _ = try await client.call("RemoteControl", args: [cmd, panel, group, num])
    }

    private func extractList(_ res: Any?) -> [Any] {
        if let m = res as? [String: Any] {
            if let list = m["pnls"] as? [Any] { return list }
            if let inner = m["result"] as? [String: Any], let list = inner["pnls"] as? [Any] { return list }
        }
        if let list = res as? [Any] { return list }
        return []
    }
}
