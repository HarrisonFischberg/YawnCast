import SwiftUI

// The v0.19 bedtime scenes: broad silhouettes in three or four depth layers, one
// warm-lit building, the Moon up on the right, and one quiet moving layer each.
// Everything below `veil` fades to the page colour so controls sit on plain dark.
// Values follow the handoff's motion-starting-values.json; they are tuning points.

/// The crescent Moon, as a Shape so the sky, the Sleep key and the mini player share
/// one drawing. Each scene bends it a little; the silhouette stays a crescent.
nonisolated struct CrescentShape: Shape {
    var scene: SceneKind?

    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
        // The bite, up and to the right, leaves a thick lower-left limb.
        let bite = Path(ellipseIn: CGRect(x: c.x - r * 0.42, y: c.y - r * 1.3, width: 1.8 * r, height: 1.8 * r))
        var moon = outer.subtracting(bite)
        switch scene {
        case .fernlight:
            // One delicate leaf at the upper tip.
            var leaf = Path(ellipseIn: CGRect(x: -r * 0.42, y: -r * 0.16, width: r * 0.84, height: r * 0.32))
            leaf = leaf.applying(CGAffineTransform(translationX: c.x + r * 0.62, y: c.y - r * 0.78).rotated(by: -0.8))
            moon = moon.union(leaf)
        case .tidalInk:
            // Two shallow scallops on the inner edge read as a wave.
            for (dx, dy) in [(0.1, -0.35), (0.42, 0.12)] {
                moon = moon.subtracting(Path(ellipseIn: CGRect(x: c.x + r * dx - r * 0.2, y: c.y + r * dy - r * 0.2, width: r * 0.4, height: r * 0.4)))
            }
        case .afterHours:
            // A small lit window in the thick limb.
            moon = moon.subtracting(Path(roundedRect: CGRect(x: c.x - r * 0.62, y: c.y - r * 0.02, width: r * 0.32, height: r * 0.4), cornerRadius: r * 0.06))
        default:
            break
        }
        return moon
    }
}

extension SceneRenderer {
    /// The theme's page colour, which each scene fades into.
    static func pageColor(_ scene: SceneKind) -> UInt32 {
        switch scene {
        case .blueHour: 0x0B1224
        case .fernlight: 0x0A1A16
        case .emberLodge: 0x160D0A
        case .tidalInk: 0x0A1521
        case .afterHours: 0x160F1C
        default: 0x000000
        }
    }

    // MARK: Blue Hour — ink-blue lake, layered hills, cottage window; slow ripples

