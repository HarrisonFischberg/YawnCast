import Foundation
import NightCastCore
import Observation
import SwiftUI
import UIKit

/// Screens pushed on the main navigation stack.
enum Route: Hashable {
    case show(Show)
    case search
}

/// The three swipeable home pages, left to right.
enum HomePage: Int, CaseIterable, Hashable {
    case new, library, explore

    var title: String {
        switch self {
        case .new: "New"
        case .library: "Library"
        case .explore: "Explore"
        }
    }
}

/// Load state for pages that fetch over the network.
enum LoadPhase: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}

/// App-wide state: library, player, and Sleep. Views read it from the environment.
@Observable
final class AppModel {
    private(set) var library: LibrarySnapshot
    let player: PlaybackEngine
    let directory: DirectoryService
    let feeds: FeedService

    var theme: Theme {
        didSet {
            library.themeID = theme.id
            persist()
        }
    }

    var isPlayerPresented = false
    /// Main navigation stack (show detail, search).
    var path: [Route] = []
    /// Which home page is showing. Library is the middle page.
    var homePage: HomePage = .library
    /// Query to prefill when Search opens (debug screenshots).
    var pendingSearchTerm: String?

    /// "New" page: recent episodes from Library shows, newest first.
    private(set) var latest: [Episode] = []
    private(set) var latestPhase: LoadPhase = .idle
    /// "Explore" page: suggestions grouped by the Library's top genres.
    private(set) var explore: [ExploreSection] = []
    private(set) var explorePhase: LoadPhase = .idle
    /// Brief confirmation shown above the Moon key.
    private(set) var toast: String?
    private(set) var sleepStatus: SleepStatus = .off

    @ObservationIgnored private let store: LibraryStore
    @ObservationIgnored private let sleep: SleepController
    @ObservationIgnored private var nowPlaying: NowPlayingBridge?
    @ObservationIgnored private var sleepTicker: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var feedCache: [String: Feed] = [:]
    @ObservationIgnored private var feedTasks: [String: Task<Feed, Error>] = [:]
    /// Feeds fetched from the network this session (the disk cache may be older).
    @ObservationIgnored private var freshFeeds: Set<String> = []
    @ObservationIgnored private let feedDisk = FeedDiskCache()
    /// Library shows (by id) that the current Explore results were computed from.
    @ObservationIgnored private var exploreBasis: [String] = []

    init(store: LibraryStore, directory: DirectoryService, feeds: FeedService, clock: PlaybackClock = SystemPlaybackClock(), sleepConfiguration: SleepConfiguration = .standard) {
        self.store = store
        self.directory = directory
        self.feeds = feeds
        let snapshot = store.load()
        library = snapshot
        theme = Theme.with(id: snapshot.themeID)
        player = PlaybackEngine()
        sleep = SleepController(clock: clock, configuration: sleepConfiguration)
        nowPlaying = NowPlayingBridge(engine: player)

        player.onProgress = { [weak self] episode, position, duration, finished in
            self?.recordProgress(episode: episode, position: position, duration: duration, finished: finished)
        }
        player.onStateChange = { [weak self] in
            guard let self else { return }
            sleep.sync()
            sleepStatus = sleep.status
            nowPlaying?.update()
            runSleepTicker()
        }
        player.onEnded = { [weak self] in
            self?.sleep.episodeDidEnd()
        }
        player.onDurationMeasured = { [weak self] episode, duration in
            self?.sleep.measuredDurationArrived(duration, episodeID: episode.id)
        }
        sleep.onChange = { [weak self] in
            guard let self else { return }
            sleepStatus = sleep.status
        }

        // Restore the last episode paused at its saved position. Never autoplay;
        // never restore Sleep.
        if let last = snapshot.lastEpisode {
            player.load(last, start: SeekMath.resumeTime(saved: snapshot.positions[last.id], duration: last.duration), autoplay: false)
        }
        recomputeLatestFromCache()
    }

    // MARK: Library

    func isSubscribed(_ show: Show) -> Bool { library.isSubscribed(show) }

    func toggleSubscription(_ show: Show) {
        if library.isSubscribed(show) { unsubscribe(show) } else { library.subscribe(show); persist() }
        recomputeLatestFromCache()
    }

    func unsubscribe(_ show: Show) {
        library.unsubscribe(show)
        persist()
        recomputeLatestFromCache()
        if library.subscriptions.isEmpty { homePage = .library }
    }

