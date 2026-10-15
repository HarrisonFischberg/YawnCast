import SwiftUI

/// Calm animated night sky: deep-blue gradient, slow rolling waves near the
/// bottom, and softly twinkling stars. ~15 fps, frozen under Reduce Motion.
struct NightSkyBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let stars: [Star] = {
        // Deterministic layout (simple LCG) so stars don't jump between launches.
        var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 11) / Double(1 << 53)
        }
        return (0..<80).map { _ in
            Star(x: next(), y: next() * 0.72, radius: 0.5 + next() * 1.3, speed: 0.3 + next() * 0.9, phase: next() * .pi * 2, sparkle: next() > 0.92)
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: reduceMotion)) { context in
            Canvas(opaque: true) { canvas, size in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let rect = CGRect(origin: .zero, size: size)
                canvas.fill(Path(rect), with: .linearGradient(
                    Gradient(colors: [Color(hex: 0x060D26), Color(hex: 0x0C1A42), Color(hex: 0x14285A)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)
                ))

                for star in Self.stars {
                    let twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * star.speed + star.phase))
                    let center = CGPoint(x: star.x * size.width, y: star.y * size.height)
                    let r = star.radius * (star.sparkle ? 1.4 : 1)
                    canvas.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                                with: .color(.white.opacity(0.75 * twinkle)))
                    if star.sparkle {
                        // A soft four-point glint on a few stars.
                        var glint = Path()
                        let len = r * 4 * twinkle
                        glint.move(to: CGPoint(x: center.x - len, y: center.y)); glint.addLine(to: CGPoint(x: center.x + len, y: center.y))
                        glint.move(to: CGPoint(x: center.x, y: center.y - len)); glint.addLine(to: CGPoint(x: center.x, y: center.y + len))
                        canvas.stroke(glint, with: .color(.white.opacity(0.35 * twinkle)), lineWidth: 0.6)
                    }
                }

                let waves: [(base: Double, amp: Double, k: Double, speed: Double, color: Color)] = [
                    (0.58, 22, 1.4, 0.10, Color(hex: 0x1A2E66).opacity(0.45)),
                    (0.70, 26, 2.1, -0.07, Color(hex: 0x22356B).opacity(0.55)),
                    (0.83, 18, 2.9, 0.05, Color(hex: 0x0F1E4A).opacity(0.85)),
                ]
                for wave in waves {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: size.height))
                    let step: CGFloat = 8
                    var x: CGFloat = 0
                    while x <= size.width + step {
                        let u = Double(x / max(size.width, 1))
                        let y = size.height * wave.base + wave.amp * sin(u * .pi * wave.k + t * wave.speed * 2 * .pi / 6)
                            + wave.amp * 0.4 * sin(u * .pi * wave.k * 2.3 - t * wave.speed)
                        path.addLine(to: CGPoint(x: x, y: y))
                        x += step
                    }
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.closeSubpath()
                    canvas.fill(path, with: .color(wave.color))
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private struct Star {
        var x, y, radius, speed, phase: Double
        var sparkle: Bool
    }
}

/// Full-screen background for a screen: the night sky, or the theme's flat color.
struct ScreenBackground: View {
    @Environment(\.theme) private var theme

    var body: some View {
        if theme.isNightSky {
            NightSkyBackground()
        } else {
            theme.bg.ignoresSafeArea()
        }
    }
}
