import NightCastCore
import SwiftUI

/// Themes: animated Scenes, then flat Color Scapes. One tap applies.
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
                    .foregroundStyle(theme.text)
                    .accessibilityAddTraits(.isHeader)
                group("Scenes", subtitle: "Calm, animated night skies", themes: Theme.scenes)
                group("Color Scapes", subtitle: "Simple and still", themes: Theme.colorScapes)
            }
            .padding(Space.xxl)
        }
        .background { ScreenBackground() }
        .sensoryFeedback(.selection, trigger: model.theme)
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
                    } label: { ThemeSwatch(option: option, selected: option == model.theme) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(option.name), \(option.blurb)")
                        .accessibilityAddTraits(option == model.theme ? .isSelected : [])
                        .accessibilityIdentifier("theme-\(option.id)")
                }
            }
        }
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