    static func blueHour(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ veil: Double, _ moon: Bool) {
        let w = size.width, h = size.height
        gradient(&c, size, [0x070C1E, 0x0F1A3A, 0x1E3160, 0x2B3F70])
        // Dusk glow low on the horizon.
        glow(&c, at: CGPoint(x: w * 0.55, y: h * 0.48), rx: w * 0.9, ry: h * 0.14, color: hex(0x3454A8), strength: 0.45)
        stars(&c, size, Array(Layouts.stars.prefix(28)), t, yScale: 0.36, maxOpacity: 0.45)
        if moon { crescent(&c, size, .blueHour, color: hex(0xF3CF8E)) }
        // Hills in four depths, each hazier and bluer the farther back it sits.
        shaded(&c, hillsPath(size, base: 0.40, amp: 40, k: 1.3, phase: 0.6), top: 0x3A4C84, bottom: 0x1F2E5C, haze: 0x2B3F70, hazeOpacity: 0.35)
        shaded(&c, hillsPath(size, base: 0.44, amp: 34, k: 2.1, phase: 2.4), top: 0x26376A, bottom: 0x162450, haze: 0x2B3F70, hazeOpacity: 0.18)
        shaded(&c, hillsPath(size, base: 0.475, amp: 26, k: 2.9, phase: 4.0), top: 0x182852, bottom: 0x0E1A3C)
        let shore = h * 0.5
        // The lake: sky colour mirrored, darkening toward the viewer.
        c.fill(Path(CGRect(x: 0, y: shore, width: w, height: h - shore)),
               with: .linearGradient(Gradient(colors: [hex(0x1C2C5A), hex(0x0E1A3C), hex(0x070C1E)]), startPoint: CGPoint(x: 0, y: shore), endPoint: CGPoint(x: 0, y: h)))
        // Soft mirror of the hills on the water.
        c.drawLayer { mirror in
            mirror.clip(to: Path(CGRect(x: 0, y: shore, width: w, height: h - shore)))
            mirror.addFilter(.blur(radius: 6))
            mirror.opacity = 0.35
            mirror.translateBy(x: 0, y: shore * 2)
            mirror.scaleBy(x: 1, y: -1)
            mirror.fill(hillsPath(size, base: 0.475, amp: 26, k: 2.9, phase: 4.0), with: .color(hex(0x0A1330)))
        }
        // Near headland on the right with cypresses and the cottage.
        var head = Path()
        head.move(to: CGPoint(x: w, y: shore + 40)); head.addLine(to: CGPoint(x: w, y: shore - 10))
        head.addQuadCurve(to: CGPoint(x: w * 0.5, y: shore + 2), control: CGPoint(x: w * 0.72, y: shore - 14))
        head.addQuadCurve(to: CGPoint(x: w * 0.58, y: shore + 40), control: CGPoint(x: w * 0.44, y: shore + 24))
        head.closeSubpath()
        shaded(&c, head, top: 0x101B3E, bottom: 0x070C1E)
        for (x, height, width) in [(0.56, 56.0, 11.0), (0.60, 74.0, 13.0), (0.635, 50.0, 10.0), (0.79, 64.0, 12.0), (0.82, 46.0, 9.0), (0.93, 70.0, 13.0)] {
            cypress(&c, at: CGPoint(x: w * x, y: shore + 2), height: height, width: width, color: 0x060B1E)
        }
        house(&c, at: CGPoint(x: w * 0.70, y: shore - 2), scale: 1.1, wall: 0x080F2A, window: 0xFFC772, glow: 1)
        // Ripples: reflections of the window and the Moon, widening and wobbling slowly.
        c.drawLayer { soft in
            soft.addFilter(.blur(radius: 3))
            ripples(&soft, x: w * 0.70, from: shore + 8, depth: h * 0.24, t: t, color: hex(0xFFC772), cycle: 18)
            ripples(&soft, x: w * 0.84, from: shore + 8, depth: h * 0.3, t: t, color: hex(0xF3CF8E), cycle: 24)
        }
        ripples(&c, x: w * 0.70, from: shore + 8, depth: h * 0.24, t: t, color: hex(0xFFC772), cycle: 18)
        ripples(&c, x: w * 0.84, from: shore + 8, depth: h * 0.3, t: t, color: hex(0xF3CF8E), cycle: 24)
        shaded(&c, wavePath(size, base: 0.76, amp: 9, k: 1.1, t: 0, speed: 0), top: 0x0B1330, bottom: 0x05091A)
        self.veil(&c, size, from: veil, color: 0x0B1224)
    }

    // MARK: Fernlight — green clearing, conifers, still pool, cabin; fireflies

