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
        static let listRowMinHeight: CGFloat = 52
        /// Scan row leading icon frame (brand PNGs and SF Symbol fallbacks).
        static let listIconFrameSize: CGFloat = 28
        /// Point size for SF Symbol row icons (e.g. simulator host, folder fallback).
        static let sfSymbolPointSize: CGFloat = 18
        /// Project group headers (node_modules, Flutter, etc.) — slightly smaller than scan rows (28pt).
        static let projectGroupIconSize: CGFloat = 16
        static let projectGroupIconCornerRadius: CGFloat = 5
        /// Aligns expanded artifact text with the project title (parent checkbox + spacing).
        static let projectArtifactLeadingInset: CGFloat = 34
    }

    enum Typography {
        static let pageTitle = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let rowTitle = Font.system(size: 13, weight: .medium)
        static let metadata = Font.system(size: 11)
        static let metadataEmphasis = Font.system(size: 11, weight: .medium)
    }

    /// Product cobalt — saturated enough for filled buttons with white labels.
    static let accent = Color(
        light: NSColor(calibratedRed: 21 / 255, green: 101 / 255, blue: 216 / 255, alpha: 1),
        dark: NSColor(calibratedRed: 56 / 255, green: 136 / 255, blue: 244 / 255, alpha: 1)
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

