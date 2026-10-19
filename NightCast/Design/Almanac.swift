import NightCastCore
import SwiftUI

// Almanac look: the farmer's almanac. A masthead with the fade time, an italic dateline.

extension SleepStatus {
    /// Volume left, 1 until the fade starts.
    var moonLit: Double {
        switch self {
        case .off, .waiting: 1
        case .fading(let level): level
        }
    }
}

/// Top line of every home page: the name, and the fade time while Sleep is on.
struct AlmanacMasthead: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("NightCast")
                Spacer()
                if let fadeAt {
                    Text("Fade at \(fadeAt.formatted(date: .omitted, time: .shortened))")
                        .foregroundStyle(theme.text)
                }
            }
            .font(.system(.caption2, weight: .bold))
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(theme.textMuted)
            // Double rule, heavy over light.
            VStack(spacing: 2.5) {
                Rectangle().fill(theme.border).frame(height: 1.5)
                Rectangle().fill(theme.border).frame(height: 0.75)
            }
            .accessibilityHidden(true)
        }
    }

    private var fadeAt: Date? {
        if case .waiting(let t) = model.sleepStatus { return Date.now.addingTimeInterval(t) }
        return nil
    }
}

/// Italic dateline under a page title: "Sunday, the nineteenth of October".
struct AlmanacDateline: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Text(Self.text())
            .font(Typo.almanacItalic)
            .foregroundStyle(theme.textMuted)
    }

    static func text(_ date: Date = .now, calendar: Calendar = .current) -> String {
        let weekday = date.formatted(.dateTime.weekday(.wide))
        let month = date.formatted(.dateTime.month(.wide))
        let day = calendar.component(.day, from: date)
        return "\(weekday), the \(ordinalWord(day)) of \(month)"
    }

    /// 19 -> "nineteenth", 21 -> "twenty-first".
    static func ordinalWord(_ n: Int) -> String {
        let spell = NumberFormatter()
        spell.numberStyle = .spellOut
        spell.locale = Locale(identifier: "en_US")
        if let word = spell.string(from: NSNumber(value: n)) {
            let irregular = ["one": "first", "two": "second", "three": "third", "five": "fifth", "eight": "eighth", "nine": "ninth", "twelve": "twelfth"]
            var parts = word.split(separator: "-").map(String.init)
            let last = parts.removeLast()
            let ord: String
            if let i = irregular[last] { ord = i }
            else if last.hasSuffix("y") { ord = String(last.dropLast()) + "ieth" }
            else { ord = last + "th" }
            return (parts + [ord]).joined(separator: "-")
        }
        return "\(n)"
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
