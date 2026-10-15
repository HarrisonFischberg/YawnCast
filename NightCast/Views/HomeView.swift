import NightCastCore
import SwiftUI

/// Home: three swipeable pages (New · Library · Explore) once the Library has
/// shows; just the Library before that, so a first launch has one clear action.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            if model.library.subscriptions.isEmpty {
                LibraryView()
            } else {
                PageDots(selection: $model.homePage)
                TabView(selection: $model.homePage) {
                    NewEpisodesView().tag(HomePage.new)
                    LibraryView().tag(HomePage.library)
                    ExploreView().tag(HomePage.explore)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .background(theme.bg.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: model.homePage)
    }
}

/// Three page dots; the current page is a longer pill. Each dot is a 44 pt target.
struct PageDots: View {
    @Binding var selection: HomePage
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomePage.allCases, id: \.self) { page in
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) { selection = page }
                } label: {
                    Capsule()
                        .fill(page == selection ? theme.text : theme.textMuted.opacity(0.45))
                        .frame(width: page == selection ? 22 : 8, height: 8)
                        .frame(width: 36, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(page.title)
                .accessibilityAddTraits(page == selection ? .isSelected : [])
                .accessibilityIdentifier("pageDot-\(page.title)")
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: selection)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pages")
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
        .refreshable { await model.refreshLatest(force: true) }
        .task(id: model.library.subscriptions.map(\.id)) { await model.refreshLatest() }
        .background(theme.bg)
    }

    @ViewBuilder
    private var content: some View {
        let groups = LatestEpisodes.byDay(model.latest)
        if groups.isEmpty {
            switch model.latestPhase {
            case .idle, .loading:
                HStack(spacing: Space.m) {
                    ProgressView().tint(theme.text)
                    Text("Checking your shows…").font(Typo.caption).foregroundStyle(theme.textMuted)
                }
                .padding(.top, Space.xl)
                .accessibilityElement(children: .combine)
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
                    Button { model.play(episode) } label: {
                        LatestRow(
                            episode: episode,
                            position: model.position(for: episode),
                            isPlaying: model.player.episode?.id == episode.id && model.player.isPlaying
                        )
                    }
                    .buttonStyle(RowStyle())
                    .contextMenu { EpisodeMenu(episode: episode) }
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

// MARK: - Explore

/// Right page: shows that share genres with the Library, from Apple's charts.
struct ExploreView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Space.xl, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xxl) {
                PageTitle(title: "Explore", subtitle: "Shows like the ones in your Library")
                    .padding(.top, Space.s)
                content
                Button { model.openSearch() } label: {
                    Label("Search for something else", systemImage: "magnifyingglass")
                        .font(Typo.headline)
                        .padding(.vertical, Space.l)
                }
                .buttonStyle(.capsuleKey())
                .fixedSize(horizontal: false, vertical: true)
                Text("Suggestions come from the Apple Podcasts genres and titles of your shows, Apple’s public genre charts, and directory search. Nothing about you is stored or sent anywhere else.")
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
            }
            .padding(.horizontal, Space.xl)
            .padding(.bottom, Space.xxxl)
        }
        .scrollIndicators(.hidden)
        .refreshable { await model.loadExplore(force: true) }
        .task(id: model.library.subscriptions.map(\.id)) { await model.loadExplore() }
        .background(theme.bg)
    }

    @ViewBuilder
    private var content: some View {
        switch model.explorePhase {
        case .idle, .loading where model.explore.isEmpty:
            HStack(spacing: Space.m) {
                ProgressView().tint(theme.text)
                Text("Finding shows you might like…").font(Typo.caption).foregroundStyle(theme.textMuted)
            }
            .accessibilityElement(children: .combine)
        case .failed(let message) where model.explore.isEmpty:
            StateMessage(title: "Explore didn’t load", message: message, systemImage: "wifi.exclamationmark", actionTitle: "Try again") {
                Task { await model.loadExplore(force: true) }
            }
            .padding(.horizontal, -Space.xxl)
        default:
            if model.explore.isEmpty {
                StateMessage(title: "Nothing to suggest yet", message: "Add a few shows from Search and Explore will find similar ones.", systemImage: "sparkle.magnifyingglass")
                    .padding(.horizontal, -Space.xxl)
            } else {
                ForEach(model.explore) { section in
                    VStack(alignment: .leading, spacing: Space.l) {
                        Text(section.genre.id == Recommender.topPicksID ? "Top picks for you" : "Because you like \(section.genre.name)")
                            .font(Typo.title)
                            .foregroundStyle(theme.text)
                            .accessibilityAddTraits(.isHeader)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: Space.xxl) {
                            ForEach(section.shows) { recommendation in
                                NavigationLink(value: Route.show(recommendation.result.show)) {
                                    ShowTile(show: recommendation.result.show)
                                }
                                .buttonStyle(TileStyle())
                            }
                        }
                    }
                }
            }
        }
    }
}
