import YawnCastCore
import SwiftUI

/// The row inside the Sleep panel while Sleep is on: −5 · 17 min · +5, three keys
/// of equal width. While fading it shows the volume, −5 is off, and +5 pauses the
/// fade (volume glides back up). Each tap floats a small "+5 min" / "−5 min" up
/// from the row so the step size is never a guess.
struct SleepChip: View {
    let status: SleepStatus
    let onAdjust: (Int) -> Void
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The step just taken, floating up and fading out.
    @State private var echo: (text: String, id: Int)?
    @State private var echoRising = false

    private var isFading: Bool {
        if case .fading = status { return true }
        return false
    }

    var body: some View {
        HStack(spacing: Space.s) {
            StepKey(minutes: -5) { step(-5) }
                .disabled(isFading)
                .opacity(isFading ? 0.35 : 1)
            SleepReadout(status: status)
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(StepKey.shape.fill(theme.raised))
            StepKey(minutes: 5) { step(5) }
        }
        .overlay(alignment: .top) {
            if let echo {
                Text(echo.text)
                    .font(Typo.small)
                    .foregroundStyle(theme.text)
                    .offset(y: echoRising && !reduceMotion ? -30 : -10)
                    .opacity(echoRising ? 0 : 1)
                    .id(echo.id)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sleep countdown")
    }

    private func step(_ minutes: Int) {
        onAdjust(minutes)
        echo = (minutes > 0 ? "+5 min" : "−5 min", (echo?.id ?? 0) + 1)
        echoRising = false
        withAnimation(.easeOut(duration: 0.9)) { echoRising = true }
    }
}

/// The time to the fade as a big numeral and a small unit ("17 min", "45 sec"),
/// or the volume while fading ("40 %").
struct SleepReadout: View {
    let status: SleepStatus

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(parts.value)
                .font(Typo.title.monospacedDigit())
                .contentTransition(.numericText())
            Text(parts.unit)
                .font(Typo.small)
                .opacity(0.8)
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .accessibilityIdentifier("sleepCountdown")
    }

    private var parts: (value: String, unit: String) {
        switch status {
        case .off: return ("", "")
        case .waiting(let t):
            // "17 min" / "45 sec" → numeral and unit.
            let text = TimeFormat.sleepDelay(t)
            guard let space = text.firstIndex(of: " ") else { return (text, "") }
            return (String(text[..<space]), String(text[text.index(after: space)...]))
        case .fading(let level): return ("\(Int((level * 100).rounded()))", "%")
        }
    }

    private var spoken: String {
        switch status {
        case .off: ""
        case .waiting(let t): "Fades in \(TimeFormat.sleepDelay(t))"
        case .fading(let level): "Fading, volume \(Int((level * 100).rounded())) percent"
        }
    }
}

/// A "−5" / "+5" key on a raised plate, 48 pt tall.
struct StepKey: View {
    let minutes: Int
    let action: () -> Void
    @Environment(\.theme) private var theme
    static let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)

    var body: some View {
        Button(action: action) {
            Text(minutes > 0 ? "+5" : "−5")
                .font(Typo.bubbleKey.monospacedDigit())
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Self.shape.fill(theme.raised))
                .contentShape(Self.shape)
        }
        .buttonStyle(PressDim())
        .accessibilityLabel(minutes > 0 ? "Add 5 minutes" : "Remove 5 minutes")
        .accessibilityIdentifier(minutes > 0 ? "sleepPlus5" : "sleepMinus5")
    }
}
