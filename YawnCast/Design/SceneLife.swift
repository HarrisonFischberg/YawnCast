import SwiftUI

/// A Scene's ambient life on Now Playing: a few lights or creatures scattered over the
/// sky, drifting slowly, each fading in and out on its own. They are out while an episode
/// plays or Sleep waits, thin out one by one as the fade runs down, and none are left at
/// lights out. Decoration only: the Moon bar and the Sleep bubble say the time and volume.
/// Drawn inside the Scene's own Canvas (`SceneBackground`), so there is one timeline.
enum SceneLife {
    /// Where they roam, as fractions of the screen: above the paper ground, below the clock.
    private static let region = CGRect(x: 0.10, y: 0.11, width: 0.80, height: 0.36)

    /// `life` is 0...1: the share of them that are out. `t` is frozen under Reduce Motion,
    /// which leaves a still, scattered arrangement that only fades.
    /// `quiet` is the title's frame; nothing shows behind it, so the words stay clean.
    static func draw(_ scene: SceneKind, in c: inout GraphicsContext, size: CGSize, t: Double, life: Double, quiet: CGRect, glow: Color) {
        let count: Int
        switch scene {
        case .rainforest: count = 9
        case .ocean: count = 6
        case .midnight: count = 11
        case .city: count = 7
        case .beach: count = 8
        case .mountain: return // the peaks and the mist are enough; nothing added
        }
        for i in 0..<count {
            // The highest-numbered go first; each takes its whole step of `life` to fade.
            let out = min(1, max(0, life * Double(count) - Double(i)))
            guard out > 0.01 else { continue }
            // Its own slow breath, never fully dark, never a flash (8 to 16 s a cycle).
            let breath = 0.5 + 0.5 * sin(t * (0.4 + 0.4 * rnd(i, 1)) + rnd(i, 2) * 6.28)
            var alpha = out * (0.3 + 0.7 * breath)
            var p = CGPoint(x: region.minX + region.width * rnd(i, 3), y: region.minY + region.height * rnd(i, 4))
            switch scene {
            case .midnight:
                break // stars stay where they are
            case .city:
                // Sky lanterns rise from the skyline and fade as they climb (about 3 minutes a trip).
                let trip = (t * 0.006 * (0.7 + 0.6 * rnd(i, 5)) + rnd(i, 6)).truncatingRemainder(dividingBy: 1)
                p.y = region.maxY - region.height * trip
                p.x += 0.03 * sin(t * 0.11 + rnd(i, 7) * 6.28)
                let at = point(p, size)
                drawLantern(&c, at: at, alpha: alpha * sin(.pi * trip) * clear(of: quiet, at), glow: glow)
                continue
            default:
                // A wide, slow wander: a minute or more to cross.
                p.x += 0.12 * sin(t * 0.04 * (0.6 + rnd(i, 5)) + rnd(i, 6) * 6.28)
                p.y += 0.05 * sin(t * 0.055 * (0.6 + rnd(i, 7)) + rnd(i, 8) * 6.28)
            }
            let at = point(p, size)
            alpha *= clear(of: quiet, at)
            guard alpha > 0.01 else { continue }
            switch scene {
            case .rainforest: drawFirefly(&c, at: at, alpha: alpha, glow: glow)
            case .ocean: drawJellyfish(&c, at: at, alpha: alpha, pulse: sin(t * 0.9 + rnd(i, 9) * 6.28), scale: 0.8 + 0.5 * rnd(i, 10), glow: glow)
            case .midnight: drawStar(&c, at: at, alpha: alpha, radius: 6 + 5 * rnd(i, 9), glow: glow)
            case .beach: drawGlint(&c, at: at, alpha: alpha, radius: 5 + 6 * rnd(i, 9), glow: glow)
            case .city, .mountain: break
            }
        }
    }

    /// 0 behind the title and for 16 pt around it, rising to 1 over the next 28 pt.
    private static func clear(of quiet: CGRect, _ p: CGPoint) -> Double {
        guard !quiet.isNull else { return 1 }
        let dx = max(quiet.minX - p.x, 0, p.x - quiet.maxX), dy = max(quiet.minY - p.y, 0, p.y - quiet.maxY)
        return min(1, max(0, (Double(max(dx, dy)) - 16) / 28))
    }

