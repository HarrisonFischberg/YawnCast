import NightCastCore
import SwiftUI

struct AppearanceSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            Text("Appearance")
                .font(Typo.title)
                .foregroundStyle(theme.text)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Space.m) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg)
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
