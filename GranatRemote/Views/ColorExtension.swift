import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    // Design system — adaptive dark / light
    static let appBackground  = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "0D0D0D") : UIColor(hex: "F2F2F7") })
    static let cardBackground = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "1C1C1C") : UIColor(hex: "FFFFFF") })
    static let inputBackground = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "1A1A1A") : UIColor(hex: "E9E9EE") })
    static let inputBorder    = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "333333") : UIColor(hex: "C8C8CC") })
    static let primaryRed     = Color(hex: "CC0000")
    static let buttonDark     = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "2A2A2A") : UIColor(hex: "E0E0E5") })
    static let textPrimary    = Color(UIColor { t in t.userInterfaceStyle == .dark ? .white : UIColor(hex: "111111") })
    static let textSecondary  = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "888888") : UIColor(hex: "6E6E73") })
    static let selectedGreen  = Color(hex: "4CAF50")
}

// UIColor hex initialiser (for dynamic providers above)
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8)  & 0xFF) / 255
        let b = CGFloat(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
