#if DEBUG
import SwiftUI
import YawnCastCore

// Three restyles of Now Playing, Library and the dock (see DesignSeed.swift).
// A "Moon Dial": centred instrument, line work straight on the Scene.
// B "Turn-Down": an opaque blanket panel anchored to the bottom, navigation in the thumb zone.
// C "Lights Out": cut-paper cards and a string of ten lanterns.

// MARK: - Shared

private func serif(_ size: CGFloat, _ style: Font.TextStyle) -> Font {
    .custom("YoungSerif-Regular", size: size, relativeTo: style)
}

private extension SleepStatus {
    var isOn: Bool { self != .off }
    var isFading: Bool { if case .fading = self { return true }; return false }
    /// Fade steps still to come, of ten.
    var lit: Int {
        switch self {
        case .off, .waiting: 10
        case .fading(let level): Int((level * 10).rounded())
        }
    }
    var title: String {
        switch self {
        case .off: "Ready for bed?"
        case .waiting: "Sweet dreams"
        case .fading: "Lights going down"
        }
    }
    var detail: String {
        switch self {
        case .off: "Tap the moon to fade out"
        case .waiting(let t): "Fades in \(TimeFormat.sleepDelayLong(t))"
        case .fading(let level): "Volume \(Int((level * 100).rounded()))%"
        }
    }
}

private extension View {
    func moonAccessibility(_ status: SleepStatus) -> some View {
        accessibilityLabel("Sleep")
            .accessibilityValue(MoonKey.accessibilityValue(for: status))
            .accessibilityHint(status.isOn ? "Turns Sleep off and restores volume." : "Fades the episode out, then pauses.")
            .accessibilityAddTraits(status.isOn ? .isSelected : [])
            .accessibilityIdentifier("moonKey")
    }
}

/// −5 / +5 on any ground: the caller picks the face.
private struct DStep<Face: View>: View {
    let minutes: Int
    let ink: Color
    @ViewBuilder let face: Face
    @Environment(AppModel.self) private var model

    var body: some View {
        Button { model.adjustSleep(minutes: minutes) } label: {
            Text(minutes > 0 ? "+5" : "−5")
                .font(.system(.subheadline, weight: .semibold).monospacedDigit())
                .foregroundStyle(ink)
                .frame(width: 44, height: 44)
                .background { face }
        }
        .buttonStyle(PressDim())
        .accessibilityLabel(minutes > 0 ? "Add 5 minutes" : "Remove 5 minutes")
    }
}

/// A position line with a round marker; drag anywhere, VoiceOver steps 15 s.
private struct DScrubber: View {
    var track: CGFloat
    var thumb: CGFloat
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @State private var dragFraction: Double?

    var body: some View {
        let player = model.player
        let duration = player.duration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        let fraction = dragFraction ?? duration.map { min(1, max(0, player.position / $0)) } ?? 0
        let shown = dragFraction.flatMap { f in duration.map { f * $0 } } ?? player.position
        VStack(spacing: Space.xs) {
            GeometryReader { geo in
                let x = thumb / 2 + (geo.size.width - thumb) * fraction
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.text.opacity(0.22)).frame(height: track)
                    Capsule().fill(theme.text).frame(width: x, height: track)
                    Circle().fill(theme.text).frame(width: thumb, height: thumb).offset(x: x - thumb / 2)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard duration != nil else { return }
                        dragFraction = min(1, max(0, (value.location.x - thumb / 2) / max(1, geo.size.width - thumb)))
                    }
                    .onEnded { _ in
                        if let f = dragFraction, let d = duration { player.seek(to: f * d) }
                        dragFraction = nil
                    })
            }
            .frame(height: 44)
            HStack {
                Text(TimeFormat.clock(shown))
                Spacer()
                Text(duration.map { TimeFormat.remaining(max(0, $0 - shown)) } ?? "--:--")
            }
            .font(Typo.digits)
            .foregroundStyle(theme.textMuted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Playback position")
        .accessibilityValue(TimeFormat.spoken(player.position))
        .accessibilityAdjustableAction { direction in
            player.seek(to: SeekMath.skip(from: player.position, by: direction == .increment ? 15 : -15, duration: duration))
        }
    }
}

