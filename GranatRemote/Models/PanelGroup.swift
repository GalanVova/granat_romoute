import Foundation

struct PanelGroup: Identifiable {
    let id: String       // composite: "\(panelId)/\(group)"
    let panelId: String  // raw server panel id
    let group: Int
    let name: String
    let address: String?
    var state: PanelState?

    static func from(json: Any) -> PanelGroup? {
        guard let m = json as? [String: Any] else { return nil }
        let panelId = "\(m["id"] ?? "")"
        let gr = Int("\(m["gr"] ?? 0)") ?? 0
        let name = (m["name"] as? String ?? m["nm"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        let addr = (m["adr"] as? String ?? m["addr"] as? String)?.trimmingCharacters(in: .whitespaces)
        let addrFinal = (addr?.isEmpty == false) ? addr : nil
        guard !panelId.isEmpty && panelId != "" else { return nil }
        return PanelGroup(id: "\(panelId)/\(gr)", panelId: panelId, group: gr, name: name, address: addrFinal, state: nil)
    }
}
