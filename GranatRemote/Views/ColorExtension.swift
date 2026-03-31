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

    // Design system
    static let appBackground  = Color(hex: "0D0D0D")
    static let cardBackground = Color(hex: "1C1C1C")
    static let inputBackground = Color(hex: "1A1A1A")
    static let inputBorder    = Color(hex: "333333")
    static let primaryRed     = Color(hex: "CC0000")
    static let buttonDark     = Color(hex: "2A2A2A")
    static let textPrimary    = Color.white
    static let textSecondary  = Color(hex: "888888")
    static let selectedGreen  = Color(hex: "4CAF50")
}
