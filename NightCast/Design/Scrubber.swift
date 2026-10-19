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
                track(width: width, x: x)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(drag(width: width, thumb: thumb))
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

    /// The track and its marker, in the look's own drawing.
    @ViewBuilder
    private func track(width: CGFloat, x: CGFloat) -> some View {
        let hidden = knownDuration == nil
        let dragging = dragFraction != nil
        switch theme.style {
        case .almanac:
            // A printed rule with an ink fill and a hairline cursor.
            ZStack(alignment: .leading) {
                Rectangle().fill(theme.border).frame(height: 4)
                Rectangle().fill(theme.text).frame(width: max(0, x), height: 4)
                Rectangle().fill(theme.text)
                    .frame(width: dragging ? 6 : 4, height: 26)
                    .offset(x: x - 2)
                    .opacity(hidden ? 0 : 1)
            }
        case .boro:
            // A running stitch, sewn in thread up to the knot.
            ZStack(alignment: .leading) {
                Stitch().stroke(theme.textMuted.opacity(0.45), style: .stitch(3)).frame(height: 4)
                Stitch().stroke(theme.text, style: .stitch(3)).frame(width: max(0, x), height: 4)
                Circle().fill(theme.text)
                    .shadow(color: .black.opacity(theme.shadowOpacity), radius: 3, y: 2)
                    .frame(width: 20, height: 20)
                    .scaleEffect(dragging ? 1.2 : 1)
                    .offset(x: x - 10)
                    .opacity(hidden ? 0 : 1)
            }
        case .safelight:
            ZStack(alignment: .leading) {
                Rectangle().fill(theme.border).frame(height: 6)
                Rectangle().fill(theme.text).frame(width: max(0, x), height: 6)
                RoundedRectangle(cornerRadius: 2).fill(theme.text)
                    .frame(width: dragging ? 8 : 6, height: 26)
                    .offset(x: x - 3)
                    .opacity(hidden ? 0 : 1)
            }
        case .signOff:
            // A tuning scale: minute ticks with a heavier tick every five, and a needle.
            ZStack(alignment: .leading) {
                Canvas { context, size in
                    let count = 40
                    for i in 0...count {
                        let px = CGFloat(i) / CGFloat(count) * size.width
                        let major = i % 5 == 0
                        let h: CGFloat = major ? 20 : 10
                        context.fill(Path(CGRect(x: px - (major ? 1 : 0.75), y: size.height - h, width: major ? 2 : 1.5, height: h)),
                                     with: .color(major ? theme.text : theme.textMuted))
                    }
                }
                .frame(height: 22)
                RoundedRectangle(cornerRadius: 1.5).fill(theme.text)
                    .frame(width: dragging ? 5 : 3, height: 36)
                    .offset(x: x - 1.5)
                    .opacity(hidden ? 0 : 1)
            }
        case .pictureBook:
            ZStack(alignment: .leading) {
                Capsule().fill(theme.raised).frame(height: 10)
                Capsule().fill(theme.text).frame(width: max(10, x), height: 10)
                PaperShape(seed: 1).fill(theme.text)
                    .frame(width: 26, height: 26)
                    .scaleEffect(dragging ? 1.15 : 1)
                    .offset(x: x - 13)
                    .opacity(hidden ? 0 : 1)
            }
        }
    }

    private func drag(width: CGFloat, thumb: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard knownDuration != nil else { return }
                dragFraction = min(1, max(0, (value.location.x - thumb / 2) / max(1, width - thumb)))
            }
            .onEnded { _ in
                if let f = dragFraction, let d = knownDuration { onSeek(f * d) }
                dragFraction = nil
            }
    }

    private var accessibilityValue: String {
        if let d = knownDuration {
            return "\(TimeFormat.spoken(position)) of \(TimeFormat.spoken(d))"
        }
        return "\(TimeFormat.spoken(position)), duration unknown"
    }
}
