import YawnCastCore
import SwiftUI

/// The Sleep bubble, at its 1.0 size: it pops up above the Moon bar when Sleep turns on, as −5 · 17 min · +5,
/// and tucks into `SleepBubblePill` after a few quiet seconds.
/// While fading it shows the volume and −5 is off. Each tap floats a small "+5 min" /
/// "−5 min" up out of the bubble, so the step size is never a guess.
struct SleepBubble: View {
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
                .opacity(isFading ? 0.4 : 1)
            readout
                .frame(minWidth: 74)
            StepKey(minutes: 5) { step(5) }
        }
        .padding(.horizontal, 4)
        .background { Capsule().fill(theme.raised).shadow(color: .black.opacity(theme.shadowOpacity * 0.6), radius: 10, y: 4) }
        .overlay(alignment: .top) {
            if let echo {
                Text(echo.text)
                    .font(Typo.small)
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, Space.s)
                    .padding(.vertical, 3)
                    .background { Capsule().fill(theme.raised) }
                    .offset(y: echoRising && !reduceMotion ? -40 : -22)
                    .opacity(echoRising ? 0 : 1)
                    .id(echo.id)
                    .fixedSize()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        // Fixed 44 pt keys: the bubble stops growing here, and the Moon bar says the same words large.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .accessibilityElement(children: .contain)
    }

    /// "17 min", "45 sec" or "40 %": a big numeral and a small unit. Sighted shorthand
    /// for the Moon bar's own line, which is what VoiceOver reads.
    private var readout: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(parts.value)
                .font(Typo.title.monospacedDigit())
                .contentTransition(.numericText())
            Text(parts.unit)
                .font(Typo.small)
                .opacity(0.8)
        }
        .foregroundStyle(theme.text)
        .lineLimit(1)
        .accessibilityHidden(true)
    }

    private var parts: (value: String, unit: String) {
        switch status {
        case .off: return ("", "")
        case .waiting(let t):
            let text = TimeFormat.sleepDelay(t)
            guard let space = text.firstIndex(of: " ") else { return (text, "") }
            return (String(text[..<space]), String(text[text.index(after: space)...]))
        case .fading(let level): return ("\(Int((level * 100).rounded()))", "%")
        }
    }

    private func step(_ minutes: Int) {
        onAdjust(minutes)
        echo = (minutes > 0 ? "+5 min" : "−5 min", (echo?.id ?? 0) + 1)
        echoRising = false
        withAnimation(.easeOut(duration: 0.9)) { echoRising = true }
    }
}

/// A round "−5" / "+5" key in the Sleep bubble: a 40 pt face, 44 pt to tap.
struct StepKey: View {
    let minutes: Int
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Text(minutes > 0 ? "+5" : "−5")
                .font(.system(.body, weight: .semibold).monospacedDigit())
                .foregroundStyle(theme.text)
                .frame(width: 40, height: 40)
                .background(Circle().fill(theme.surface))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(PressDim())
        .accessibilityLabel(minutes > 0 ? "Add 5 minutes" : "Remove 5 minutes")
        .accessibilityIdentifier(minutes > 0 ? "sleepPlus5" : "sleepMinus5")
        .accessibilityShowsLargeContentViewer { Text(minutes > 0 ? "+5 min" : "−5 min") }
    }
}

/// The tucked-away Sleep bubble: a small pill with the time left ("17 min", "40 %").
/// Tap it to open the larger −5 · 17 min · +5 pill.
struct SleepBubblePill: View {
    let status: SleepStatus
    let onExpand: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onExpand) {
            Text(text)
                .font(.system(.footnote, weight: .semibold).monospacedDigit())
                .contentTransition(.numericText())
                .foregroundStyle(theme.text)
                .padding(.horizontal, Space.m)
                .frame(height: 30)
                .background { Capsule().fill(theme.raised) }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressDim())
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .accessibilityLabel("Adjust Sleep")
        .accessibilityValue(text)
        .accessibilityHint("Shows the add and remove 5 minutes keys.")
        .accessibilityIdentifier("sleepBubblePill")
    }

    private var text: String {
        switch status {
        case .off: ""
        case .waiting(let t): TimeFormat.sleepDelay(t)
        case .fading(let level): "\(Int((level * 100).rounded())) %"
        }
    }
}
