import YawnCastCore
import SwiftUI

// Shared pieces: the page tabs, the cut-paper shape and the Moon key.

// MARK: - Page tabs

/// New · Library · Explore as paper tags. They are also the page's title: the
/// current page is the bright tag, so no page repeats its name underneath.
struct LookTabs: View {
    @Binding var selection: HomePage
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Space.s) {
            ForEach(Array(HomePage.allCases.enumerated()), id: \.element) { index, page in
                let on = page == selection
                Button {
                    withAnimation(reduceMotion ? nil : Motion.move) { selection = page }
                } label: {
                    Text(page.title)
                        .font(Typo.headline)
                        .foregroundStyle(on ? theme.bg : theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, typeSize.isAccessibilitySize ? Space.m : Space.xl)
                        .frame(minHeight: 44)
                        .paper(seed: index, fill: on ? theme.text : theme.surface)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressDim())
                .accessibilityShowsLargeContentViewer { Text(page.title) }
                .modifier(TabAccessibility(page: page, selected: on))
            }
            Spacer(minLength: 0)
        }
        // Three tabs share one row; past this size they would truncate, so they stop
        // growing and a long press shows the name large.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pages")
    }
}

private struct TabAccessibility: ViewModifier {
    let page: HomePage
    let selected: Bool
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(page.title)
            .accessibilityAddTraits(selected ? [.isSelected, .isHeader] : [])
            .accessibilityIdentifier("pageDot-\(page.title)")
    }
}

/// Picture Book's cut-paper rectangle: four slightly different corner radii, so
/// keys and mats look trimmed by hand. `seed` picks one of a few cuts.
nonisolated struct PaperShape: InsettableShape {
    var seed = 0
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let cuts: [RectangleCornerRadii] = [
            .init(topLeading: 16, bottomLeading: 13, bottomTrailing: 18, topTrailing: 12),
            .init(topLeading: 14, bottomLeading: 17, bottomTrailing: 12, topTrailing: 16),
            .init(topLeading: 18, bottomLeading: 12, bottomTrailing: 15, topTrailing: 14),
        ]
        let r = cuts[abs(seed) % cuts.count]
        let scale = min(1, min(rect.width, rect.height) / 44)
        let radii = RectangleCornerRadii(topLeading: r.topLeading * scale, bottomLeading: r.bottomLeading * scale,
                                         bottomTrailing: r.bottomTrailing * scale, topTrailing: r.topTrailing * scale)
        return UnevenRoundedRectangle(cornerRadii: radii, style: .continuous).path(in: rect.insetBy(dx: inset, dy: inset))
    }

    func inset(by amount: CGFloat) -> PaperShape { PaperShape(seed: seed, inset: inset + amount) }
}

// MARK: - Moon key

/// The Moon key: one paper bar. The moon turns Sleep on and off; while it is on the
/// bar takes the accent and carries the status and the −5 / +5 keys. The ten fade
/// steps live in `FadeMarks`, drawn from the Scene.
struct LookMoonKey: View {
    let status: SleepStatus
    let action: () -> Void
    let onAdjust: (Int) -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The step just taken, floating up and fading out, so the step size is never a guess.
    @State private var echo: (text: String, id: Int)?
    @State private var echoRising = false

    private var isOn: Bool { status != .off }
    private var ink: Color { isOn ? theme.onAccent : theme.text }
    private var isFading: Bool {
        if case .fading = status { return true }
        return false
    }

    var body: some View {
        // Stacked at accessibility sizes, so the status never truncates beside the keys.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s))
            : AnyLayout(HStackLayout(spacing: Space.s))
        layout {
            HStack(spacing: Space.m) {
                Button(action: action) { well }
                    .buttonStyle(PressDim())
                    .accessibilityLabel("Sleep")
                    .accessibilityValue(MoonKey.accessibilityValue(for: status))
                    .accessibilityHint(isOn ? "Turns Sleep off and restores volume." : "Fades the episode out, then pauses.")
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                    .accessibilityIdentifier("moonKey")
                words
                Spacer(minLength: 0)
            }
            if isOn {
                HStack(spacing: Space.s) {
                    StepKey(minutes: -5, ink: ink) { step(-5) }
                        .disabled(isFading)
                        .opacity(isFading ? 0.4 : 1)
                    StepKey(minutes: 5, ink: ink) { step(5) }
                }
                .overlay(alignment: .top) {
                    if let echo {
                        Text(echo.text)
                            .font(Typo.small)
                            .offset(y: echoRising && !reduceMotion ? -34 : -16)
                            .opacity(echoRising ? 0 : 1)
                            .id(echo.id)
                            .fixedSize()
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .transition(.opacity)
            }
        }
        .foregroundStyle(ink)
        .padding(Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(seed: 2, fill: isOn ? theme.accent : theme.surface)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityElement(children: .contain)
    }

    /// The status beside the moon. Tapping it works the moon too; VoiceOver reads the
    /// countdown as its own element, after the Sleep key.
    private var words: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Space.s) {
                Text(title).font(Typo.title).textCase(Typo.titleCase)
                if case .waiting = status { AccentHeart() }
            }
            .accessibilityHidden(true)
            // The invitation is dropped at accessibility sizes, where the bar must stay on screen.
            if isOn || !typeSize.isAccessibilitySize {
                Text(subtitle)
                    .font(.system(.subheadline, weight: .semibold))
                    .opacity(0.85)
                    .contentTransition(.numericText())
                    .accessibilityLabel(spoken)
                    .accessibilityHidden(!isOn)
                    .accessibilityIdentifier(isOn ? "sleepCountdown" : "sleepInvitation")
            }
        }
        .lineLimit(typeSize.isAccessibilitySize ? 3 : 1)
        // "Lights going down" beside two step keys on a 375 pt phone needs to shrink this far.
        .minimumScaleFactor(0.65)
        .layoutPriority(1)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    private var well: some View {
        Image(systemName: isFading ? "moon.zzz.fill" : "moon.fill")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(ink)
            .contentTransition(.symbolEffect(.replace))
            .frame(width: 48, height: 48)
            .paper(seed: 0, fill: isOn ? Color.black.opacity(0.16) : theme.raised)
            .contentShape(Rectangle())
    }

    private func step(_ minutes: Int) {
        onAdjust(minutes)
        echo = (minutes > 0 ? "+5 min" : "−5 min", (echo?.id ?? 0) + 1)
        echoRising = false
        withAnimation(.easeOut(duration: 0.9)) { echoRising = true }
    }

    private var title: String {
        switch status {
        case .off: "Ready for bed?"
        case .waiting: "Sweet dreams"
        case .fading: theme.style == .pictureBook ? "Lights going down" : "Drifting off"
        }
    }

    private var subtitle: String {
        switch status {
        case .off: "Tap the moon to fade out"
        case .waiting(let t): "Fades in \(TimeFormat.sleepDelayLong(t))"
        case .fading(let level): "Volume \(Int((level * 100).rounded()))%"
        }
    }

    /// The countdown for VoiceOver, in the short form the chip used to speak.
    private var spoken: String {
        switch status {
        case .off: ""
        case .waiting(let t): "Fades in \(TimeFormat.sleepDelay(t))"
        case .fading(let level): "Fading, volume \(Int((level * 100).rounded())) percent"
        }
    }
}

extension SleepStatus {
    /// Volume left, 1 until the fade starts.
    var moonLit: Double {
        switch self {
        case .off, .waiting: 1
        case .fading(let level): level
        }
    }
}

/// Press feedback without a physical edge.
struct PressDim: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(reduceMotion ? nil : Motion.press, value: configuration.isPressed)
    }
}
