import SwiftUI

/// A coordinated palette. Values mirror `replica/design/tokens.<id>.json`,
/// which is what the contrast check runs against.
struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let blurb: String
    let colorScheme: ColorScheme
    let bg: Color
    let surface: Color
    let raised: Color
    let border: Color
    let text: Color
    let textMuted: Color
    let accent: Color
    let onAccent: Color
    let danger: Color
    /// Key "edge" (the visible side of a raised key).
    let edge: Color
    /// Top-edge highlight on raised keys.
    let highlight: Color
    let shadowOpacity: Double
    /// Draw the animated night sky (gradient, waves, stars) instead of a flat `bg`.
    var isNightSky = false

    /// Default: deep-blue night sky with slow waves and twinkling stars.
    static let midnight = Theme(
        id: "midnight", name: "Midnight", blurb: "Night sky, calm",
        colorScheme: .dark,
        bg: Color(hex: 0x0A1430), surface: Color(hex: 0x16244D), raised: Color(hex: 0x1E2F60),
        border: Color(hex: 0x2C3F78), text: Color(hex: 0xEEF2FF), textMuted: Color(hex: 0xA9B7DD),
        accent: Color(hex: 0xF4CF7B), onAccent: Color(hex: 0x1A1408), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x070E24), highlight: .white.opacity(0.10), shadowOpacity: 0.55,
        isNightSky: true
    )

    static let paper = Theme(
        id: "paper", name: "Paper", blurb: "Warm daylight",
        colorScheme: .light,
        bg: Color(hex: 0xF2EDE3), surface: Color(hex: 0xE7E0D2), raised: Color(hex: 0xFBF8F2),
        border: Color(hex: 0xD6CDBA), text: Color(hex: 0x1C1A16), textMuted: Color(hex: 0x5C564B),
        accent: Color(hex: 0x2E2A6B), onAccent: Color(hex: 0xF7F3EA), danger: Color(hex: 0xA33224),
        edge: Color(hex: 0xCFC5B1), highlight: .white.opacity(0.9), shadowOpacity: 0.12
    )

    static let ink = Theme(
        id: "ink", name: "Ink", blurb: "Quiet dark",
        colorScheme: .dark,
        bg: Color(hex: 0x111113), surface: Color(hex: 0x1C1C20), raised: Color(hex: 0x26262B),
        border: Color(hex: 0x2E2E34), text: Color(hex: 0xF1EEE7), textMuted: Color(hex: 0xA29E95),
        accent: Color(hex: 0xE9B44C), onAccent: Color(hex: 0x1A1408), danger: Color(hex: 0xF07A68),
        edge: Color(hex: 0x0A0A0B), highlight: .white.opacity(0.08), shadowOpacity: 0.5
    )

    static let ember = Theme(
        id: "ember", name: "Ember", blurb: "Bedtime, low light",
        colorScheme: .dark,
        bg: Color(hex: 0x070504), surface: Color(hex: 0x110C09), raised: Color(hex: 0x1A120D),
        border: Color(hex: 0x22170F), text: Color(hex: 0xB98F6C), textMuted: Color(hex: 0x9C7A5C),
        accent: Color(hex: 0xC27142), onAccent: Color(hex: 0x070504), danger: Color(hex: 0xC96E55),
        edge: Color(hex: 0x030201), highlight: Color(hex: 0xB98F6C).opacity(0.07), shadowOpacity: 0.6
    )

    static let all: [Theme] = [.midnight, .paper, .ink, .ember]

    static func with(id: String?) -> Theme {
        all.first { $0.id == id } ?? .midnight
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .midnight
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

/// Type ramp. Every style maps to a Dynamic Type text style so it scales.
enum Typo {
    static let display = Font.system(.largeTitle, design: .serif, weight: .bold)
    static let playerTitle = Font.system(.title, design: .serif, weight: .bold)
    static let title = Font.system(.title3, design: .rounded, weight: .semibold)
    static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
    static let body = Font.system(.body, design: .default)
    static let caption = Font.system(.footnote, design: .rounded, weight: .medium)
    static let eyebrow = Font.system(.caption, design: .rounded, weight: .bold)
    static let digits = Font.system(.subheadline, design: .rounded, weight: .semibold).monospacedDigit()
}

enum Space {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 48
}
