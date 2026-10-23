import YawnCastCore
import Observation
import SwiftUI

@Observable
final class ShowModel {
    enum State: Equatable {
        case loading
        case loaded
        case empty
        case failed(String)
    }

    private(set) var show: Show
    private(set) var episodes: [Episode] = []
    private(set) var state: State = .loading
    /// Year sections in the chosen order, recomputed only when episodes or order change.
    private(set) var groups: [YearGroup] = []
    var newestFirst = true {
        didSet { if newestFirst != oldValue { regroup() } }
    }

    @ObservationIgnored private let app: AppModel

    init(show: Show, app: AppModel) {
        self.show = show
        self.app = app
        if let cached = app.cachedFeed(for: show) { apply(cached) }
    }

    func load(force: Bool = false) async {
        if episodes.isEmpty { state = .loading }
        do {
            let feed = try await app.feed(for: show, force: force)
            apply(feed)
        } catch is CancellationError {
            return
        } catch {
            // Keep showing cached episodes if we have them; only surface the error otherwise.
            if episodes.isEmpty { state = .failed(Self.message(for: error)) }
        }
    }

    private func apply(_ feed: Feed) {
        // Keep the directory's id/artwork when the feed omits them.
        var merged = feed.show
        merged.directoryID = merged.directoryID ?? show.directoryID
        merged.artworkURL = merged.artworkURL ?? show.artworkURL
        if merged.author == nil { merged.author = show.author }
        show = merged
        episodes = feed.episodes
        regroup()
        state = episodes.isEmpty ? .empty : .loaded
        app.refreshSubscription(merged)
    }

    private func regroup() {
        groups = EpisodeGrouping.byYear(episodes, newestFirst: newestFirst)
    }

    static func message(for error: Error) -> String {
        if let error = error as? FeedError {
            switch error {
            case .malformed: return "This show’s feed couldn’t be read. The publisher may have a problem with it."
            case .noEpisodes: return "This show has no playable episodes."
            case .http(let status) where status == 404 || status == 410: return "This show’s feed no longer exists."
            case .http: return "The show’s server isn’t responding right now."
            }
        }
        return SearchModel.message(for: error)
    }
}

struct ShowView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.theme) private var theme
    @State private var model: ShowModel
    @State private var expanded = false
    @Environment(\.dynamicTypeSize) private var typeSize

    init(show: Show, app: AppModel) {
        _model = State(initialValue: ShowModel(show: show, app: app))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                header
                    .padding(.bottom, Space.xl)
                episodesSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Space.xl)
            .padding(.bottom, Space.xxxl)
        }
        .scrollIndicators(.hidden)
        .dockAware()
        .refreshable { await model.load(force: true) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { ScreenBackground() }
        .task { await model.load() }
        .toolbarBackground(theme.bg, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        let show = model.show
        let subscribed = app.isSubscribed(show)
        return VStack(alignment: .leading, spacing: Space.l) {
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.l))
                : AnyLayout(HStackLayout(alignment: .top, spacing: Space.l))
            layout {
                ArtworkView(url: show.artworkURL, cornerRadius: 16, title: show.title)
                    .frame(width: 128, height: 128)
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text(show.title)
                        .font(Typo.showTitle)
                        .textCase(Typo.titleCase)
                        .foregroundStyle(theme.text)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 4)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: typeSize.isAccessibilitySize)
                        .accessibilityAddTraits(.isHeader)
                    if let author = show.author {
                        Text(author)
                            .font(Typo.caption)
                            .foregroundStyle(theme.textMuted)
                            .lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                app.toggleSubscription(show)
            } label: {
                Label(subscribed ? "Subscribed" : "Subscribe", systemImage: subscribed ? "checkmark" : "plus")
                    .font(Typo.headline)
                    .padding(.vertical, Space.m)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.capsuleKey(subscribed ? .standard : .primary))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(subscribed ? "Subscribed" : "Subscribe")
            .accessibilityHint(subscribed ? "Removes this show from your library." : "Adds this show to your library.")
            .accessibilityIdentifier("subscribeKey")
            .sensoryFeedback(.success, trigger: subscribed)

            if let summary = show.summary, !summary.isEmpty {
                Button { withAnimation(.easeOut(duration: 0.2)) { expanded.toggle() } } label: {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text(summary)
                            .font(Typo.body)
                            .foregroundStyle(theme.textMuted)
                            .lineLimit(expanded ? nil : 3)
                            .multilineTextAlignment(.leading)
                        Text(expanded ? "Less" : "More")
                            .font(Typo.caption)
                            .foregroundStyle(theme.text)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint(expanded ? "Shows less of the description." : "Shows the full description.")
            }
        }
        .padding(.top, Space.s)
    }

    @ViewBuilder
    private var episodesSection: some View {
        switch model.state {
        case .loading:
            HStack(spacing: Space.m) {
                ProgressView().tint(theme.text)
                Text("Loading episodes…").font(Typo.caption).foregroundStyle(theme.textMuted)
            }
            .padding(.top, Space.xl)
            .accessibilityElement(children: .combine)
        case .failed(let message):
            StateMessage(title: "Episodes didn’t load", message: message, systemImage: "exclamationmark.triangle", actionTitle: "Try again") {
                Task { await model.load(force: true) }
            }
            .padding(.horizontal, -Space.xxl)
        case .empty:
            StateMessage(title: "No episodes yet", message: "This feed has no playable episodes right now.", systemImage: "tray")
                .padding(.horizontal, -Space.xxl)
        case .loaded:
            HStack(alignment: .center) {
                // Uppercased here, not with .textCase: textCase also uppercases the
                // accessibility label, and VoiceOver reads all-caps words letter by letter.
                Text(verbatim: "Episodes · \(model.episodes.count)".uppercased())
                    .font(Typo.eyebrow)
                    .tracking(1.2)
                    .foregroundStyle(theme.textMuted)
                    .accessibilityLabel("\(model.episodes.count) episode\(model.episodes.count == 1 ? "" : "s")")
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("episodesHeader")
                Spacer()
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { model.newestFirst.toggle() }
                } label: {
                    Label(model.newestFirst ? "Newest first" : "Oldest first", systemImage: "arrow.up.arrow.down")
                        .font(Typo.caption)
                        .padding(.horizontal, Space.m)
                        .padding(.vertical, Space.s)
                }
                .buttonStyle(.capsuleKey(depth: 3))
                .fixedSize()
                .accessibilityHint("Changes the order of the episode list.")
                .accessibilityIdentifier("episodeOrder")
            }
            .padding(.bottom, Space.s)
            ForEach(model.groups) { group in
                Section {
                    ForEach(group.episodes) { episode in
                        Button { app.open(episode) } label: {
                            EpisodeRow(
                                episode: episode,
                                position: app.position(for: episode),
                                isCurrent: app.player.episode?.id == episode.id,
                                isPlaying: app.player.episode?.id == episode.id && app.player.isPlaying
                            )
                        }
                        .buttonStyle(RowStyle())
                        .accessibilityIdentifier("episodeRow")
                        .contextMenu { EpisodeMenu(episode: episode) }
                        .episodeAccessibilityActions(episode)
                        Rectangle().fill(theme.border).frame(height: 1)
                    }
                } header: {
                    YearHeader(group: group)
                }
            }
        }
    }
}

