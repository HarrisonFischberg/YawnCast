import YawnCastCore
import SwiftUI

// Shared pieces: the labelled page tabs, the Moon key with its progress bar,
// icon and floating z's.

/// Fade step 0...9 the fade is on, or nil before it starts.
extension SleepStatus {
    var fadeStep: Int? {
        guard case .fading(let level) = self else { return nil }
        return min(9, max(0, Int((10 * (1 - level)).rounded())))
    }
}

// MARK: - Page tabs

/// New · Library · Explore as named tabs, in place of the v0.2 dots. Every style
/// uses Picture Book's: plain labels, the current page on a cut-paper tab.
struct LookTabs: View {
    @Binding var selection: HomePage
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Space.xs) {
            ForEach(HomePage.allCases, id: \.self) { page in
                let on = page == selection
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { selection = page }
                } label: {
                    Text(page.title)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(on ? theme.text : theme.textMuted)
                        .padding(.horizontal, Space.l)
                        .padding(.vertical, 7)
                        .background(on ? PaperShape(seed: 1).fill(theme.raised) : nil)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .modifier(TabAccessibility(page: page, selected: on))
            }
        }
        .frame(maxWidth: .infinity)
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
            .accessibilityAddTraits(selected ? .isSelected : [])
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

/// The Moon key, the same in both styles but for its face: cut paper (Picture
/// Book) or an on-air lamp (Sign-Off).
struct LookMoonKey: View {
    let status: SleepStatus
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    private var isOn: Bool { status != .off }
    private var ink: Color { isOn ? theme.onAccent : theme.text }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            toggle
            if !typeSize.isAccessibilitySize {
                FadeSteps(status: status, ink: ink)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(ink)
        .padding(.horizontal, Space.xl)
        .padding(.vertical, Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { face }
    }

    private var toggle: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.m) {
                HStack(spacing: Space.l) {
                    well
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: Space.s) {
                            Text(title).font(Typo.title).textCase(Typo.titleCase)
                            if case .waiting = status { AccentHeart().accessibilityHidden(true) }
                        }
                        if let subtitle {
                            Text(subtitle)
                                .font(.system(.subheadline, weight: .semibold))
                                .opacity(0.85)
                                .contentTransition(.numericText())
                        }
                    }
                    .lineLimit(typeSize.isAccessibilitySize ? 3 : 1)
                    .minimumScaleFactor(0.75)
                    Spacer(minLength: 0)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressDim())
        .accessibilityLabel("Sleep")
        .accessibilityValue(MoonKey.accessibilityValue(for: status))
        .accessibilityHint(isOn ? "Turns Sleep off and restores volume." : "Fades the episode out, then pauses.")
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier("moonKey")
    }

    /// The bar is slightly see-through, so a Scene shows behind it.
    private static let faceOpacity = 0.88

    @ViewBuilder
    private var face: some View {
        let fill = (isOn ? theme.accent : theme.surface).opacity(Self.faceOpacity)
        switch theme.style {
        case .pictureBook:
            PaperShape(seed: 2).fill(fill)
        case .signOff:
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(fill)
                .shadow(color: isOn ? theme.accent.opacity(0.35) : .clear, radius: 18)
        }
    }

    private var well: some View {
        ZStack {
            wellShape.fill(isOn ? Color.black.opacity(0.16) : theme.raised)
            Image(systemName: SleepGlyph.symbol(theme: theme, fading: isFading))
                .font(.system(size: 26, weight: .semibold))
                // In ink while off; the accent face carries the icon once Sleep is on.
                .foregroundStyle(isOn ? theme.onAccent : theme.text)
                // The icon dims with the volume, step by step.
                .opacity(max(0.35, status.moonLit))
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: 56, height: 56)
        .accessibilityHidden(true)
    }

    private var wellShape: AnyShape {
        switch theme.style {
        case .pictureBook: AnyShape(PaperShape(seed: 0))
        case .signOff: AnyShape(Circle())
        }
    }

    private var isFading: Bool {
        if case .fading = status { return true }
        return false
    }

    private var title: String {
        switch status {
        case .off: "Ready for bed?"
        case .waiting: "Sweet dreams"
        case .fading: theme.style == .pictureBook ? "Lights going down" : "Drifting off"
        }
    }

    private var subtitle: String? {
        switch status {
        case .off: nil
        case .waiting(let t): "Fades in \(TimeFormat.sleepDelayLong(t))"
        case .fading(let level): "Volume \(Int((level * 100).rounded()))%"
        }
    }
}

/// The ten fade steps as a progress bar (Picture Book's, on every style):
/// each mark goes dark as its step passes.
struct FadeSteps: View {
    let status: SleepStatus
    let ink: Color

    /// How many of the ten steps are still to come (lit).
    private var remaining: Int {
        switch status {
        case .off, .waiting: 10
        case .fading(let level): Int((level * 10).rounded())
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<10, id: \.self) { i in
                Capsule()
                    .fill(ink.opacity(status == .off ? 0.25 : (i < 10 - remaining ? 0.2 : 0.9)))
                    .frame(height: 6)
            }
        }
    }
}

/// The Sleep icon: the Scene's own (a wave underwater, a tree in the rainforest),
/// else the style's (a lamp in Picture Book, the moon elsewhere).
enum SleepGlyph {
    static func symbol(theme: Theme, fading: Bool) -> String {
        switch theme.scene {
        case .ocean: return "water.waves"
        case .rainforest: return "tree.fill"
        case .mountain: return "mountain.2.fill"
        case .beach: return "beach.umbrella.fill"
        case .city: return "building.2.fill"
        case .midnight: return "moon.stars.fill"
        case nil: break
        }
        if theme.style == .pictureBook { return "lamp.table.fill" }
        return fading ? "moon.zzz.fill" : "moon.fill"
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
            .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

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
