import NightCastCore
import SwiftUI

/// Settings: theme and Library layout. Small and quick, never a destination.
struct SettingsSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xl) {
                Text("Settings")
                    .font(Typo.title)
                    .foregroundStyle(theme.text)
                    .accessibilityAddTraits(.isHeader)

                Text("Library").font(Typo.eyebrow).tracking(1.2).textCase(.uppercase).foregroundStyle(theme.textMuted)
                HStack(spacing: Space.m) {
                    ForEach(LibraryLayout.allCases, id: \.self) { layout in
                        Button { model.libraryLayout = layout } label: {
                            LayoutSwatch(layout: layout, selected: layout == model.libraryLayout)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(layout.title) layout")
                        .accessibilityAddTraits(layout == model.libraryLayout ? .isSelected : [])
                        .accessibilityIdentifier("layout-\(layout.rawValue)")
                    }
                }
                .sensoryFeedback(.selection, trigger: model.libraryLayout)

                Text("Theme").font(Typo.eyebrow).tracking(1.2).textCase(.uppercase).foregroundStyle(theme.textMuted)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.m), GridItem(.flexible(), spacing: Space.m)], spacing: Space.l) {
                    ForEach(Theme.all) { option in
                        Button { model.theme = option } label: { ThemeSwatch(option: option, selected: option == model.theme) }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(option.name), \(option.blurb)")
                            .accessibilityAddTraits(option == model.theme ? .isSelected : [])
                            .accessibilityIdentifier("theme-\(option.id)")
                    }
                }
                .sensoryFeedback(.selection, trigger: model.theme)
            }
            .padding(Space.xxl)
        }
        .background { ScreenBackground() }
    }
}

/// Mini diagram of a Library layout.
private struct LayoutSwatch: View {
    let layout: LibraryLayout
    let selected: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: Space.s) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.surface)
                .overlay {
                    Group {
                        switch layout {
                        case .large: grid(columns: 2, rows: 2)
                        case .small: grid(columns: 3, rows: 3)
                        case .list:
                            VStack(spacing: 5) {
                                ForEach(0..<4, id: \.self) { _ in
                                    HStack(spacing: 5) {
                                        RoundedRectangle(cornerRadius: 2).fill(theme.textMuted.opacity(0.6)).frame(width: 12, height: 12)
                                        Capsule().fill(theme.textMuted.opacity(0.4)).frame(height: 5)
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(selected ? theme.text : theme.border, lineWidth: selected ? 3 : 1)
                }
                .frame(height: 92)
            Text(layout.title)
                .font(Typo.headline)
                .foregroundStyle(theme.text)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private func grid(columns: Int, rows: Int) -> some View {
        VStack(spacing: 5) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: 5) {
                    ForEach(0..<columns, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 3).fill(theme.textMuted.opacity(0.6))
                    }
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

    var body: some View {
        VStack(spacing: Space.s) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(option.bg)
                .overlay {
                    if option.isNightSky {
                        // Hint of the night sky: a few stars and a wave.
                        Canvas { context, size in
                            for (x, y) in [(0.2, 0.2), (0.7, 0.15), (0.5, 0.35), (0.85, 0.4)] {
                                context.fill(Path(ellipseIn: CGRect(x: x * size.width, y: y * size.height, width: 2.5, height: 2.5)), with: .color(.white.opacity(0.8)))
                            }
                        }
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
