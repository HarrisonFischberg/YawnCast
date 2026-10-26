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

/// A printed key: a filled face with no edge; pressing dims and settles.
/// (The raised v0.1 key with a visible edge was retired in v0.17.)
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
            // Standard keys turn to glass on iOS 26; primary and accent stay solid, the one bright key.
            .nightGlass(in: shape, interactive: true, enabled: role == .standard) { shape.fill(face) }
            .scaleEffect(pressed ? 0.96 : 1)
            .opacity(isEnabled ? (pressed ? 0.75 : 1) : 0.45)
            .contentShape(shape)
            .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.7), value: pressed)
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

extension ButtonStyle where Self == KeyStyle<Circle> {
    static func roundKey(_ role: KeyRole = .standard, depth: CGFloat = 4) -> KeyStyle<Circle> {
        KeyStyle(shape: Circle(), role: role, depth: depth)
    }
}

extension ButtonStyle where Self == KeyStyle<Capsule> {
    static func capsuleKey(_ role: KeyRole = .standard, depth: CGFloat = 4) -> KeyStyle<Capsule> {
        KeyStyle(shape: Capsule(), role: role, depth: depth)
    }
}

/// Almanac's printed round key: an outline in the colour's rule, no edge.
/// Every style uses it for the small icon keys (v0.17, owner request).
struct OutlineKeyStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(theme.text)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .nightGlass(in: Circle(), interactive: true) {
                Circle().fill(theme.bg.opacity(0.35)).overlay(Circle().strokeBorder(theme.text.opacity(0.55), lineWidth: 1.5))
            }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.45)
            .contentShape(Circle())
            .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
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
        .frame(width: 48, height: 48)
        .accessibilityLabel(label)
        // The glyph stays 17 pt; at accessibility sizes a long press shows it large.
        .accessibilityShowsLargeContentViewer {
            Label(label, systemImage: systemName)
        }
    }
}

/// Liquid Glass behind a view on iOS 26, else the given solid face. Glass blurs what is
/// behind it, so the Scenes keep moving underneath. Reduce Transparency is handled by
/// the system glass itself.
struct NightGlass<S: Shape, Fallback: View>: ViewModifier {
    let shape: S
    var tint: Color?
    var interactive = false
    var enabled = true
    let fallback: Fallback
    @Environment(\.theme) private var theme

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if enabled {
                // Ember promises no blue light, so its glass is always warm-tinted.
                content.glassEffect(.regular.tint(tint ?? (theme.warmOnly ? theme.accent.opacity(0.18) : nil)).interactive(interactive), in: shape)
            } else {
                content.background { fallback }
            }
        } else {
            content.background { fallback }
        }
    }
}

extension View {
    func nightGlass<S: Shape, F: View>(in shape: S, tint: Color? = nil, interactive: Bool = false, enabled: Bool = true,
                                       @ViewBuilder otherwise fallback: () -> F) -> some View {
        modifier(NightGlass(shape: shape, tint: tint, interactive: interactive, enabled: enabled, fallback: fallback()))
    }
}
