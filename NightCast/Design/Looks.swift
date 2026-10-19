import NightCastCore
import SwiftUI

// Shared pieces whose drawing changes with the look: the labelled page tabs, the
// Moon key for Boro, Safelight, Sign-Off and Picture Book (Almanac has its own in
// Almanac.swift), and each look's way of showing the ten fade steps.

/// Running stitch: a dashed line in thread colour (Boro).
nonisolated struct Stitch: Shape {
    var vertical = false
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if vertical {
            p.move(to: CGPoint(x: rect.midX, y: rect.minY)); p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        } else {
            p.move(to: CGPoint(x: rect.minX, y: rect.midY)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
        return p
    }
}

extension StrokeStyle {
    /// Sashiko proportions: long stitches, short gaps.
    static func stitch(_ width: CGFloat = 2) -> StrokeStyle { StrokeStyle(lineWidth: width, lineCap: .round, dash: [8, 6]) }
}

/// Fade step 0...9 the fade is on, or nil before it starts.
extension SleepStatus {
    var fadeStep: Int? {
        guard case .fading(let level) = self else { return nil }
        return min(9, max(0, Int((10 * (1 - level)).rounded())))
    }
}

// MARK: - Page tabs

/// New · Library · Explore as named tabs, in place of the v0.2 dots.
struct LookTabs: View {
    @Binding var selection: HomePage
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        switch theme.style {
        case .almanac:
            AlmanacTabs(selection: $selection)
        case .signOff:
            segmented
        default:
            row
        }
    }

    private func select(_ page: HomePage) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { selection = page }
    }

    /// Boro, Safelight, Picture Book: a row of labels; the current one is marked.
    private var row: some View {
        HStack(spacing: theme.style == .pictureBook ? Space.xs : Space.xxl) {
            ForEach(HomePage.allCases, id: \.self) { page in
                Button { select(page) } label: {
                    label(page)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .modifier(TabAccessibility(page: page, selected: page == selection))
            }
        }
        .frame(maxWidth: .infinity, alignment: theme.style == .safelight ? .leading : .center)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pages")
    }

    @ViewBuilder
    private func label(_ page: HomePage) -> some View {
        let on = page == selection
        switch theme.style {
        case .safelight:
            Text(page.title)
                .font(.custom("BarlowCondensed-SemiBold", size: 17, relativeTo: .subheadline))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(on ? theme.text : theme.textMuted)
                .padding(.bottom, 6)
                .overlay(alignment: .bottom) { Rectangle().fill(on ? theme.text : .clear).frame(height: 2) }
        case .pictureBook:
            Text(page.title)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(on ? theme.text : theme.textMuted)
                .padding(.horizontal, Space.l)
                .padding(.vertical, 7)
                .background(on ? PaperShape(seed: 1).fill(theme.raised) : nil)
        default: // Boro
            Text(page.title)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(on ? theme.text : theme.textMuted)
                .padding(.bottom, 7)
                .overlay(alignment: .bottom) {
                    if on { Stitch().stroke(theme.text, style: .stitch(2)).frame(height: 2) }
                }
        }
    }

    /// Sign-Off: a segmented control.
    private var segmented: some View {
        HStack(spacing: 0) {
            ForEach(HomePage.allCases, id: \.self) { page in
                let on = page == selection
                Button { select(page) } label: {
                    Text(page.title)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(on ? theme.text : theme.textMuted)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Capsule().fill(on ? theme.raised : .clear).shadow(color: .black.opacity(on ? 0.25 : 0), radius: 2, y: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .modifier(TabAccessibility(page: page, selected: on))
            }
        }
        .padding(3)
        .background(Capsule().fill(theme.surface))
        .frame(minHeight: 44)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pages")
    }
}

private struct TabAccessibility: ViewModifier {
    let page: HomePage
    let selected: Bool
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(page.title)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier("pageDot-\(page.title)")
    }
}

/// Picture Book's cut-paper rectangle: four slightly different corner radii, so
/// keys and mats look trimmed by hand. `seed` picks one of a few cuts.
nonisolated struct PaperShape: InsettableShape {
    var seed = 0
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let cuts: [RectangleCornerRadii] = [
            .init(topLeading: 16, bottomLeading: 13, bottomTrailing: 18, topTrailing: 12),
            .init(topLeading: 14, bottomLeading: 17, bottomTrailing: 12, topTrailing: 16),
            .init(topLeading: 18, bottomLeading: 12, bottomTrailing: 15, topTrailing: 14),
        ]
        let r = cuts[abs(seed) % cuts.count]
        let scale = min(1, min(rect.width, rect.height) / 44)
        let radii = RectangleCornerRadii(topLeading: r.topLeading * scale, bottomLeading: r.bottomLeading * scale,
                                         bottomTrailing: r.bottomTrailing * scale, topTrailing: r.topTrailing * scale)
        return UnevenRoundedRectangle(cornerRadii: radii, style: .continuous).path(in: rect.insetBy(dx: inset, dy: inset))
    }

    func inset(by amount: CGFloat) -> PaperShape { PaperShape(seed: seed, inset: inset + amount) }
}

// MARK: - Moon key

