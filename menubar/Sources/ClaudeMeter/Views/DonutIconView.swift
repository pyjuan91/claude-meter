import SwiftUI
import AppKit

// MARK: - Donut gauge rendered as an NSImage for the menu bar status item

enum DonutIcon {

    /// Render a tiny donut arc at the given utilization percentage.
    /// - Parameters:
    ///   - percentage: 0…100+
    ///   - size: point size of the square image (default 18 pt — standard menu bar icon)
    /// - Returns: Template-aware NSImage suitable for NSStatusItem.button.image
    static func render(percentage: Double, size: CGFloat = 18) -> NSImage {
        let clamped = min(max(percentage, 0), 100)
        let lineWidth: CGFloat = 2.5
        let padding: CGFloat = 1.0
        let radius = (size - lineWidth) / 2 - padding
        let center = CGPoint(x: size / 2, y: size / 2)

        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            // Background track
            ctx.setStrokeColor(NSColor.secondaryLabelColor.withAlphaComponent(0.25).cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.strokePath()

            // Foreground arc  (starts at 12 o'clock = −π/2)
            if clamped > 0 {
                let endAngle: CGFloat = (.pi * 2 * clamped / 100) - (.pi / 2)
                let startAngle: CGFloat = -.pi / 2

                ctx.setStrokeColor(ColorThresholds.nsColor(for: percentage).cgColor)
                ctx.setLineWidth(lineWidth)
                ctx.setLineCap(.round)
                ctx.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                ctx.strokePath()
            }

            return true
        }

        // Make it a template image so macOS adapts to light/dark menu bar automatically
        // (Disabled — we want our own utilization colours)
        image.isTemplate = false
        return image
    }
}