    func openSearch() {
        path.append(.search)
    }

    /// Marks an episode played or unplayed without playing it.
    func setPlayed(_ episode: Episode, _ played: Bool) {
        let duration = library.positions[episode.id]?.duration ?? episode.duration
        library.positions[episode.id] = PlaybackPosition(seconds: played ? (duration ?? 0) : 0, duration: duration, completed: played)
        persist()
    }

    /// True when the show has an unplayed episode from the last 7 days.
    func hasNewEpisode(_ show: Show) -> Bool {
        let weekAgo = Date().addingTimeInterval(-7 * 86_400)
        return latest.contains { episode in
            FeedURL.key(episode.showFeedURL) == show.id
                && (episode.published ?? .distantPast) >= weekAgo
                && library.positions[episode.id] == nil
        }
    }

    func position(for episode: Episode) -> PlaybackPosition? { library.positions[episode.id] }

    /// Updates stored metadata (title, artwork, summary) for a subscribed show.
    func refreshSubscription(_ show: Show) {
        guard let index = library.subscriptions.firstIndex(where: { $0.id == show.id }),
              library.subscriptions[index] != show else { return }
        library.subscriptions[index] = show
        persist()
    }

    // MARK: Feeds

    /// Last known feed: from this session, or from the disk cache of an earlier one.
    func cachedFeed(for show: Show) -> Feed? {
        if let feed = feedCache[show.id] { return feed }
        guard let feed = feedDisk.load(show.feedURL) else { return nil }
        feedCache[show.id] = feed
        return feed
    }

    /// Fetches a feed from the network once per session (or again when forced),
    /// sharing in-flight requests. Successful fetches are saved to disk.
    func feed(for show: Show, force: Bool = false) async throws -> Feed {
        if !force, freshFeeds.contains(show.id), let cached = feedCache[show.id] { return cached }
        if let running = feedTasks[show.id] { return try await running.value }
        let feeds = self.feeds
        let task = Task { try await feeds.fetch(show.feedURL) }
        feedTasks[show.id] = task
        defer { feedTasks[show.id] = nil }
        let feed = try await task.value
        feedCache[show.id] = feed
        freshFeeds.insert(show.id)
        feedDisk.save(feed)
        return feed
    }

    // MARK: New page

    private static let latestWindow: TimeInterval = 30 * 86_400

    private func recomputeLatestFromCache() {
        let feeds = library.subscriptions.compactMap { cachedFeed(for: $0) }
        latest = LatestEpisodes.collect(from: feeds, since: Date().addingTimeInterval(-Self.latestWindow))
    }

    /// Shows cached episodes at once, then refreshes every Library feed (4 at a time).
    func refreshLatest(force: Bool = false) async {
        recomputeLatestFromCache()
        let shows = library.subscriptions
        guard !shows.isEmpty else {
            latestPhase = .loaded
            return
        }
        if latest.isEmpty { latestPhase = .loading }
        var failures = 0
        var index = 0
        while index < shows.count {
            let batch = shows[index..<min(shows.count, index + 4)]
            index += batch.count
            // Unstructured child tasks inherit the main actor; the network
            // waits overlap, so a batch fetches concurrently.
            let tasks = batch.map { show in
                Task { (try? await self.feed(for: show, force: force)) != nil }
            }
            for task in tasks where !(await task.value) { failures += 1 }
            recomputeLatestFromCache()
        }
        if failures == shows.count && latest.isEmpty {
            latestPhase = .failed("Couldn’t reach your shows. Check your connection and pull to try again.")
        } else {
            latestPhase = .loaded
        }
    }

    // MARK: Explore page

