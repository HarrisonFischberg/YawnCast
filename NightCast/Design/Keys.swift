import SwiftUI

/// Visual weight of a key.
enum KeyRole {
    /// Raised neutral face.
    case standard
    /// High-contrast face (text color), used once per screen for the primary action.
    case primary
    /// Accent face, reserved for the Moon when Sleep is on.
    case accent
}

/// A physical key: a face sitting on a visible edge. Pressing sinks the face
/// onto the edge. Shapes are drawn with SwiftUI only (no images, no 3D engine).
struct KeyStyle<S: InsettableShape>: ButtonStyle {
    var shape: S
    var role: KeyRole = .standard
    var depth: CGFloat = 4

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if theme.style.raisedKeys {
            keyBody(configuration)
        } else {
            flatBody(configuration)
        }
    }

    /// Printed keys (every look but Boro): no edge; pressing dims and settles.
    /// Almanac rules a standard key in ink; the others fill it with the surface.
    private func flatBody(_ configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if role == .standard {
                    switch theme.style {
                    case .almanac:
                        shape.fill(theme.bg.opacity(0.001))
                            .overlay(shape.strokeBorder(theme.border, lineWidth: 1.5))
                    case .safelight:
                        shape.fill(theme.surface)
                            .overlay(shape.strokeBorder(theme.border, lineWidth: 1))
                    default:
                        shape.fill(theme.surface)
                    }
                } else {
                    shape.fill(face)
                }
            }
            .scaleEffect(pressed ? 0.96 : 1)
            .opacity(isEnabled ? (pressed ? 0.75 : 1) : 0.45)
            .contentShape(shape)
            .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.7), value: pressed)
    }

    private func keyBody(_ configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let travel = pressed ? depth - 1 : 0
        return configuration.label
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                shape.fill(face)
                    .overlay {
                        // Boro: a running stitch just inside the edge of every key.
                        shape.inset(by: 5).stroke(foreground.opacity(0.3), style: .stitch(1.5))
                    }
                    .overlay {
                        // Top highlight: a thin lit lip on the face.
                        shape.inset(by: 0.5)
                            .stroke(LinearGradient(colors: [highlight, .clear], startPoint: .top, endPoint: .center), lineWidth: 1)
                    }
            }
            .offset(y: travel)
            .background {
                // The key's edge, visible below the face.
                shape.fill(edge)
                    .offset(y: depth)
                    .shadow(color: .black.opacity(pressed ? theme.shadowOpacity * 0.4 : theme.shadowOpacity), radius: pressed ? 2 : 8, y: pressed ? 1 : 5)
            }
            .padding(.bottom, depth)
            .contentShape(shape)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.7), value: pressed)
    }

    private var face: Color {
        switch role {
        case .standard: theme.raised
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

    private var edge: Color {
        switch role {
        case .standard: theme.edge
        case .primary: theme.text.mix(with: .black, by: 0.45)
        case .accent: theme.accent.mix(with: .black, by: 0.45)
        }
    }

    private var highlight: Color {
        switch role {
        case .standard: theme.highlight
        case .primary, .accent: theme.warmOnly ? theme.highlight : .white.opacity(theme.colorScheme == .light ? 0.25 : 0.18)
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
            .background(Circle().fill(theme.bg.opacity(0.35)).overlay(Circle().strokeBorder(theme.text.opacity(0.55), lineWidth: 1.5)))
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
