import SwiftUI

/// Visual weight of a key.
enum KeyRole {
    /// Neutral face.
    case standard
    /// High-contrast face (text color), used once per screen for the primary action.
    case primary
    /// Accent face, reserved for the Moon when Sleep is on.
    case accent
}

/// A paper key: a cut-paper face with no edge; pressing dims and settles.
/// (The raised v0.1 key with a visible edge was retired in v0.17; glass in Lights Out.)
struct KeyStyle<S: InsettableShape>: ButtonStyle {
    var shape: S
    var role: KeyRole = .standard
    /// Kept for call sites from the raised-key era; printed keys have no depth.
    var depth: CGFloat = 4

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { shape.fill(face) }
            .scaleEffect(pressed ? 0.96 : 1)
            .opacity(isEnabled ? (pressed ? 0.75 : 1) : 0.45)
            .contentShape(shape)
            .animation(reduceMotion ? nil : Motion.press, value: pressed)
    }

    private var face: Color {
        switch role {
        case .standard: theme.surface
        case .primary: theme.text
        case .accent: theme.accent
        }
    }

    private var foreground: Color {
        switch role {
        case .standard: theme.text
        case .primary: theme.bg
        case .accent: theme.onAccent
        }
    }
}

extension ButtonStyle where Self == KeyStyle<PaperShape> {
    /// Square-ish keys: transport, the mini player's Moon and Play.
    static func roundKey(_ role: KeyRole = .standard, depth: CGFloat = 4) -> KeyStyle<PaperShape> {
        KeyStyle(shape: PaperShape(seed: role == .primary ? 2 : 0), role: role, depth: depth)
    }

    /// Wide keys with a label.
    static func capsuleKey(_ role: KeyRole = .standard, depth: CGFloat = 4) -> KeyStyle<PaperShape> {
        KeyStyle(shape: PaperShape(seed: 2), role: role, depth: depth)
    }
}

/// The small icon keys: a square of paper in the surface colour.
struct OutlineKeyStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(theme.text)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .paper(seed: 1, fill: theme.surface)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.45)
            .contentShape(Rectangle())
            .animation(reduceMotion ? nil : Motion.press, value: configuration.isPressed)
    }
}

/// Small 44 pt toolbar key with an SF Symbol.
struct IconKey: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
        }
        .buttonStyle(OutlineKeyStyle())
        .frame(width: 44, height: 44)
        .accessibilityLabel(label)
        // The glyph stays 17 pt; at accessibility sizes a long press shows it large.
        .accessibilityShowsLargeContentViewer {
            Label(label, systemImage: systemName)
        }
    }
}

extension View {
    /// A cut-paper face behind a view: the one surface in Lights Out. Opaque, so text
    /// keeps its contrast over any Scene; `seed` picks the cut.
    func paper(seed: Int = 0, fill: Color) -> some View {
        background { PaperShape(seed: seed).fill(fill) }
    }
}
