import YawnCastCore
import SwiftUI

/// Home: three swipeable pages (New · Library · Explore) once the Library has
/// shows; just the Library before that, so a first launch has one clear action.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    /// First launch only; installing the app counts as step 1, picking shows is step 3.
    @AppStorage("didOnboard") private var didOnboard = false
    @State private var pickingShows = false

    static let onboarding = [
        OnboardingPage(
            systemImage: "moon.zzz.fill",
            title: "Fall asleep, not stay up",
            message: "Tap the moon while you listen. Later, YawnCast slowly fades the episode out and pauses, so it never plays all night. In the morning it takes you back to where the fade began.",
            buttonTitle: "Pick your shows"
        ),
    ]

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            // Stay on the single Library page while a first-launch search adds shows.
            if model.library.subscriptions.isEmpty || (model.searchingOn == .library && model.searchFindsNew) {
                LibraryView()
            } else {
                VStack(spacing: Space.m) {
                    BrandMark()
                    LookTabs(selection: $model.homePage)
                }
                .padding(.horizontal, Space.xl)
                .padding(.top, Space.s)
                TabView(selection: $model.homePage) {
                    NewEpisodesView().tag(HomePage.new)
                    LibraryView().tag(HomePage.library)
                    ExploreView().tag(HomePage.explore)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .background { ScreenBackground() }
        .fullScreenCover(isPresented: Binding(get: { !didOnboard && model.library.subscriptions.isEmpty }, set: { if !$0 { didOnboard = true } })) {
            Group {
                if pickingShows {
                    PickShowsView { didOnboard = true }
                } else {
                    OnboardingFlow(pages: Self.onboarding, stepsAfter: 1) { _ in pickingShows = true }
                }
            }
            .environment(model)
            .environment(\.theme, theme)
        }
        .sensoryFeedback(.selection, trigger: model.homePage)
        // Leaving a page ends its in-place search.
        .onChange(of: model.homePage) { _, page in
            if let searching = model.searchingOn, searching != page { model.endSearch() }
        }
    }
}

/// "YawnCast" with the crescent and its two pink z's, above the page tabs.
struct BrandMark: View {
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: Space.s) {
            Text("YawnCast")
                .font(Typo.title)
                .foregroundStyle(theme.text)
            CrescentShape(scene: theme.scene)
                .fill(theme.accent)
                .frame(width: 18, height: 18)
                .overlay(alignment: .topTrailing) {
                    HStack(alignment: .bottom, spacing: 0) {
                        Text("z").font(.system(size: 9, weight: .heavy, design: .rounded))
                        Text("z").font(.system(size: 7, weight: .heavy, design: .rounded)).offset(y: -4)
                    }
                    .foregroundStyle(theme.brandPink)
                    .offset(x: 12, y: -6)
                }
            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("YawnCast")
    }
}

/// Large page title shared by the home pages.
struct PageTitle: View {
    let title: String
    var subtitle: String?
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title)
                .font(Typo.display)
                .textCase(Typo.titleCase)
                .foregroundStyle(theme.text)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
            }
        }
    }
}

// MARK: - New

/// Left page: the newest episodes from Library shows, newest first, by day.
struct NewEpisodesView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                PageTitle(title: "New", subtitle: "Latest episodes from your shows")
                    .padding(.top, Space.s)
                    .padding(.bottom, Space.l)
                content
            }
            .padding(.horizontal, Space.xl)
            .padding(.bottom, Space.xxxl)
        }
        .scrollIndicators(.hidden)
        .dockAware()
        .refreshable { await model.refreshLatest(force: true) }
        .task(id: model.library.subscriptions.map(\.id)) { await model.refreshLatest() }
    }

    @ViewBuilder
    private var content: some View {
        let groups = LatestEpisodes.byDay(model.latest)
        if groups.isEmpty {
            switch model.latestPhase {
            case .idle, .loading:
                StagedProgress(title: "Checking your shows", done: model.latestChecked, total: model.library.subscriptions.count)
                    .padding(.top, Space.xl)
            case .failed(let message):
                StateMessage(title: "Couldn’t load new episodes", message: message, systemImage: "wifi.exclamationmark", actionTitle: "Try again") {
                    Task { await model.refreshLatest(force: true) }
                }
                .padding(.horizontal, -Space.xxl)
            case .loaded:
                StateMessage(title: "All quiet", message: "Nothing new from your shows in the last 30 days.", systemImage: "moon.zzz")
                    .padding(.horizontal, -Space.xxl)
            }
        } else {
            ForEach(groups, id: \.day) { group in
                Text(Self.dayLabel(group.day))
                    .font(Typo.eyebrow)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.textMuted)
                    .padding(.top, Space.l)
                    .padding(.bottom, Space.xs)
                    .accessibilityAddTraits(.isHeader)
                ForEach(group.episodes) { episode in
                    Button { model.open(episode) } label: {
                        LatestRow(
                            episode: episode,
                            position: model.position(for: episode),
                            isPlaying: model.player.episode?.id == episode.id && model.player.isPlaying
                        )
                    }
                    .buttonStyle(RowStyle())
                    .contextMenu { EpisodeMenu(episode: episode) }
                    .episodeAccessibilityActions(episode)
                    .accessibilityIdentifier("latestRow")
                }
            }
        }
    }

    static func dayLabel(_ day: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        if let days = calendar.dateComponents([.day], from: day, to: calendar.startOfDay(for: now)).day, days < 7 {
            return day.formatted(.dateTime.weekday(.wide))
        }
        let sameYear = calendar.isDate(day, equalTo: now, toGranularity: .year)
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year(sameYear ? .omitted : .defaultDigits))
    }
}

private struct LatestRow: View {
    let episode: Episode
    let position: PlaybackPosition?
    let isPlaying: Bool
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: .center, spacing: Space.m) {
            if !typeSize.isAccessibilitySize {
                ArtworkView(url: episode.artworkURL, cornerRadius: 10, title: episode.showTitle)
                    .frame(width: 56, height: 56)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title)
                    .font(Typo.headline)
                    .foregroundStyle(position?.completed == true ? theme.textMuted : theme.text)
                    .lineLimit(typeSize.isAccessibilitySize ? 4 : 2)
                    .multilineTextAlignment(.leading)
                Text(meta)
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
                    .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
            }
            Spacer(minLength: Space.s)
            ProgressPlayGlyph(fraction: position?.fraction ?? 0, isPlaying: isPlaying)
        }
        .padding(.vertical, Space.s)
        .padding(.horizontal, Space.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(episode.title), \(episode.showTitle)")
        .accessibilityValue(meta)
        .accessibilityAddTraits(.isButton)
    }

    private var meta: String {
        var parts = [episode.showTitle]
        let duration = position?.duration ?? episode.duration
        if position?.completed == true {
            parts.append("Played")
        } else if let position, position.seconds > 5, let duration, duration > 0 {
            parts.append("\(TimeFormat.duration(max(0, duration - position.seconds))) left")
        } else if let duration {
            parts.append(TimeFormat.duration(duration))
        }
        return parts.joined(separator: " · ")
    }
}
