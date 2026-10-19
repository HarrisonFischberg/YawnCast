import NightCastCore
import SwiftUI

// Shared pieces whose drawing changes with the look: the labelled page tabs, the
// Moon key every style shares, and its progress bar and icon.

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

/// New · Library · Explore as named tabs, in place of the v0.2 dots. Every style
/// uses Picture Book's: plain labels, the current page on a cut-paper tab.
struct LookTabs: View {
    @Binding var selection: HomePage
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Space.xs) {
            ForEach(HomePage.allCases, id: \.self) { page in
                let on = page == selection
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { selection = page }
                } label: {
                    Text(page.title)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(on ? theme.text : theme.textMuted)
                        .padding(.horizontal, Space.l)
                        .padding(.vertical, 7)
                        .background(on ? PaperShape(seed: 1).fill(theme.raised) : nil)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .modifier(TabAccessibility(page: page, selected: on))
            }
        }
        .frame(maxWidth: .infinity)
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

/// The Moon key, the same in every style but for its face: a ruled card (Almanac),
/// a stitched patch (Boro), a square plate (Safelight), an on-air lamp (Sign-Off),
/// cut paper (Picture Book).
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

    /// The bar is slightly see-through, so a Scene shows behind it.
    private static let faceOpacity = 0.88

    @ViewBuilder
    private var face: some View {
        let fill = (isOn ? theme.accent : theme.surface).opacity(Self.faceOpacity)
        switch theme.style {
        case .almanac:
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(fill)
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(isOn ? theme.accent : theme.border, lineWidth: 1.5))
        case .boro:
            // A patch sewn on: raised face, a stitched border just inside the edge.
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .overlay(RoundedRectangle(cornerRadius: radius - 5, style: .continuous).inset(by: 6).stroke(ink.opacity(0.35), style: .stitch(2)))
                .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill((isOn ? theme.accent.mix(with: .black, by: 0.4) : theme.edge).opacity(Self.faceOpacity)).offset(y: 6))
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
            Image(systemName: SleepGlyph.symbol(theme: theme, fading: isFading))
                .font(.system(size: 26, weight: .semibold))
                // In ink while off; the accent face carries the icon once Sleep is on.
                .foregroundStyle(isOn ? theme.onAccent : theme.text)
                // The icon dims with the volume, step by step.
                .opacity(max(0.35, status.moonLit))
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

/// The ten fade steps as a progress bar (Picture Book's, on every style):
/// each mark goes dark as its step passes.
struct FadeSteps: View {
    let status: SleepStatus
    let ink: Color

    /// How many of the ten steps are still to come (lit).
    private var remaining: Int {
        switch status {
        case .off, .waiting: 10
        case .fading(let level): Int((level * 10).rounded())
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<10, id: \.self) { i in
                Capsule()
                    .fill(ink.opacity(status == .off ? 0.25 : (i < 10 - remaining ? 0.2 : 0.9)))
                    .frame(height: 6)
            }
        }
    }
}

/// The Sleep icon: the Scene's own (a wave underwater, a tree in the rainforest),
/// else the style's (a lamp in Picture Book, the moon elsewhere).
enum SleepGlyph {
    static func symbol(theme: Theme, fading: Bool) -> String {
        switch theme.scene {
        case .ocean: return "water.waves"
        case .rainforest: return "tree.fill"
        case .mountain: return "mountain.2.fill"
        case .beach: return "beach.umbrella.fill"
        case .city: return "building.2.fill"
        case .midnight: return "moon.stars.fill"
        case nil: break
        }
        if theme.style == .pictureBook { return "lamp.table.fill" }
        return fading ? "moon.zzz.fill" : "moon.fill"
    }
}
