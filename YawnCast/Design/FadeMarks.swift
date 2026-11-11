import YawnCastCore
import SwiftUI

/// The ten fade steps, drawn from the Scene's own world: ten lights that go out one
/// per step, left to right. The mechanic, positions and spoken value are the same
/// everywhere; only the drawing changes.
enum FadeMotif {
    /// City Scape, and the flat colours: paper lanterns on a sagging wire.
    case lanterns
    /// Rainforest: fireflies, no wire.
    case fireflies
    /// Underwater: glowing jellyfish.
    case jellyfish
    /// Beach: little boats on the waterline, sails lit.
    case boats
    /// Mountain Vista: tents on a ridge, lit from inside.
    case tents
    /// Midnight: a constellation.
    case stars

    init(_ scene: SceneKind?) {
        switch scene {
        case .rainforest: self = .fireflies
        case .ocean: self = .jellyfish
        case .beach: self = .boats
        case .mountain: self = .tents
        case .midnight: self = .stars
        case .city, nil: self = .lanterns
        }
    }
}

extension SleepStatus {
    /// Fade steps still to come, of ten; none while Sleep is off.
    var litSteps: Int {
        switch self {
        case .off: 0
        case .waiting: 10
        case .fading(let level): Int((level * 10).rounded())
        }
    }

    /// What VoiceOver reads for the fade marks: "Volume 60%, 6 of 10".
    var fadeMarksValue: String {
        switch self {
        case .off: "Off"
        case .waiting(let t): "Fades in \(TimeFormat.sleepDelayLong(t)), 10 of 10"
        case .fading(let level): "Volume \(Int((level * 100).rounded()))%, \(litSteps) of 10"
        }
    }
}

/// The strip of ten marks on Now Playing.
struct FadeMarks: View {
    let status: SleepStatus
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: reduceMotion)) { context in
            FadeMarksCanvas(
                motif: FadeMotif(theme.scene), lit: Double(status.litSteps),
                // Reduce Motion: the marks hold still and only cross-fade when one goes out.
                time: reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate,
                glow: theme.fadeMark, ink: theme.text, ground: theme.bg
            )
        }
        .animation(Motion.lightsOut, value: status.litSteps)
        .frame(height: 58)
        .accessibilityElement()
        .accessibilityLabel("Fade steps")
        .accessibilityValue(status.fadeMarksValue)
        .accessibilityHidden(status == .off)
        .accessibilityIdentifier("fadeMarks")
    }
}

/// The same ten steps as dots, for the mini player.
struct FadeDots: View {
    let status: SleepStatus
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { i in
                let lit = i >= 10 - status.litSteps
                Circle().fill(lit ? theme.fadeMark : .clear)
                    .overlay(Circle().strokeBorder(theme.text.opacity(lit ? 0 : 0.6), lineWidth: 1))
                    .frame(width: 7, height: 7)
            }
        }
        .animation(Motion.lightsOut, value: status.litSteps)
        .accessibilityHidden(true) // the Moon key beside it carries the value
    }
}

/// Draws the marks. `lit` animates, so a mark fades out rather than snapping.
private struct FadeMarksCanvas: View, Animatable {
    let motif: FadeMotif
    var lit: Double
    let time: Double
    let glow: Color
    let ink: Color
    let ground: Color

    var animatableData: Double {
        get { lit }
        set { lit = newValue }
    }

    var body: some View {
        Canvas { c, size in
            let w = size.width
            support(&c, w)
            for i in 0..<10 {
                let x = w * (CGFloat(i) + 0.5) / 10
                // Marks go out from the left; 0 is dark, 1 is fully lit.
                let brightness = min(1, max(0, lit - Double(9 - i)))
                mark(&c, i, CGPoint(x: x, y: anchorY(i, x, w)), brightness)
            }
        }
    }

    /// A slow, small drift so the marks feel alive; each has its own phase.
    private func drift(_ i: Int, _ speed: Double, _ amount: CGFloat) -> CGFloat {
        CGFloat(sin(time * speed + Double(i) * 1.7)) * amount
    }