    private static func point(_ p: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: p.y * size.height)
    }

    /// A fixed pseudo-random number in 0..<1 for creature `i`, channel `k`.
    private static func rnd(_ i: Int, _ k: Double) -> Double {
        let v = sin(Double(i) * 12.9898 + k * 78.233) * 43_758.5453
        return v - floor(v)
    }

    private static func circle(_ p: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }

    /// Rainforest: a point of light in a soft halo.
    private static func drawFirefly(_ c: inout GraphicsContext, at p: CGPoint, alpha: Double, glow: Color) {
        c.fill(circle(p, 13), with: .radialGradient(Gradient(colors: [glow.opacity(0.32 * alpha), .clear]), center: p, startRadius: 0, endRadius: 13))
        c.fill(circle(p, 3), with: .color(glow.opacity(alpha)))
    }

    /// Underwater: a bell that opens and closes a little, three trailing tentacles.
    private static func drawJellyfish(_ c: inout GraphicsContext, at p: CGPoint, alpha: Double, pulse: Double, scale: CGFloat, glow: Color) {
        let w = 11 * scale * (1 + 0.08 * pulse), h = 15 * scale * (1 - 0.06 * pulse)
        c.fill(circle(p, 22 * scale), with: .radialGradient(Gradient(colors: [glow.opacity(0.16 * alpha), .clear]), center: p, startRadius: 0, endRadius: 22 * scale))
        for k in -1...1 {
            var tentacle = Path()
            let x = p.x + CGFloat(k) * w * 0.5
            tentacle.move(to: CGPoint(x: x, y: p.y + 3))
            tentacle.addQuadCurve(to: CGPoint(x: x + 2 * pulse, y: p.y + 3 + h), control: CGPoint(x: x - 3, y: p.y + h * 0.5))
            c.stroke(tentacle, with: .color(glow.opacity(0.55 * alpha)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
        var bell = Path()
        bell.move(to: CGPoint(x: p.x - w, y: p.y + 4))
        bell.addCurve(to: CGPoint(x: p.x + w, y: p.y + 4), control1: CGPoint(x: p.x - w, y: p.y - h), control2: CGPoint(x: p.x + w, y: p.y - h))
        bell.closeSubpath()
        c.fill(bell, with: .color(glow.opacity(0.7 * alpha)))
    }

    /// Midnight: a four-point star.
    private static func drawStar(_ c: inout GraphicsContext, at p: CGPoint, alpha: Double, radius: CGFloat, glow: Color) {
        var star = Path()
        for k in 0..<8 {
            let angle = Double(k) * .pi / 4 - .pi / 2
            let r = k % 2 == 0 ? radius : radius * 0.3
            let q = CGPoint(x: p.x + CGFloat(cos(angle)) * r, y: p.y + CGFloat(sin(angle)) * r)
            k == 0 ? star.move(to: q) : star.addLine(to: q)
        }
        star.closeSubpath()
        c.fill(star, with: .color(glow.opacity(0.9 * alpha)))
    }

    /// City Scape: a paper sky lantern, lit from below.
    private static func drawLantern(_ c: inout GraphicsContext, at p: CGPoint, alpha: Double, glow: Color) {
        c.fill(circle(p, 18), with: .radialGradient(Gradient(colors: [glow.opacity(0.22 * alpha), .clear]), center: p, startRadius: 0, endRadius: 18))
        c.fill(Path(roundedRect: CGRect(x: p.x - 6, y: p.y - 8, width: 12, height: 16), cornerRadius: 5, style: .continuous), with: .color(glow.opacity(0.8 * alpha)))
        c.fill(Path(CGRect(x: p.x - 3.5, y: p.y + 8, width: 7, height: 2)), with: .color(Color.white.opacity(0.7 * alpha)))
    }

    /// Beach: moonlight caught in the sea air, a soft disc with a faint rim.
    private static func drawGlint(_ c: inout GraphicsContext, at p: CGPoint, alpha: Double, radius: CGFloat, glow: Color) {
        c.fill(circle(p, radius), with: .color(glow.opacity(0.22 * alpha)))
        c.stroke(circle(p, radius), with: .color(glow.opacity(0.45 * alpha)), lineWidth: 1)
    }
}