/// Skip −15, play/pause, skip +15 with caller-drawn faces.
private struct DTransport<SkipFace: View, PlayFace: View>: View {
    var spacing: CGFloat
    var skipSize: CGSize
    var playSize: CGSize
    @ViewBuilder let skipFace: SkipFace
    @ViewBuilder let playFace: PlayFace
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        let player = model.player
        HStack(spacing: spacing) {
            skip("gobackward.15", "Back 15 seconds", -15)
            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(theme.bg)
                    .frame(width: playSize.width, height: playSize.height)
                    .background { playFace }
            }
            .buttonStyle(PressDim())
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            .accessibilityIdentifier("playPause")
            skip("goforward.15", "Forward 15 seconds", 15)
        }
        .frame(maxWidth: .infinity)
    }

    private func skip(_ symbol: String, _ label: String, _ delta: TimeInterval) -> some View {
        Button { model.player.skip(by: delta) } label: {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(theme.text)
                .frame(width: skipSize.width, height: skipSize.height)
                .background { skipFace }
        }
        .buttonStyle(PressDim())
        .accessibilityLabel(label)
    }
}

private struct DIcon<Face: View>: View {
    let systemName: String
    let label: String
    let action: () -> Void
    @ViewBuilder let face: Face
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.text)
                .frame(width: 44, height: 44)
                .background { face }
                .contentShape(Rectangle())
        }
        .buttonStyle(PressDim())
        .accessibilityLabel(label)
    }
}

/// The ten fade steps as a row of marks.
private struct DSteps: View {
    let status: SleepStatus
    let ink: Color
    var height: CGFloat = 3
    var spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<10, id: \.self) { i in
                Capsule().fill(ink.opacity(i < 10 - status.lit ? 0.25 : 0.9)).frame(height: height)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Switches

struct DesignNowPlaying: View {
    let option: DesignOption
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            switch option {
            case .A: NowPlayingA(close: { dismiss() })
            case .B: NowPlayingB(close: { dismiss() })
            default: NowPlayingC(close: { dismiss() })
            }
        }
        .accessibilityAction(.escape) { dismiss() }
        .presentationBackground(.clear)
    }
}

struct DesignHome: View {
    let option: DesignOption
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            switch option {
            case .A: TabsA(selection: $model.homePage)
            case .C: TabsC(selection: $model.homePage)
            default: EmptyView()
            }
            TabView(selection: $model.homePage) {
                NewEpisodesView().tag(HomePage.new)
                DesignLibrary(option: option).tag(HomePage.library)
                ExploreView().tag(HomePage.explore)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background { ScreenBackground() }
        .overlay(alignment: .bottom) {
            switch option {
            case .A: DockA().padding(.horizontal, Space.xl).padding(.bottom, Space.s)
            case .B: DockB(selection: $model.homePage)
            default: DockC().padding(.horizontal, Space.xl).padding(.bottom, Space.s)
            }
        }
        .sheet(isPresented: $model.isThemesPresented) {
            ThemesSheet()
                .presentationDetents([.fraction(0.8), .large])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
        }
    }
}

