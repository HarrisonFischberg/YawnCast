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
        // iOS 26: the three tabs float as one glass pill over the Scene.
        .padding(.horizontal, Space.xs)
        .nightGlass(in: Capsule()) {}
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

/// The Sleep panel: a dark inset plate with the glowing crescent on the left, the
/// state on the right and, while Sleep is on, the −5 · 17 min · +5 row beneath.
/// One panel for every theme; the crescent follows the scene.
struct LookMoonKey: View {
    let status: SleepStatus
    /// Audio paused: the z's hold still (Sleep stays on).
    var paused = false
    /// When Sleep was last switched on here; drives the one-time bloom and burst.
    var activatedAt: Date?
    /// ±5 handler; nil hides the row.
    var onAdjust: ((Int) -> Void)?
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isOn: Bool { status != .off }
    private static let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            toggle
            if isOn, let onAdjust {
                SleepChip(status: status, onAdjust: onAdjust)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 6)))
            }
        }
        .padding(Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Self.shape
                .fill(theme.surface.opacity(0.9))
                .overlay(Self.shape.strokeBorder(theme.border.opacity(0.8), lineWidth: 1))
                .shadow(color: .black.opacity(theme.shadowOpacity * 0.5), radius: 14, y: 6)
        }
        // The z's rise out of the crescent, up past the panel's top edge, well short of
        // the transport keys. They never take taps.
        .overlay(alignment: .topLeading) {
            if isOn {
                FloatingZs(isFading: isFading, paused: paused, level: status.moonLit, activatedAt: activatedAt)
                    .frame(width: 112, height: 84)
                    .offset(x: Space.m, y: -44)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.75), value: isOn)
    }

    private var toggle: some View {
        Button(action: action) {
            HStack(spacing: Space.l) {
                well
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Typo.title)
                        .textCase(Typo.titleCase)
                        .foregroundStyle(theme.text)
                    Text(subtitle)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(theme.textMuted)
                        .contentTransition(.numericText())
                }
                .lineLimit(typeSize.isAccessibilitySize ? 3 : 2)
                .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
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

    /// The crescent in its ring. Off: resting, in ink. On: lit in the accent with a
    /// halo that blooms once (a spring overshoot) and softens as the audio fades.
    private var well: some View {
        let lit = status.moonLit
        return ZStack {
            Circle().fill(theme.raised)
            Circle()
                .fill(theme.accent)
                .blur(radius: 14)
                .opacity(isOn ? 0.35 + 0.3 * lit : 0)
                .scaleEffect(isOn ? 1 : 0.5)
            Circle().strokeBorder(theme.accent.opacity(isOn ? 0.45 + 0.4 * lit : 0.2), lineWidth: 1.5)
            SleepGlyphView(fading: isFading)
                .foregroundStyle(isOn ? theme.accent : theme.text.opacity(0.75))
                .frame(width: 30, height: 30)
                .opacity(isOn ? 0.55 + 0.45 * lit : 1)
        }
        .frame(width: 64, height: 64)
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.45), value: activatedAt)
        .animation(.easeOut(duration: 0.3), value: isOn)
        .accessibilityHidden(true)
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

    /// Off: the tagline, so the key reads as the Moon to tap.
    private var subtitle: String {
        switch status {
        case .off: "Tap the moon and drift off."
        case .waiting(let t): "Fades in \(TimeFormat.sleepDelayLong(t))"
        case .fading(let level): "Volume \(Int((level * 100).rounded()))%"
        }
    }
}

/// The Sleep icon: the scene's own crescent for the bedtime scenes, the older
/// Scenes' symbols (a wave underwater, a tree in the rainforest), else the style's
/// (a lamp in Picture Book, the moon elsewhere).
struct SleepGlyphView: View {
    var fading = false
    @Environment(\.theme) private var theme