    /// Where mark `i` hangs, floats or stands.
    private func anchorY(_ i: Int, _ x: CGFloat, _ w: CGFloat) -> CGFloat {
        switch motif {
        case .lanterns:
            let u = (x - w / 2) / (w / 2)
            return 4 + (20 + drift(0, 0.6, 1.5)) * (1 - u * u) // the wire breathes a point or two
        case .fireflies: return 28 + CGFloat(sin(Double(i) * 1.3)) * 12 + drift(i, 0.9, 3)
        case .jellyfish: return 22 + CGFloat(sin(Double(i) * 0.9)) * 8 + drift(i, 0.7, 3)
        case .boats: return 40 + drift(i, 0.8, 1.5)
        case .tents: return 46 - CGFloat(sin(Double(i) * 0.7 + 0.4)) * 6
        case .stars: return 28 + CGFloat(sin(Double(i) * 1.9)) * 13
        }
    }

    /// What the marks hang from or stand on.
    private func support(_ c: inout GraphicsContext, _ w: CGFloat) {
        var line = Path()
        switch motif {
        case .lanterns:
            for x in stride(from: CGFloat(0), through: w + 6, by: 6) {
                let p = CGPoint(x: x, y: anchorY(0, x, w))
                x == 0 ? line.move(to: p) : line.addLine(to: p)
            }
            c.stroke(line, with: .color(ink.opacity(0.5)), lineWidth: 1.5)
        case .boats:
            for x in stride(from: CGFloat(0), through: w + 4, by: 4) {
                let p = CGPoint(x: x, y: 47 + CGFloat(sin(Double(x) * 0.09 + time * 0.8)) * 1.5)
                x == 0 ? line.move(to: p) : line.addLine(to: p)
            }
            c.stroke(line, with: .color(ink.opacity(0.5)), lineWidth: 1.5)
        case .tents:
            line.move(to: CGPoint(x: 0, y: 47))
            for i in 0..<10 {
                let x = w * (CGFloat(i) + 0.5) / 10
                line.addLine(to: CGPoint(x: x, y: anchorY(i, x, w)))
            }
            line.addLine(to: CGPoint(x: w, y: 44))
            c.stroke(line, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
        case .stars:
            for i in 0..<10 {
                let x = w * (CGFloat(i) + 0.5) / 10
                let p = CGPoint(x: x, y: anchorY(i, x, w))
                i == 0 ? line.move(to: p) : line.addLine(to: p)
            }
            c.stroke(line, with: .color(ink.opacity(0.28)), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
        case .fireflies, .jellyfish:
            break
        }
    }

    /// One mark: its dark outline always, its lit face on top at `b`.
    private func mark(_ c: inout GraphicsContext, _ i: Int, _ p: CGPoint, _ b: Double) {
        let dark = GraphicsContext.Shading.color(ink.opacity(0.6)) // 0.6 keeps 3:1 on every colour (contrast.py)
        let lit = GraphicsContext.Shading.color(glow.opacity(b))
        func outlined(_ shape: Path) {
            // A keyline in the ground colour first, so a mark keeps its edge over a
            // bright part of a Scene (the Beach moon, Mountain mist).
            c.stroke(shape, with: .color(ground), lineWidth: 5)
            c.fill(shape, with: .color(ground))
            c.stroke(shape, with: dark, lineWidth: 1.5)
            if b > 0 { c.fill(shape, with: lit) }
        }
        switch motif {
        case .lanterns:
            c.fill(Path(CGRect(x: p.x - 3, y: p.y, width: 6, height: 8)), with: dark)
            outlined(Path(roundedRect: CGRect(x: p.x - 9, y: p.y + 7, width: 18, height: 22), cornerRadius: 8, style: .continuous))

        case .fireflies:
            // Two wings, a body, and a halo while it glows.
            for side in [-1.0, 1.0] {
                let wing = Path(ellipseIn: CGRect(x: -3, y: -9, width: 6, height: 10))
                    .applying(CGAffineTransform(rotationAngle: side * 0.7).concatenating(.init(translationX: p.x + side * 5, y: p.y - 3)))
                c.fill(wing, with: .color(ink.opacity(0.45)))
            }
            if b > 0 { c.fill(Path(ellipseIn: CGRect(x: p.x - 12, y: p.y - 12, width: 24, height: 24)), with: .color(glow.opacity(0.22 * b))) }
            outlined(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)))

        case .jellyfish:
            // Tentacles first, then the bell over them.
            for k in -1...1 {
                var t = Path()
                let x = p.x + CGFloat(k) * 5
                t.move(to: CGPoint(x: x, y: p.y + 4))
                t.addQuadCurve(to: CGPoint(x: x + drift(i + k, 1.3, 2), y: p.y + 18), control: CGPoint(x: x - 3, y: p.y + 11))
                c.stroke(t, with: dark, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                if b > 0 { c.stroke(t, with: lit, style: StrokeStyle(lineWidth: 1.5, lineCap: .round)) }
            }
            var bell = Path()
            bell.move(to: CGPoint(x: p.x - 10, y: p.y + 5))
            bell.addCurve(to: CGPoint(x: p.x + 10, y: p.y + 5), control1: CGPoint(x: p.x - 10, y: p.y - 13), control2: CGPoint(x: p.x + 10, y: p.y - 13))
            bell.closeSubpath()
            outlined(bell)

        case .boats:
            var hull = Path()
            hull.move(to: CGPoint(x: p.x - 10, y: p.y))
            hull.addLine(to: CGPoint(x: p.x + 10, y: p.y))
            hull.addLine(to: CGPoint(x: p.x + 6, y: p.y + 6))
            hull.addLine(to: CGPoint(x: p.x - 6, y: p.y + 6))
            hull.closeSubpath()
            c.fill(hull, with: .color(ink.opacity(0.75)))
            var sail = Path()
            sail.move(to: CGPoint(x: p.x - 1, y: p.y - 24))
            sail.addLine(to: CGPoint(x: p.x + 9, y: p.y - 3))
            sail.addLine(to: CGPoint(x: p.x - 8, y: p.y - 3))
            sail.closeSubpath()
            outlined(sail)

        case .tents:
            var tent = Path()
            tent.move(to: CGPoint(x: p.x, y: p.y - 22))
            tent.addLine(to: CGPoint(x: p.x + 11, y: p.y))
            tent.addLine(to: CGPoint(x: p.x - 11, y: p.y))
            tent.closeSubpath()
            outlined(tent)
            // The door flap, dark against the lit canvas.
            var door = Path()
            door.move(to: CGPoint(x: p.x, y: p.y - 11))
            door.addLine(to: CGPoint(x: p.x + 4, y: p.y))
            door.addLine(to: CGPoint(x: p.x - 4, y: p.y))
            door.closeSubpath()
            c.fill(door, with: .color(ground.opacity(0.85 * b)))

        case .stars:
            // A dark star is a small ring; a lit one is a four-point sparkle that twinkles.
            c.stroke(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)), with: .color(ink.opacity(0.6 * (1 - b))), lineWidth: 1.5)
            guard b > 0 else { return }
            let r = 12 * (0.92 + 0.08 * (1 + drift(i, 1.6, 1))) * CGFloat(0.5 + 0.5 * b)
            var star = Path()
            for k in 0..<8 {
                let angle = Double(k) * .pi / 4 - .pi / 2
                let radius = k % 2 == 0 ? r : r * 0.34
                let q = CGPoint(x: p.x + CGFloat(cos(angle)) * radius, y: p.y + CGFloat(sin(angle)) * radius)
                k == 0 ? star.move(to: q) : star.addLine(to: q)
            }
            star.closeSubpath()
            c.fill(star, with: lit)
        }
    }
}
