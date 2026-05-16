import AppKit
import SwiftUI

enum AppStyle {
    enum Radius {
        static let chip: CGFloat = 6
        static let control: CGFloat = 8
        static let panel: CGFloat = 10
        static let card: CGFloat = 14
    }

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    enum Row {
        static let compactHeight: CGFloat = 36
        static let parentHeight: CGFloat = 44
    }

    enum Typography {
        static let pageTitle = Font.system(size: 22, weight: .semibold)
        static let rowTitle = Font.system(size: 13, weight: .medium)
        static let metadata = Font.system(size: 11)
        static let metadataEmphasis = Font.system(size: 11, weight: .medium)
    }

    /// Product blue (Notion / macOS system blue family).
    static let accent = Color(
        light: NSColor(calibratedRed: 0.0, green: 0.48, blue: 1.0, alpha: 1),
        dark: NSColor(calibratedRed: 0.35, green: 0.62, blue: 1.0, alpha: 1)
    )
    static let selectionFill = accent.opacity(0.07)
    static let selectionStroke = accent.opacity(0.18)
    static let canvas = Color(light: NSColor(calibratedWhite: 0.98, alpha: 1), dark: NSColor(calibratedWhite: 0.09, alpha: 1))
    static let panel = Color(light: NSColor(calibratedWhite: 0.96, alpha: 1), dark: NSColor(calibratedWhite: 0.12, alpha: 1))
    static let elevated = Color(light: NSColor.white, dark: NSColor(calibratedWhite: 0.14, alpha: 1))
    static let rowHover = Color(light: NSColor(calibratedWhite: 0.94, alpha: 1), dark: NSColor(calibratedWhite: 0.16, alpha: 1))
    static let hairline = Color.primary.opacity(0.1)

    static let safe = Color(red: 54 / 255, green: 148 / 255, blue: 104 / 255)
    static let warning = Color(red: 187 / 255, green: 126 / 255, blue: 51 / 255)
    static let danger = Color(red: 202 / 255, green: 80 / 255, blue: 80 / 255)
    static let neutral = Color.secondary
}

extension Color {
    init(light: NSColor, dark: NSColor) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return dark
            }
            return light
        })
    }
}