/// The Library page in each direction: same shows, same actions.
private struct DesignLibrary: View {
    let option: DesignOption
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        SearchablePage(page: .library) {
            ScrollView {
                VStack(alignment: .leading, spacing: option == .B ? Space.xl : Space.l) {
                    switch option {
                    case .A: toolsA
                    case .B: headerB
                    default: toolsC
                    }
                    LazyVGrid(columns: columns, alignment: .leading, spacing: option == .A ? Space.xl : (option == .B ? Space.xxl : Space.m)) {
                        ForEach(Array(model.library.subscriptions.enumerated()), id: \.element.id) { index, show in
                            NavigationLink(value: Route.show(show)) { tile(show, index) }
                                .buttonStyle(TileStyle())
                                .contextMenu {
                                    Button { model.moveToTop(show) } label: { Label("Move to Top", systemImage: "arrow.up.to.line") }
                                    Button { model.moveToEnd(show) } label: { Label("Move to End", systemImage: "arrow.down.to.line") }
                                    Button(role: .destructive) { model.unsubscribe(show) } label: { Label("Unsubscribe", systemImage: "minus.circle") }
                                }
                                .accessibilityLabel(show.author.map { "\(show.title), \($0)" } ?? show.title)
                                .accessibilityValue(model.hasNewEpisode(show) ? "New episode" : "")
                        }
                    }
                }
                .padding(.horizontal, Space.xl)
                .padding(.top, Space.s)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, option == .B ? 190 : 88, for: .scrollContent)
        }
    }

    private var columns: [GridItem] {
        let count = option == .A ? 3 : 2
        let gap = option == .A ? Space.m : (option == .B ? Space.l : Space.m)
        return Array(repeating: GridItem(.flexible(), spacing: gap, alignment: .top), count: count)
    }

    @ViewBuilder
    private func tile(_ show: Show, _ index: Int) -> some View {
        let isNew = model.hasNewEpisode(show)
        switch option {
        case .A:
            VStack(alignment: .leading, spacing: 6) {
                ArtworkView(url: show.artworkURL, cornerRadius: 10, title: show.title)
                    .overlay(alignment: .topTrailing) { if isNew { NewPip(size: 14) } }
                Text(show.title)
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(theme.text)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
            }
        case .B:
            VStack(alignment: .leading, spacing: Space.s) {
                ArtworkView(url: show.artworkURL, cornerRadius: 16, title: show.title)
                    .overlay(alignment: .topTrailing) { if isNew { NewPip(size: 18) } }
                VStack(alignment: .leading, spacing: 2) {
                    Text(show.title)
                        .font(serif(17, .headline))
                        .foregroundStyle(theme.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(show.author ?? "").font(Typo.caption).foregroundStyle(theme.textMuted).lineLimit(1)
                }
            }
        default:
            VStack(alignment: .leading, spacing: Space.s) {
                ArtworkView(url: show.artworkURL, cornerRadius: 8, title: show.title)
                // Room for a two-line title in every card, with the author tucked under the title.
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(" ").font(serif(16, .headline)).lineLimit(2, reservesSpace: true)
                        Text(" ").font(Typo.caption)
                    }
                    .hidden()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(show.title)
                            .font(serif(16, .headline))
                            .foregroundStyle(theme.text)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(show.author ?? "").font(Typo.caption).foregroundStyle(theme.textMuted).lineLimit(1)
                    }
                }
                .padding(.horizontal, Space.xs)
                .padding(.bottom, Space.xs)
            }
            .padding(Space.s)
            .background(PaperShape(seed: index).fill(theme.surface))
            .overlay(alignment: .topTrailing) { if isNew { NewPip(size: 18).offset(x: -4, y: 4) } }
        }
    }

    private var layoutLabel: String { "Layout: \(model.libraryLayout.title). Switch to \(model.libraryLayout.next.title)" }
    private func nextLayout() { model.libraryLayout = model.libraryLayout.next }

    private func search<S: InsettableShape>(_ shape: S, fill: Color, stroke: Color = .clear) -> some View {
        Button { model.openSearch() } label: {
            HStack(spacing: Space.s) {
                Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .semibold))
                Text("Search your shows").lineLimit(1)
                Spacer(minLength: 0)
            }
            .font(.system(.body))
            .foregroundStyle(theme.textMuted)
            .padding(.horizontal, Space.l)
            .frame(minHeight: 44)
            .background(shape.fill(fill).overlay(shape.strokeBorder(stroke, lineWidth: 1)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("librarySearch")
    }

    // A: one quiet row; hairline field, bare icons.
    private var toolsA: some View {
        HStack(spacing: Space.xs) {
            search(Capsule(), fill: theme.bg.opacity(0.45), stroke: theme.text.opacity(0.25))
            DIcon(systemName: model.libraryLayout.symbol, label: layoutLabel, action: nextLayout) { EmptyView() }
            DIcon(systemName: "circle.lefthalf.filled", label: "Themes", action: { model.isThemesPresented = true }) { EmptyView() }
        }
    }

    // B: a big title that owns the top of the page.
    private var headerB: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Library").font(serif(40, .largeTitle)).foregroundStyle(theme.text).accessibilityAddTraits(.isHeader)
                    Text("\(model.library.subscriptions.count) shows").font(Typo.caption).foregroundStyle(theme.textMuted)
                }
                Spacer()
                HStack(spacing: Space.s) {
                    DIcon(systemName: model.libraryLayout.symbol, label: layoutLabel, action: nextLayout) { Circle().fill(theme.surface) }
                    DIcon(systemName: "circle.lefthalf.filled", label: "Themes", action: { model.isThemesPresented = true }) { Circle().fill(theme.surface) }
                }
            }
            search(RoundedRectangle(cornerRadius: 16, style: .continuous), fill: theme.surface)
        }
    }

    // C: a paper strip.
    private var toolsC: some View {
        HStack(spacing: Space.s) {
            search(PaperShape(seed: 1), fill: theme.surface)
            DIcon(systemName: model.libraryLayout.symbol, label: layoutLabel, action: nextLayout) { PaperShape(seed: 0).fill(theme.surface) }
            DIcon(systemName: "circle.lefthalf.filled", label: "Themes", action: { model.isThemesPresented = true }) { PaperShape(seed: 2).fill(theme.surface) }
        }
    }
}

// MARK: - A · Moon Dial

