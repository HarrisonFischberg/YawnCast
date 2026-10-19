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
    /// Use only warm tints for highlights and decorations (Safelight, Red Light), no cool or rainbow colors.
    var warmOnly = false
    /// The look this palette belongs to. Every screen draws with the chosen style
    /// (AppModel.look) over the chosen colour; see `styled(_:)`.
    var style: ThemeStyle = .almanac
    /// Night page whose day partner is drawn when the phone is in light mode.
    var dayVariant: String?

    // MARK: Looks (v0.17). Each is a whole visual world with a night and a day page.

    /// Almanac (default): the farmer's almanac. Ink-black page at night with goldenrod
    /// kept for the Moon alone; by day the goldenrod cover with a red Moon.
    static let almanac = Theme(
        id: "almanac", name: "Almanac", blurb: "Lunar tables, letterpress",
        colorScheme: .dark,
        bg: Color(hex: 0x100F0C), surface: Color(hex: 0x1C180F), raised: Color(hex: 0x241F14),
        border: Color(hex: 0x4A4231), text: Color(hex: 0xEFE6CF), textMuted: Color(hex: 0xA99F86),
        accent: Color(hex: 0xF2C230), onAccent: Color(hex: 0x17140D), danger: Color(hex: 0xFF8F7A),
        edge: Color(hex: 0x080706), highlight: .white.opacity(0.06), shadowOpacity: 0.5,
        style: .almanac, dayVariant: "almanacday"
    )

    static let almanacDay = Theme(
        id: "almanacday", name: "Almanac", blurb: "Lunar tables, letterpress",
        colorScheme: .light,
        bg: Color(hex: 0xF2C230), surface: Color(hex: 0xE6B520), raised: Color(hex: 0xF7D364),
        border: Color(hex: 0x17140D), text: Color(hex: 0x17140D), textMuted: Color(hex: 0x4D4223),
        accent: Color(hex: 0xA8261B), onAccent: Color(hex: 0xFBEFD8), danger: Color(hex: 0x8A1C12),
        edge: Color(hex: 0xC99A12), highlight: .white.opacity(0.3), shadowOpacity: 0.15,
        style: .almanac
    )

    /// Boro: indigo futon cloth mended with sashiko stitch; a persimmon patch for the Moon.
    static let boro = Theme(
        id: "boro", name: "Boro", blurb: "Indigo cloth, running stitch",
        colorScheme: .dark,
        bg: Color(hex: 0x14203A), surface: Color(hex: 0x1B2A4A), raised: Color(hex: 0x22355C),
        border: Color(hex: 0x3A4E78), text: Color(hex: 0xECE6D6), textMuted: Color(hex: 0xA7B2C9),
        accent: Color(hex: 0xE2783E), onAccent: Color(hex: 0x1D0E05), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x0B1428), highlight: .white.opacity(0.07), shadowOpacity: 0.55,
        style: .boro, dayVariant: "boroday"
    )

    static let boroDay = Theme(
        id: "boroday", name: "Boro", blurb: "Indigo cloth, running stitch",
        colorScheme: .light,
        bg: Color(hex: 0xDCE6EC), surface: Color(hex: 0xCDDAE3), raised: Color(hex: 0xEEF3F6),
        border: Color(hex: 0x8FA6BD), text: Color(hex: 0x14203A), textMuted: Color(hex: 0x46597A),
        accent: Color(hex: 0x9C3F12), onAccent: Color(hex: 0xFFF6EE), danger: Color(hex: 0xA33224),
        edge: Color(hex: 0xA9BCCB), highlight: .white.opacity(0.7), shadowOpacity: 0.15,
        style: .boro
    )

    /// Safelight: the darkroom under its red lamp. No blue light anywhere; the palette
    /// is one warm zone ramp, and the fade is drawn on it.
    static let safelight = Theme(
        id: "safelight", name: "Safelight", blurb: "Darkroom red, no blue light",
        colorScheme: .dark,
        bg: Color(hex: 0x0A0504), surface: Color(hex: 0x170B08), raised: Color(hex: 0x24110C),
        border: Color(hex: 0x4A271C), text: Color(hex: 0xE9AE93), textMuted: Color(hex: 0xC27A5E),
        accent: Color(hex: 0xFF7A2E), onAccent: Color(hex: 0x1A0602), danger: Color(hex: 0xFFB27A),
        edge: Color(hex: 0x050202), highlight: Color(hex: 0xE9AE93).opacity(0.08), shadowOpacity: 0.7,
        warmOnly: true, style: .safelight, dayVariant: "safelightday"
    )

    static let safelightDay = Theme(
        id: "safelightday", name: "Safelight", blurb: "Darkroom red, no blue light",
        colorScheme: .light,
        bg: Color(hex: 0xF3F1EC), surface: Color(hex: 0xE7E4DD), raised: Color(hex: 0xFFFFFF),
        border: Color(hex: 0xC3BDB2), text: Color(hex: 0x1C1915), textMuted: Color(hex: 0x4C463E),
        accent: Color(hex: 0xA82B14), onAccent: Color(hex: 0xFFF3EE), danger: Color(hex: 0x9E2A14),
        edge: Color(hex: 0xD9D5CC), highlight: .white.opacity(0.8), shadowOpacity: 0.12,
        warmOnly: true, style: .safelight
    )

    /// Sign-Off: late-night radio. After-hours plum, QSL-card shows, an on-air lamp for the
    /// Moon, and colour bars that go dark as the station signs off.
    static let signOff = Theme(
        id: "signoff", name: "Sign-Off", blurb: "Late-night radio, on air",
        colorScheme: .dark,
        bg: Color(hex: 0x1F1029), surface: Color(hex: 0x2B1838), raised: Color(hex: 0x37204A),
        border: Color(hex: 0x4D3263), text: Color(hex: 0xF7EEE6), textMuted: Color(hex: 0xC3AFCB),
        accent: Color(hex: 0xFF5A47), onAccent: Color(hex: 0x2A0503), danger: Color(hex: 0xFFA090),
        edge: Color(hex: 0x140A1B), highlight: .white.opacity(0.08), shadowOpacity: 0.55,
        style: .signOff, dayVariant: "signoffday"
    )

    static let signOffDay = Theme(
        id: "signoffday", name: "Sign-Off", blurb: "Late-night radio, on air",
        colorScheme: .light,
        bg: Color(hex: 0xEDE4F2), surface: Color(hex: 0xE0D3E8), raised: Color(hex: 0xF8F3FA),
        border: Color(hex: 0xBFA9CD), text: Color(hex: 0x1F1029), textMuted: Color(hex: 0x5C4670),
        accent: Color(hex: 0xA81E14), onAccent: Color(hex: 0xFFF2EF), danger: Color(hex: 0x9E1E14),
        edge: Color(hex: 0xD3C3DD), highlight: .white.opacity(0.8), shadowOpacity: 0.12,
        style: .signOff
    )

    /// Picture Book: the bedtime story's painted room. Flat gouache greens, a yellow lamp
    /// for the Moon, painted mats behind the shows.
    static let pictureBook = Theme(
        id: "picturebook", name: "Picture Book", blurb: "Painted room, the lamp goes down",
        colorScheme: .dark,
        bg: Color(hex: 0x10261B), surface: Color(hex: 0x1B3A2A), raised: Color(hex: 0x24493A),
        border: Color(hex: 0x2F5A47), text: Color(hex: 0xF4EBD8), textMuted: Color(hex: 0xB5C4A6),
        accent: Color(hex: 0xF2B640), onAccent: Color(hex: 0x2A1A02), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x0A1912), highlight: .white.opacity(0.06), shadowOpacity: 0.5,
        style: .pictureBook, dayVariant: "picturebookday"
    )

    static let pictureBookDay = Theme(
        id: "picturebookday", name: "Picture Book", blurb: "Painted room, the lamp goes down",
        colorScheme: .light,
        bg: Color(hex: 0x2E6A40), surface: Color(hex: 0x347047), raised: Color(hex: 0x36744A),
        border: Color(hex: 0x5C9A6E), text: Color(hex: 0xFFFFFF), textMuted: Color(hex: 0xF0F7EA),
        accent: Color(hex: 0xF7C844), onAccent: Color(hex: 0x2A1A02), danger: Color(hex: 0xFFD0C8),
        edge: Color(hex: 0x245634), highlight: .white.opacity(0.12), shadowOpacity: 0.3,
        style: .pictureBook
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
        accent: Color(hex: 0xFFB38A), onAccent: Color(hex: 0x2A0E00), danger: Color(hex: 0xFF9A8A),
        edge: Color(hex: 0x01111C), highlight: .white.opacity(0.10), shadowOpacity: 0.6,
        scene: .ocean
    )

    /// Warm, low-blue night palette: soft coral and terracotta on warm near-black.
    static let redLight = Theme(
        id: "redlight", name: "Red Light", blurb: "Warm, low blue",
        colorScheme: .dark,
        bg: Color(hex: 0x0B0504), surface: Color(hex: 0x1C0E0A), raised: Color(hex: 0x24130E),
        border: Color(hex: 0x3A1D15), text: Color(hex: 0xEFA084), textMuted: Color(hex: 0xCC8A72),
        accent: Color(hex: 0xD9805F), onAccent: Color(hex: 0x160704), danger: Color(hex: 0xFFB27A),
        edge: Color(hex: 0x050202), highlight: Color(hex: 0xEFA084).opacity(0.10), shadowOpacity: 0.7,
        warmOnly: true
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

    static let paper = Theme(
        id: "paper", name: "Paper", blurb: "Warm daylight",
        colorScheme: .light,
        bg: Color(hex: 0xF2EDE3), surface: Color(hex: 0xE7E0D2), raised: Color(hex: 0xFBF8F2),
        border: Color(hex: 0xD6CDBA), text: Color(hex: 0x1C1A16), textMuted: Color(hex: 0x5C564B),
        accent: Color(hex: 0x2E2A6B), onAccent: Color(hex: 0xF7F3EA), danger: Color(hex: 0xA33224),
        edge: Color(hex: 0xCFC5B1), highlight: .white.opacity(0.9), shadowOpacity: 0.12
    )

    static let ink = Theme(
        id: "ink", name: "Ink", blurb: "Quiet dark",
        colorScheme: .dark,
        bg: Color(hex: 0x111113), surface: Color(hex: 0x1C1C20), raised: Color(hex: 0x26262B),
        border: Color(hex: 0x2E2E34), text: Color(hex: 0xF1EEE7), textMuted: Color(hex: 0xA29E95),
        accent: Color(hex: 0xE9B44C), onAccent: Color(hex: 0x1A1408), danger: Color(hex: 0xF07A68),
        edge: Color(hex: 0x0A0A0B), highlight: .white.opacity(0.08), shadowOpacity: 0.5
    )

    static let ember = Theme(
        id: "ember", name: "Ember", blurb: "Bedtime, low light",
        colorScheme: .dark,
        bg: Color(hex: 0x070504), surface: Color(hex: 0x110C09), raised: Color(hex: 0x1A120D),
        border: Color(hex: 0x22170F), text: Color(hex: 0xB98F6C), textMuted: Color(hex: 0x9C7A5C),
        accent: Color(hex: 0xC27142), onAccent: Color(hex: 0x070504), danger: Color(hex: 0xC96E55),
        edge: Color(hex: 0x030201), highlight: Color(hex: 0xB98F6C).opacity(0.07), shadowOpacity: 0.6
    )

    /// The five looks' own palettes, in the order the Themes sheet shows them.
    static let looks: [Theme] = [.almanac, .boro, .safelight, .signOff, .pictureBook]
    /// Animated colours, all calm and night-time.
    static let scenes: [Theme] = [.midnight, .mountain, .beach, .rainforest, .ocean, .city]
    /// Flat colours.
    static let colorScapes: [Theme] = [.paper, .ember, .ink, .redLight]
    static let all: [Theme] = looks + scenes + colorScapes
    private static let dayPages: [Theme] = [.almanacDay, .boroDay, .safelightDay, .signOffDay, .pictureBookDay]

    static func with(id: String?) -> Theme {
        all.first { $0.id == id } ?? .almanac
    }

    /// This colour drawn in a given style.
    func styled(_ look: ThemeStyle) -> Theme {
        var copy = self
        copy.style = look
        return copy
    }

    /// A look's own palette.
    static func palette(of look: ThemeStyle) -> Theme {
        looks.first { $0.style == look } ?? .almanac
    }

    /// The page to draw in the phone's current appearance.
    func resolved(for scheme: ColorScheme) -> Theme {
        guard scheme == .light, let dayVariant, let day = Self.dayPages.first(where: { $0.id == dayVariant }) else { return self }
        return day
    }

    /// The looks' own palettes follow the phone's light/dark setting; Scenes and
    /// Color Scapes keep their one appearance, as before.
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
enum ThemeStyle: String, CaseIterable {
    /// Farmer's almanac: slab masthead, Old Standard titles, ruled lines, printed keys.
    case almanac
    /// Indigo cloth: raised keys with a sashiko stitch, Shippori Mincho titles.
    case boro
    /// Darkroom: condensed caps, square keys, the zone ramp.
    case safelight
    /// Late-night radio: wide heavy caps, QSL cards, a segmented page control.
    case signOff = "signoff"
    /// Painted room: Young Serif, cut-paper corners, painted mats.
    case pictureBook = "picturebook"

    var name: String { Theme.palette(of: self).name }
    var blurb: String { Theme.palette(of: self).blurb }

    /// Physical keys with a visible edge (the v0.1 key), rather than printed ones.
    var raisedKeys: Bool { self == .boro }
    /// Titles set in capitals.
    var capsTitles: Bool { self == .safelight || self == .signOff }
    /// Corner radius on show artwork.
    var artworkRadius: CGFloat {
        switch self {
        case .almanac: 3
        case .boro: 3
        case .safelight: 3
        case .signOff: 0
        case .pictureBook: 8
        }
    }
    /// Corner radius on cards, rows and the mini player.
    var cardRadius: CGFloat {
        switch self {
        case .almanac: 14
        case .boro: 12
        case .safelight: 8
        case .signOff: 24
        case .pictureBook: 20
        }
    }
}

/// Type ramp. Every style maps to a Dynamic Type text style so it scales.
/// The look's faces apply app-wide; AppModel sets `style` when the theme changes.
enum Typo {
    static var style: ThemeStyle = .almanac

    static var display: Font { display(style) }

    static func display(_ style: ThemeStyle) -> Font {
        switch style {
        case .almanac: .custom("AlfaSlabOne-Regular", size: 38, relativeTo: .largeTitle)
        case .boro: .custom("ShipporiMinchoB1-ExtraBold", size: 36, relativeTo: .largeTitle)
        case .safelight: .custom("BarlowCondensed-Bold", size: 46, relativeTo: .largeTitle)
        case .signOff: .custom("ArchivoExpanded-ExtraBold", size: 30, relativeTo: .largeTitle)
        case .pictureBook: .custom("YoungSerif-Regular", size: 38, relativeTo: .largeTitle)
        }
    }
    static var playerTitle: Font {
        switch style {
        case .almanac: .custom("OldStandardTT-Bold", size: 34, relativeTo: .title)
        case .boro: .custom("ShipporiMinchoB1-ExtraBold", size: 36, relativeTo: .title)
        case .safelight: .custom("BarlowCondensed-Bold", size: 48, relativeTo: .title)
        case .signOff: .custom("ArchivoExpanded-ExtraBold", size: 32, relativeTo: .title)
        case .pictureBook: .custom("YoungSerif-Regular", size: 34, relativeTo: .title)
        }
    }
    /// Moon key title and sheet titles.
    static var title: Font {
        switch style {
        case .almanac: .custom("AlfaSlabOne-Regular", size: 22, relativeTo: .title3)
        case .boro: .custom("ShipporiMinchoB1-ExtraBold", size: 22, relativeTo: .title3)
        case .safelight: .custom("BarlowCondensed-Bold", size: 27, relativeTo: .title3)
        case .signOff: .custom("ArchivoExpanded-ExtraBold", size: 18, relativeTo: .title3)
        case .pictureBook: .custom("YoungSerif-Regular", size: 21, relativeTo: .title3)
        }
    }
    /// Row and tile titles.
    static var headline: Font {
        switch style {
        case .almanac: .custom("OldStandardTT-Bold", size: 17, relativeTo: .headline)
        case .pictureBook: .custom("YoungSerif-Regular", size: 17, relativeTo: .headline)
        default: .system(.headline)
        }
    }
    /// Show page title.
    static var showTitle: Font {
        switch style {
        case .almanac: .custom("OldStandardTT-Bold", size: 26, relativeTo: .title2)
        case .boro: .custom("ShipporiMinchoB1-ExtraBold", size: 24, relativeTo: .title2)
        case .safelight: .custom("BarlowCondensed-Bold", size: 32, relativeTo: .title2)
        case .signOff: .custom("ArchivoExpanded-ExtraBold", size: 20, relativeTo: .title2)
        case .pictureBook: .custom("YoungSerif-Regular", size: 25, relativeTo: .title2)
        }
    }
    /// Year headings on a show page.
    static var sectionTitle: Font {
        switch style {
        case .almanac: .custom("AlfaSlabOne-Regular", size: 24, relativeTo: .title3)
        case .boro: .custom("ShipporiMinchoB1-ExtraBold", size: 22, relativeTo: .title3)
        case .safelight: .custom("BarlowCondensed-Bold", size: 26, relativeTo: .title3)
        case .signOff: .custom("ArchivoExpanded-ExtraBold", size: 20, relativeTo: .title3)
        case .pictureBook: .custom("YoungSerif-Regular", size: 24, relativeTo: .title3)
        }
    }
    /// Capitals for the looks that set titles in caps.
    static var titleCase: Text.Case? { style.capsTitles ? .uppercase : nil }
    static let body = Font.system(.body, design: .default)
    static let caption = Font.system(.footnote, weight: .medium)
    static var eyebrow: Font {
        style == .safelight ? .custom("BarlowCondensed-SemiBold", size: 14, relativeTo: .caption) : .system(.caption, weight: .bold)
    }
    static let digits = Font.system(.subheadline, weight: .semibold).monospacedDigit()
    /// Almanac's italic dateline and Moon subtitle.
    static let almanacItalic = Font.custom("OldStandardTT-Italic", size: 16, relativeTo: .subheadline)
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
