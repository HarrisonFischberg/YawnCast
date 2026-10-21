import YawnCastCore
import SwiftUI

/// The chip above the Moon key while Sleep is on: −5 · 17 min · +5.
/// While fading it shows the volume, −5 is off, and +5 pauses the fade (volume
/// glides back up). It stays put; nothing tucks away. Each tap floats a small
/// "+5 min" / "−5 min" up from the chip so the step size is never a guess.
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
        HStack(spacing: 2) {
            StepKey(minutes: -5) { step(-5) }
                .disabled(isFading)
                .opacity(isFading ? 0.35 : 1)
            SleepReadout(status: status)
                .foregroundStyle(theme.text)
                .frame(minWidth: 74)
            StepKey(minutes: 5) { step(5) }
        }
        .padding(.horizontal, 4)
        .background {
            Capsule()
                .fill(theme.raised.opacity(0.92))
                .shadow(color: .black.opacity(theme.shadowOpacity * 0.6), radius: 10, y: 4)
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

/// A round "−5" / "+5" key in the text style's face, 44 pt to tap.
struct StepKey: View {
    let minutes: Int
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Text(minutes > 0 ? "+5" : "−5")
                .font(Typo.bubbleKey.monospacedDigit())
                .foregroundStyle(theme.text)
                .frame(width: 40, height: 40)
                .background(Circle().fill(theme.surface))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(PressDim())
        .accessibilityLabel(minutes > 0 ? "Add 5 minutes" : "Remove 5 minutes")
        .accessibilityIdentifier(minutes > 0 ? "sleepPlus5" : "sleepMinus5")
    }
}