private struct TabsA: View {
    @Binding var selection: HomePage
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.xl) {
            ForEach(HomePage.allCases, id: \.self) { page in
                let on = page == selection
                Button { withAnimation(.easeOut(duration: 0.2)) { selection = page } } label: {
                    Text(page.title)
                        .font(on ? serif(34, .largeTitle) : serif(20, .title3))
                        .foregroundStyle(on ? theme.text : theme.textMuted)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? [.isSelected, .isHeader] : [])
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Space.xl)
        .padding(.top, Space.xs)
    }
}

/// The moon as lit by the volume: full until the fade starts, then waning.
private struct MoonPhase: View {
    let status: SleepStatus
    @Environment(\.theme) private var theme

    var body: some View {
        GeometryReader { geo in
            let d = geo.size.width
            ZStack {
                Circle().fill(theme.text.opacity(0.14))
                if status.isOn {
                    Circle().fill(theme.text)
                        .mask {
                            ZStack {
                                Circle()
                                Circle().offset(x: -d * (0.25 + 0.75 * status.moonLit)).blendMode(.destinationOut)
                            }
                            .compositingGroup()
                        }
                } else {
                    Circle().strokeBorder(theme.text.opacity(0.7), lineWidth: max(1.5, d / 40))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

private struct DialRing: View {
    let status: SleepStatus
    var lineWidth: CGFloat
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                Circle()
                    .trim(from: Double(i) / 10 + 0.012, to: Double(i + 1) / 10 - 0.012)
                    .stroke(color(i), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
        .rotationEffect(.degrees(-90))
        .padding(lineWidth / 2)
        .accessibilityHidden(true)
    }

    private func color(_ i: Int) -> Color {
        guard status.isOn else { return theme.text.opacity(0.22) }
        return i < 10 - status.lit ? theme.text.opacity(0.22) : theme.accent
    }
}

private struct NowPlayingA: View {
    let close: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        let episode = model.player.episode
        let status = model.sleepStatus
        ZStack {
            ScreenBackground()
            LinearGradient(colors: [theme.bg.opacity(0), theme.bg.opacity(0.8)], startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    DIcon(systemName: "chevron.down", label: "Close player", action: close) { EmptyView() }
                        .accessibilityIdentifier("closePlayer")
                    Spacer()
                }
                VStack(spacing: Space.s) {
                    Text(episode?.showTitle ?? "")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(theme.textMuted)
                        .lineLimit(1)
                    Text(episode?.title ?? "Nothing playing")
                        .font(serif(26, .title2))
                        .foregroundStyle(theme.text)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.horizontal, Space.l)

                Spacer(minLength: Space.l)
                dial(status)
                Spacer(minLength: Space.l)

                DScrubber(track: 4, thumb: 16)
                DTransport(spacing: Space.xxxl, skipSize: CGSize(width: 56, height: 56), playSize: CGSize(width: 72, height: 72)) {
                    EmptyView()
                } playFace: {
                    Circle().fill(theme.text)
                }
                .padding(.top, Space.m)
            }
            .padding(.horizontal, Space.xxl)
            .padding(.bottom, Space.l)
        }
    }

    private func dial(_ status: SleepStatus) -> some View {
        Button { model.toggleSleep() } label: {
            ZStack {
                Circle().fill(theme.bg.opacity(0.6)).padding(16)
                DialRing(status: status, lineWidth: 6)
                VStack(spacing: Space.s) {
                    MoonPhase(status: status).frame(width: 96, height: 96)
                    VStack(spacing: 0) {
                        Text(readout(status))
                            .font(serif(32, .title).monospacedDigit())
                            .foregroundStyle(theme.text)
                            .contentTransition(.numericText())
                        Text(status.isOn ? caption(status) : status.detail)
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(theme.textMuted)
                    }
                }
            }
            .frame(width: 296, height: 296)
            .contentShape(Circle())
        }
        .buttonStyle(PressDim())
        .moonAccessibility(status)
        .frame(maxWidth: .infinity)
        // −5 and +5 sit in the dial's lower corners, only while Sleep is on.
        .overlay(alignment: .bottom) {
            if status.isOn {
                HStack {
                    DStep(minutes: -5, ink: theme.text) { Circle().strokeBorder(theme.text.opacity(0.35), lineWidth: 1.5) }
                        .disabled(status.isFading)
                        .opacity(status.isFading ? 0.4 : 1)
                    Spacer()
                    DStep(minutes: 5, ink: theme.text) { Circle().strokeBorder(theme.text.opacity(0.35), lineWidth: 1.5) }
                }
            }
        }
    }

    private func readout(_ status: SleepStatus) -> String {
        switch status {
        case .off: "Ready for bed?"
        case .waiting(let t): TimeFormat.sleepDelay(t)
        case .fading(let level): "\(Int((level * 100).rounded()))%"
        }
    }

    private func caption(_ status: SleepStatus) -> String {
        status.isFading ? "Lights going down" : "until the fade"
    }
}

private struct DockA: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        let player = model.player
        let status = model.sleepStatus
        HStack(spacing: Space.m) {
            Button { model.isPlayerPresented = true } label: {
                HStack(spacing: Space.m) {
                    ArtworkView(url: player.episode?.artworkURL, cornerRadius: 20, title: player.episode?.showTitle ?? "")
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(player.episode?.title ?? "")
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(theme.text)
                            .lineLimit(1)
                        Text(status.isOn ? status.detail : (player.episode?.showTitle ?? ""))
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(theme.textMuted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Now playing: \(player.episode?.title ?? "")")
            .accessibilityIdentifier("miniPlayer")

            Button { model.toggleSleep() } label: {
                ZStack {
                    DialRing(status: status, lineWidth: 3.5)
                    Image(systemName: "moon.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(theme.text)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(PressDim())
            .accessibilityLabel("Sleep")
            .accessibilityValue(status.isOn ? "On" : "Off")
            .accessibilityIdentifier("miniMoonKey")

            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.bg)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(theme.text))
            }
            .buttonStyle(PressDim())
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
        }
        .padding(Space.s)
        .background(Capsule().fill(theme.bg.opacity(0.9)).overlay(Capsule().strokeBorder(theme.text.opacity(0.22), lineWidth: 1)))
    }
}

// MARK: - B · Turn-Down

/// The blanket: square at the bottom, rounded at the top, with the top-right corner
/// cut on the diagonal when it is folded back (`fold` > 0).
private nonisolated struct BlanketShape: Shape {
    var fold: CGFloat = 0
    var radius: CGFloat = 32

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: radius))
        p.addQuadCurve(to: CGPoint(x: radius, y: 0), control: .zero)
        if fold > 0 {
            p.addLine(to: CGPoint(x: rect.maxX - fold, y: 0))
            p.addLine(to: CGPoint(x: rect.maxX, y: fold))
        } else {
            p.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: radius), control: CGPoint(x: rect.maxX, y: 0))
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// The folded-back corner: the lining shows in the accent, and it holds the moon.
private struct FoldCorner: View {
    let size: CGFloat
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        Button { model.toggleSleep() } label: {
            ZStack(alignment: .bottomLeading) {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: size, y: size))
                    p.addLine(to: CGPoint(x: size * 0.18, y: size))
                    p.addQuadCurve(to: CGPoint(x: 0, y: size * 0.82), control: CGPoint(x: 0, y: size))
                    p.closeSubpath()
                }
                .fill(theme.accent)
                Image(systemName: "moon.fill")
                    .font(.system(size: size * 0.26, weight: .bold))
                    .foregroundStyle(theme.onAccent)
                    .padding(.leading, size * 0.13)
                    .padding(.bottom, size * 0.15)
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressDim())
        .moonAccessibility(.off)
    }
}

