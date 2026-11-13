import YawnCastCore
import SwiftUI

/// Themes: a color (a Scene or one of five flat colors) and the text style
/// (Picture Book or Sign-Off), chosen separately. One tap applies.
struct ThemesSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Send Debug Logs: the note typed so far, kept if the sheet closes.
    @AppStorage("supportDraft") private var problem = ""
    @State private var sending = false
    @State private var sendFailed = false

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
                group("Scenes", subtitle: "Calm, animated night skies", themes: Theme.scenes)
                group("Colors", subtitle: "Simple and still, with a day page that follows your phone", themes: Theme.colours)
                textStyles
                sendDebugLogs
                versionLine
            }
            .padding(Space.xxl)
        }
        // The note field has no Return-to-close (Return is a new line); a drag puts the keyboard away.
        .scrollDismissesKeyboard(.interactively)
        .background {
            // iOS 26: the sheet is system glass, so the live Scene shows through as you pick.
            if #available(iOS 26, *) {} else { ScreenBackground() }
        }
        .sensoryFeedback(.selection, trigger: model.theme)
        .sensoryFeedback(.selection, trigger: model.look)
    }

    /// Send Debug Logs: a draft to support in the user's email app (SupportMail.swift); the user taps Send there.
    private var sendDebugLogs: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Send Debug Logs to \(SupportMail.address)")
                    .font(Typo.eyebrow).tracking(0.6)
                    .foregroundStyle(theme.textMuted)
                    .accessibilityAddTraits(.isHeader)
                Text("Opens your email app with what you wrote, the app version, your device and this session's error logs. Nothing is sent until you tap Send.")
                    .font(Typo.caption).foregroundStyle(theme.textMuted)
            }
            TextField("", text: $problem, prompt: Text("What went wrong?").foregroundStyle(theme.textMuted), axis: .vertical)
                .lineLimit(3...8)
                .font(Typo.body)
                .foregroundStyle(theme.text)
                .padding(Space.l)
                .paper(seed: 1, fill: theme.surface)
                .accessibilityLabel("What went wrong?")
                .accessibilityIdentifier("support-problem")
            Button {
                Task {
                    sending = true
                    sendFailed = !(await SupportMail.send(problem: problem))
                    sending = false
                }
            } label: {
                Text(sending ? "Gathering logs…" : "Send Debug Logs").font(Typo.headline).frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.capsuleKey())
            .disabled(sending || problem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("support-send")
            if !problem.isEmpty {
                // The draft stays until Mail has really sent it (we can't tell), so clearing is the user's call.
                Button("Clear") { problem = "" }
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("support-clear")
            }
            if sendFailed {
                Text("No email app opened. The report is copied: paste it into an email to \(SupportMail.address).")
                    .font(Typo.caption).foregroundStyle(theme.textMuted)
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
                        .buttonStyle(PressDim())
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
                        .buttonStyle(PressDim())
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
            PaperShape(seed: 1)
                .fill(current.surface)
                .overlay {
                    Text("Aa")
                        .font(Typo.display(look))
                        .foregroundStyle(current.text)
                        .accessibilityHidden(true)
                }
                .overlay {
                    PaperShape(seed: 1)
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
            PaperShape(seed: 1)
                .fill(option.bg)
                .overlay {
                    if let scene = option.scene {
                        // A still frame of the actual scene.
                        ScenePreview(scene: scene)
                            .clipShape(PaperShape(seed: 1))
                    }
                }
                .overlay(alignment: .trailing) {
                    // A style colour's day page, as the right-hand edge.
                    if option.followsSystem {
                        Rectangle().fill(option.resolved(for: .light).bg)
                            .frame(width: 44)
                    }
                }
                .overlay(alignment: .bottom) {
                    PaperShape(seed: 2)
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
                .clipShape(PaperShape(seed: 1))
                .overlay {
                    PaperShape(seed: 1)
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
