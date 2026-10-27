import YawnCastCore
import SwiftUI

/// Themes: a colour (a Scene or one of four flat colours) and the text style
/// (Picture Book or Sign-Off), chosen separately. One tap applies.
struct ThemesSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The older Scenes and Colours sit in a drawer, open when one of them is worn.
    @State private var showOlder = false

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
                group("Scenes", subtitle: "Five bedtime landscapes, each with its own moon", themes: Theme.nights)
                olderDrawer
                textStyles
                versionLine
            }
            .padding(Space.xxl)
        }
        .background {
            // iOS 26: the sheet is system glass, so the live Scene shows through as you pick.
            if #available(iOS 26, *) {} else { ScreenBackground() }
        }
        .sensoryFeedback(.selection, trigger: model.theme)
        .sensoryFeedback(.selection, trigger: model.look)
        .onAppear { showOlder = !model.theme.isNight }
    }

    /// "Older themes": the six classic Scenes and five Colours, kept as they were.
    private var olderDrawer: some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { showOlder.toggle() }
            } label: {
                HStack {
                    Text("Older themes")
                        .font(Typo.headline)
                        .foregroundStyle(theme.text)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.textMuted)
                        .rotationEffect(.degrees(showOlder ? 180 : 0))
                }
                .padding(.vertical, Space.m)
                .padding(.horizontal, Space.l)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.surface))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(showOlder ? "Expanded" : "Collapsed")
            .accessibilityIdentifier("olderThemes")
            if showOlder {
                group("Classic scenes", subtitle: "Calm, animated night skies", themes: Theme.scenes)
                group("Colours", subtitle: "Simple and still, with a day page that follows your phone", themes: Theme.colours)
            }
        }
    }

    /// The version, at the bottom.
    private var versionLine: some View {
        let info = Bundle.main.infoDictionary
        let version = "\(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
        return Text("YawnCast \(version)")
            .font(Typo.caption)
            .foregroundStyle(theme.textMuted)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("version-line")
    }

    private var textStyles: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Text")
                    .font(Typo.eyebrow).tracking(1.2).textCase(.uppercase)
                    .foregroundStyle(theme.textMuted)
                    .accessibilityAddTraits(.isHeader)
                Text("The lettering on every screen").font(Typo.caption).foregroundStyle(theme.textMuted)
            }
            LazyVGrid(columns: columns, spacing: Space.l) {
                ForEach(ThemeStyle.allCases, id: \.self) { look in
                    Button {
                        withAnimation(.easeInOut(duration: 0.35)) { model.look = look }
                    } label: { StyleSwatch(look: look, selected: look == model.look) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(look.name) text")
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

/// A text style's card: "Aa" in its display face, on the current colour.
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
