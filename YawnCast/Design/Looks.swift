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

// MARK: - Floating z's

/// Little "z"s that drift up out of the Sleep icon while Sleep is on and float
/// away up the screen: three loose streams, each z with its own start, pace,
/// sway and size, so they never march in step. Still (three resting columns)
/// with Reduce Motion.
struct FloatingZs: View {
    var isFading = false
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Each stream: where it starts across, its base rise time, its base size.
    private static let streams: [(x: Double, period: Double, size: Double)] = [
        (8, 6.3, 18), (40, 7.9, 22), (70, 5.6, 16),
    ]
    /// z's in the air per stream.
    private static let perStream = 3

    var body: some View {
        Group {
            if reduceMotion {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(0..<3, id: \.self) { line in
                        VStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Text("z")
                                    .font(.system(size: 10 + CGFloat(2 - i) * 4, weight: .heavy, design: .rounded))
                                    .rotationEffect(.degrees(-12))
                            }
                        }
                        .offset(y: -CGFloat(line % 2) * 10)
                    }
                }
                .foregroundStyle(theme.accent.opacity(0.85))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    Canvas { canvas, size in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let z = canvas.resolve(
                            Text("z").font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(theme.accent)
                        )
                        for (n, stream) in Self.streams.enumerated() {
                            for i in 0..<Self.perStream {
                                let seed = Double(n * 7 + i * 3)
                                // Each z keeps its own pace, nudged again on every trip.
                                let period = stream.period * (0.8 + 0.4 * Self.noise(seed)) * (isFading ? 1.3 : 1)
                                let offset = Self.noise(seed + 0.5) + Double(i) / Double(Self.perStream)
                                let progress = t / period + offset
                                let trip = floor(progress)
                                let phase = progress - trip
                                // A fresh start, drift and sway for every trip up.
                                let r1 = Self.noise(seed + trip * 1.37)
                                let r2 = Self.noise(seed + trip * 2.71 + 9)
                                let r3 = Self.noise(seed + trip * 0.91 + 4)
                                let startX = stream.x + (r1 - 0.5) * 22
                                let drift = (r2 - 0.35) * 70 * phase
                                let sway = sin(t * (0.8 + r3) + seed) * (4 + 6 * r3)
                                // Rises the full height, a little faster at first, and fades as it goes.
                                let rise = 1 - pow(1 - phase, 1.4)
                                var layer = canvas
                                layer.opacity = min(1, phase * 6) * (1 - phase) * 0.95
                                layer.translateBy(x: startX + drift + sway, y: size.height * (1 - rise))
                                layer.rotate(by: .degrees(-18 + (r3 - 0.5) * 30 + sin(t * 0.7 + seed) * 8))
                                let scale = (stream.size / 20) * (0.5 + phase * 0.8) * (0.85 + 0.3 * r1)
                                layer.scaleBy(x: scale, y: scale)
                                layer.draw(z, at: .zero)
                            }
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// A steady pseudo-random number in 0..<1 for a seed.
    private static func noise(_ x: Double) -> Double {
        let v = sin(x * 12.9898 + 78.233) * 43758.5453
        return v - floor(v)
    }
}
