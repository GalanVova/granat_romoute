import Foundation

struct PanelGroup: Identifiable {
    let id: String
    let group: Int
    let name: String
    let address: String?

    static func from(json: Any) -> PanelGroup? {
        guard let m = json as? [String: Any] else { return nil }
        let id = "\(m["id"] ?? "")"
        let gr = Int("\(m["gr"] ?? 0)") ?? 0
        let name = "\(m["name"] ?? m["nm"] ?? "")"
        let addr = m["addr"].map { "\($0)" }
        return PanelGroup(id: id, group: gr, name: name, address: addr)
    }
}