private struct NowPlayingB: View {
    let close: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        let episode = model.player.episode
        let status = model.sleepStatus
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Space.xl) {
                DIcon(systemName: "chevron.down", label: "Close player", action: close) { Circle().fill(theme.surface) }
                    .accessibilityIdentifier("closePlayer")
                HStack(spacing: Space.m) {
                    ArtworkView(url: episode?.artworkURL, cornerRadius: 12, title: episode?.showTitle ?? "")
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(episode?.showTitle ?? "").font(.system(.headline)).foregroundStyle(theme.text).lineLimit(1)
                        Text(episode?.duration.map { TimeFormat.duration($0) } ?? "").font(Typo.caption).foregroundStyle(theme.textMuted)
                    }
                }
                .padding(.top, Space.s)
                Text(episode?.title ?? "Nothing playing")
                    .font(serif(40, .largeTitle))
                    .foregroundStyle(theme.text)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Space.xxl)
            .padding(.top, Space.s)

            VStack(spacing: 0) {
                if status.isOn { hem(status) } else { invitation }
                VStack(spacing: Space.l) {
                    DScrubber(track: 8, thumb: 22)
                    DTransport(spacing: Space.xl, skipSize: CGSize(width: 60, height: 60), playSize: CGSize(width: 136, height: 64)) {
                        Circle().fill(theme.raised)
                    } playFace: {
                        Capsule().fill(theme.text)
                    }
                }
                .padding(.horizontal, Space.xxl)
                .padding(.top, Space.l)
                .padding(.bottom, Space.l)
            }
            .background {
                BlanketShape(fold: status.isOn ? 0 : 88).fill(theme.surface).ignoresSafeArea(edges: .bottom)
            }
        }
        .background {
            ZStack(alignment: .top) {
                ScreenBackground()
                LinearGradient(colors: [theme.bg.opacity(0.75), theme.bg.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 420)
                    .ignoresSafeArea()
            }
        }
    }

    // Sleep off: the corner of the blanket is folded back, waiting.
    private var invitation: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(SleepStatus.off.title).font(serif(21, .title3)).foregroundStyle(theme.text)
            Text(SleepStatus.off.detail).font(.system(.subheadline, weight: .medium)).foregroundStyle(theme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(.horizontal, Space.xxl)
        .overlay(alignment: .topTrailing) { FoldCorner(size: 88) }
    }

    // Sleep on: the whole top of the blanket is turned down, lining out, with a stitched hem.
    private func hem(_ status: SleepStatus) -> some View {
        VStack(spacing: Space.m) {
            HStack(spacing: Space.s) {
                Button { model.toggleSleep() } label: {
                    HStack(spacing: Space.m) {
                        Image(systemName: status.isFading ? "moon.zzz.fill" : "moon.fill")
                            .font(.system(size: 22, weight: .bold))
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(.black.opacity(0.16)))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: Space.s) {
                                Text(status.title).font(serif(21, .title3))
                                if !status.isFading { AccentHeart().accessibilityHidden(true) }
                            }
                            Text(status.detail).font(.system(.subheadline, weight: .semibold)).opacity(0.85)
                                .contentTransition(.numericText())
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressDim())
                .moonAccessibility(status)
                DStep(minutes: -5, ink: theme.onAccent) { Circle().fill(.black.opacity(0.16)) }
                    .disabled(status.isFading)
                    .opacity(status.isFading ? 0.4 : 1)
                DStep(minutes: 5, ink: theme.onAccent) { Circle().fill(.black.opacity(0.16)) }
            }
            DSteps(status: status, ink: theme.onAccent)
        }
        .foregroundStyle(theme.onAccent)
        .padding(.horizontal, Space.xl)
        .padding(.top, Space.l)
        .padding(.bottom, Space.m)
        .background(BlanketShape().fill(theme.accent))
        // The fold's shadow on the blanket below.
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.black.opacity(0.28), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 8)
                .offset(y: 8)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topLeading) {
            FloatingZs(isFading: status.isFading)
                .frame(width: 110, height: 150)
                .offset(x: 20, y: -140)
        }
    }
}

