import Foundation

struct PanelState {
    let armMode: Int      // grd: 0=disarmed, 1=armed, 2=partial/home
    let hasMainPower: Bool  // mPow or pow
    let hasBattery: Bool    // bPow or bat
    let hasSignal: Bool     // sgn or gsm
    let hasWifi: Bool       // wifi or wf
    let hasCamera: Bool     // cam or vid — only show camera icon if true
    let availableCommands: [Int]  // cmd array

    var isArmed: Bool { armMode != 0 }
    var armLabel: String {
        switch armMode {
        case 0: return "Disarmed"
        case 1: return "Armed"
        case 2: return "Home"
        default: return "Unknown"
        }
    }
    var armColor: String {
        switch armMode {
        case 0: return "selectedGreen"   // green = disarmed safe
        case 1: return "primaryRed"      // red = armed
        case 2: return "orange"          // orange = partial
        default: return "textSecondary"
        }
    }

    static func from(json: Any?) -> PanelState? {
        var m: [String: Any] = [:]
        if let dict = json as? [String: Any] {
            m = dict
        } else if let s = json as? String,
                  let data = s.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            m = dict
        } else {
            return nil
        }

        // Try nested under "result" key
        if m.isEmpty { return nil }
        let inner: [String: Any]
        if let r = m["result"] as? [String: Any] {
            inner = r
        } else {
            inner = m
        }

        func intVal(_ keys: [String]) -> Int {
            for k in keys { if let v = inner[k] { return Int("\(v)") ?? 0 } }
            return 0
        }
        func boolVal(_ keys: [String]) -> Bool { intVal(keys) != 0 }

        let armMode = intVal(["grd", "arm"])
        let mainPow = boolVal(["mPow", "pow", "mpow", "main_pow"])
        let batPow = boolVal(["bPow", "bat", "bpow", "bat_pow"])
        let signal = boolVal(["sgn", "gsm", "signal"])
        let wifi = boolVal(["wifi", "wf", "wlan"])
        let camera = boolVal(["cam", "vid", "camera", "video"])

        var cmds: [Int] = []
        if let cmdArr = inner["cmd"] as? [Any] {
            cmds = cmdArr.compactMap { Int("\($0)") }
        }

        return PanelState(armMode: armMode, hasMainPower: mainPow, hasBattery: batPow,
                          hasSignal: signal, hasWifi: wifi, hasCamera: camera,
                          availableCommands: cmds)
    }
}
