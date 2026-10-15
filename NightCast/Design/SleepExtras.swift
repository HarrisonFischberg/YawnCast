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

/// Little "z"s that drift up out of the moon while Sleep is on: slow, soft,
/// slightly swaying. Still (three resting z's) when Reduce Motion is on.
struct FloatingZs: View {
    var isFading = false
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Text("z")
                            .font(.system(size: 12 + CGFloat(i) * 5, weight: .heavy, design: .rounded))
                            .rotationEffect(.degrees(-12))
                            .offset(y: -CGFloat(i) * 8)
                    }
                }
                .foregroundStyle(theme.accent.opacity(0.85))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    Canvas { canvas, size in
                        let t = context.date.timeIntervalSinceReferenceDate
                        // Drowsier when fading: slower rise.
                        let period = isFading ? 5.5 : 4.2
                        let z = canvas.resolve(
                            Text("z").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(theme.accent)
                        )
                        for i in 0..<4 {
                            let phase = (t / period + Double(i) / 4).truncatingRemainder(dividingBy: 1)
                            var layer = canvas
                            layer.opacity = sin(phase * .pi) * 0.9
                            layer.translateBy(
                                x: 14 + phase * 34 + sin((t + Double(i) * 1.7) * 1.4) * 7,
                                y: size.height * (1 - phase)
                            )
                            layer.rotate(by: .degrees(-14 + sin(t * 0.9 + Double(i)) * 9))
                            let scale = 0.45 + phase * 0.75
                            layer.scaleBy(x: scale, y: scale)
                            layer.draw(z, at: .zero)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