/// B's dock: the mini player and the page tabs on one blanket, in reach of a thumb.
private struct DockB: View {
    @Binding var selection: HomePage
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        let player = model.player
        let status = model.sleepStatus
        VStack(spacing: 0) {
            if status.isOn {
                Button { model.toggleSleep() } label: {
                    HStack(spacing: Space.s) {
                        Image(systemName: status.isFading ? "moon.zzz.fill" : "moon.fill").font(.system(size: 15, weight: .bold))
                        Text(status.detail).font(.system(.subheadline, weight: .semibold)).lineLimit(1)
                        Spacer(minLength: Space.m)
                        DSteps(status: status, ink: theme.onAccent, spacing: 4).frame(width: 110)
                    }
                    .foregroundStyle(theme.onAccent)
                    .padding(.horizontal, Space.xl)
                    .frame(minHeight: 44)
                    .background(BlanketShape(radius: 28).fill(theme.accent))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressDim())
                .accessibilityLabel("Sleep")
                .accessibilityValue("On")
                .accessibilityIdentifier("miniMoonKey")
            }
            HStack(spacing: Space.m) {
                Button { model.isPlayerPresented = true } label: {
                    HStack(spacing: Space.m) {
                        ArtworkView(url: player.episode?.artworkURL, cornerRadius: 10, title: player.episode?.showTitle ?? "")
                            .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(player.episode?.title ?? "").font(.system(.subheadline, weight: .semibold)).foregroundStyle(theme.text).lineLimit(1)
                            Text(player.episode?.showTitle ?? "").font(.system(.caption, weight: .medium)).foregroundStyle(theme.textMuted).lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Now playing: \(player.episode?.title ?? "")")
                .accessibilityIdentifier("miniPlayer")
                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.bg)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(theme.text))
                }
                .buttonStyle(PressDim())
                .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            }
            .padding(.leading, Space.xl)
            .padding(.trailing, status.isOn ? Space.xl : 68)
            .padding(.vertical, Space.m)
            .overlay(alignment: .topTrailing) { if !status.isOn { FoldCorner(size: 60) } }