    /// Builds suggestions from the genres of Library shows (Apple directory
    /// lookup) and Apple's public per-genre charts. Recomputed when the Library changes.
    func loadExplore(force: Bool = false) async {
        let basis = library.subscriptions.map(\.id).sorted()
        if !force, basis == exploreBasis, explorePhase == .loaded { return }
        let ids = library.subscriptions.compactMap(\.directoryID)
        guard !ids.isEmpty else {
            explore = []
            exploreBasis = basis
            explorePhase = .loaded
            return
        }
        if explore.isEmpty { explorePhase = .loading }
        do {
            let records = try await directory.lookup(ids: ids)
            let taste = Recommender.taste(from: records)
            var rankByID: [Int: Int] = [:]
            for weight in taste.prefix(3) {
                let chart = (try? await directory.topShowIDs(genreID: weight.genre.id, limit: 25)) ?? []
                for (rank, id) in chart.enumerated() where rankByID[id].map({ rank < $0 }) ?? true {
                    rankByID[id] = rank
                }
            }
            var candidates = try await directory.lookup(ids: Array(rankByID.keys).sorted())
                .map { (result: $0, chartRank: rankByID[$0.directoryID] ?? 99) }
            // Words shared by several Library titles (e.g. "sleep") find shows
            // that genre charts miss; search results rank below chart hits.
            let keywords = Recommender.keywords(fromTitles: library.subscriptions.map(\.title))
            for keyword in keywords.sorted(by: { $0.value > $1.value }).prefix(2).map(\.key) {
                let found = (try? await directory.search(keyword)) ?? []
                candidates += found.enumerated().map { (result: $0.element, chartRank: 30 + $0.offset) }
            }
            let ranked = Recommender.rank(candidates: candidates, taste: taste, keywords: keywords, excluding: library.subscriptions)
            explore = Recommender.sections(ranked, taste: taste, maxRows: 3, perRow: 6)
            exploreBasis = basis
            explorePhase = .loaded
        } catch is CancellationError {
            return
        } catch {
            if explore.isEmpty { explorePhase = .failed(SearchModel.message(for: error)) }
        }
    }

    // MARK: Playback

    /// Deliberate tap on an episode: start or resume it. A different episode cancels Sleep.
    func play(_ episode: Episode) {
        if player.episode?.id == episode.id {
            if !player.isPlaying { player.play() }
        } else {
            sleep.episodeWillChange(to: episode.id)
            let start = SeekMath.resumeTime(saved: library.positions[episode.id], duration: episode.duration)
            player.load(episode, start: start, autoplay: true)
            library.lastEpisode = episode
            persist()
        }
        presentPlayer()
    }

    private func presentPlayer() {
        isPlayerPresented = true
    }

    // MARK: Sleep

    func toggleSleep() {
        guard let episode = player.episode else { return }
        let remaining = SeekMath.remaining(position: player.position, duration: player.duration)
        if let delay = sleep.toggle(
            player: player,
            episodeID: episode.id,
            remaining: remaining,
            position: player.position,
            durationIsProvisional: !player.isDurationMeasured
        ) {
            show(toast: SleepCopy.activated(fadeDelay: delay))
        } else {
            show(toast: SleepCopy.cancelled)
        }
        sleepStatus = sleep.status
        runSleepTicker()
    }

    /// Ticks the Sleep controller 4×/s while Sleep needs it and audio is
    /// actually playing. Correctness does not depend on tick rate: the
    /// controller measures active time from the clock, and every play/pause/
    /// buffer change also syncs it (see `onStateChange`), which restarts this.
    private func runSleepTicker() {
        guard sleepTicker == nil, sleep.needsTicks, player.isActivelyPlaying else { return }
        sleepTicker = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.sleep.needsTicks, self.player.isActivelyPlaying else { break }
                self.sleep.sync()
                try? await Task.sleep(for: .milliseconds(250))
            }
            self?.sleepTicker = nil
        }
    }

    private func show(toast message: String) {
        toast = message
        UIAccessibility.post(notification: .announcement, argument: message)
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self?.toast = nil
        }
    }

    // MARK: Persistence

    private func recordProgress(episode: Episode, position: TimeInterval, duration: TimeInterval?, finished: Bool) {
        library.positions[episode.id] = PlaybackPosition(seconds: position, duration: duration, completed: finished)
        persist()
    }

    private func persist() {
        do { try store.save(library) } catch { print("NightCast: save failed: \(error)") }
    }

    #if DEBUG
    // MARK: Demo seeding (screenshots / UI tests only, via launch arguments)

    func seedForDemo(_ shows: [Show]) {
        for show in shows where !library.isSubscribed(show) { library.subscribe(show) }
        persist()
    }

    func loadForDemo(_ episode: Episode, position: TimeInterval) {
        player.load(episode, start: position, autoplay: false)
        library.lastEpisode = episode
        persist()
    }

    func activateSleepForDemo() {
        toggleSleep()
    }
    #endif
}