/// Pinned year heading on the show page: "2024 · 52 episodes".
private struct YearHeader: View {
    let group: YearGroup
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s) {
            Text(group.year.map(String.init) ?? "Undated")
                .font(Typo.sectionTitle)
                .foregroundStyle(theme.text)
            Text("\(group.episodes.count) episode\(group.episodes.count == 1 ? "" : "s")")
                .font(Typo.caption)
                .foregroundStyle(theme.textMuted)
            Spacer()
        }
        .padding(.top, Space.l)
        .padding(.bottom, Space.s)
        .background {
            // Pinned over scrolling rows; a soft frosted band over a Scene.
            if theme.scene != nil {
                Rectangle().fill(.ultraThinMaterial).padding(.horizontal, -Space.xl)
            } else {
                theme.bg.padding(.horizontal, -Space.xl)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("yearHeader")
    }
}

struct EpisodeRow: View {
    let episode: Episode
    let position: PlaybackPosition?
    let isCurrent: Bool
    let isPlaying: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: Space.m) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(episode.title)
                    .font(Typo.headline)
                    .foregroundStyle(position?.completed == true && !isCurrent ? theme.textMuted : theme.text)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Text(meta)
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: Space.s)
            ProgressPlayGlyph(fraction: position?.fraction ?? 0, isPlaying: isPlaying)
        }
        .padding(.vertical, Space.m)
        .padding(.horizontal, Space.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(episode.title)
        .accessibilityValue(meta)
        .accessibilityHint(isPlaying ? "Playing. Opens Now Playing." : "Opens Now Playing.")
        .accessibilityAddTraits(.isButton)
    }

    private var meta: String {
        var parts: [String] = []
        if let date = episode.published { parts.append(date.formatted(.dateTime.month(.abbreviated).day().year(Calendar.current.isDate(date, equalTo: .now, toGranularity: .year) ? .omitted : .defaultDigits))) }
        let duration = position?.duration ?? episode.duration
        if let position, position.completed {
            parts.append("Played")
        } else if let position, position.seconds > 5, let duration, duration > 0 {
            parts.append("\(TimeFormat.duration(max(0, duration - position.seconds))) left")
        } else if let duration {
            parts.append(TimeFormat.duration(duration))
        }
        return parts.joined(separator: " · ")
    }
}

/// A play glyph inside a progress ring.
struct ProgressPlayGlyph: View {
    let fraction: Double
    let isPlaying: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            Circle().stroke(theme.border, lineWidth: 3)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(theme.text, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.text)
                .symbolEffect(.variableColor.iterative, isActive: isPlaying)
        }
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
    }
}

/// The long-press menu's Mark as Played, as a VoiceOver action (swipe up/down on the row).
private struct EpisodeAccessibilityActions: ViewModifier {
    let episode: Episode
    @Environment(AppModel.self) private var app

    func body(content: Content) -> some View {
        let played = app.position(for: episode)?.completed == true
        content.accessibilityAction(named: played ? "Mark as Unplayed" : "Mark as Played") {
            app.setPlayed(episode, !played)
        }
    }
}

extension View {
    func episodeAccessibilityActions(_ episode: Episode) -> some View {
        modifier(EpisodeAccessibilityActions(episode: episode))
    }
}

/// Long-press actions shared by episode rows.
struct EpisodeMenu: View {
    let episode: Episode
    @Environment(AppModel.self) private var app

    var body: some View {
        let played = app.position(for: episode)?.completed == true
        Button { app.play(episode) } label: { Label("Play", systemImage: "play.fill") }
        Button { app.setPlayed(episode, !played) } label: {
            Label(played ? "Mark as Unplayed" : "Mark as Played", systemImage: played ? "circle" : "checkmark.circle")
        }
    }
}
