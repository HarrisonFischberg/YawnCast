import NightCastCore
import SwiftUI

// Almanac look: the farmer's almanac and its lunar tables. Its signature is the
// Sleep fade drawn as ten moon phases, full moon at full volume to new moon at pause.

/// The lit part of a waning moon. `lit` runs from 1 (full) to 0 (new); the lit
/// side is on the left, the terminator an ellipse.
nonisolated struct MoonPhaseShape: Shape {
    var lit: Double

    var animatableData: Double {
        get { lit }
        set { lit = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let k = min(1, max(0, lit))
        let r = min(rect.width, rect.height) / 2
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        guard k > 0.001 else { return path }
        if k >= 0.999 { return Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)) }
        // Left limb: half circle from top to bottom through the left.
        path.move(to: CGPoint(x: c.x, y: c.y - r))
        path.addArc(center: c, radius: r, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: true)
        // Terminator: half ellipse back to the top. Past half lit it bulges right.
        let rx = abs(1 - 2 * k) * r
        let bulgeRight = k > 0.5
        let steps = 24
        for i in 1...steps {
            let t = Double(i) / Double(steps) * .pi
            let y = c.y + r * cos(t)
            let x = c.x + (bulgeRight ? 1 : -1) * rx * sin(t)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.closeSubpath()
        return path
    }
}

/// A moon at a given phase: the dark disc with its lit part on top.
struct MoonPhaseGlyph: View {
    var lit: Double
    var litColor: Color
    var darkColor: Color
    var ring: Color? = nil

    var body: some View {
        ZStack {
            Circle().fill(darkColor)
            MoonPhaseShape(lit: lit).fill(litColor)
            if let ring { Circle().strokeBorder(ring, lineWidth: 1.2) }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

extension SleepStatus {
    /// Volume as the moon's lit fraction: full until the fade starts.
    var moonLit: Double {
        switch self {
        case .off, .waiting: 1
        case .fading(let level): level
        }
    }
}

/// Labelled page tabs between two rules, in place of the page dots.
struct AlmanacTabs: View {
    @Binding var selection: HomePage
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(HomePage.allCases.enumerated()), id: \.element) { index, page in
                if index > 0 { Rectangle().fill(theme.border).frame(width: 0.75) }
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { selection = page }
                } label: {
                    Text(page.title)
                        .font(.system(.footnote, weight: .bold))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(page == selection ? theme.text : theme.textMuted)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(page == selection ? theme.surface : .clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(page.title)
                .accessibilityAddTraits(page == selection ? .isSelected : [])
                .accessibilityIdentifier("pageDot-\(page.title)")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay(alignment: .top) { Rectangle().fill(theme.border).frame(height: 0.75) }
        .overlay(alignment: .bottom) { Rectangle().fill(theme.border).frame(height: 1.5) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pages")
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

/// The Moon key, Almanac edition: today's phase, the title, and all ten phases below.
struct AlmanacMoonKey: View {
    let status: SleepStatus
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    private var isOn: Bool { status != .off }
    private var ink: Color { isOn ? theme.onAccent : theme.text }
    /// Moonlight: pale on every face, so a full moon never reads as a dark disc.
    private var moonlight: Color { theme.colorScheme == .dark && !isOn ? theme.text : Color(hex: 0xFFF6DF) }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.m) {
                HStack(spacing: Space.l) {
                    MoonPhaseGlyph(lit: status.moonLit, litColor: moonlight, darkColor: ink.opacity(0.18), ring: ink.opacity(0.7))
                        .frame(width: 56, height: 56)
                        .animation(.easeInOut(duration: 1.2), value: status.moonLit)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: Space.s) {
                            Text(title).font(Typo.title)
                            if case .waiting = status {
                                AccentHeart().accessibilityHidden(true)
                            }
                        }
                        if let subtitle {
                            Text(subtitle)
                                .font(Typo.almanacItalic)
                                .opacity(0.85)
                                .contentTransition(.numericText())
                        }
                    }
                    .lineLimit(typeSize.isAccessibilitySize ? 3 : 1)
                    .minimumScaleFactor(0.75)
                    Spacer(minLength: 0)
                }
                if !typeSize.isAccessibilitySize {
                    VStack(spacing: 6) {
                        Rectangle().fill(ink.opacity(0.5)).frame(height: 1)
                        HStack(spacing: 0) {
                            ForEach(0..<10, id: \.self) { i in
                                let phase = 1 - Double(i) / 10
                                let current = isCurrent(step: i)
                                MoonPhaseGlyph(lit: phase, litColor: moonlight, darkColor: ink.opacity(0.18), ring: current ? ink : ink.opacity(0.5))
                                    .frame(width: current ? 22 : 16, height: current ? 22 : 16)
                                    .opacity(isPast(step: i) ? 0.35 : 1)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 24)
                        HStack {
                            Text(isOn ? "Full" : "Full volume")
                            Spacer()
                            Text("Pause")
                        }
                        .font(.system(.caption2, weight: .bold))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .opacity(0.75)
                    }
                    .accessibilityHidden(true)
                }
            }
            .foregroundStyle(ink)
            .padding(.horizontal, Space.xl)
            .padding(.vertical, Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isOn ? theme.accent : theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(isOn ? theme.accent : theme.border, lineWidth: 1.5))
            }
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PressDim())
        .accessibilityLabel("Sleep")
        .accessibilityValue(MoonKey.accessibilityValue(for: status))
        .accessibilityHint(isOn ? "Turns Sleep off and restores volume." : "Fades the episode out, then pauses.")
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier("moonKey")
    }

    /// The step the fade is on (0 = full volume, 9 = last step before pause).
    private func isCurrent(step: Int) -> Bool {
        if case .waiting = status { return step == 0 }
        guard case .fading(let level) = status else { return false }
        return step == min(9, max(0, Int((10 * (1 - level)).rounded())))
    }

    private func isPast(step: Int) -> Bool {
        switch status {
        case .off: false
        case .waiting: false
        case .fading(let level): Double(step) < 10 * (1 - level) - 0.5
        }
    }

    private var title: String {
        switch status {
        case .off: "Ready for bed?"
        case .waiting: "Sweet dreams"
        case .fading: "Drifting off"
        }
    }

    private var subtitle: String? {
        switch status {
        case .off: nil
        case .waiting(let t): "Fade in \(TimeFormat.sleepDelayLong(t))."
        case .fading(let level): "Volume \(Int((level * 100).rounded()))%"
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
