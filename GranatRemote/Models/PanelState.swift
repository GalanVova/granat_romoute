import Foundation

struct PanelState {
    let armMode: Int      // st.gr.grd: 0=disarmed, 1=armed, 2=home
    let hasMainPower: Bool  // st.mPow
    let hasBattery: Bool    // st.bPow (absent = no battery module)
    let hasSignal: Bool     // st.sgn > 0
    let hasWifi: Bool       // st.wifi
    let hasCamera: Bool     // cmd id 22 present
    let availableCommands: [Int]  // cmd ids

    var isArmed: Bool { armMode != 0 }
    var armLabel: String {
        switch armMode {
        case 0: return "Disarmed"
        case 1: return "Armed"
        case 2: return "Home"
        default: return "Unknown"
        }
    }

    static func from(json: Any?) -> PanelState? {
        var root: [String: Any] = [:]
        if let dict = json as? [String: Any] {
            root = dict
        } else if let s = json as? String,
                  let data = s.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            root = dict
        } else {
            return nil
        }

        // Server wraps data in "st" key
        guard let st = root["st"] as? [String: Any] else { return nil }

        // Arm mode lives inside st.gr.grd
        let gr = st["gr"] as? [String: Any] ?? [:]

        func intSt(_ keys: [String]) -> Int {
            for k in keys { if let v = st[k] { return Int("\(v)") ?? 0 } }
            return 0
        }
        func intGr(_ keys: [String]) -> Int {
            for k in keys { if let v = gr[k] { return Int("\(v)") ?? 0 } }
            return 0
        }

        let armMode   = intGr(["grd", "arm"])
        let mainPower = intSt(["mPow", "mpow"]) != 0
        let battery   = intSt(["bPow", "bpow"]) != 0
        let signal    = intSt(["sgn", "gsm", "signal"]) > 0
        let wifi      = intSt(["wifi", "wf"]) != 0

        // Commands are array of dicts {id, nm, clr}
        var cmdIds: [Int] = []
        if let cmdArr = st["cmd"] as? [[String: Any]] {
            cmdIds = cmdArr.compactMap { item in
                guard let raw = item["id"] else { return nil }
                return Int("\(raw)")
            }
        }
        let hasCamera = cmdIds.contains(22)

        return PanelState(armMode: armMode, hasMainPower: mainPower, hasBattery: battery,
                          hasSignal: signal, hasWifi: wifi, hasCamera: hasCamera,
                          availableCommands: cmdIds)
    }
}
