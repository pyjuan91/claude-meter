import SwiftUI

// MARK: - Utilization color thresholds (matches the browser extension)
//
//   ≤ 30%  →  Sand        (#C4A882)
//  30–60%  →  Terracotta  (#D4835E)
//  60–80%  →  Amber       (#E0A020)
//   > 80%  →  Red         (#E5524A)

enum ColorThresholds {

    static func color(for utilization: Double) -> Color {
        Color(nsColor: nsColor(for: utilization))
    }

    static func nsColor(for utilization: Double) -> NSColor {
        switch utilization {
        case ...30:     return NSColor(hex: 0xC4A882)
        case 30..<60:   return NSColor(hex: 0xD4835E)
        case 60..<80:   return NSColor(hex: 0xE0A020)
        default:        return NSColor(hex: 0xE5524A)
        }
    }
}

// MARK: - Hex color initialiser

extension NSColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green:   CGFloat((hex >> 8)  & 0xFF) / 255,
            blue:    CGFloat( hex        & 0xFF) / 255,
            alpha:   alpha
        )
    }
}
