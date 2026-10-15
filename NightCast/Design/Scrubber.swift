import SwiftUI
import NightCastCore

/// Thick, easy-to-grab position control. Drag anywhere on the track; the
/// seek is committed on release. VoiceOver adjusts in 15 s steps.
struct Scrubber: View {
    let position: TimeInterval
    let duration: TimeInterval?
    let onSeek: (TimeInterval) -> Void

    @Environment(\.theme) private var theme
    @State private var dragFraction: Double?

    private var knownDuration: TimeInterval? {
        guard let duration, duration.isFinite, duration > 0 else { return nil }
        return duration
    }

    private var fraction: Double {
        if let dragFraction { return dragFraction }
        guard let d = knownDuration else { return 0 }
        return min(1, max(0, position / d))
    }

    private var shownPosition: TimeInterval {
        if let dragFraction, let d = knownDuration { return dragFraction * d }
        return position
    }

    var body: some View {
        VStack(spacing: Space.s) {
            GeometryReader { geo in
                let width = geo.size.width
                let thumb: CGFloat = 28
                let x = thumb / 2 + (width - thumb) * fraction
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.surface)
                        .overlay(Capsule().stroke(theme.border, lineWidth: 1))
                        .frame(height: 10)
                    Capsule()
                        .fill(theme.text)
                        .frame(width: max(10, x), height: 10)
                    Circle()
                        .fill(theme.raised)
                        .overlay(Circle().stroke(theme.border, lineWidth: 1))
                        .shadow(color: .black.opacity(theme.shadowOpacity), radius: 4, y: 2)
                        .frame(width: thumb, height: thumb)
                        .scaleEffect(dragFraction == nil ? 1 : 1.15)
                        .offset(x: x - thumb / 2)
                        .opacity(knownDuration == nil ? 0 : 1)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard knownDuration != nil else { return }
                            dragFraction = min(1, max(0, (value.location.x - thumb / 2) / max(1, width - thumb)))
                        }
                        .onEnded { _ in
                            if let f = dragFraction, let d = knownDuration { onSeek(f * d) }
                            dragFraction = nil
                        }
                )
                .animation(.spring(response: 0.2), value: dragFraction == nil)
            }
            .frame(height: 44)

            HStack {
                Text(TimeFormat.clock(shownPosition))
                Spacer()
                Text(knownDuration.map { TimeFormat.remaining(max(0, $0 - shownPosition)) } ?? "--:--")
            }
            .font(Typo.digits)
            .foregroundStyle(theme.textMuted)
        }
        .sensoryFeedback(.selection, trigger: dragFraction == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Playback position")
        .accessibilityValue(accessibilityValue)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onSeek(SeekMath.skip(from: position, by: 15, duration: knownDuration))
            case .decrement: onSeek(SeekMath.skip(from: position, by: -15, duration: knownDuration))
            @unknown default: break
            }
        }
        .accessibilityIdentifier("scrubber")
    }

    private var accessibilityValue: String {
        if let d = knownDuration {
            return "\(TimeFormat.spoken(position)) of \(TimeFormat.spoken(d))"
        }
        return "\(TimeFormat.spoken(position)), duration unknown"
    }
}
