import YawnCastCore
import SwiftUI

// Shared pieces: the page tabs, the cut-paper shape and the Moon bar.

// MARK: - Page tabs

/// New · Library · Explore in one pill. The bright thumb slides to the current page, which
/// is also the page's title, so no page repeats its name underneath.
struct LookTabs: View {
    @Binding var selection: HomePage
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var thumb

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomePage.allCases, id: \.self) { page in
                let on = page == selection
                Button {
                    withAnimation(reduceMotion ? nil : Motion.slide) { selection = page }
                } label: {
                    Text(page.title)
                        .font(Typo.headline)
                        .foregroundStyle(on ? theme.bg : theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, Space.s)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            if on { Capsule().fill(theme.text).matchedGeometryEffect(id: "thumb", in: thumb) }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressDim())
                .accessibilityShowsLargeContentViewer { Text(page.title) }
                .modifier(TabAccessibility(page: page, selected: on))
            }
        }
        .padding(Space.xs)
        .background { Capsule().fill(theme.surface) }
        // Also when the page was changed by a swipe: the thumb follows as the page lands.
        .animation(reduceMotion ? nil : Motion.slide, value: selection)
        // Three segments share one row; past this size they would truncate, so they stop
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

/// The Moon bar: the largest control on Now Playing. The moon turns Sleep on and off;
/// while it is on the bar takes the accent and says what will happen. The −5 / +5 keys
/// live in the `SleepBubble` that pops up above it.
struct LookMoonKey: View {
    let status: SleepStatus
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.isEnabled) private var isEnabled

    private var isOn: Bool { status != .off }
    private var ink: Color { isOn ? theme.onAccent : theme.text }
    private var isFading: Bool {
        if case .fading = status { return true }
        return false
    }

    var body: some View {
        HStack(spacing: Space.l) {
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
        VStack(alignment: .leading, spacing: Space.xs) {
            // At accessibility sizes the bar has to stay on screen: while Sleep is on it keeps
            // only the line that matters (the countdown), and the title is smaller while off.
            if !(isOn && typeSize.isAccessibilitySize) {
                HStack(spacing: Space.s) {
                    Text(title).font(typeSize.isAccessibilitySize ? Typo.title : Typo.sectionTitle).textCase(Typo.titleCase)
                    if case .waiting = status { AccentHeart() }
                }
                .accessibilityHidden(true)
            }
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
        .minimumScaleFactor(0.65)
        .layoutPriority(1)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    private var well: some View {
        Image(systemName: isFading ? "moon.zzz.fill" : "moon.fill")
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(ink)
            .contentTransition(.symbolEffect(.replace))
            .frame(width: typeSize.isAccessibilitySize ? 52 : 68, height: typeSize.isAccessibilitySize ? 52 : 68)
            .paper(seed: 0, fill: isOn ? Color.black.opacity(0.16) : theme.raised)
            .contentShape(Rectangle())
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