    static func fernlight(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ veil: Double, _ moon: Bool) {
        let w = size.width, h = size.height
        gradient(&c, size, [0x051210, 0x0B201C, 0x14362B, 0x1E4A38])
        glow(&c, at: CGPoint(x: w * 0.5, y: h * 0.46), rx: w * 0.9, ry: h * 0.14, color: hex(0x2E6A48), strength: 0.45)
        stars(&c, size, Array(Layouts.stars.prefix(18)), t, yScale: 0.3, maxOpacity: 0.35)
        if moon { crescent(&c, size, .fernlight, color: hex(0xF2D08C)) }
        shaded(&c, hillsPath(size, base: 0.40, amp: 54, k: 1.6, phase: 1.1), top: 0x2E5A48, bottom: 0x183A2E, haze: 0x1E4A38, hazeOpacity: 0.4)
        conifers(&c, size, base: 0.44, height: 0.13, spacing: 0.06, seed: 3, top: 0x1C4234, bottom: 0x0F2A20, haze: 0x1E4A38, hazeOpacity: 0.25)
        conifers(&c, size, base: 0.49, height: 0.17, spacing: 0.08, seed: 8, top: 0x123226, bottom: 0x081C14)
        let pool = h * 0.52
        c.fill(Path(CGRect(x: 0, y: pool, width: w, height: h - pool)),
               with: .linearGradient(Gradient(colors: [hex(0x123A2E), hex(0x0A2620), hex(0x05120F)]), startPoint: CGPoint(x: 0, y: pool), endPoint: CGPoint(x: 0, y: h)))
        c.drawLayer { mirror in
            mirror.clip(to: Path(CGRect(x: 0, y: pool, width: w, height: h - pool)))
            mirror.addFilter(.blur(radius: 6))
            mirror.opacity = 0.4
            mirror.translateBy(x: 0, y: pool * 2)
            mirror.scaleBy(x: 1, y: -1)
            conifers(&mirror, size, base: 0.49, height: 0.17, spacing: 0.08, seed: 8, top: 0x081C14, bottom: 0x081C14)
        }
        // Mist lying on the water.
        c.drawLayer { mist in
            mist.addFilter(.blur(radius: 18))
            mist.fill(Path(ellipseIn: CGRect(x: -w * 0.1, y: pool - 10, width: w * 1.2, height: 40)), with: .color(hex(0x9ED0B8).opacity(0.08)))
        }
        shaded(&c, hillsPath(size, base: 0.525, amp: 12, k: 2.6, phase: 0.3), top: 0x0B1F18, bottom: 0x061410)
        house(&c, at: CGPoint(x: w * 0.72, y: pool - 2), scale: 1.2, wall: 0x05120E, window: 0xFFB85C, glow: 1)
        c.drawLayer { soft in
            soft.addFilter(.blur(radius: 3))
            ripples(&soft, x: w * 0.72, from: pool + 8, depth: h * 0.2, t: t, color: hex(0xFFB85C), cycle: 20)
        }
        ripples(&c, x: w * 0.72, from: pool + 8, depth: h * 0.2, t: t, color: hex(0xFFB85C), cycle: 20)
        for leaf in Layouts.leaves {
            var l = c
            l.translateBy(x: leaf.x * w, y: h * leaf.y)
            l.rotate(by: .degrees(leaf.angle))
            l.fill(Path(ellipseIn: CGRect(x: 0, y: -leaf.width / 2, width: leaf.length, height: leaf.width)), with: .color(hex(0x030E0A)))
        }
        // Fireflies: a slow glow cycle each, drifting a little; no flashing.
        for fly in Layouts.fireflies.prefix(14) {
            let x = (fly.x + 0.03 * sin(t * fly.speed * 0.5 + fly.phase)) * w
            let y = (0.34 + (fly.y - 0.35) * 0.18 + 0.015 * cos(t * fly.speed * 0.35 + fly.phase)) * h
            let glow = pow(0.5 + 0.5 * sin(t * (0.7 + 0.25 * fly.blink) + fly.phase), 2)
            guard glow > 0.03 else { continue }
            c.fill(Path(ellipseIn: CGRect(x: x - 7, y: y - 7, width: 14, height: 14)), with: .color(hex(0xF2D08C).opacity(0.18 * glow)))
            c.fill(Path(ellipseIn: CGRect(x: x - 1.6, y: y - 1.6, width: 3.2, height: 3.2)), with: .color(hex(0xFFE9A8).opacity(0.9 * glow)))
        }
        self.veil(&c, size, from: veil, color: 0x0A1A16)
    }

    // MARK: Ember Lodge — copper dusk, mountain layers, cabin; chimney smoke, window flicker

