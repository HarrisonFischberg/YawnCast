import SwiftUI
import NightCastCore

/// The signature control. One tap turns Sleep on; another turns it off.
/// The five ticks on the right are the five fade steps: all lit while
/// waiting at full volume, going dark one by one as the fade progresses.
struct MoonKey: View {
    let status: SleepStatus
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    private var isOn: Bool { status != .off }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.l) {
                MoonWell(isOn: isOn, isFading: isFading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typo.title)
                    Text(subtitle)
                        .font(Typo.caption)
                        .opacity(0.8)
                        .contentTransition(.numericText())
                }
                .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(0.7)
                Spacer(minLength: Space.s)
                if !typeSize.isAccessibilitySize {
                    FadeTicks(status: status)
                        .accessibilityHidden(true)
                }
            }
            .padding(.leading, Space.m)
            .padding(.trailing, Space.xxl)
            .padding(.vertical, typeSize.isAccessibilitySize ? Space.m : 0)
        }
        .buttonStyle(.capsuleKey(isOn ? .accent : .standard, depth: 6))
        .frame(minHeight: 88)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("Sleep")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(isOn ? "Turns Sleep off and restores volume." : "Fades the episode out, then pauses.")
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier("moonKey")
    }

    private var isFading: Bool {
        if case .fading = status { return true }
        return false
    }

    private var title: String {
        switch status {
        case .off: "Sleep"
        case .waiting: "Sleep on"
        case .fading: "Drifting off"
        }
    }

    private var subtitle: String {
        switch status {
        case .off: "Fade out, then pause"
        case .waiting(let t): "Fade begins in \(TimeFormat.sleepDelay(t))"
        case .fading(let level): "Volume \(Int((level * 100).rounded()))%"
        }
    }

    private var accessibilityValue: String {
        switch status {
        case .off: "Off"
        case .waiting(let t): "On. Fade begins in \(TimeFormat.spoken(t))"
        case .fading(let level): "On. Fading, volume \(Int((level * 100).rounded())) percent"
        }
    }
}

/// A recessed circular well holding the moon glyph.
private struct MoonWell: View {
    let isOn: Bool
    let isFading: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            Circle()
                .fill(isOn ? theme.onAccent.opacity(0.14) : theme.surface)
                .overlay {
                    // Inner shadow: darker at the top, as if pressed into the face.
                    Circle()
                        .stroke(LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                        .blur(radius: 1)
                        .clipShape(Circle())
                }
            Image(systemName: isFading ? "moon.zzz.fill" : "moon.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(isOn ? theme.onAccent : theme.accent)
                .symbolEffect(.bounce, value: isOn)
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: 60, height: 60)
    }
}

private struct FadeTicks: View {
    let status: SleepStatus
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(isLit(index) ? Color.primary : Color.primary.opacity(0.18))
                    .frame(width: 5, height: 10 + CGFloat(index) * 4)
            }
        }
    }

    private func isLit(_ index: Int) -> Bool {
        switch status {
        case .off: false
        case .waiting: true
        case .fading(let level): index < Int((level * 5).rounded())
        }
    }
}
