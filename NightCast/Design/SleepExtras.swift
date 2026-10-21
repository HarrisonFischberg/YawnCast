import NightCastCore
import SwiftUI

/// The bubble above the Moon key while Sleep is on: "−5 min · Fade in 30 min · +5 min".
/// While fading, −5 is off and +5 pauses the fade (volume glides back up).
struct SleepAdjustBubble: View {
    let status: SleepStatus
    let onAdjust: (Int) -> Void
    var onCollapse: () -> Void = {}
    @Environment(\.theme) private var theme

    private var isFading: Bool {
        if case .fading = status { return true }
        return false
    }

    var body: some View {
        HStack(spacing: 0) {
            stepButton("−5", label: "Remove 5 minutes", minutes: -5)
                .disabled(isFading)
                .opacity(isFading ? 0.35 : 1)
            Button(action: onCollapse) {
                Text(centerText)
                    .font(Typo.caption.monospacedDigit())
                    .foregroundStyle(theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(minWidth: 112, minHeight: 44)
                    .contentTransition(.numericText())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(centerText)
            .accessibilityHint("Tucks the countdown into a small bubble.")
            .accessibilityIdentifier("sleepCountdown")
            stepButton("+5", label: "Add 5 minutes", minutes: 5)
        }
        .padding(.horizontal, Space.xs)
        .background {
            Capsule()
                .fill(theme.raised)
                .overlay(Capsule().strokeBorder(theme.border, lineWidth: 1))
                .shadow(color: .black.opacity(theme.shadowOpacity), radius: 10, y: 4)
        }
        .overlay(alignment: .bottom) {
            // Small tail pointing down at the Moon key.
            BubbleTail()
                .fill(theme.raised)
                .overlay(BubbleTail().stroke(theme.border, lineWidth: 1).mask(Rectangle().padding(.top, 1)))
                .frame(width: 18, height: 9)
                .offset(y: 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sleep countdown")
    }

    private var centerText: String {
        switch status {
        case .off: ""
        case .waiting(let t): "Fade in \(TimeFormat.sleepDelay(t))"
        case .fading(let level): "Fading · \(Int((level * 100).rounded()))%"
        }
    }

    private func stepButton(_ title: String, label: String, minutes: Int) -> some View {
        Button { onAdjust(minutes) } label: {
            Text(title + " min")
                .font(Typo.headline.monospacedDigit())
                .foregroundStyle(theme.text)
                .frame(minWidth: 64, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(minutes > 0 ? "sleepPlus5" : "sleepMinus5")
    }
}

/// The tucked-away bubble: a small pill above the Moon key; tap to open the ±5 controls.
struct CollapsedSleepPill: View {
    let status: SleepStatus
    let onExpand: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: Space.xs) {
                Image(systemName: "timer")
                Text(shortText).monospacedDigit().contentTransition(.numericText())
                Image(systemName: "chevron.up").font(.system(size: 10, weight: .bold))
            }
            .font(Typo.caption)
            .foregroundStyle(theme.text)
            .padding(.horizontal, Space.m)
            .frame(minHeight: 44)
            .background {
                Capsule()
                    .fill(theme.raised)
                    .overlay(Capsule().strokeBorder(theme.border, lineWidth: 1))
                    .shadow(color: .black.opacity(theme.shadowOpacity), radius: 8, y: 3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sleep countdown, \(shortText)")
        .accessibilityHint("Shows the add and remove 5 minutes controls.")
        .accessibilityIdentifier("sleepBubbleCollapsed")
    }

    private var shortText: String {
        switch status {
        case .off: ""
        case .waiting(let t): TimeFormat.sleepDelay(t)
        case .fading(let level): "\(Int((level * 100).rounded()))%"
        }
    }
}

private struct BubbleTail: Shape {
    nonisolated init() {}
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
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
