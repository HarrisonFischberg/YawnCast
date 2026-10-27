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
    // MARK: Blue Hour — ink-blue lake, layered hills, cottage window; slow ripples

    static func blueHour(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ veil: Double) {
        let w = size.width, h = size.height
        gradient(&c, size, [0x0A1026, 0x101B3A, 0x1A2C58])
        stars(&c, size, Array(Layouts.stars.prefix(28)), t, yScale: 0.36, maxOpacity: 0.45)
        crescent(&c, size, .blueHour, color: hex(0xF3CF8E))
        c.fill(peaksPath(size, base: 0.50, amp: 58, k: 1.5, phase: 0.6), with: .color(hex(0x182A52)))
        c.fill(peaksPath(size, base: 0.55, amp: 46, k: 2.3, phase: 2.4), with: .color(hex(0x111E42)))
        // Lake from the far shore down.
        let shore = h * 0.6
        c.fill(Path(CGRect(x: 0, y: shore, width: w, height: h - shore)),
               with: .linearGradient(Gradient(colors: [hex(0x12224A), hex(0x080E22)]), startPoint: CGPoint(x: 0, y: shore), endPoint: CGPoint(x: 0, y: h)))
        // Near headland with cypresses and the cottage.
        c.fill(peaksPath(size, base: 0.605, amp: 22, k: 3.2, phase: 4.1), with: .color(hex(0x0B1330)))
        for (x, height) in [(0.56, 54.0), (0.60, 70.0), (0.63, 48.0), (0.78, 60.0), (0.81, 44.0)] {
            c.fill(Path(ellipseIn: CGRect(x: w * x - 6, y: shore - height, width: 12, height: height)), with: .color(hex(0x070D22)))
        }
        house(&c, at: CGPoint(x: w * 0.70, y: shore - 2), scale: 1, wall: 0x0A1128, window: 0xFFC772, glow: 1)
        // Ripples: reflections of the window and the Moon, widening and wobbling slowly.
        ripples(&c, x: w * 0.70, from: shore, depth: h * 0.25, t: t, color: hex(0xFFC772), cycle: 18)
        ripples(&c, x: w * 0.84, from: shore, depth: h * 0.3, t: t, color: hex(0xF3CF8E), cycle: 24)
        c.fill(wavePath(size, base: 0.80, amp: 9, k: 1.1, t: 0, speed: 0), with: .color(hex(0x070C1C)))
        self.veil(&c, size, from: veil, color: 0x0B1224)
    }

    // MARK: Fernlight — green clearing, conifers, still pool, cabin; fireflies

    static func fernlight(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ veil: Double) {
        let w = size.width, h = size.height
        gradient(&c, size, [0x0A1917, 0x0F2620, 0x17382C])
        stars(&c, size, Array(Layouts.stars.prefix(18)), t, yScale: 0.3, maxOpacity: 0.35)
        crescent(&c, size, .fernlight, color: hex(0xF2D08C))
        c.fill(peaksPath(size, base: 0.47, amp: 64, k: 1.7, phase: 1.1), with: .color(hex(0x163229)))
        conifers(&c, size, base: 0.50, height: 0.14, spacing: 0.07, seed: 3, color: 0x0F2720)
        conifers(&c, size, base: 0.56, height: 0.2, spacing: 0.09, seed: 8, color: 0x0A1E18)
        let pool = h * 0.63
        c.fill(Path(CGRect(x: 0, y: pool, width: w, height: h - pool)),
               with: .linearGradient(Gradient(colors: [hex(0x0D2A22), hex(0x06130F)]), startPoint: CGPoint(x: 0, y: pool), endPoint: CGPoint(x: 0, y: h)))
        c.fill(peaksPath(size, base: 0.635, amp: 14, k: 2.6, phase: 0.3), with: .color(hex(0x081914)))
        house(&c, at: CGPoint(x: w * 0.72, y: pool - 2), scale: 1.1, wall: 0x071510, window: 0xFFB85C, glow: 1)
        ripples(&c, x: w * 0.72, from: pool, depth: h * 0.2, t: t, color: hex(0xFFB85C), cycle: 20)
        // Foreground ferns: big dark fronds in the corners, still.
        for leaf in Layouts.leaves {
            var l = c
            l.translateBy(x: leaf.x * w, y: h * leaf.y)
            l.rotate(by: .degrees(leaf.angle))
            l.fill(Path(ellipseIn: CGRect(x: 0, y: -leaf.width / 2, width: leaf.length, height: leaf.width)), with: .color(hex(0x04110D)))
        }
        // Fireflies: a slow glow cycle each, drifting a little; no flashing.
        for fly in Layouts.fireflies.prefix(14) {
            let x = (fly.x + 0.03 * sin(t * fly.speed * 0.5 + fly.phase)) * w
            let y = (0.42 + (fly.y - 0.35) * 0.55 + 0.02 * cos(t * fly.speed * 0.35 + fly.phase)) * h
            let glow = pow(0.5 + 0.5 * sin(t * (0.7 + 0.25 * fly.blink) + fly.phase), 2)
            guard glow > 0.03 else { continue }
            c.fill(Path(ellipseIn: CGRect(x: x - 7, y: y - 7, width: 14, height: 14)), with: .color(hex(0xF2D08C).opacity(0.18 * glow)))
            c.fill(Path(ellipseIn: CGRect(x: x - 1.6, y: y - 1.6, width: 3.2, height: 3.2)), with: .color(hex(0xFFE9A8).opacity(0.9 * glow)))
        }
        self.veil(&c, size, from: veil, color: 0x0A1A16)
    }

    // MARK: Ember Lodge — copper dusk, mountain layers, cabin; chimney smoke, window flicker

    static func emberLodge(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ veil: Double) {
        let w = size.width, h = size.height
        gradient(&c, size, [0x160C0A, 0x3A1A12, 0x7A3A1C])
        stars(&c, size, Array(Layouts.stars.prefix(16)), t, yScale: 0.28, maxOpacity: 0.35)
        crescent(&c, size, .emberLodge, color: hex(0xF0B070))
        c.fill(peaksPath(size, base: 0.44, amp: 78, k: 1.4, phase: 0.9), with: .color(hex(0x5A2A18)))
        c.fill(peaksPath(size, base: 0.51, amp: 60, k: 2.1, phase: 2.8), with: .color(hex(0x3A1A10)))
        c.fill(peaksPath(size, base: 0.58, amp: 40, k: 3.0, phase: 4.6), with: .color(hex(0x22100A)))
        let lake = h * 0.6
        c.fill(Path(CGRect(x: 0, y: lake, width: w, height: h * 0.1)),
               with: .linearGradient(Gradient(colors: [hex(0x4A2414), hex(0x1E0E09)]), startPoint: CGPoint(x: 0, y: lake), endPoint: CGPoint(x: 0, y: lake + h * 0.1)))
        ripples(&c, x: w * 0.5, from: lake, depth: h * 0.09, t: t, color: hex(0xF0B070), cycle: 22)
        c.fill(Path(CGRect(x: 0, y: lake + h * 0.1, width: w, height: h)), with: .color(hex(0x1E0E09)))
        conifers(&c, size, base: 0.68, height: 0.16, spacing: 0.11, seed: 5, color: 0x120806)
        let cabin = CGPoint(x: w * 0.74, y: h * 0.70)
        // Window light breathes slowly, never flickers.
        let flicker = 0.82 + 0.18 * sin(t * 0.55) * sin(t * 0.9 + 1)
        house(&c, at: cabin, scale: 1.5, wall: 0x0E0604, window: 0xFFB45A, glow: flicker)
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

    static func tidalInk(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ veil: Double) {
        let w = size.width, h = size.height
        gradient(&c, size, [0x0A1424, 0x10213A, 0x183652])
        stars(&c, size, Array(Layouts.stars.prefix(26)), t, yScale: 0.34, maxOpacity: 0.45)
        crescent(&c, size, .tidalInk, color: hex(0xF1D6A0))
        c.fill(peaksPath(size, base: 0.49, amp: 44, k: 1.2, phase: 2.0), with: .color(hex(0x14283F)))
        let sea = h * 0.5
        c.fill(Path(CGRect(x: 0, y: sea, width: w, height: h - sea)),
               with: .linearGradient(Gradient(colors: [hex(0x163352), hex(0x0A1524)]), startPoint: CGPoint(x: 0, y: sea), endPoint: CGPoint(x: 0, y: h)))
        // Lighthouse on its rock, lamp lit.
        let rock = CGPoint(x: w * 0.72, y: sea + 14)
        c.fill(Path(ellipseIn: CGRect(x: rock.x - 46, y: rock.y - 16, width: 92, height: 32)), with: .color(hex(0x0B1628)))
        var tower = Path()
        tower.move(to: CGPoint(x: rock.x - 6, y: rock.y - 10)); tower.addLine(to: CGPoint(x: rock.x + 6, y: rock.y - 10))
        tower.addLine(to: CGPoint(x: rock.x + 4, y: rock.y - 48)); tower.addLine(to: CGPoint(x: rock.x - 4, y: rock.y - 48)); tower.closeSubpath()
        c.fill(tower, with: .color(hex(0x0B1628)))
        glowDot(&c, at: CGPoint(x: rock.x, y: rock.y - 50), r: 2.6, color: hex(0xFFE2A0), glow: 18, strength: 1)
        ripples(&c, x: w * 0.84, from: sea, depth: h * 0.28, t: t, color: hex(0xF1D6A0), cycle: 16)
        // Broad swells rolling in, slow.
        for (i, base) in [0.60, 0.68, 0.76, 0.84].enumerated() {
            let wave = wavePath(size, base: base, amp: 7 + Double(i) * 2, k: 1.6 + Double(i) * 0.4, t: t, speed: 0.035 + Double(i) * 0.01)
            c.fill(wave, with: .color(hex(i % 2 == 0 ? 0x10243C : 0x0B1A2C)))
            c.stroke(wavePath(size, base: base, amp: 7 + Double(i) * 2, k: 1.6 + Double(i) * 0.4, t: t, speed: 0.035 + Double(i) * 0.01, closed: false),
                     with: .color(.white.opacity(0.07)), lineWidth: 1.2)
        }
        // Near headland on the left.
        var head = Path()
        head.move(to: CGPoint(x: 0, y: h)); head.addLine(to: CGPoint(x: 0, y: h * 0.56))
        head.addQuadCurve(to: CGPoint(x: w * 0.42, y: h * 0.68), control: CGPoint(x: w * 0.22, y: h * 0.54))
        head.addQuadCurve(to: CGPoint(x: w * 0.3, y: h), control: CGPoint(x: w * 0.5, y: h * 0.84))
        head.closeSubpath()
        c.fill(head, with: .color(hex(0x070F1C)))
        self.veil(&c, size, from: veil, color: 0x0A1521)
    }

    // MARK: After Hours — plum skyline, canal and bridge, bookshop window; sparse rain

    static func afterHours(_ c: inout GraphicsContext, _ size: CGSize, _ t: Double, _ veil: Double) {
        let w = size.width, h = size.height
        gradient(&c, size, [0x160E1E, 0x2A1A30, 0x5A2E36])
        stars(&c, size, Array(Layouts.stars.prefix(14)), t, yScale: 0.26, maxOpacity: 0.3)
        crescent(&c, size, .afterHours, color: hex(0xF3C98B))
        // Skyline in two depths, a few windows lit for the night.
        for (depth, buildings) in [Layouts.farBuildings, Layouts.nearBuildings].enumerated() {
            let near = depth == 1
            for b in buildings {
                let height = h * b.height * (near ? 0.42 : 0.5)
                let rect = CGRect(x: b.x * w, y: h * 0.58 - height, width: b.width * w, height: height)
                c.fill(Path(rect), with: .color(hex(near ? 0x1A1022 : 0x2A1A30)))
                if hash(b.seed) > 0.6 {
                    var spire = Path()
                    spire.move(to: CGPoint(x: rect.midX - 4, y: rect.minY)); spire.addLine(to: CGPoint(x: rect.midX, y: rect.minY - 18)); spire.addLine(to: CGPoint(x: rect.midX + 4, y: rect.minY))
                    c.fill(spire, with: .color(hex(near ? 0x1A1022 : 0x2A1A30)))
                }
                for i in 0..<3 where hash(b.seed + Double(i)) > 0.6 {
                    c.fill(Path(CGRect(x: rect.minX + 4 + Double(i) * 8, y: rect.minY + 10 + hash(b.seed + 7 + Double(i)) * 20, width: 3, height: 4)),
                           with: .color(hex(0xFFD9A0).opacity(0.5)))
                }
            }
        }
        // Canal, then the bridge across it.
        let canal = h * 0.6
        c.fill(Path(CGRect(x: 0, y: canal, width: w, height: h - canal)),
               with: .linearGradient(Gradient(colors: [hex(0x2E1C30), hex(0x120B18)]), startPoint: CGPoint(x: 0, y: canal), endPoint: CGPoint(x: 0, y: h)))
        var bridge = Path(CGRect(x: 0, y: canal - 6, width: w * 0.8, height: 16))
        bridge.addEllipse(in: CGRect(x: w * 0.3, y: canal - 2, width: w * 0.3, height: 36))
        c.fill(bridge, with: .color(hex(0x120B18)), style: FillStyle(eoFill: true))
        glowDot(&c, at: CGPoint(x: w * 0.45, y: canal + 10), r: 2, color: hex(0xFFD9A0), glow: 14, strength: 0.8)
        // Bookshop on the right, its window the warm focal point.
        c.fill(Path(CGRect(x: w * 0.8, y: h * 0.38, width: w * 0.2, height: h * 0.36)), with: .color(hex(0x140C1A)))
        let window = CGRect(x: w * 0.84, y: h * 0.48, width: w * 0.16, height: h * 0.2)
        c.fill(Path(ellipseIn: window.insetBy(dx: -w * 0.1, dy: -h * 0.08)),
               with: .radialGradient(Gradient(colors: [hex(0xF2B46A).opacity(0.28), .clear]), center: CGPoint(x: window.midX, y: window.midY), startRadius: 0, endRadius: w * 0.22))
        c.fill(Path(roundedRect: window, cornerRadius: 4), with: .color(hex(0xF2B46A)))
        c.fill(Path(CGRect(x: window.minX, y: window.minY, width: window.width, height: 3)), with: .color(hex(0x140C1A)))
        // Street lamp.
        c.fill(Path(CGRect(x: w * 0.77, y: h * 0.47, width: 2, height: h * 0.14)), with: .color(hex(0x0B0710)))
        glowDot(&c, at: CGPoint(x: w * 0.78, y: h * 0.47), r: 3, color: hex(0xFFD9A0), glow: 22, strength: 1)
        ripples(&c, x: window.midX, from: canal + 12, depth: h * 0.22, t: t, color: hex(0xF2B46A), cycle: 14)
        ripples(&c, x: w * 0.78, from: canal + 12, depth: h * 0.18, t: t, color: hex(0xFFD9A0), cycle: 20)
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
        let center = CGPoint(x: size.width - 58, y: size.height * 0.2)
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

    /// A row of conifer silhouettes along `base`, heights from a seed.
    static func conifers(_ c: inout GraphicsContext, _ size: CGSize, base: Double, height: Double, spacing: Double, seed: Double, color: UInt32) {
        var x = -0.03 + hash(seed) * 0.04
        var i = 0.0
        while x < 1.05 {
            let hgt = size.height * height * (0.6 + 0.6 * hash(seed + i))
            let cx = x * size.width
            let y = size.height * base
            var tree = Path()
            tree.move(to: CGPoint(x: cx - hgt * 0.28, y: y + 4))
            tree.addLine(to: CGPoint(x: cx, y: y - hgt))
            tree.addLine(to: CGPoint(x: cx + hgt * 0.28, y: y + 4))
            tree.closeSubpath()
            c.fill(tree, with: .color(hex(color)))
            x += spacing * (0.7 + 0.6 * hash(seed + i + 0.5))
            i += 1
        }
        c.fill(Path(CGRect(x: 0, y: size.height * base, width: size.width, height: size.height)), with: .color(hex(color)))
    }

    /// Fade to the page colour from `from` (fraction of height) down.
    static func veil(_ c: inout GraphicsContext, _ size: CGSize, from: Double, color: UInt32) {
        let top = size.height * from
        c.fill(Path(CGRect(x: 0, y: top, width: size.width, height: size.height - top)),
               with: .linearGradient(Gradient(colors: [hex(color).opacity(0), hex(color)]),
                                     startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: top + size.height * 0.22)))
    }
}