    var body: some View {
        if theme.isNight {
            CrescentShape(scene: theme.scene).aspectRatio(1, contentMode: .fit)
        } else {
            Image(systemName: SleepGlyph.symbol(theme: theme, fading: fading))
                .font(.system(size: 24, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
        }
    }
}

enum SleepGlyph {
    static func symbol(theme: Theme, fading: Bool) -> String {
        switch theme.scene {
        case .ocean: return "water.waves"
        case .rainforest: return "tree.fill"
        case .mountain: return "mountain.2.fill"
        case .beach: return "beach.umbrella.fill"
        case .city: return "building.2.fill"
        case .midnight: return "moon.stars.fill"
        default: break
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

/// Sleepy "z"s drifting up out of the crescent: three sparse streams of two or three
/// z's each, five for a moment right after Sleep is switched on. They rise only as
/// far as the canvas, hold still while audio is paused, thin out as the audio fades,
/// and stand still (three resting columns) under Reduce Motion. Fernlight sends
/// firefly lights up too. Decorative only: never the timer, never a tap target.
struct FloatingZs: View {
    var isFading = false
    var paused = false
    /// 1 → 0 as the real fade progresses.
    var level: Double = 1
    var activatedAt: Date?
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Particle clock: wall time minus every pause, so resuming never jumps.
    @State private var pauseStart: Date?
    @State private var pausedTotal: TimeInterval = 0

    /// Each stream: where it starts across, its base rise time, its base size. The
    /// first three run steadily; all five for the activation burst.
    private static let streams: [(x: Double, period: Double, size: Double)] = [
        (12, 6.3, 18), (44, 7.2, 22), (76, 5.6, 16), (28, 5.1, 14), (60, 6.8, 15),
    ]
    private static let perStream = 3
    private static let burstSeconds = 1.6

    private var ink: Color { theme.zColor ?? theme.accent }

    var body: some View {
        Group {
            if reduceMotion {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(0..<3, id: \.self) { line in
                        VStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Text("z")
                                    .font(.system(size: 9 + CGFloat(2 - i) * 3, weight: .heavy, design: .rounded))
                                    .rotationEffect(.degrees(-12))
                            }
                        }
                        .offset(y: -CGFloat(line % 2) * 8)
                    }
                }
                .foregroundStyle(ink.opacity(0.4 + 0.5 * level))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: paused)) { context in
                    Canvas { canvas, size in
                        let now = pauseStart ?? context.date
                        let t = now.timeIntervalSinceReferenceDate - pausedTotal
                        let age = activatedAt.map { now.timeIntervalSince($0) } ?? .infinity
                        let z = canvas.resolve(Text("z").font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(ink))
                        let streams = age < Self.burstSeconds ? Self.streams.count : 3
                        for (n, stream) in Self.streams.prefix(streams).enumerated() {
                            // Burst streams thin out over the last half second.
                            let burst = n < 3 ? 1 : min(1, (Self.burstSeconds - age) / 0.6)
                            for i in 0..<Self.perStream {
                                let seed = Double(n * 7 + i * 3)
                                let period = stream.period * (0.8 + 0.4 * Self.noise(seed)) * (isFading ? 1.3 : 1)
                                let offset = Self.noise(seed + 0.5) + Double(i) / Double(Self.perStream)
                                let progress = t / period + offset
                                let trip = floor(progress)
                                let phase = progress - trip
                                let r1 = Self.noise(seed + trip * 1.37)
                                let r2 = Self.noise(seed + trip * 2.71 + 9)
                                let r3 = Self.noise(seed + trip * 0.91 + 4)
                                let startX = stream.x + (r1 - 0.5) * 14
                                let drift = (r2 - 0.5) * 24 * phase
                                let sway = sin(t * (0.8 + r3) + seed) * (3 + 4 * r3)
                                let rise = 1 - pow(1 - phase, 1.4)
                                var layer = canvas
                                layer.opacity = min(1, phase * 6) * (1 - phase) * 0.95 * (0.3 + 0.7 * level) * burst
                                layer.translateBy(x: startX + drift + sway, y: size.height * (1 - rise * 0.9))
                                if theme.scene == .fernlight, i % 2 == 0 {
                                    // A firefly light, with a soft glow.
                                    let r = 2 + phase * 2
                                    layer.fill(Path(ellipseIn: CGRect(x: -r * 3, y: -r * 3, width: r * 6, height: r * 6)), with: .color(ink.opacity(0.25)))
                                    layer.fill(Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)), with: .color(ink))
                                } else {
                                    layer.rotate(by: .degrees(-18 + (r3 - 0.5) * 30 + sin(t * 0.7 + seed) * 8))
                                    let scale = (stream.size / 20) * (0.5 + phase * 0.6) * (0.85 + 0.3 * r1)
                                    layer.scaleBy(x: scale, y: scale)
                                    layer.draw(z, at: .zero)
                                }
                            }
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { if paused { pauseStart = .now } }
        .onChange(of: paused) { _, nowPaused in
            if nowPaused {
                pauseStart = .now
            } else if let start = pauseStart {
                pausedTotal += Date.now.timeIntervalSince(start)
                pauseStart = nil
            }
        }
    }

    /// A steady pseudo-random number in 0..<1 for a seed.
    private static func noise(_ x: Double) -> Double {
        let v = sin(x * 12.9898 + 78.233) * 43758.5453
        return v - floor(v)
    }
}
