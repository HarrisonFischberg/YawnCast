import SwiftUI

/// The animated backgrounds behind "Scene" themes. All share one mood: dark,
/// slow, softly sparkling. Drawn with Canvas at ~15 fps; still under Reduce Motion.
enum SceneKind: String, CaseIterable {
    case midnight, mountain, beach, rainforest, ocean, city
    // v0.19 bedtime scenes: still landscapes with one moving layer each (NightScenes.swift).
    case blueHour, fernlight, emberLodge, tidalInk, afterHours

    var isNight: Bool {
        switch self {
        case .blueHour, .fernlight, .emberLodge, .tidalInk, .afterHours: true
        default: false
        }
    }
}

struct SceneBackground: View {
    let scene: SceneKind
    /// Now Playing shows the whole landscape; other screens squeeze it into the header
    /// and go quiet (fade to the page colour) sooner. Older scenes ignore this.
    var player = false
    /// Off on pages whose title runs under the Moon's spot (a show's name).
    var moon = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: reduceMotion)) { context in
            Canvas(opaque: true) { canvas, size in
                let t = reduceMotion ? 1_000 : context.date.timeIntervalSinceReferenceDate
                SceneRenderer.draw(scene, in: &canvas, size: size, t: t, player: player, moon: moon)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// A still frame of a scene, for theme swatches.
struct ScenePreview: View {
    let scene: SceneKind

    var body: some View {
        Canvas(opaque: true) { canvas, size in
            SceneRenderer.draw(scene, in: &canvas, size: size, t: 1_000)
        }
        .accessibilityHidden(true)
    }
}

/// Full-screen background for a screen: the theme's scene, or its flat color.
struct ScreenBackground: View {
    /// See `SceneBackground.player` and `.moon`.
    var player = false
    var moon = true
    @Environment(\.theme) private var theme

    var body: some View {
        if let scene = theme.scene {
            SceneBackground(scene: scene, player: player, moon: moon)
        } else {
            theme.bg.ignoresSafeArea()
        }
    }
}

// MARK: - Rendering

enum SceneRenderer {
    static func draw(_ scene: SceneKind, in canvas: inout GraphicsContext, size: CGSize, t: Double, player: Bool = false, moon: Bool = true) {
        // Night scenes on a page: the landscape in the top 70%, veiled from 45% of that.
        let veil = player ? 0.5 : 0.45
        if scene.isNight, !player {
            canvas.fill(Path(CGRect(origin: .zero, size: size)), with: .color(hex(SceneRenderer.pageColor(scene))))
            canvas.scaleBy(x: 1, y: 0.7)
        }
        draw(scene, in: &canvas, size: size, t: t, veil: veil, moon: moon)
    }

    private static func draw(_ scene: SceneKind, in canvas: inout GraphicsContext, size: CGSize, t: Double, veil: Double, moon: Bool) {
        switch scene {
        case .midnight: midnight(&canvas, size, t)
        case .mountain: mountain(&canvas, size, t)
        case .beach: beach(&canvas, size, t)
        case .rainforest: rainforest(&canvas, size, t)
        case .ocean: ocean(&canvas, size, t)
        case .city: city(&canvas, size, t)
        case .blueHour: blueHour(&canvas, size, t, veil, moon)
        case .fernlight: fernlight(&canvas, size, t, veil, moon)
        case .emberLodge: emberLodge(&canvas, size, t, veil, moon)
        case .tidalInk: tidalInk(&canvas, size, t, veil, moon)
        case .afterHours: afterHours(&canvas, size, t, veil, moon)
        }
    }

    // MARK: Midnight — deep-blue sky, twinkling stars, three rolling waves

    private static func midnight(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        gradient(&c, size, [0x060D26, 0x0C1A42, 0x14285A])
        stars(&c, size, Layouts.stars, t, yScale: 0.72, maxOpacity: 0.75)
        let waves: [(Double, Double, Double, Double, UInt32, Double)] = [
            (0.58, 22.0, 1.4, 0.10, 0x1A2E66, 0.45),
            (0.70, 26.0, 2.1, -0.07, 0x22356B, 0.55),
            (0.83, 18.0, 2.9, 0.05, 0x0F1E4A, 0.85),
        ]
        for wave in waves {
            c.fill(wavePath(size, base: wave.0, amp: wave.1, k: wave.2, t: t, speed: wave.3), with: .color(hex(wave.4).opacity(wave.5)))
        }
    }

    // MARK: Mountain Vista — violet dusk, moon, layered peaks, drifting mist

    private static func mountain(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        gradient(&c, size, [0x0E0B26, 0x241C4E, 0x4B3A73])
        stars(&c, size, Layouts.stars, t, yScale: 0.5, maxOpacity: 0.7)
        // Moon peeking in at the right edge above the peaks: outside the
        // content margins, so it never sits behind text.
        moon(&c, center: CGPoint(x: size.width - 4, y: size.height * 0.40), radius: 22, color: hex(0xF5E9C8))
        let ridges: [(base: Double, amp: Double, k: Double, phase: Double, color: UInt32)] = [
            (0.52, 70, 2.2, 0.4, 0x3A2F66),
            (0.63, 60, 3.1, 1.9, 0x2A2350),
            (0.76, 46, 4.3, 3.3, 0x1A1638),
        ]
        for (index, ridge) in ridges.enumerated() {
            c.fill(peaksPath(size, base: ridge.base, amp: ridge.amp, k: ridge.k, phase: ridge.phase), with: .color(hex(ridge.color)))
            // Mist drifting between the ranges.
            if index < 2 {
                c.drawLayer { layer in
                    layer.addFilter(.blur(radius: 22))
                    for i in 0..<3 {
                        let drift = (Double(i) * 0.43 + t * 0.006 * Double(index + 1)).truncatingRemainder(dividingBy: 1.4) - 0.2
                        let y = size.height * (ridge.base + 0.04)
                        layer.fill(Path(ellipseIn: CGRect(x: drift * size.width, y: y, width: size.width * 0.55, height: 34)),
                                   with: .color(.white.opacity(0.07)))
                    }
                }
            }
        }
    }

    // MARK: Beach — moonlit sea, shimmering moon path, rolling foam, quiet shore

    private static func beach(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        let horizon = size.height * 0.6
        gradient(&c, CGSize(width: size.width, height: horizon), [0x061626, 0x0C2A40, 0x1D4A63])
        stars(&c, size, Layouts.stars, t, yScale: 0.45, maxOpacity: 0.7)
        // Low moon just above the horizon, so its light path runs straight down the sea.
        let moonX = size.width * 0.5
        moon(&c, center: CGPoint(x: moonX, y: horizon - 22), radius: 16, color: hex(0xF4EBD0))
        c.fill(Path(CGRect(x: 0, y: horizon, width: size.width, height: size.height - horizon)),
               with: .linearGradient(Gradient(colors: [hex(0x0D3A55), hex(0x072538)]),
                                     startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: size.height)))
        // Moon path on the water: short shimmering dashes widening toward the viewer.
        let seaDepth = size.height - horizon
        for i in 0..<20 {
            let f = Double(i) / 20
            let y = horizon + 6 + f * seaDepth * 0.55
            let width = 8 + f * 60
            let x = moonX + sin(t * 1.3 + Double(i)) * 4 - width / 2
            let shimmer = 0.5 + 0.5 * sin(t * 2.1 + Double(i) * 0.9)
            c.fill(Path(roundedRect: CGRect(x: x, y: y, width: width, height: 2), cornerRadius: 1),
                   with: .color(hex(0xF4EBD0).opacity((0.15 + 0.4 * shimmer) * (1 - f * 0.7))))
        }
        for (i, base) in [0.68, 0.76, 0.84].enumerated() {
            let path = wavePath(size, base: base, amp: 5, k: 3 + Double(i), t: t, speed: 0.05 + Double(i) * 0.02, closed: false)
            c.stroke(path, with: .color(.white.opacity(0.10 + 0.04 * Double(i))), lineWidth: 1.4)
        }
        // Shore with foam lapping up and back.
        let lap = sin(t * 0.5) * 6
        let shore = wavePath(size, base: 0.91 + lap / size.height, amp: 8, k: 1.3, t: t, speed: 0.02)
        c.fill(shore, with: .color(hex(0x12222B)))
        c.stroke(wavePath(size, base: 0.91 + lap / size.height, amp: 8, k: 1.3, t: t, speed: 0.02, closed: false),
                 with: .color(.white.opacity(0.22)), lineWidth: 2)
    }

    // MARK: Rainforest — swaying canopy layers, mist, blinking fireflies

    private static func rainforest(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        gradient(&c, size, [0x03100C, 0x0B271D, 0x1C4A38])
        stars(&c, size, Array(Layouts.stars.prefix(30)), t, yScale: 0.28, maxOpacity: 0.45)
        let canopies: [(base: Double, color: UInt32, sway: Double)] = [
            (0.50, 0x0E3326, 0.15),
            (0.64, 0x0A281E, -0.12),
            (0.79, 0x051A13, 0.09),
        ]
        for (index, layer) in canopies.enumerated() {
            c.fill(canopyPath(size, base: layer.base, t: t * layer.sway, seed: Double(index) * 2.7), with: .color(hex(layer.color)))
        }
        c.drawLayer { mist in
            mist.addFilter(.blur(radius: 26))
            mist.fill(Path(ellipseIn: CGRect(x: -size.width * 0.2 + sin(t * 0.05) * 30, y: size.height * 0.72, width: size.width * 1.4, height: 70)),
                      with: .color(.white.opacity(0.06)))
        }
        // Big foreground leaves, gently rocking.
        for leaf in Layouts.leaves {
            var l = c
            l.translateBy(x: leaf.x * size.width, y: size.height * leaf.y)
            l.rotate(by: .degrees(leaf.angle + sin(t * 0.4 + leaf.x * 5) * 3))
            l.fill(Path(ellipseIn: CGRect(x: 0, y: -leaf.width / 2, width: leaf.length, height: leaf.width)), with: .color(hex(0x04120D)))
        }
        for fly in Layouts.fireflies {
            let x = (fly.x + 0.06 * sin(t * fly.speed + fly.phase)) * size.width
            let y = (fly.y + 0.04 * cos(t * fly.speed * 0.7 + fly.phase)) * size.height
            let blink = pow(max(0, sin(t * fly.blink + fly.phase)), 2)
            guard blink > 0.02 else { continue }
            c.fill(Path(ellipseIn: CGRect(x: x - 9, y: y - 9, width: 18, height: 18)), with: .color(hex(0xD6F07A).opacity(0.16 * blink)))
            c.fill(Path(ellipseIn: CGRect(x: x - 1.8, y: y - 1.8, width: 3.6, height: 3.6)), with: .color(hex(0xEFFFB0).opacity(0.95 * blink)))
        }
    }

    // MARK: Underwater — light rays from above, rising bubbles, drifting fish, swaying kelp

    private static func ocean(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        gradient(&c, size, [0x0E4A63, 0x06283C, 0x020E18])
        // Soft light rays fanning down from the surface, swaying slowly.
        c.drawLayer { rays in
            rays.addFilter(.blur(radius: 14))
            for i in 0..<5 {
                let sway = sin(t * 0.12 + Double(i) * 1.3) * 0.04
                let top = (0.12 + Double(i) * 0.2 + sway) * size.width
                let spread = size.width * (0.05 + 0.03 * Double(i % 2))
                var ray = Path()
                ray.move(to: CGPoint(x: top - spread * 0.3, y: 0))
                ray.addLine(to: CGPoint(x: top + spread * 0.3, y: 0))
                ray.addLine(to: CGPoint(x: top + spread * 2 + size.width * 0.12, y: size.height * 0.75))
                ray.addLine(to: CGPoint(x: top - spread + size.width * 0.08, y: size.height * 0.75))
                ray.closeSubpath()
                rays.fill(ray, with: .linearGradient(Gradient(colors: [.white.opacity(0.10), .clear]),
                                                     startPoint: CGPoint(x: top, y: 0), endPoint: CGPoint(x: top, y: size.height * 0.75)))
            }
        }
        // Kelp swaying from the sea floor.
        for strand in Layouts.kelp {
            var path = Path()
            let baseX = strand.x * size.width
            path.move(to: CGPoint(x: baseX, y: size.height + 10))
            let height = strand.height * size.height
            var point = CGPoint(x: baseX, y: size.height + 10)
            for segment in 1...6 {
                let f = Double(segment) / 6
                let sway = sin(t * 0.5 + strand.phase + f * 2) * 14 * f
                let next = CGPoint(x: baseX + sway, y: size.height + 10 - height * f)
                path.addQuadCurve(to: next, control: CGPoint(x: (point.x + next.x) / 2 + sway * 0.4, y: (point.y + next.y) / 2))
                point = next
            }
            c.stroke(path, with: .color(hex(0x05302B).opacity(0.9)), style: StrokeStyle(lineWidth: strand.width, lineCap: .round))
        }
        c.fill(wavePath(size, base: 0.95, amp: 6, k: 1.7, t: 0, speed: 0), with: .color(hex(0x031520)))
        // Fish: slow silhouettes crossing, tails wagging, nearer ones darker and larger.
        for fish in Layouts.fish {
            let travel = (fish.offset + t * fish.speed).truncatingRemainder(dividingBy: 1.4) - 0.2
            let x = (fish.direction > 0 ? travel : 1 - travel) * size.width
            let y = (fish.y + 0.015 * sin(t * 0.6 + fish.offset * 9)) * size.height
            var f = c
            f.translateBy(x: x, y: y)
            f.scaleBy(x: fish.direction * fish.size / 20, y: fish.size / 20)
            f.opacity = fish.near ? 0.9 : 0.55
            let color = hex(fish.near ? 0x021623 : 0x0B3A52)
            f.fill(Path(ellipseIn: CGRect(x: -14, y: -6, width: 28, height: 12)), with: .color(color))
            let wag = sin(t * 4 + fish.offset * 20) * 3
            var tail = Path()
            tail.move(to: CGPoint(x: -12, y: 0))
            tail.addLine(to: CGPoint(x: -22, y: -7 + wag))
            tail.addLine(to: CGPoint(x: -22, y: 7 + wag))
            tail.closeSubpath()
            f.fill(tail, with: .color(color))
        }
        // Bubbles rising and wobbling.
        for bubble in Layouts.bubbles {
            let rise = (bubble.y + t * bubble.speed).truncatingRemainder(dividingBy: 1.1)
            let y = size.height * (1.05 - rise)
            let x = (bubble.x + 0.01 * sin(t * 2 + bubble.y * 30)) * size.width
            c.stroke(Path(ellipseIn: CGRect(x: x - bubble.r, y: y - bubble.r, width: bubble.r * 2, height: bubble.r * 2)),
                     with: .color(.white.opacity(0.28 * min(1, rise * 4))), lineWidth: 0.8)
        }
    }

    // MARK: City Scape — Tokyo-style neon skyline, twinkling windows, soft rain

    private static func city(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        gradient(&c, size, [0x08041A, 0x160C2E, 0x3A1A55])
        stars(&c, size, Array(Layouts.stars.prefix(25)), t, yScale: 0.3, maxOpacity: 0.35)
        // Neon haze over the skyline.
        c.fill(Path(ellipseIn: CGRect(x: -size.width * 0.2, y: size.height * 0.45, width: size.width * 1.4, height: size.height * 0.35)),
               with: .radialGradient(Gradient(colors: [hex(0xFF4FA3).opacity(0.16), .clear]),
                                     center: CGPoint(x: size.width / 2, y: size.height * 0.62), startRadius: 0, endRadius: size.width * 0.7))
        for (layerIndex, buildings) in [Layouts.farBuildings, Layouts.nearBuildings].enumerated() {
            let near = layerIndex == 1
            for b in buildings {
                let rect = CGRect(x: b.x * size.width, y: size.height * (1 - b.height), width: b.width * size.width, height: size.height * b.height)
                c.fill(Path(rect), with: .color(hex(near ? 0x0B0618 : 0x1A0F33)))
                // Windows: a lit grid where some rooms switch on and off slowly.
                let cols = max(2, Int(rect.width / 9)), rows = Int(rect.height / 12)
                for row in 0..<min(rows, near ? 24 : 16) {
                    for col in 0..<cols {
                        let seed = b.seed + Double(row * 31 + col * 7)
                        let lit = hash(seed) > (near ? 0.62 : 0.72)
                        let toggles = hash(seed + 1.7) > 0.85
                        let on = lit && (!toggles || Int((t + hash(seed) * 9) / (4 + hash(seed + 3) * 6)) % 2 == 0)
                        guard on else { continue }
                        let warm = hash(seed + 5) > 0.35
                        c.fill(Path(CGRect(x: rect.minX + 3 + Double(col) * 9, y: rect.minY + 6 + Double(row) * 12, width: 4, height: 5)),
                               with: .color(hex(warm ? 0xFFD58A : 0x7FE8FF).opacity(near ? 0.55 : 0.3)))
                    }
                }
                if near, let sign = b.sign {
                    let pulse = 0.55 + 0.35 * sin(t * 2 + b.seed)
                    let signRect = CGRect(x: rect.midX - 4, y: rect.minY + 14, width: 8, height: min(70, rect.height * 0.4))
                    let path = Path(roundedRect: signRect, cornerRadius: 4)
                    let color = hex(sign ? 0xFF4FA3 : 0x3FE0FF)
                    c.stroke(path, with: .color(color.opacity(0.14 * pulse)), lineWidth: 9)
                    c.stroke(path, with: .color(color.opacity(pulse)), lineWidth: 2)
                }
            }
        }
        // Light rain.
        for drop in Layouts.rain {
            let x = ((drop.x + t * 0.02).truncatingRemainder(dividingBy: 1)) * size.width
            let y = ((drop.y + t * drop.speed).truncatingRemainder(dividingBy: 1.1) - 0.05) * size.height
            var p = Path()
            p.move(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x - 3, y: y + 14))
            c.stroke(p, with: .color(.white.opacity(0.10)), lineWidth: 1)
        }
    }

    // MARK: Shared pieces

    static func gradient(_ c: inout GraphicsContext, _ size: CGSize, _ colors: [UInt32]) {
        c.fill(Path(CGRect(origin: .zero, size: size)),
               with: .linearGradient(Gradient(colors: colors.map(hex)), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
    }

    static func stars(_ c: inout GraphicsContext, _ size: CGSize, _ stars: [Layouts.Star], _ t: Double, yScale: Double, maxOpacity: Double) {
        for star in stars {
            let twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * star.speed + star.phase))
            let center = CGPoint(x: star.x * size.width, y: star.y * yScale * size.height)
            let r = star.radius * (star.sparkle ? 1.4 : 1)
            c.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                   with: .color(.white.opacity(maxOpacity * twinkle)))
            if star.sparkle {
                var glint = Path()
                let len = r * 4 * twinkle
                glint.move(to: CGPoint(x: center.x - len, y: center.y)); glint.addLine(to: CGPoint(x: center.x + len, y: center.y))
                glint.move(to: CGPoint(x: center.x, y: center.y - len)); glint.addLine(to: CGPoint(x: center.x, y: center.y + len))
                c.stroke(glint, with: .color(.white.opacity(maxOpacity * 0.45 * twinkle)), lineWidth: 0.6)
            }
        }
    }

    static func moon(_ c: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        c.fill(Path(ellipseIn: CGRect(x: center.x - radius * 4, y: center.y - radius * 4, width: radius * 8, height: radius * 8)),
               with: .radialGradient(Gradient(colors: [color.opacity(0.18), .clear]), center: center, startRadius: radius, endRadius: radius * 4))
        c.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), with: .color(color))
    }

    /// Smooth rolling wave across the width at `base` (fraction of height).
    static func wavePath(_ size: CGSize, base: Double, amp: Double, k: Double, t: Double, speed: Double, closed: Bool = true) -> Path {
        var path = Path()
        var x: CGFloat = 0
        var first = true
        while x <= size.width + 8 {
            let u = Double(x / max(size.width, 1))
            let y = size.height * base + amp * sin(u * .pi * k + t * speed * 2 * .pi / 6) + amp * 0.4 * sin(u * .pi * k * 2.3 - t * speed)
            if first {
                if closed { path.move(to: CGPoint(x: 0, y: size.height)); path.addLine(to: CGPoint(x: 0, y: y)) } else { path.move(to: CGPoint(x: 0, y: y)) }
                first = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            x += 8
        }
        if closed {
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
        }
        return path
    }

    /// Mountain range: sharp-ish peaks from summed rectified sines.
    static func peaksPath(_ size: CGSize, base: Double, amp: Double, k: Double, phase: Double) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 6 {
            let u = Double(x / max(size.width, 1))
            let h = pow(abs(sin(u * .pi * k + phase)), 1.6) * 0.75 + abs(sin(u * .pi * k * 2.7 + phase * 2)) * 0.25
            path.addLine(to: CGPoint(x: x, y: size.height * base - amp * h))
            x += 6
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        return path
    }

    /// Tree canopy: bumpy top line that sways slightly.
    static func canopyPath(_ size: CGSize, base: Double, t: Double, seed: Double) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 5 {
            let u = Double(x / max(size.width, 1))
            let bumps = abs(sin(u * 11 + seed + sin(t) * 0.3)) * 22 + abs(sin(u * 23 + seed * 2)) * 10 + sin(u * 3 + seed) * 18
            path.addLine(to: CGPoint(x: x, y: size.height * base - bumps))
            x += 5
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        return path
    }

    static func hex(_ value: UInt32) -> Color { Color(hex: value) }

    /// Stable pseudo-random 0…1 for a seed.
    static func hash(_ seed: Double) -> Double {
        let v = sin(seed * 12.9898) * 43758.5453
        return v - v.rounded(.down)
    }

    /// Deterministic layouts so a scene looks the same every launch.
    enum Layouts {
        struct Star { var x, y, radius, speed, phase: Double; var sparkle: Bool }
        struct Firefly { var x, y, speed, blink, phase: Double }
        struct Leaf { var x, y, length, width, angle: Double }
        struct Building { var x, width, height, seed: Double; var sign: Bool? }
        struct Drop { var x, y, speed: Double }

        private struct Random {
            var state: UInt64
            mutating func next() -> Double {
                state = state &* 6364136223846793005 &+ 1442695040888963407
                return Double(state >> 11) / Double(1 << 53)
            }
        }

        static let stars: [Star] = {
            var r = Random(state: 0x9E37_79B9_7F4A_7C15)
            return (0..<80).map { _ in
                Star(x: r.next(), y: r.next(), radius: 0.5 + r.next() * 1.3, speed: 0.3 + r.next() * 0.9, phase: r.next() * .pi * 2, sparkle: r.next() > 0.92)
            }
        }()

        static let fireflies: [Firefly] = {
            var r = Random(state: 42)
            return (0..<26).map { _ in
                Firefly(x: 0.05 + r.next() * 0.9, y: 0.35 + r.next() * 0.55, speed: 0.15 + r.next() * 0.3, blink: 0.6 + r.next() * 1.2, phase: r.next() * .pi * 2)
            }
        }()

        static let leaves: [Leaf] = [
            Leaf(x: -0.05, y: 0.93, length: 150, width: 46, angle: -28),
            Leaf(x: 0.02, y: 0.99, length: 130, width: 40, angle: -8),
            Leaf(x: 1.02, y: 0.92, length: 150, width: 44, angle: 208),
            Leaf(x: 0.98, y: 1.0, length: 120, width: 38, angle: 188),
        ]

        static let farBuildings: [Building] = buildings(seed: 7, minHeight: 0.30, maxHeight: 0.50, signs: false)
        static let nearBuildings: [Building] = buildings(seed: 11, minHeight: 0.16, maxHeight: 0.38, signs: true)

        private static func buildings(seed: UInt64, minHeight: Double, maxHeight: Double, signs: Bool) -> [Building] {
            var r = Random(state: seed)
            var x = -0.02
            var result: [Building] = []
            while x < 1.02 {
                let width = 0.06 + r.next() * 0.07
                let sign: Bool? = signs && r.next() > 0.7 ? r.next() > 0.5 : nil
                result.append(Building(x: x, width: width, height: minHeight + r.next() * (maxHeight - minHeight), seed: r.next() * 1000, sign: sign))
                x += width + r.next() * 0.01
            }
            return result
        }

        struct Fish { var offset, y, speed, direction, size: Double; var near: Bool }
        struct Kelp { var x, height, width, phase: Double }
        struct Bubble { var x, y, speed, r: Double }

        static let fish: [Fish] = {
            var r = Random(state: 2024)
            return (0..<10).map { _ in
                let near = r.next() > 0.6
                return Fish(offset: r.next() * 1.4, y: 0.22 + r.next() * 0.6, speed: 0.008 + r.next() * 0.012,
                            direction: r.next() > 0.5 ? 1 : -1, size: near ? 22 + r.next() * 8 : 12 + r.next() * 6, near: near)
            }
        }()

        static let kelp: [Kelp] = {
            var r = Random(state: 77)
            return (0..<7).map { i in
                Kelp(x: (Double(i) + 0.2 + r.next() * 0.6) / 7, height: 0.18 + r.next() * 0.22, width: 5 + r.next() * 5, phase: r.next() * 6)
            }
        }()

        static let bubbles: [Bubble] = {
            var r = Random(state: 5)
            return (0..<30).map { _ in Bubble(x: r.next(), y: r.next(), speed: 0.03 + r.next() * 0.05, r: 1.5 + r.next() * 3) }
        }()

        static let rain: [Drop] = {
            var r = Random(state: 99)
            return (0..<60).map { _ in Drop(x: r.next(), y: r.next(), speed: 0.12 + r.next() * 0.1) }
        }()
    }
}
