import Foundation
import NightCastCore
import Observation
import SwiftUI
import UIKit

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
    var isSearchPresented = false
    /// Library navigation (show detail pushes).
    var libraryPath: [Show] = []
    /// Query to prefill when Search opens (debug screenshots).
    var pendingSearchTerm: String?
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
    }

    // MARK: Library

    func isSubscribed(_ show: Show) -> Bool { library.isSubscribed(show) }

    func toggleSubscription(_ show: Show) {
        if library.isSubscribed(show) { library.unsubscribe(show) } else { library.subscribe(show) }
        persist()
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

    func cachedFeed(for show: Show) -> Feed? { feedCache[show.id] }

    /// Fetches a feed, sharing in-flight requests and caching for this session.
    func feed(for show: Show, force: Bool = false) async throws -> Feed {
        if !force, let cached = feedCache[show.id] { return cached }
        if let running = feedTasks[show.id] { return try await running.value }
        let feeds = self.feeds
        let task = Task { try await feeds.fetch(show.feedURL) }
        feedTasks[show.id] = task
        defer { feedTasks[show.id] = nil }
        let feed = try await task.value
        feedCache[show.id] = feed
        return feed
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

    /// Opens Now Playing, closing the search sheet first if it is up
    /// (two modal presentations can't stack from the root).
    private func presentPlayer() {
        guard isSearchPresented else {
            isPlayerPresented = true
            return
        }
        isSearchPresented = false
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            self?.isPlayerPresented = true
        }
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