/// The Moon key for Boro, Safelight, Sign-Off and Picture Book. Same behaviour and
/// copy as every look; each draws the ten fade steps its own way.
struct LookMoonKey: View {
    let status: SleepStatus
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    private var isOn: Bool { status != .off }
    private var ink: Color { isOn ? theme.onAccent : theme.text }
    private var radius: CGFloat { theme.style == .safelight ? 12 : 24 }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.m) {
                HStack(spacing: Space.l) {
                    well
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: Space.s) {
                            Text(title).font(Typo.title).textCase(Typo.titleCase)
                            if case .waiting = status { AccentHeart().accessibilityHidden(true) }
                        }
                        if let subtitle {
                            Text(subtitle)
                                .font(.system(.subheadline, weight: .semibold))
                                .opacity(0.85)
                                .contentTransition(.numericText())
                        }
                    }
                    .lineLimit(typeSize.isAccessibilitySize ? 3 : 1)
                    .minimumScaleFactor(0.75)
                    Spacer(minLength: 0)
                }
                if !typeSize.isAccessibilitySize {
                    FadeSteps(status: status, ink: ink)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(ink)
            .padding(.horizontal, Space.xl)
            .padding(.vertical, Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { face }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressDim())
        .accessibilityLabel("Sleep")
        .accessibilityValue(MoonKey.accessibilityValue(for: status))
        .accessibilityHint(isOn ? "Turns Sleep off and restores volume." : "Fades the episode out, then pauses.")
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier("moonKey")
    }

    @ViewBuilder
    private var face: some View {
        let fill = isOn ? theme.accent : theme.surface
        switch theme.style {
        case .boro:
            // A patch sewn on: raised face, a stitched border just inside the edge.
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .overlay(RoundedRectangle(cornerRadius: radius - 5, style: .continuous).inset(by: 6).stroke(ink.opacity(0.35), style: .stitch(2)))
                .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(isOn ? theme.accent.mix(with: .black, by: 0.4) : theme.edge).offset(y: 6))
                .padding(.bottom, 6)
        case .pictureBook:
            PaperShape(seed: 2).fill(fill)
        case .signOff:
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .shadow(color: isOn ? theme.accent.opacity(0.35) : .clear, radius: 18)
        default: // Safelight
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(isOn ? theme.accent : theme.border, lineWidth: 1))
        }
    }

    private var well: some View {
        ZStack {
            wellShape.fill(isOn ? Color.black.opacity(0.16) : theme.raised)
            Image(systemName: theme.style == .pictureBook ? "lamp.table.fill" : (isFading ? "moon.zzz.fill" : "moon.fill"))
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(isOn ? theme.onAccent : theme.accent)
                .opacity(theme.style == .pictureBook ? max(0.35, status.moonLit) : 1)
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: 56, height: 56)
        .accessibilityHidden(true)
    }

    private var wellShape: AnyShape {
        switch theme.style {
        case .boro: AnyShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        case .safelight: AnyShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        case .pictureBook: AnyShape(PaperShape(seed: 0))
        default: AnyShape(Circle())
        }
    }

    private var isFading: Bool {
        if case .fading = status { return true }
        return false
    }

    private var title: String {
        switch status {
        case .off: "Ready for bed?"
        case .waiting: "Sweet dreams"
        case .fading: theme.style == .pictureBook ? "Lights going down" : "Drifting off"
        }
    }

    private var subtitle: String? {
        switch status {
        case .off: nil
        case .waiting(let t): "Fade in \(TimeFormat.sleepDelayLong(t))."
        case .fading(let level): "Volume \(Int((level * 100).rounded()))%"
        }
    }
}

/// The ten fade steps, drawn in the look's own way.
struct FadeSteps: View {
    let status: SleepStatus
    let ink: Color
    @Environment(\.theme) private var theme

    /// How many of the ten steps are still to come (lit).
    private var remaining: Int {
        switch status {
        case .off, .waiting: 10
        case .fading(let level): Int((level * 10).rounded())
        }
    }

    var body: some View {
        switch theme.style {
        case .safelight: zoneRamp
        case .signOff: colourBars
        default: dashes
        }
    }

    /// Boro: ten stitches; Picture Book: ten page marks. Unlit once that step has passed.
    private var dashes: some View {
        HStack(spacing: theme.style == .boro ? 7 : 6) {
            ForEach(0..<10, id: \.self) { i in
                Capsule()
                    .fill(ink.opacity(status == .off ? 0.25 : (i < 10 - remaining ? 0.2 : 0.9)))
                    .frame(height: theme.style == .boro ? 4 : 6)
            }
        }
    }

    /// Safelight: the eleven-zone ramp, 100% to 0%, current zone outlined.
    private var zoneRamp: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(0...10, id: \.self) { i in
                    Rectangle()
                        .fill(zone(i))
                        .overlay(Rectangle().strokeBorder(ink, lineWidth: i == currentZone ? 2.5 : 0))
                }
            }
            .frame(height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            HStack(spacing: 0) {
                ForEach(0...10, id: \.self) { i in
                    Text("\(100 - i * 10)")
                        .font(.custom("BarlowCondensed-SemiBold", size: 11, relativeTo: .caption2))
                        .monospacedDigit()
                        .opacity(i == currentZone ? 1 : 0.65)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var currentZone: Int {
        switch status {
        case .off: -1
        case .waiting: 0
        case .fading(let level): 10 - Int((level * 10).rounded())
        }
    }

    /// Zone i, from the colour's text (0, full volume) down to its ground (10, silence).
    private func zone(_ i: Int) -> Color {
        theme.text.mix(with: theme.bg, by: Double(i) / 10)
    }

    /// Sign-Off: ten broadcast bars that go dark one by one.
    private var colourBars: some View {
        HStack(spacing: 3) {
            ForEach(0..<10, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < remaining && status != .off ? Self.bars[i] : ink.opacity(0.18))
            }
        }
        .frame(height: 16)
    }

    private static let bars: [Color] = [
        Color(hex: 0xF1F1F1), Color(hex: 0xE9D44A), Color(hex: 0x53C8D8), Color(hex: 0x5DC461), Color(hex: 0xC858C4),
        Color(hex: 0xDB4A3C), Color(hex: 0x3D53CC), Color(hex: 0x9C9C9C), Color(hex: 0x5B5B5B), Color(hex: 0x2A2A2A),
    ]
}