    static func emberLodge(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ veil: Double, _ moon: Bool) {
        let w = size.width, h = size.height
        gradient(&c, size, [0x120806, 0x2A120C, 0x5A2614, 0x8E4420])
        glow(&c, at: CGPoint(x: w * 0.5, y: h * 0.44), rx: w * 0.95, ry: h * 0.14, color: hex(0xC2602A), strength: 0.5)
        stars(&c, size, Array(Layouts.stars.prefix(16)), t, yScale: 0.28, maxOpacity: 0.35)
        if moon { crescent(&c, size, .emberLodge, color: hex(0xF0B070)) }
        shaded(&c, peaksPath(size, base: 0.40, amp: 50, k: 1.4, phase: 0.9), top: 0x8A4424, bottom: 0x5A2816, haze: 0x8E4420, hazeOpacity: 0.3)
        shaded(&c, peaksPath(size, base: 0.44, amp: 44, k: 2.1, phase: 2.8), top: 0x5E2A16, bottom: 0x36180E, haze: 0x8E4420, hazeOpacity: 0.15)
        shaded(&c, peaksPath(size, base: 0.48, amp: 34, k: 3.0, phase: 4.6), top: 0x34170E, bottom: 0x1C0C08)
        let lake = h * 0.49
        c.fill(Path(CGRect(x: 0, y: lake, width: w, height: h * 0.1)),
               with: .linearGradient(Gradient(colors: [hex(0x5A2816), hex(0x1E0E09)]), startPoint: CGPoint(x: 0, y: lake), endPoint: CGPoint(x: 0, y: lake + h * 0.1)))
        c.drawLayer { soft in
            soft.addFilter(.blur(radius: 3))
            ripples(&soft, x: w * 0.5, from: lake + 4, depth: h * 0.09, t: t, color: hex(0xF0B070), cycle: 22)
        }
        ripples(&c, x: w * 0.5, from: lake + 4, depth: h * 0.09, t: t, color: hex(0xF0B070), cycle: 22)
        c.fill(Path(CGRect(x: 0, y: lake + h * 0.1, width: w, height: h)), with: .color(hex(0x1E0E09)))
        conifers(&c, size, base: 0.565, height: 0.14, spacing: 0.11, seed: 5, top: 0x1A0A06, bottom: 0x0C0503)
        let cabin = CGPoint(x: w * 0.70, y: h * 0.555)
        // Window light breathes slowly, never flickers.
        let flicker = 0.82 + 0.18 * sin(t * 0.55) * sin(t * 0.9 + 1)
        glow(&c, at: CGPoint(x: cabin.x, y: cabin.y - 16), rx: 70, ry: 50, color: hex(0xFFB45A), strength: 0.22 * flicker)
        house(&c, at: cabin, scale: 1.5, wall: 0x0C0503, window: 0xFFB45A, glow: flicker)
        // One thin curl of smoke: puffs rising from the chimney, drifting and thinning.
        c.drawLayer { smoke in
            smoke.addFilter(.blur(radius: 5))
            for i in 0..<5 {
                let p = (t / 13 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
                let x = cabin.x + 11 + sin(p * 5 + t * 0.15) * 8 * p + p * 10
                let y = cabin.y - 34 - p * 90
                let r = 3 + p * 9
                smoke.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)), with: .color(hex(0xF2DFC8).opacity(0.16 * (1 - p))))
            }
        }
        self.veil(&c, size, from: veil, color: 0x160D0A)
    }

    // MARK: Tidal Ink — Prussian-blue headlands, lighthouse, broad waves; shimmering moonlight

    static func tidalInk(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ veil: Double, _ moon: Bool) {
        let w = size.width, h = size.height
        gradient(&c, size, [0x060C1A, 0x0E1C34, 0x1A3252, 0x26466C])
        glow(&c, at: CGPoint(x: w * 0.5, y: h * 0.42), rx: w * 0.9, ry: h * 0.12, color: hex(0x3C6090), strength: 0.45)
        stars(&c, size, Array(Layouts.stars.prefix(26)), t, yScale: 0.34, maxOpacity: 0.45)
        if moon { crescent(&c, size, .tidalInk, color: hex(0xF1D6A0)) }
        shaded(&c, hillsPath(size, base: 0.405, amp: 40, k: 1.2, phase: 2.0), top: 0x2C4668, bottom: 0x162A44, haze: 0x26466C, hazeOpacity: 0.35)
        let sea = h * 0.44
        c.fill(Path(CGRect(x: 0, y: sea, width: w, height: h - sea)),
               with: .linearGradient(Gradient(colors: [hex(0x1E3A5C), hex(0x10243C), hex(0x070E1C)]), startPoint: CGPoint(x: 0, y: sea), endPoint: CGPoint(x: 0, y: h)))
        // Lighthouse on its rock, lamp lit, light spilling on the water.
        let rock = CGPoint(x: w * 0.72, y: sea + 14)
        shaded(&c, Path(ellipseIn: CGRect(x: rock.x - 46, y: rock.y - 16, width: 92, height: 32)), top: 0x16284A, bottom: 0x0B1628)
        var tower = Path()
        tower.move(to: CGPoint(x: rock.x - 6, y: rock.y - 10)); tower.addLine(to: CGPoint(x: rock.x + 6, y: rock.y - 10))
        tower.addLine(to: CGPoint(x: rock.x + 4, y: rock.y - 48)); tower.addLine(to: CGPoint(x: rock.x - 4, y: rock.y - 48)); tower.closeSubpath()
        c.fill(tower, with: .color(hex(0x0B1628)))
        glowDot(&c, at: CGPoint(x: rock.x, y: rock.y - 50), r: 2.6, color: hex(0xFFE2A0), glow: 26, strength: 1)
        c.drawLayer { soft in
            soft.addFilter(.blur(radius: 4))
            ripples(&soft, x: w * 0.84, from: sea + 6, depth: h * 0.3, t: t, color: hex(0xF1D6A0), cycle: 16)
            ripples(&soft, x: rock.x, from: rock.y + 10, depth: h * 0.14, t: t, color: hex(0xFFE2A0), cycle: 12)
        }
        ripples(&c, x: w * 0.84, from: sea + 6, depth: h * 0.3, t: t, color: hex(0xF1D6A0), cycle: 16)
        // Broad swells rolling in, slow, each shaded and lit along its crest.
        for (i, base) in [0.54, 0.62, 0.70, 0.78].enumerated() {
            let amp = 7 + Double(i) * 2, k = 1.6 + Double(i) * 0.4, speed = 0.035 + Double(i) * 0.01
            shaded(&c, wavePath(size, base: base, amp: amp, k: k, t: t, speed: speed), top: i % 2 == 0 ? 0x1A3254 : 0x12243E, bottom: i % 2 == 0 ? 0x0E1C32 : 0x0A1628)
            c.stroke(wavePath(size, base: base, amp: amp, k: k, t: t, speed: speed, closed: false),
                     with: .color(hex(0xF1D6A0).opacity(0.10)), lineWidth: 1.2)
        }
        var head = Path()
        head.move(to: CGPoint(x: 0, y: h)); head.addLine(to: CGPoint(x: 0, y: h * 0.5))
        head.addQuadCurve(to: CGPoint(x: w * 0.42, y: h * 0.62), control: CGPoint(x: w * 0.22, y: h * 0.48))
        head.addQuadCurve(to: CGPoint(x: w * 0.3, y: h), control: CGPoint(x: w * 0.5, y: h * 0.84))
        head.closeSubpath()
        shaded(&c, head, top: 0x0E1A30, bottom: 0x050A16)
        self.veil(&c, size, from: veil, color: 0x0A1521)
    }

    // MARK: After Hours — plum skyline, canal and bridge, bookshop window; sparse rain

    static func afterHours(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ veil: Double, _ moon: Bool) {
        let w = size.width, h = size.height
        gradient(&c, size, [0x100818, 0x24122C, 0x4A2438, 0x6E3A3E])
        glow(&c, at: CGPoint(x: w * 0.5, y: h * 0.46), rx: w * 0.95, ry: h * 0.14, color: hex(0x9A5240), strength: 0.5)
        stars(&c, size, Array(Layouts.stars.prefix(14)), t, yScale: 0.26, maxOpacity: 0.3)
        if moon { crescent(&c, size, .afterHours, color: hex(0xF3C98B)) }
        // Skyline in two depths, a few windows lit for the night.
        for (depth, buildings) in [Layouts.farBuildings, Layouts.nearBuildings].enumerated() {
            let near = depth == 1
            var skyline = Path()
            for b in buildings {
                let height = h * b.height * (near ? 0.42 : 0.32)
                let rect = CGRect(x: b.x * w, y: h * 0.5 - height, width: b.width * w, height: height)
                skyline.addRect(rect)
                if hash(b.seed) > 0.6 {
                    skyline.move(to: CGPoint(x: rect.midX - 4, y: rect.minY)); skyline.addLine(to: CGPoint(x: rect.midX, y: rect.minY - 18)); skyline.addLine(to: CGPoint(x: rect.midX + 4, y: rect.minY)); skyline.closeSubpath()
                }
            }
            if near {
                shaded(&c, skyline, top: 0x241430, bottom: 0x140B1C)
            } else {
                shaded(&c, skyline, top: 0x4A2A48, bottom: 0x2E1A34, haze: 0x6E3A3E, hazeOpacity: 0.3)
            }
            for b in buildings {
                let height = h * b.height * (near ? 0.42 : 0.32)
                let rect = CGRect(x: b.x * w, y: h * 0.5 - height, width: b.width * w, height: height)
                for i in 0..<3 where hash(b.seed + Double(i)) > 0.6 {
                    c.fill(Path(CGRect(x: rect.minX + 4 + Double(i) * 8, y: rect.minY + 10 + hash(b.seed + 7 + Double(i)) * 20, width: 3, height: 4)),
                           with: .color(hex(0xFFD9A0).opacity(near ? 0.6 : 0.4)))
                }
            }
        }
        // Canal mirroring the sky, then the bridge across it.
        let canal = h * 0.51
        c.fill(Path(CGRect(x: 0, y: canal, width: w, height: h - canal)),
               with: .linearGradient(Gradient(colors: [hex(0x5A3040), hex(0x2A1830), hex(0x100818)]), startPoint: CGPoint(x: 0, y: canal), endPoint: CGPoint(x: 0, y: h)))
        c.drawLayer { mirror in
            mirror.clip(to: Path(CGRect(x: 0, y: canal, width: w, height: h - canal)))
            mirror.addFilter(.blur(radius: 8))
            mirror.opacity = 0.45
            mirror.translateBy(x: 0, y: canal * 2)
            mirror.scaleBy(x: 1, y: -1)
            for b in Layouts.nearBuildings {
                let height = h * b.height * 0.42
                mirror.fill(Path(CGRect(x: b.x * w, y: h * 0.5 - height, width: b.width * w, height: height)), with: .color(hex(0x140B1C)))
            }
        }
        var bridge = Path(CGRect(x: 0, y: canal - 6, width: w * 0.8, height: 16))
        bridge.addEllipse(in: CGRect(x: w * 0.3, y: canal - 2, width: w * 0.3, height: 36))
        c.fill(bridge, with: .color(hex(0x120B18)), style: FillStyle(eoFill: true))
        glowDot(&c, at: CGPoint(x: w * 0.45, y: canal + 10), r: 2, color: hex(0xFFD9A0), glow: 14, strength: 0.8)
        // Bookshop on the right, its window the warm focal point.
        shaded(&c, Path(CGRect(x: w * 0.85, y: h * 0.35, width: w * 0.15, height: h * 0.2)), top: 0x1C1024, bottom: 0x0E0812)
        let window = CGRect(x: w * 0.885, y: h * 0.385, width: w * 0.1, height: h * 0.075)
        glow(&c, at: CGPoint(x: window.midX, y: window.midY), rx: w * 0.26, ry: h * 0.12, color: hex(0xF2B46A), strength: 0.3)
        c.fill(Path(roundedRect: window, cornerRadius: 4),
               with: .linearGradient(Gradient(colors: [hex(0xFFD29A), hex(0xE09A52)]), startPoint: CGPoint(x: 0, y: window.minY), endPoint: CGPoint(x: 0, y: window.maxY)))
        c.fill(Path(CGRect(x: window.minX, y: window.minY, width: window.width, height: 3)), with: .color(hex(0x140C1A)))
        c.fill(Path(CGRect(x: window.midX - 1, y: window.minY, width: 2, height: window.height)), with: .color(hex(0x140C1A).opacity(0.6)))
        // Street lamp.
        c.fill(Path(CGRect(x: w * 0.79, y: h * 0.40, width: 2, height: h * 0.11)), with: .color(hex(0x0B0710)))
        glowDot(&c, at: CGPoint(x: w * 0.80, y: h * 0.40), r: 3, color: hex(0xFFD9A0), glow: 24, strength: 1)
        c.drawLayer { soft in
            soft.addFilter(.blur(radius: 4))
            ripples(&soft, x: window.midX, from: canal + 12, depth: h * 0.22, t: t, color: hex(0xF2B46A), cycle: 14)
            ripples(&soft, x: w * 0.80, from: canal + 12, depth: h * 0.18, t: t, color: hex(0xFFD9A0), cycle: 20)
        }
        ripples(&c, x: window.midX, from: canal + 12, depth: h * 0.22, t: t, color: hex(0xF2B46A), cycle: 14)
        ripples(&c, x: w * 0.80, from: canal + 12, depth: h * 0.18, t: t, color: hex(0xFFD9A0), cycle: 20)
        // Sparse rain: long, slow, faint.
        for drop in Layouts.rain.prefix(18) {
            let y = ((drop.y + t * drop.speed * 0.35).truncatingRemainder(dividingBy: 1.1) - 0.05) * h
            let x = drop.x * w
            var p = Path()
            p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x - 1.5, y: y + 22))
            c.stroke(p, with: .color(.white.opacity(0.07)), lineWidth: 1)
        }
        self.veil(&c, size, from: veil, color: 0x160F1C)
    }

    // MARK: Shared pieces

    /// The Moon in the sky: top right, outside the title's run, with a soft halo.
    static func crescent(_ c: inout GraphicsContext, _ size: CGSize, _ scene: SceneKind, color: Color) {
        let r: CGFloat = 26
        let center = CGPoint(x: size.width - 58, y: size.height * 0.3)
        c.fill(Path(ellipseIn: CGRect(x: center.x - r * 3, y: center.y - r * 3, width: r * 6, height: r * 6)),
               with: .radialGradient(Gradient(colors: [color.opacity(0.16), .clear]), center: center, startRadius: r * 0.8, endRadius: r * 3))
        c.fill(CrescentShape(scene: scene).path(in: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)), with: .color(color))
    }

    /// A small house: walls, roof and one lit window with a glow.
    static func house(_ c: inout GraphicsContext, at base: CGPoint, scale: CGFloat, wall: UInt32, window: UInt32, glow: Double) {
        var h = c
        h.translateBy(x: base.x, y: base.y)
        h.scaleBy(x: scale, y: scale)
        h.fill(Path(CGRect(x: -16, y: -20, width: 32, height: 20)), with: .color(hex(wall)))
        var roof = Path()
        roof.move(to: CGPoint(x: -20, y: -20)); roof.addLine(to: CGPoint(x: 0, y: -34)); roof.addLine(to: CGPoint(x: 20, y: -20)); roof.closeSubpath()
        h.fill(roof, with: .color(hex(wall)))
        h.fill(Path(CGRect(x: 7, y: -32, width: 4, height: 8)), with: .color(hex(wall)))
        h.fill(Path(ellipseIn: CGRect(x: -18, y: -30, width: 36, height: 34)),
               with: .radialGradient(Gradient(colors: [hex(window).opacity(0.3 * glow), .clear]), center: CGPoint(x: 0, y: -11), startRadius: 0, endRadius: 20))
        h.fill(Path(CGRect(x: -4, y: -15, width: 7, height: 8)), with: .color(hex(window).opacity(glow)))
    }

    static func glowDot(_ c: inout GraphicsContext, at p: CGPoint, r: CGFloat, color: Color, glow: CGFloat, strength: Double) {
        c.fill(Path(ellipseIn: CGRect(x: p.x - glow, y: p.y - glow, width: glow * 2, height: glow * 2)),
               with: .radialGradient(Gradient(colors: [color.opacity(0.35 * strength), .clear]), center: p, startRadius: 0, endRadius: glow))
        c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(color.opacity(strength)))
    }

    /// A light's reflection on water: short dashes widening toward the viewer, each
    /// wobbling sideways and breathing over `cycle` seconds. Still when t is fixed.
    static func ripples(_ c: inout GraphicsContext, x: CGFloat, from top: CGFloat, depth: CGFloat, t: Double, color: Color, cycle: Double) {
        for i in 0..<12 {
            let f = Double(i) / 12
            let y = top + 4 + f * depth
            let width = 6 + f * 36
            let wobble = sin(t * 2 * .pi / cycle + Double(i) * 1.1) * (2 + 5 * f)
            let breathe = 0.6 + 0.4 * sin(t * 2 * .pi / (cycle * 0.7) + Double(i) * 0.8)
            c.fill(Path(roundedRect: CGRect(x: x + wobble - width / 2, y: y, width: width, height: 1.6), cornerRadius: 1),
                   with: .color(color.opacity((0.12 + 0.22 * breathe) * (1 - f * 0.8))))
        }
    }

    /// A row of tiered conifer silhouettes along `base`, heights from a seed, shaded
    /// from `top` to `bottom` and optionally hazed.
    static func conifers(_ c: inout GraphicsContext, _ size: CGSize, base: Double, height: Double, spacing: Double, seed: Double,
                         top: UInt32, bottom: UInt32, haze: UInt32? = nil, hazeOpacity: Double = 0) {
        var trees = Path()
        var x = -0.03 + hash(seed) * 0.04
        var i = 0.0
        while x < 1.05 {
            let hgt = size.height * height * (0.6 + 0.6 * hash(seed + i))
            let cx = x * size.width
            let y = size.height * base
            // Three tiers, the lowest sitting on the ground.
            for (topF, baseF, halfF) in [(0.55, 0.0, 0.26), (0.8, 0.35, 0.2), (1.0, 0.62, 0.14)] {
                trees.move(to: CGPoint(x: cx - hgt * halfF, y: y - hgt * baseF + 4))
                trees.addLine(to: CGPoint(x: cx, y: y - hgt * topF))
                trees.addLine(to: CGPoint(x: cx + hgt * halfF, y: y - hgt * baseF + 4))
                trees.closeSubpath()
            }
            x += spacing * (0.7 + 0.6 * hash(seed + i + 0.5))
            i += 1
        }
        trees.addRect(CGRect(x: 0, y: size.height * base, width: size.width, height: size.height))
        shaded(&c, trees, top: top, bottom: bottom, haze: haze, hazeOpacity: hazeOpacity)
    }

    /// Rolling hills: a smooth sum of sines (peaksPath is for sharp ranges).
    static func hillsPath(_ size: CGSize, base: Double, amp: Double, k: Double, phase: Double) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 6 {
            let u = Double(x / max(size.width, 1))
            let y = sin(u * .pi * k + phase) * 0.6 + sin(u * .pi * k * 2.3 + phase * 1.7) * 0.3 + sin(u * .pi * k * 5.1 + phase * 0.4) * 0.1
            path.addLine(to: CGPoint(x: x, y: size.height * base - amp * (y * 0.5 + 0.5)))
            x += 6
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        return path
    }

    /// A silhouette shaded from `top` at its highest point to `bottom` 140 pt lower, then
    /// optionally washed with sky `haze` so far layers recede.
    static func shaded(_ c: inout GraphicsContext, _ path: Path, top: UInt32, bottom: UInt32, haze: UInt32? = nil, hazeOpacity: Double = 0) {
        let box = path.boundingRect
        c.fill(path, with: .linearGradient(Gradient(colors: [hex(top), hex(bottom)]),
                                           startPoint: CGPoint(x: 0, y: box.minY), endPoint: CGPoint(x: 0, y: box.minY + 140)))
        if let haze, hazeOpacity > 0 {
            c.fill(path, with: .color(hex(haze).opacity(hazeOpacity)))
        }
    }

    /// A broad soft light, elliptical, blurred.
    static func glow(_ c: inout GraphicsContext, at p: CGPoint, rx: CGFloat, ry: CGFloat, color: Color, strength: Double) {
        // A circle in a squashed context: elliptical falloff with no hard edge.
        var g = c
        g.translateBy(x: p.x, y: p.y)
        g.scaleBy(x: 1, y: ry / rx)
        g.fill(Path(ellipseIn: CGRect(x: -rx, y: -rx, width: rx * 2, height: rx * 2)),
               with: .radialGradient(Gradient(colors: [color.opacity(strength), .clear]), center: .zero, startRadius: 0, endRadius: rx))
    }

    /// A cypress: a tapered flame shape with a slight lean.
    static func cypress(_ c: inout GraphicsContext, at base: CGPoint, height: CGFloat, width: CGFloat, color: UInt32) {
        var p = Path()
        p.move(to: CGPoint(x: base.x - width / 2, y: base.y))
        p.addQuadCurve(to: CGPoint(x: base.x + 1, y: base.y - height), control: CGPoint(x: base.x - width * 0.9, y: base.y - height * 0.55))
        p.addQuadCurve(to: CGPoint(x: base.x + width / 2, y: base.y), control: CGPoint(x: base.x + width * 0.9, y: base.y - height * 0.55))
        p.closeSubpath()
        c.fill(p, with: .color(hex(color)))
    }

    /// Fade to the page colour from `from` (fraction of height) down.
    static func veil(_ c: inout GraphicsContext, _ size: CGSize, from: Double, color: UInt32) {
        let top = size.height * from
        c.fill(Path(CGRect(x: 0, y: top, width: size.width, height: size.height - top)),
               with: .linearGradient(Gradient(colors: [hex(color).opacity(0), hex(color)]),
                                     startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: top + size.height * 0.17)))
    }
}
