#if DEBUG
import SwiftUI
import YawnCastCore

// Design exploration (branch design/explore): `-design base|A|B|C` seeds a synthetic
// library with drawn covers, and A/B/C restyle Now Playing, Library and the dock.
// Debug builds only; nothing here ships.

enum DesignOption: String {
    case base, A, B, C

    static let current: DesignOption? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-design"), i + 1 < args.count else { return nil }
        return DesignOption(rawValue: args[i + 1])
    }()

    /// A, B or C; nil for the baseline UI (with or without the synthetic seed).
    static var restyle: DesignOption? { current == .base ? nil : current }
}

nonisolated enum DesignSeed {
    struct Spec {
        let slug: String, title: String, author: String, cover: String
        let bg: UInt32, fg: UInt32, ink: UInt32
        let motif: Int
        var serif = false
    }

    static let specs: [Spec] = [
        Spec(slug: "tide", title: "The Slow Tide", author: "Harbor Lane Audio", cover: "The Slow Tide", bg: 0x1F4E5F, fg: 0xF3E9D2, ink: 0x88C7C2, motif: 0, serif: true),
        Spec(slug: "urgent", title: "Nothing Urgent: quiet stories for the end of the day", author: "Fenwick & Rue", cover: "Nothing Urgent", bg: 0xE8D9B8, fg: 0x2B2A33, ink: 0xC9683F, motif: 1),
        Spec(slug: "atlas", title: "Night Atlas", author: "Odd Hours Radio", cover: "Night Atlas", bg: 0x232A5C, fg: 0xF6D97A, ink: 0x5A66B8, motif: 2, serif: true),
        Spec(slug: "lanterns", title: "Paper Lanterns", author: "Mira Okafor", cover: "Paper Lanterns", bg: 0xB8432F, fg: 0xFFE9C9, ink: 0xF2A65A, motif: 3),
        Spec(slug: "home", title: "The Long Way Home", author: "Northbound Sound", cover: "The Long Way Home", bg: 0x2F5D50, fg: 0xF4EBD8, ink: 0x8FB996, motif: 4, serif: true),
        Spec(slug: "rain", title: "Rain on Tin", author: "Lowlight Collective", cover: "Rain on Tin", bg: 0x3A3F4B, fg: 0xE6ECF2, ink: 0x8A96A8, motif: 5),
        Spec(slug: "history", title: "Half Asleep History", author: "Tobias Wren", cover: "Half Asleep History", bg: 0xD9A441, fg: 0x2A1D0A, ink: 0xA8721B, motif: 6, serif: true),
        Spec(slug: "moth", title: "Moth Hours", author: "Juniper Press Audio", cover: "Moth Hours", bg: 0x4B2E4F, fg: 0xF2DDE6, ink: 0xB58BB0, motif: 7),
    ]

    static func spec(_ slug: String) -> Spec { specs.first { $0.slug == slug } ?? specs[0] }

    static let shows: [Show] = specs.map {
        Show(feedURL: URL(string: "design://feed/\($0.slug)")!, title: $0.title, author: $0.author,
             artworkURL: URL(string: "design://cover/\($0.slug)"))
    }

    /// `-designAudio <path>`: a long silent file on the Mac, so the scrubber shows a real length.
    static var audioURL: URL {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-designAudio"), i + 1 < args.count { return URL(fileURLWithPath: args[i + 1]) }
        return Bundle.main.url(forResource: "fixture-tone", withExtension: "m4a")!
    }

    static let episodeTitles = ["The lighthouse keeper’s last winter", "A slow walk through the botanical garden", "How the night train got its name"]

    static func episodes(for show: Show) -> [Episode] {
        let index = shows.firstIndex(of: show) ?? 0
        return episodeTitles.enumerated().map { n, title in
            // Every third show has something from yesterday (a "new" pip); the rest are older.
            let daysAgo = (index % 3 == 0 ? 1 : 12) + n * 7
            return Episode(id: "\(show.id)-\(n)", showFeedURL: show.feedURL, showTitle: show.title, title: title,
                           published: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()),
                           duration: 38 * 60 + 40, audioURL: audioURL,
                           summary: "A synthetic episode for design previews.", artworkURL: show.artworkURL)
        }
    }

    @MainActor static func run(model: AppModel, launch: LaunchOptions, arguments: [String]) {
        UserDefaults.standard.set(true, forKey: "didOnboard")
        UserDefaults.standard.set(true, forKey: "celebratedFirstShow")
        model.seedForDemo(shows)
        if let page = launch.page { model.homePage = page }
        if let layout = launch.layout { model.libraryLayout = layout }
        model.loadForDemo(episodes(for: shows[2])[0], position: 14 * 60 + 22)
        if launch.openPlayer { model.isPlayerPresented = true }
        Task { await model.refreshLatest() } // fills the "new episode" pips
        guard let i = arguments.firstIndex(of: "-designSleep"), i + 1 < arguments.count else { return }
        let status: SleepStatus = arguments[i + 1] == "fade" ? .fading(level: 0.6) : .waiting(untilFade: 19 * 60)
        // The real controller resets the status when the player settles, so pin it for a few seconds.
        Task { @MainActor in
            for _ in 0..<40 {
                model.setSleepStatusForDesign(status)
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }
}

struct DesignFeedService: FeedService {
    func fetch(_ feedURL: URL, maxPages: Int) async throws -> Feed {
        guard let show = DesignSeed.shows.first(where: { $0.feedURL == feedURL }) else { throw FeedError.noEpisodes }
        return Feed(show: show, episodes: DesignSeed.episodes(for: show))
    }
}

/// Drawn stand-in for podcast artwork: a flat field, one motif, the show's name.
struct DesignCover: View {
    let slug: String

    var body: some View {
        let spec = DesignSeed.spec(slug)
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .bottomLeading) {
                Color(hex: spec.bg)
                Canvas { c, size in Self.draw(spec, &c, size) }
                if w > 70 {
                    Text(spec.cover)
                        .font(.system(size: w * 0.135, weight: spec.serif ? .bold : .heavy, design: spec.serif ? .serif : .default))
                        .foregroundStyle(Color(hex: spec.fg))
                        .lineSpacing(-w * 0.01)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)
                        .padding(w * 0.09)
                        .frame(width: w * 0.86, alignment: .leading)
                }
            }
        }
    }

    private static func draw(_ spec: DesignSeed.Spec, _ c: inout GraphicsContext, _ s: CGSize) {
        let w = s.width, h = s.height
        let ink = Color(hex: spec.ink), fg = Color(hex: spec.fg)
        switch spec.motif {
        case 0: // tide: three bands
            for i in 0..<3 {
                var p = Path()
                let y = h * (0.18 + 0.12 * Double(i))
                p.move(to: CGPoint(x: 0, y: y))
                p.addCurve(to: CGPoint(x: w, y: y), control1: CGPoint(x: w * 0.3, y: y - h * 0.09), control2: CGPoint(x: w * 0.7, y: y + h * 0.09))
                c.stroke(p, with: .color(ink.opacity(0.9 - Double(i) * 0.25)), lineWidth: w * 0.05)
            }
        case 1: // sun over a line
            c.fill(Path(ellipseIn: CGRect(x: w * 0.52, y: h * 0.12, width: w * 0.36, height: w * 0.36)), with: .color(ink))
            c.fill(Path(CGRect(x: w * 0.09, y: h * 0.55, width: w * 0.82, height: h * 0.012)), with: .color(fg))
        case 2: // crescent and stars
            c.fill(Path(ellipseIn: CGRect(x: w * 0.5, y: h * 0.1, width: w * 0.38, height: w * 0.38)), with: .color(fg))
            c.fill(Path(ellipseIn: CGRect(x: w * 0.42, y: h * 0.06, width: w * 0.36, height: w * 0.36)), with: .color(Color(hex: spec.bg)))
            for (x, y) in [(0.14, 0.2), (0.3, 0.42), (0.2, 0.52), (0.84, 0.56)] {
                c.fill(Path(ellipseIn: CGRect(x: w * x, y: h * y, width: w * 0.03, height: w * 0.03)), with: .color(ink))
            }
        case 3: // lanterns
            for (x, y, r) in [(0.2, 0.2, 0.2), (0.52, 0.12, 0.14), (0.72, 0.28, 0.2), (0.4, 0.36, 0.1)] {
                c.fill(Path(ellipseIn: CGRect(x: w * x, y: h * y, width: w * r, height: w * r * 1.2)), with: .color(ink))
            }
        case 4: // hill and road
            var hill = Path()
            hill.move(to: CGPoint(x: 0, y: h * 0.5))
            hill.addQuadCurve(to: CGPoint(x: w, y: h * 0.34), control: CGPoint(x: w * 0.5, y: h * 0.12))
            hill.addLine(to: CGPoint(x: w, y: 0)); hill.addLine(to: CGPoint(x: 0, y: 0)); hill.closeSubpath()
            c.fill(hill, with: .color(ink.opacity(0.55)))
            c.fill(Path(ellipseIn: CGRect(x: w * 0.68, y: h * 0.08, width: w * 0.14, height: w * 0.14)), with: .color(fg))
        case 5: // rain
            for i in 0..<9 {
                var p = Path()
                let x = w * (0.08 + 0.11 * Double(i))
                p.move(to: CGPoint(x: x + w * 0.06, y: h * 0.08)); p.addLine(to: CGPoint(x: x, y: h * (0.3 + 0.03 * Double(i % 3))))
                c.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: w * 0.018, lineCap: .round))
            }
        case 6: // columns
            for i in 0..<5 {
                c.fill(Path(CGRect(x: w * (0.1 + 0.17 * Double(i)), y: h * 0.1, width: w * 0.09, height: h * 0.4)), with: .color(ink))
            }
            c.fill(Path(CGRect(x: w * 0.07, y: h * 0.07, width: w * 0.86, height: h * 0.04)), with: .color(Color(hex: spec.fg)))
        default: // moth
            var wings = Path()
            wings.move(to: CGPoint(x: w * 0.5, y: h * 0.3))
            wings.addLine(to: CGPoint(x: w * 0.16, y: h * 0.12)); wings.addLine(to: CGPoint(x: w * 0.26, y: h * 0.46)); wings.closeSubpath()
            wings.move(to: CGPoint(x: w * 0.5, y: h * 0.3))
            wings.addLine(to: CGPoint(x: w * 0.84, y: h * 0.12)); wings.addLine(to: CGPoint(x: w * 0.74, y: h * 0.46)); wings.closeSubpath()
            c.fill(wings, with: .color(ink))
            c.fill(Path(ellipseIn: CGRect(x: w * 0.47, y: h * 0.2, width: w * 0.06, height: h * 0.24)), with: .color(fg))
        }
    }
}
#endif
