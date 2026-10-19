import NightCastCore
import SwiftUI

/// Themes: a style (type, keys, Moon key) and a colour, chosen separately, so the
/// Scenes and Color Scapes can be worn in any style. One tap applies.
struct ThemesSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Space.m), count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xl) {
                Text("Themes")
                    .font(Typo.title)
                    .textCase(Typo.titleCase)
                    .foregroundStyle(theme.text)
                    .accessibilityAddTraits(.isHeader)
                styles
                Text("Colour")
                    .font(Typo.title)
                    .textCase(Typo.titleCase)
                    .foregroundStyle(theme.text)
                    .padding(.top, Space.l)
                    .accessibilityAddTraits(.isHeader)
                group("Style colours", subtitle: "Night and day pages that follow your phone", themes: Theme.looks)
                group("Scenes", subtitle: "Calm, animated night skies", themes: Theme.scenes)
                group("Color Scapes", subtitle: "Simple and still", themes: Theme.colorScapes)
            }
            .padding(Space.xxl)
        }
        .background { ScreenBackground() }
        .sensoryFeedback(.selection, trigger: model.theme)
        .sensoryFeedback(.selection, trigger: model.look)
    }

    private var styles: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Style")
                    .font(Typo.eyebrow).tracking(1.2).textCase(.uppercase)
                    .foregroundStyle(theme.textMuted)
                    .accessibilityAddTraits(.isHeader)
                Text("Type, keys and how the Moon shows the fade").font(Typo.caption).foregroundStyle(theme.textMuted)
            }
            LazyVGrid(columns: columns, spacing: Space.l) {
                ForEach(ThemeStyle.allCases, id: \.self) { look in
                    Button {
                        withAnimation(.easeInOut(duration: 0.35)) { model.choose(look: look) }
                    } label: { StyleSwatch(look: look, selected: look == model.look) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(look.name) style, \(look.blurb)")
                        .accessibilityAddTraits(look == model.look ? .isSelected : [])
                        .accessibilityIdentifier("look-\(look.rawValue)")
                }
            }
        }
    }

    private func group(_ title: String, subtitle: String, themes: [Theme]) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typo.eyebrow).tracking(1.2).textCase(.uppercase)
                    .foregroundStyle(theme.textMuted)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle).font(Typo.caption).foregroundStyle(theme.textMuted)
            }
            LazyVGrid(columns: columns, spacing: Space.l) {
                ForEach(themes) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.35)) { model.theme = option }
                    } label: { ThemeSwatch(option: option, selected: option.id == model.theme.id) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(option.name), \(option.blurb)")
                        .accessibilityAddTraits(option.id == model.theme.id ? .isSelected : [])
                        .accessibilityIdentifier("theme-\(option.id)")
                }
            }
        }
    }
}

/// A style's card: "Aa" in its display face, on the current colour.
private struct StyleSwatch: View {
    let look: ThemeStyle
    let selected: Bool
    @Environment(\.theme) private var current

    var body: some View {
        VStack(spacing: Space.s) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(current.surface)
                .overlay {
                    Text("Aa")
                        .font(Typo.display(look))
                        .foregroundStyle(current.text)
                        .accessibilityHidden(true)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(selected ? current.text : current.border, lineWidth: selected ? 3 : 1)
                }
                .frame(height: 96)
            Text(look.name)
                .font(Typo.headline)
                .foregroundStyle(current.text)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

/// A tiny preview of the theme: its background with a Moon key in its accent.
private struct ThemeSwatch: View {
    let option: Theme
    let selected: Bool
    @Environment(\.theme) private var current
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: Space.s) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(option.bg)
                .overlay {
                    if let scene = option.scene {
                        // A still frame of the actual scene.
                        ScenePreview(scene: scene)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .overlay(alignment: .trailing) {
                    // A style colour's day page, as the right-hand edge.
                    if option.followsSystem {
                        Rectangle().fill(option.resolved(for: .light).bg)
                            .frame(width: 44)
                            .clipShape(UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: 18, topTrailing: 18), style: .continuous))
                    }
                }
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(option.accent)
                        .frame(height: 22)
                        .overlay(Image(systemName: "moon.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(option.onAccent))
                        .padding(10)
                }
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Capsule().fill(option.text).frame(width: 34, height: 6)
                        Capsule().fill(option.textMuted).frame(width: 22, height: 5)
                    }
                    .padding(12)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(selected ? current.text : current.border, lineWidth: selected ? 3 : 1)
                }
                .frame(height: 120)
            Text(option.name)
                .font(Typo.headline)
                .foregroundStyle(current.text)
            Text(option.blurb)
                .font(Typo.caption)
                .foregroundStyle(current.textMuted)
                .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
