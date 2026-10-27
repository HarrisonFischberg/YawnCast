import SwiftUI

/// A coordinated palette. Values mirror `replica/design/tokens.<id>.json`,
/// which is what the contrast check runs against.
struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let blurb: String
    let colorScheme: ColorScheme
    let bg: Color
    let surface: Color
    let raised: Color
    let border: Color
    let text: Color
    let textMuted: Color
    let accent: Color
    let onAccent: Color
    let danger: Color
    /// Key "edge" (the visible side of a raised key).
    let edge: Color
    /// Top-edge highlight on raised keys.
    let highlight: Color
    let shadowOpacity: Double
    /// Animated scene drawn behind screens (the Scenes); nil for flat colours.
    var scene: SceneKind?
    /// Use only warm tints for highlights and decorations (Ember), no cool or rainbow colors.
    var warmOnly = false
    /// The text style every screen draws in, set from AppModel.look; see `styled(_:)`.
    var style: ThemeStyle = .pictureBook
    /// Night page whose day partner is drawn when the phone is in light mode.
    var dayVariant: String?
    /// The Sleep z's and brand z's; the accent when nil.
    var zColor: Color?

    /// The pink z of the brand mark; warm-only pages use their accent instead.
    var brandPink: Color { warmOnly ? accent : Color(hex: 0xF48FB1) }
    /// One of the 0.19 bedtime scenes (Blue Hour … After Hours).
    var isNight: Bool { scene?.isNight ?? false }

    // MARK: Bedtime scenes (v0.19): five candidate landscapes, none chosen yet. Midnight
    // stays the default until a product decision maps it.

    static let blueHour = Theme(
        id: "bluehour", name: "Blue Hour", blurb: "Ink-blue lake, a cottage window",
        colorScheme: .dark,
        bg: Color(hex: 0x0B1224), surface: Color(hex: 0x151F38), raised: Color(hex: 0x1D2A47),
        border: Color(hex: 0x2E3D60), text: Color(hex: 0xF2E8D5), textMuted: Color(hex: 0xAAB3C9),
        accent: Color(hex: 0xF3CF8E), onAccent: Color(hex: 0x1A1408), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x070C1A), highlight: .white.opacity(0.08), shadowOpacity: 0.6,
        scene: .blueHour, zColor: Color(hex: 0xF4A3C4)
    )

    /// Trial twin of Blue Hour drawn from a photo (Daniel Scicchitano, Unsplash).
    static let blueHourPhoto = Theme(
        id: "bluehour-photo", name: "Blue Hour Photo", blurb: "Photo trial: moon over a lit boathouse",
        colorScheme: .dark,
        bg: Color(hex: 0x0B1224), surface: Color(hex: 0x151F38), raised: Color(hex: 0x1D2A47),
        border: Color(hex: 0x2E3D60), text: Color(hex: 0xF2E8D5), textMuted: Color(hex: 0xAAB3C9),
        accent: Color(hex: 0xF3CF8E), onAccent: Color(hex: 0x1A1408), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x070C1A), highlight: .white.opacity(0.08), shadowOpacity: 0.6,
        scene: .blueHourPhoto, zColor: Color(hex: 0xF4A3C4)
    )

    static let fernlight = Theme(
        id: "fernlight", name: "Fernlight", blurb: "Deep green clearing, fireflies",
        colorScheme: .dark,
        bg: Color(hex: 0x0A1A16), surface: Color(hex: 0x12261F), raised: Color(hex: 0x183128),
        border: Color(hex: 0x274539), text: Color(hex: 0xF1E9D2), textMuted: Color(hex: 0xA7BDAF),
        accent: Color(hex: 0xF2D08C), onAccent: Color(hex: 0x1A1408), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x050E0B), highlight: .white.opacity(0.07), shadowOpacity: 0.6,
        scene: .fernlight, zColor: Color(hex: 0xF2D08C)
    )

    /// Warm-only like Ember: no blue in any app-owned paint.
    static let emberLodge = Theme(
        id: "emberlodge", name: "Ember Lodge", blurb: "Copper mountains, chimney smoke",
        colorScheme: .dark,
        bg: Color(hex: 0x160D0A), surface: Color(hex: 0x22150F), raised: Color(hex: 0x2E1D15),
        border: Color(hex: 0x4A2F22), text: Color(hex: 0xF2DFC8), textMuted: Color(hex: 0xC19B82),
        accent: Color(hex: 0xF0B070), onAccent: Color(hex: 0x1A0A04), danger: Color(hex: 0xFFB27A),
        edge: Color(hex: 0x0A0503), highlight: Color(hex: 0xF2DFC8).opacity(0.08), shadowOpacity: 0.7,
        scene: .emberLodge, warmOnly: true, zColor: Color(hex: 0xF5B87A)
    )

    static let tidalInk = Theme(
        id: "tidalink", name: "Tidal Ink", blurb: "Lighthouse over broad waves",
        colorScheme: .dark,
        bg: Color(hex: 0x0A1521), surface: Color(hex: 0x122032), raised: Color(hex: 0x192B40),
        border: Color(hex: 0x2A4057), text: Color(hex: 0xEDE9DC), textMuted: Color(hex: 0xA4B3C2),
        accent: Color(hex: 0xF1D6A0), onAccent: Color(hex: 0x161008), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x060D16), highlight: .white.opacity(0.08), shadowOpacity: 0.6,
        scene: .tidalInk, zColor: Color(hex: 0xF4A6C0)
    )

    static let afterHours = Theme(
        id: "afterhours", name: "After Hours", blurb: "Plum city, canal, a bookshop",
        colorScheme: .dark,
        bg: Color(hex: 0x160F1C), surface: Color(hex: 0x211829), raised: Color(hex: 0x2C2136),
        border: Color(hex: 0x463652), text: Color(hex: 0xF4E7DA), textMuted: Color(hex: 0xBBA7C0),
        accent: Color(hex: 0xF3C98B), onAccent: Color(hex: 0x1A1008), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x0B0710), highlight: .white.opacity(0.08), shadowOpacity: 0.6,
        scene: .afterHours, zColor: Color(hex: 0xE8A0B4)
    )

    // MARK: Colours (v0.17): four flat palettes, each with a night and a day page that
    // follow the phone. They merge the earlier Color Scapes: Almanac takes over from
    // Paper and Ink, Ember from Ember and Red Light.

    /// Almanac (default): ink-black at night with goldenrod for the Moon; by day the
    /// goldenrod page with a red Moon.
    static let almanac = Theme(
        id: "almanac", name: "Almanac", blurb: "Ink by night, goldenrod by day",
        colorScheme: .dark,
        bg: Color(hex: 0x100F0C), surface: Color(hex: 0x1C180F), raised: Color(hex: 0x241F14),
        border: Color(hex: 0x4A4231), text: Color(hex: 0xEFE6CF), textMuted: Color(hex: 0xA99F86),
        accent: Color(hex: 0xF2C230), onAccent: Color(hex: 0x17140D), danger: Color(hex: 0xFF8F7A),
        edge: Color(hex: 0x080706), highlight: .white.opacity(0.06), shadowOpacity: 0.5,
        dayVariant: "almanacday"
    )

    static let almanacDay = Theme(
        id: "almanacday", name: "Almanac", blurb: "Ink by night, goldenrod by day",
        colorScheme: .light,
        bg: Color(hex: 0xF2C230), surface: Color(hex: 0xE6B520), raised: Color(hex: 0xF7D364),
        border: Color(hex: 0x17140D), text: Color(hex: 0x17140D), textMuted: Color(hex: 0x4D4223),
        accent: Color(hex: 0xA8261B), onAccent: Color(hex: 0xFBEFD8), danger: Color(hex: 0x8A1C12),
        edge: Color(hex: 0xC99A12), highlight: .white.opacity(0.3), shadowOpacity: 0.15
    )

    /// Ember: warm red on near-black, no blue light (was Ember, Red Light and Safelight).
    static let ember = Theme(
        id: "safelight", name: "Ember", blurb: "Warm red, no blue light",
        colorScheme: .dark,
        bg: Color(hex: 0x0A0504), surface: Color(hex: 0x170B08), raised: Color(hex: 0x24110C),
        border: Color(hex: 0x4A271C), text: Color(hex: 0xE9AE93), textMuted: Color(hex: 0xC27A5E),
        accent: Color(hex: 0xFF7A2E), onAccent: Color(hex: 0x1A0602), danger: Color(hex: 0xFFB27A),
        edge: Color(hex: 0x050202), highlight: Color(hex: 0xE9AE93).opacity(0.08), shadowOpacity: 0.7,
        warmOnly: true, dayVariant: "safelightday"
    )

    static let emberDay = Theme(
        id: "safelightday", name: "Ember", blurb: "Warm red, no blue light",
        colorScheme: .light,
        bg: Color(hex: 0xF3F1EC), surface: Color(hex: 0xE7E4DD), raised: Color(hex: 0xFFFFFF),
        border: Color(hex: 0xC3BDB2), text: Color(hex: 0x1C1915), textMuted: Color(hex: 0x4C463E),
        accent: Color(hex: 0xA82B14), onAccent: Color(hex: 0xFFF3EE), danger: Color(hex: 0x9E2A14),
        edge: Color(hex: 0xD9D5CC), highlight: .white.opacity(0.8), shadowOpacity: 0.12,
        warmOnly: true
    )

    /// Plum: after-hours plum with a red on-air Moon.
    static let plum = Theme(
        id: "signoff", name: "Plum", blurb: "After-hours plum",
        colorScheme: .dark,
        bg: Color(hex: 0x1F1029), surface: Color(hex: 0x2B1838), raised: Color(hex: 0x37204A),
        border: Color(hex: 0x4D3263), text: Color(hex: 0xF7EEE6), textMuted: Color(hex: 0xC3AFCB),
        accent: Color(hex: 0xFF5A47), onAccent: Color(hex: 0x2A0503), danger: Color(hex: 0xFFA090),
        edge: Color(hex: 0x140A1B), highlight: .white.opacity(0.08), shadowOpacity: 0.55,
        dayVariant: "signoffday"
    )

    static let plumDay = Theme(
        id: "signoffday", name: "Plum", blurb: "After-hours plum",
        colorScheme: .light,
        bg: Color(hex: 0xEDE4F2), surface: Color(hex: 0xE0D3E8), raised: Color(hex: 0xF8F3FA),
        border: Color(hex: 0xBFA9CD), text: Color(hex: 0x1F1029), textMuted: Color(hex: 0x5C4670),
        accent: Color(hex: 0xA81E14), onAccent: Color(hex: 0xFFF2EF), danger: Color(hex: 0x9E1E14),
        edge: Color(hex: 0xD3C3DD), highlight: .white.opacity(0.8), shadowOpacity: 0.12
    )

    /// Meadow: painted greens with a yellow lamp for the Moon.
    static let meadow = Theme(
        id: "picturebook", name: "Meadow", blurb: "Painted greens, a yellow lamp",
        colorScheme: .dark,
        bg: Color(hex: 0x10261B), surface: Color(hex: 0x1B3A2A), raised: Color(hex: 0x24493A),
        border: Color(hex: 0x2F5A47), text: Color(hex: 0xF4EBD8), textMuted: Color(hex: 0xB5C4A6),
        accent: Color(hex: 0xF2B640), onAccent: Color(hex: 0x2A1A02), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x0A1912), highlight: .white.opacity(0.06), shadowOpacity: 0.5,
        dayVariant: "picturebookday"
    )

    static let meadowDay = Theme(
        id: "picturebookday", name: "Meadow", blurb: "Painted greens, a yellow lamp",
        colorScheme: .light,
        bg: Color(hex: 0x2E6A40), surface: Color(hex: 0x347047), raised: Color(hex: 0x36744A),
        border: Color(hex: 0x5C9A6E), text: Color(hex: 0xFFFFFF), textMuted: Color(hex: 0xF0F7EA),
        accent: Color(hex: 0xF7C844), onAccent: Color(hex: 0x2A1A02), danger: Color(hex: 0xFFD0C8),
        edge: Color(hex: 0x245634), highlight: .white.opacity(0.12), shadowOpacity: 0.3
    )

    /// Dream: night indigo with a dream-violet Moon (UI/UX Pro Max's sleep palette, v0.18).
    static let dream = Theme(
        id: "dream", name: "Dream", blurb: "Night indigo, dream violet",
        colorScheme: .dark,
        bg: Color(hex: 0x0F172A), surface: Color(hex: 0x192134), raised: Color(hex: 0x232D45),
        border: Color(hex: 0x334166), text: Color(hex: 0xF8FAFC), textMuted: Color(hex: 0x94A3B8),
        accent: Color(hex: 0x818CF8), onAccent: Color(hex: 0x0F172A), danger: Color(hex: 0xFCA5A5),
        edge: Color(hex: 0x080D1A), highlight: .white.opacity(0.08), shadowOpacity: 0.55,
        dayVariant: "dreamday"
    )

    static let dreamDay = Theme(
        id: "dreamday", name: "Dream", blurb: "Night indigo, dream violet",
        colorScheme: .light,
        bg: Color(hex: 0xFAF5FF), surface: Color(hex: 0xF1E9FC), raised: Color(hex: 0xFFFFFF),
        border: Color(hex: 0xD8C9F2), text: Color(hex: 0x0F172A), textMuted: Color(hex: 0x475569),
        accent: Color(hex: 0x5B21B6), onAccent: Color(hex: 0xFFFFFF), danger: Color(hex: 0xB91C1C),
        edge: Color(hex: 0xE4D8F7), highlight: .white.opacity(0.8), shadowOpacity: 0.12
    )

    // MARK: Scenes and Color Scapes (v0.5 to v0.16), back as colours in v0.17 so they
    // can be worn with any style's type.

    /// Default: deep-blue night sky with slow waves and twinkling stars.
    static let midnight = Theme(
        id: "midnight", name: "Midnight", blurb: "Night sky, calm",
        colorScheme: .dark,
        bg: Color(hex: 0x0A1430), surface: Color(hex: 0x16244D), raised: Color(hex: 0x1E2F60),
        border: Color(hex: 0x2C3F78), text: Color(hex: 0xEEF2FF), textMuted: Color(hex: 0xA9B7DD),
        accent: Color(hex: 0xF4CF7B), onAccent: Color(hex: 0x1A1408), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x070E24), highlight: .white.opacity(0.10), shadowOpacity: 0.55,
        scene: .midnight
    )

    static let mountain = Theme(
        id: "mountain", name: "Mountain Vista", blurb: "Moonlit peaks, drifting mist",
        colorScheme: .dark,
        bg: Color(hex: 0x120F2E), surface: Color(hex: 0x231C4A), raised: Color(hex: 0x2D2560),
        border: Color(hex: 0x3D3478), text: Color(hex: 0xF1EDFF), textMuted: Color(hex: 0xBDB4E0),
        accent: Color(hex: 0xCDBDFF), onAccent: Color(hex: 0x1A1238), danger: Color(hex: 0xFF9A9A),
        edge: Color(hex: 0x0A0820), highlight: .white.opacity(0.10), shadowOpacity: 0.55,
        scene: .mountain
    )

    static let beach = Theme(
        id: "beach", name: "Beach", blurb: "Moonlit sea, soft waves",
        colorScheme: .dark,
        bg: Color(hex: 0x071A2B), surface: Color(hex: 0x10304A), raised: Color(hex: 0x163C5A),
        border: Color(hex: 0x22506F), text: Color(hex: 0xECF7FF), textMuted: Color(hex: 0xA9C7D8),
        accent: Color(hex: 0x8FE3D3), onAccent: Color(hex: 0x052126), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x04111D), highlight: .white.opacity(0.10), shadowOpacity: 0.55,
        scene: .beach
    )

    static let rainforest = Theme(
        id: "rainforest", name: "Rainforest", blurb: "Swaying canopy, fireflies",
        colorScheme: .dark,
        bg: Color(hex: 0x04140F), surface: Color(hex: 0x0C2A1F), raised: Color(hex: 0x12362A),
        border: Color(hex: 0x1E4A3A), text: Color(hex: 0xEAF7EE), textMuted: Color(hex: 0xA8CCB7),
        accent: Color(hex: 0xD6F07A), onAccent: Color(hex: 0x13200A), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x020C08), highlight: .white.opacity(0.08), shadowOpacity: 0.6,
        scene: .rainforest
    )

    static let ocean = Theme(
        id: "ocean", name: "Underwater", blurb: "Drifting fish, rising bubbles",
        colorScheme: .dark,
        bg: Color(hex: 0x031B2A), surface: Color(hex: 0x0A2E42), raised: Color(hex: 0x0F3A52),
        border: Color(hex: 0x1A5068), text: Color(hex: 0xE8FBFF), textMuted: Color(hex: 0xA6D0DC),
        // v0.17: a deep sea blue for the Sleep bar (owner request), was peach #FFB38A.
        accent: Color(hex: 0x2D6AA3), onAccent: Color(hex: 0xFFFFFF), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x01111C), highlight: .white.opacity(0.10), shadowOpacity: 0.6,
        scene: .ocean
    )


    static let city = Theme(
        id: "city", name: "City Scape", blurb: "Neon skyline, soft rain",
        colorScheme: .dark,
        bg: Color(hex: 0x0B0618), surface: Color(hex: 0x1A1030), raised: Color(hex: 0x24173F),
        border: Color(hex: 0x36255A), text: Color(hex: 0xF5EEFF), textMuted: Color(hex: 0xC2B4E0),
        accent: Color(hex: 0xFF6FB5), onAccent: Color(hex: 0x1A0410), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x060310), highlight: .white.opacity(0.10), shadowOpacity: 0.6,
        scene: .city
    )




    /// Flat colours, in the order the Themes sheet shows them (ids kept from v0.17's looks).
    static let colours: [Theme] = [.almanac, .ember, .plum, .meadow, .dream]
    /// Animated colours, all calm and night-time.
    static let scenes: [Theme] = [.midnight, .mountain, .beach, .rainforest, .ocean, .city]
    /// The 0.19 bedtime scenes, shown first in Themes; the rest sit in the "older themes" drawer.
    static let nights: [Theme] = [.blueHour, .blueHourPhoto, .fernlight, .emberLodge, .tidalInk, .afterHours]
    static let all: [Theme] = nights + scenes + colours
    private static let dayPages: [Theme] = [.almanacDay, .emberDay, .plumDay, .meadowDay, .dreamDay]

    static func with(id: String?) -> Theme {
        all.first { $0.id == id } ?? .almanac
    }

    /// Where a colour id from an earlier version lands now: the retired Color Scapes
    /// and Boro go to the nearest colour or Scene.
    static func migrated(from id: String?) -> Theme {
        if let colour = all.first(where: { $0.id == id }) { return colour }
        switch id {
        case "ember", "redlight": return .ember
        case "boro": return .midnight
        default: return .almanac
        }
    }

    /// This colour drawn in a given text style.
    func styled(_ look: ThemeStyle) -> Theme {
        var copy = self
        copy.style = look
        return copy
    }

    /// The page to draw in the phone's current appearance.
    func resolved(for scheme: ColorScheme) -> Theme {
        guard scheme == .light, let dayVariant, let day = Self.dayPages.first(where: { $0.id == dayVariant }) else { return self }
        return day
    }

    /// The flat colours follow the phone's light/dark setting; Scenes keep their one
    /// appearance, as before.
    var followsSystem: Bool { dayVariant != nil }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .almanac
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