            Rectangle().fill(theme.text.opacity(0.12)).frame(height: 1).padding(.horizontal, Space.xl)

            HStack(spacing: 0) {
                ForEach(HomePage.allCases, id: \.self) { page in
                    let on = page == selection
                    Button { selection = page } label: {
                        VStack(spacing: Space.xs) {
                            Text(page.title)
                                .font(.system(.subheadline, weight: on ? .bold : .medium))
                                .foregroundStyle(on ? theme.text : theme.textMuted)
                            Capsule().fill(on ? theme.text : .clear).frame(width: 20, height: 3)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(.horizontal, Space.m)
        }
        .background {
            BlanketShape(fold: status.isOn ? 0 : 60, radius: 28)
                .fill(theme.surface)
                .shadow(color: .black.opacity(0.35), radius: 16, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - C · Lights Out

private struct TabsC: View {
    @Binding var selection: HomePage
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: Space.s) {
            ForEach(Array(HomePage.allCases.enumerated()), id: \.element) { index, page in
                let on = page == selection
                Button { selection = page } label: {
                    Text(page.title)
                        .font(serif(17, .headline))
                        .foregroundStyle(on ? theme.bg : theme.text)
                        .fixedSize()
                        .padding(.horizontal, Space.xl)
                        .frame(minHeight: 44)
                        .background(PaperShape(seed: index).fill(on ? theme.text : theme.surface))
                }
                .buttonStyle(PressDim())
                .accessibilityAddTraits(on ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Space.xl)
        .padding(.top, Space.s)
        .padding(.bottom, Space.s)
    }
}

/// Ten lanterns on a sagging wire; each goes dark as its fade step passes.
private struct LanternString: View {
    let status: SleepStatus
    @Environment(\.theme) private var theme

    var body: some View {
        Canvas { c, size in
            let w = size.width, sag: CGFloat = 20, top: CGFloat = 4
            func wireY(_ x: CGFloat) -> CGFloat {
                let u = (x - w / 2) / (w / 2)
                return top + sag * (1 - u * u)
            }
            var wire = Path()
            wire.move(to: CGPoint(x: 0, y: wireY(0)))
            for x in stride(from: CGFloat(0), through: w, by: 6) { wire.addLine(to: CGPoint(x: x, y: wireY(x))) }
            wire.addLine(to: CGPoint(x: w, y: wireY(w)))
            c.stroke(wire, with: .color(theme.text.opacity(0.5)), lineWidth: 1.5)
            for i in 0..<10 {
                let x = w * (CGFloat(i) + 0.5) / 10, y = wireY(x)
                let lit = status.isOn && i >= 10 - status.lit
                let body = CGRect(x: x - 9, y: y + 7, width: 18, height: 22)
                c.fill(Path(CGRect(x: x - 3, y: y, width: 6, height: 8)), with: .color(theme.text.opacity(0.5)))
                let lantern = Path(roundedRect: body, cornerRadius: 8, style: .continuous)
                c.fill(lantern, with: .color(lit ? theme.accent : theme.bg))
                if !lit { c.stroke(lantern, with: .color(theme.text.opacity(0.45)), lineWidth: 1.5) }
            }
        }
        .frame(height: 58)
        .accessibilityHidden(true)
    }
}

/// The cut-paper ground the controls stand on: two layers, hand-cut top edges.
private nonisolated struct GroundShape: Shape {
    var lift: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 26 - lift))
        p.addCurve(to: CGPoint(x: rect.maxX, y: 14 - lift),
                   control1: CGPoint(x: rect.maxX * 0.3, y: -14 - lift), control2: CGPoint(x: rect.maxX * 0.68, y: 34 - lift))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct NowPlayingC: View {
    let close: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        let episode = model.player.episode
        let status = model.sleepStatus
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    DIcon(systemName: "chevron.down", label: "Close player", action: close) { PaperShape(seed: 1).fill(theme.surface) }
                        .accessibilityIdentifier("closePlayer")
                    Spacer()
                }
                Spacer(minLength: Space.s)
                ArtworkView(url: episode?.artworkURL, cornerRadius: 8, title: episode?.showTitle ?? "")
                    .frame(width: 148, height: 148)
                    .padding(Space.s)
                    .background(PaperShape(seed: 1).fill(theme.raised))
                    .rotationEffect(.degrees(-2))
                VStack(spacing: Space.xs) {
                    Text(episode?.title ?? "Nothing playing")
                        .font(serif(28, .title))
                        .foregroundStyle(theme.text)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .accessibilityAddTraits(.isHeader)
                    Text(episode?.showTitle ?? "").font(Typo.caption).foregroundStyle(theme.textMuted).lineLimit(1)
                }
                .padding(.top, Space.l)
                Spacer(minLength: Space.s)
            }
            .padding(.horizontal, Space.xxl)
            .padding(.top, Space.s)

            LanternString(status: status)
                .padding(.bottom, Space.xxl)

            VStack(spacing: Space.l) {
                DScrubber(track: 10, thumb: 24)
                DTransport(spacing: Space.xl, skipSize: CGSize(width: 64, height: 64), playSize: CGSize(width: 104, height: 76)) {
                    PaperShape(seed: 0).fill(theme.surface)
                } playFace: {
                    PaperShape(seed: 2).fill(theme.text)
                }
                moonBar(status)
            }
            .padding(.horizontal, Space.xxl)
            .padding(.top, Space.xxl)
            .padding(.bottom, Space.m)
            .background {
                ZStack {
                    GroundShape(lift: 14).fill(theme.raised)
                    GroundShape().fill(theme.bg)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background { ScreenBackground() }
    }

    private func moonBar(_ status: SleepStatus) -> some View {
        let ink = status.isOn ? theme.onAccent : theme.text
        return HStack(spacing: Space.s) {
            Button { model.toggleSleep() } label: {
                HStack(spacing: Space.m) {
                    Image(systemName: status.isFading ? "moon.zzz.fill" : "moon.fill")
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 48, height: 48)
                        .background(PaperShape(seed: 0).fill(status.isOn ? Color.black.opacity(0.16) : theme.raised))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Space.s) {
                            Text(status.title).font(serif(20, .title3))
                            if case .waiting = status { AccentHeart().accessibilityHidden(true) }
                        }
                        Text(status.detail).font(.system(.subheadline, weight: .semibold)).opacity(0.85)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressDim())
            .moonAccessibility(status)
            if status.isOn {
                DStep(minutes: -5, ink: ink) { PaperShape(seed: 1).fill(.black.opacity(0.16)) }
                    .disabled(status.isFading)
                    .opacity(status.isFading ? 0.4 : 1)
                DStep(minutes: 5, ink: ink) { PaperShape(seed: 2).fill(.black.opacity(0.16)) }
            }
        }
        .foregroundStyle(ink)
        .padding(Space.m)
        .background(PaperShape(seed: 2).fill(status.isOn ? theme.accent : theme.surface))
    }
}

private struct DockC: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        let player = model.player
        let status = model.sleepStatus
        HStack(spacing: Space.s) {
            Button { model.isPlayerPresented = true } label: {
                HStack(spacing: Space.m) {
                    ArtworkView(url: player.episode?.artworkURL, cornerRadius: 8, title: player.episode?.showTitle ?? "")
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(player.episode?.title ?? "").font(serif(15, .subheadline)).foregroundStyle(theme.text).lineLimit(1)
                        if status.isOn {
                            HStack(spacing: 4) {
                                ForEach(0..<10, id: \.self) { i in
                                    let lit = i >= 10 - status.lit
                                    Circle().fill(lit ? theme.text : .clear) // text, not accent: Underwater's accent is too dark at this size
                                        .overlay(Circle().strokeBorder(theme.text.opacity(lit ? 0 : 0.45), lineWidth: 1))
                                        .frame(width: 7, height: 7)
                                }
                            }
                            .frame(height: 14)
                            .accessibilityHidden(true)
                        } else {
                            Text(player.episode?.showTitle ?? "").font(.system(.caption, weight: .medium)).foregroundStyle(theme.textMuted).lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Now playing: \(player.episode?.title ?? "")")
            .accessibilityIdentifier("miniPlayer")

            Button { model.toggleSleep() } label: {
                Image(systemName: "moon.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(status.isOn ? theme.onAccent : theme.text)
                    .frame(width: 44, height: 44)
                    .background(PaperShape(seed: 0).fill(status.isOn ? theme.accent : theme.surface))
            }
            .buttonStyle(PressDim())
            .accessibilityLabel("Sleep")
            .accessibilityValue(status.isOn ? "On" : "Off")
            .accessibilityIdentifier("miniMoonKey")

            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.bg)
                    .frame(width: 44, height: 44)
                    .background(PaperShape(seed: 2).fill(theme.text))
            }
            .buttonStyle(PressDim())
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
        }
        .padding(Space.s)
        .background(PaperShape(seed: 1).fill(theme.raised).shadow(color: .black.opacity(0.4), radius: 10, y: 4))
    }
}
#endif
