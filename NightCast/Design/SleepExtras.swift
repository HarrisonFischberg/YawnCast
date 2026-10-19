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