/// A look's component language. Colors live in Theme; this is everything else.
/// The text style: fonts, keys and cards. Two to choose from (v0.17).
enum ThemeStyle: String, CaseIterable {
    /// Painted room: Young Serif, cut-paper corners, painted mats.
    case pictureBook = "picturebook"
    /// Late-night radio: wide heavy caps, QSL-card artwork.
    case signOff = "signoff"

    var name: String {
        switch self {
        case .pictureBook: "Picture Book"
        case .signOff: "Sign-Off"
        }
    }

    /// Titles set in capitals.
    var capsTitles: Bool { self == .signOff }
    /// Corner radius on show artwork.
    var artworkRadius: CGFloat { self == .signOff ? 0 : 8 }
    /// Corner radius on cards, rows and the mini player.
    var cardRadius: CGFloat { self == .signOff ? 24 : 20 }
}

/// Type ramp. Every style maps to a Dynamic Type text style so it scales.
/// The style's faces apply app-wide; AppModel sets `style` when it changes.
enum Typo {
    static var style: ThemeStyle = .pictureBook

    static var display: Font { display(style) }

    static func display(_ style: ThemeStyle) -> Font {
        switch style {
        case .signOff: .custom("ArchivoExpanded-ExtraBold", size: 30, relativeTo: .largeTitle)
        case .pictureBook: .custom("YoungSerif-Regular", size: 38, relativeTo: .largeTitle)
        }
    }
    static var playerTitle: Font {
        switch style {
        case .signOff: .custom("ArchivoExpanded-ExtraBold", size: 32, relativeTo: .title)
        case .pictureBook: .custom("YoungSerif-Regular", size: 34, relativeTo: .title)
        }
    }
    /// Moon key title and sheet titles.
    static var title: Font {
        switch style {
        case .signOff: .custom("ArchivoExpanded-ExtraBold", size: 18, relativeTo: .title3)
        case .pictureBook: .custom("YoungSerif-Regular", size: 21, relativeTo: .title3)
        }
    }
    /// Row and tile titles.
    static var headline: Font {
        switch style {
        case .signOff: .system(.headline)
        case .pictureBook: .custom("YoungSerif-Regular", size: 17, relativeTo: .headline)
        }
    }
    /// Show page title.
    static var showTitle: Font {
        switch style {
        case .signOff: .custom("ArchivoExpanded-ExtraBold", size: 20, relativeTo: .title2)
        case .pictureBook: .custom("YoungSerif-Regular", size: 25, relativeTo: .title2)
        }
    }
    /// Year headings on a show page.
    static var sectionTitle: Font {
        switch style {
        case .signOff: .custom("ArchivoExpanded-ExtraBold", size: 20, relativeTo: .title3)
        case .pictureBook: .custom("YoungSerif-Regular", size: 24, relativeTo: .title3)
        }
    }
    /// The Sleep bubble's ±5 keys: about 12% under `headline`.
    static var bubbleKey: Font {
        switch style {
        case .signOff: .system(.subheadline, weight: .semibold)
        case .pictureBook: .custom("YoungSerif-Regular", size: 15, relativeTo: .subheadline)
        }
    }
    /// Small text in the style's own face: the Sleep bubble's countdown and its pill.
    static var small: Font {
        switch style {
        case .signOff: .custom("ArchivoExpanded-ExtraBold", size: 10, relativeTo: .caption2)
        case .pictureBook: .custom("YoungSerif-Regular", size: 12, relativeTo: .caption2)
        }
    }
    /// Capitals for the style that sets titles in caps.
    static var titleCase: Text.Case? { style.capsTitles ? .uppercase : nil }
    static let body = Font.system(.body, design: .default)
    static let caption = Font.system(.footnote, weight: .medium)
    static let eyebrow = Font.system(.caption, weight: .bold)
    static let digits = Font.system(.subheadline, weight: .semibold).monospacedDigit()
}

enum Space {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 48
}
