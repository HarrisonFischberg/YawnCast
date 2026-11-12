import Foundation
import YawnCastCore
import Observation
import SwiftUI
import UIKit

/// Screens pushed on the main navigation stack.
enum Route: Hashable {
    case show(Show)
    case category(PodcastCategory)
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

    /// The colour: a Scene or one of the four flat colours.
    var theme: Theme {
        didSet {
            library.themeID = theme.id
            persist()
        }
    }

    /// The text style (Picture Book or Sign-Off), worn over whichever colour is chosen.
    var look: ThemeStyle {
        didSet {
            Typo.style = look
            library.lookID = look.rawValue
            persist()
        }
    }


    var isPlayerPresented = false {
        didSet { if !isPlayerPresented { preview = nil } }
    }
    /// An episode opened while another plays: Now Playing shows it, and the
    /// current one keeps playing until Play is pressed here. Cleared on close.
    private(set) var preview: Episode?
    var isThemesPresented = false
    /// Main navigation stack (show detail, search).
    var path: [Route] = []
    /// Which home page is showing. Library is the middle page.
    var homePage: HomePage = .library
    /// Which home page is searching in place (nil = not searching).
    private(set) var searchingOn: HomePage?
    /// One shared search (query, debounce, results) used by whichever page is searching.
    @ObservationIgnored let search: SearchModel
    /// Focus the field when search opens, but not when coming back from a show page.
    @ObservationIgnored var focusSearchOnAppear = false

    /// "New" page: recent episodes from Library shows, newest first.
    private(set) var latest: [Episode] = []
    /// `latest` by show id, so each Library tile's "new" dot doesn't re-key every episode.
    private(set) var latestByShow: [String: [Episode]] = [:]
    private(set) var latestPhase: LoadPhase = .idle
    /// Library feeds checked so far in the current New refresh.
    private(set) var latestChecked = 0
    /// "Explore" page: suggestions grouped by the Library's top genres.
    private(set) var explore: [ExploreSection] = []
    private(set) var explorePhase: LoadPhase = .idle
    /// "Your interests" chips on Explore, from the genres and titles of saved shows.
    private(set) var interests: [PodcastCategory] = []
    /// Brief confirmation shown above the Moon key.
    private(set) var toast: String?
    /// "Added to your library" pill at the top of the screen after a + tap.
    private(set) var addedNote: String?
    /// The show just unsubscribed and the slot it sat in, while its Undo toast is up.
    private(set) var unsubscribed: (show: Show, index: Int)?
    /// Search opened on an empty Library finds new shows; otherwise Library search only filters saved ones.
    private(set) var searchFindsNew = false
    /// Note shown in the toast slot when Sleep turned itself on late at night.
    private(set) var nightNote: String?
    /// Local hour, 0-23. Replaced in Debug by `-nightHour` (TestSupport/DebugLaunch.swift).
    @ObservationIgnored var currentHour: () -> Int = { Calendar.current.component(.hour, from: Date()) }
    private(set) var sleepStatus: SleepStatus = .off
    /// Drift back: where Sleep's fade began on an episode it then
    /// faded out and paused. In memory only; cleared by the jump or a different episode.
    private(set) var driftBack: DriftBackMarker?

    @ObservationIgnored private let store: LibraryStore
    @ObservationIgnored private let sleep: SleepController
    @ObservationIgnored private var nowPlaying: NowPlayingBridge?
    @ObservationIgnored private var sleepTicker: Task<Void, Never>?
    /// Wake extend: the episode Sleep last faded out on, and when. In memory only.
    @ObservationIgnored private var fadedOut: (episodeID: String, at: Date)?
    @ObservationIgnored private var wasPlaying = false
    @ObservationIgnored private let wakeExtendWindow: TimeInterval = 10 * 60
    /// Drift back: the fade start of the current Sleep, kept until it pauses the episode.
    @ObservationIgnored private var fadeBegan: DriftBackMarker?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var addedNoteTask: Task<Void, Never>?
    @ObservationIgnored private var undoTask: Task<Void, Never>?
    @ObservationIgnored private var nightNoteTask: Task<Void, Never>?
    /// The episode load the late-night check already ran for, so turning Sleep off sticks.
    @ObservationIgnored private var nightCheckedEpisodeID: String?
    @ObservationIgnored private var feedCache: [String: Feed] = [:]
    @ObservationIgnored private var feedTasks: [String: Task<Feed, Error>] = [:]
    /// Feeds fetched from the network this session (the disk cache may be older).
    @ObservationIgnored private var freshFeeds: Set<String> = []
    @ObservationIgnored private let feedDisk = FeedDiskCache()
    /// The launch read of the disk copies; the New refresh waits for it so it merges onto them.
    @ObservationIgnored private var diskLoad: Task<Void, Never>?
    /// Library shows (by id) that the current Explore results were computed from.
    @ObservationIgnored private var exploreBasis: [String] = []
    @ObservationIgnored private var categoryCache: [String: [DirectoryResult]] = [:]

    init(store: LibraryStore, directory: DirectoryService, feeds: FeedService, clock: PlaybackClock = SystemPlaybackClock(), sleepConfiguration: SleepConfiguration = .standard) {
        self.store = store
        self.directory = directory
        self.feeds = feeds
        search = SearchModel(directory: directory)
        var snapshot = store.load()
        // v0.17: a colour (a Scene or one of four flat colours) and a text style (Picture
        // Book or Sign-Off). Retired colours move to the nearest one; text starts as Picture Book.
        if (snapshot.appearanceVersion ?? 0) < 8 {
            snapshot.themeID = Theme.migrated(from: snapshot.themeID).id
            if ThemeStyle(rawValue: snapshot.lookID ?? "") == nil { snapshot.lookID = ThemeStyle.pictureBook.rawValue }
            snapshot.appearanceVersion = 8
            try? store.save(snapshot)
        }
        // v0.18: everyone starts on the Midnight scene once (new installs and existing
        // ones); a colour picked after that sticks.
        if (snapshot.appearanceVersion ?? 0) < 9 {
            snapshot.themeID = Theme.midnight.id
            snapshot.appearanceVersion = 9
            try? store.save(snapshot)
        }
        library = snapshot
        theme = Theme.with(id: snapshot.themeID)
        let savedLook = ThemeStyle(rawValue: snapshot.lookID ?? "") ?? .pictureBook
        look = savedLook
        Typo.style = savedLook
        player = PlaybackEngine()
        sleep = SleepController(clock: clock, configuration: sleepConfiguration)
        nowPlaying = NowPlayingBridge(engine: player)
        installLockStatus()

        player.onProgress = { [weak self] episode, position, duration, finished in
            self?.recordProgress(episode: episode, position: position, duration: duration, finished: finished)
        }
        player.onStateChange = { [weak self] in
            guard let self else { return }
            sleep.sync()
            sleepStatus = sleep.status
            nowPlaying?.update()
            lockStatusPushed = lockStatusLine()
            runSleepTicker()
            let started = player.isPlaying && !wasPlaying
            wakeExtendIfNeeded()
            // Night auto covers every way playback starts: mini player, Now Playing,
            // Lock Screen, headphones, and a relaunch's restored episode.
            if started, let episode = player.episode { armSleepIfLate(for: episode) }
        }
        player.onEnded = { [weak self] in
            self?.sleep.episodeDidEnd()
        }
        player.onDurationMeasured = { [weak self] episode, duration in
            self?.sleep.measuredDurationArrived(duration, episodeID: episode.id)
        }
        sleep.onFadeBegan = { [weak self] episodeID, secondsAgo in
            guard let self else { return }
            fadeBegan = DriftBackMarker(episodeID: episodeID, position: max(0, player.position - secondsAgo))
        }
        sleep.onFadedToSilence = { [weak self] episodeID in
            guard let self else { return }
            fadedOut = (episodeID, Date())
            // Sleep finished on its own, so a later late-night play arms it again.
            // Only turning Sleep off by hand sticks for the load.
            if nightCheckedEpisodeID == episodeID { nightCheckedEpisodeID = nil }
            guard let began = fadeBegan, began.episodeID == episodeID else { return }
            fadeBegan = nil
            driftBack = began
        }
        sleep.onChange = { [weak self] in
            guard let self else { return }
            sleepStatus = sleep.status
            refreshLockStatus()
        }

        // Restore the last episode paused at its saved position. Never autoplay;
        // never restore Sleep.
        if let last = snapshot.lastEpisode {
            player.load(last, start: SeekMath.resumeTime(saved: snapshot.position(for: last), duration: last.duration), autoplay: false)
        }
        loadDiskFeeds(snapshot.subscriptions)
    }

    // MARK: Library

    func isSubscribed(_ show: Show) -> Bool { library.isSubscribed(show) }

    func toggleSubscription(_ show: Show) {
        if library.isSubscribed(show) {
            unsubscribe(show)
        } else if unsubscribed?.show.id == show.id {
            // Subscribing again while its toast is up is an undo: back in its old slot.
            undoUnsubscribe()
        } else {
            library.subscribe(show)
            persist()
        }
        recomputeLatestFromCache()
    }

    /// The + on a search or category row: saves the show and confirms briefly.
    func add(_ show: Show) {
        guard !isSubscribed(show) else { return }
        toggleSubscription(show)
        let note = "Added to your library"
        addedNote = note
        UIAccessibility.post(notification: .announcement, argument: note)
        addedNoteTask?.cancel()
        addedNoteTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self?.addedNote = nil
        }
    }

    /// Large / Small / List. Saved with the Library.
    var libraryLayout: LibraryLayout {
        get { library.libraryLayout ?? .large }
        set {
            library.libraryLayout = newValue
            persist()
        }
    }

    func moveSubscription(id: String, onto targetID: String) {
        if library.moveSubscription(id: id, onto: targetID) { persist() }
    }

    func moveToTop(_ show: Show) {
        guard let first = library.subscriptions.first, first.id != show.id else { return }
        withAnimation(Motion.moveUnlessReduced) { moveSubscription(id: show.id, onto: first.id) }
    }

    func moveToEnd(_ show: Show) {
        guard let last = library.subscriptions.last, last.id != show.id else { return }
        withAnimation(Motion.moveUnlessReduced) { moveSubscription(id: show.id, onto: last.id) }
    }

    func unsubscribe(_ show: Show) {
        let index = library.subscriptions.firstIndex { $0.id == show.id }
        library.unsubscribe(show)
        persist()
        recomputeLatestFromCache()
        if library.subscriptions.isEmpty { homePage = .library }
        if searchingOn != nil && searchingOn != .library && library.subscriptions.isEmpty { endSearch() }
        guard let index else { return }
        // Saved spots are kept, so Undo loses nothing.
        unsubscribed = (show, index)
        UIAccessibility.post(notification: .announcement, argument: "Unsubscribed from \(show.title). Undo is at the bottom of the screen.")
        undoTask?.cancel()
        undoTask = Task { [weak self] in
            try? await Task.sleep(for: Motion.undoLife)
            guard !Task.isCancelled else { return }
            self?.unsubscribed = nil
        }
    }

    /// The Undo on the toast: the show goes back into the slot it left.
    func undoUnsubscribe() {
        guard let undo = unsubscribed else { return }
        undoTask?.cancel()
        unsubscribed = nil
        guard !library.isSubscribed(undo.show) else { return }
        library.subscriptions.insert(undo.show, at: min(undo.index, library.subscriptions.count))
        persist()
        recomputeLatestFromCache()
        UIAccessibility.post(notification: .announcement, argument: "Subscribed again")
    }

    /// Search in place on the current home page: its content glides away and results appear.
    func openSearch() {
        let page = library.subscriptions.isEmpty ? HomePage.library : homePage
        searchFindsNew = page != .library || library.subscriptions.isEmpty
        // Pick up where the last search left off, even across launches.
        if search.query.isEmpty { search.query = UserDefaults.standard.string(forKey: "lastSearch") ?? "" }
        // Closing search mid-request cancels it; ask again so the kept query isn't left "Searching…".
        if searchFindsNew { search.retry() }
        focusSearchOnAppear = true
        withAnimation(.smooth(duration: 0.42)) { searchingOn = page }
    }

    func endSearch() {
        search.cancel()
        // The query stays, so reopening search shows the last one.
        withAnimation(.smooth(duration: 0.42)) { searchingOn = nil; searchFindsNew = false }
    }

    /// Marks an episode played or unplayed without playing it.
    func setPlayed(_ episode: Episode, _ played: Bool) {
        let duration = library.position(for: episode)?.duration ?? episode.duration
        library.setPosition(PlaybackPosition(seconds: played ? (duration ?? 0) : 0, duration: duration, completed: played), for: episode)
        persist()
    }

    /// True when the show has an unplayed episode from the last 7 days.
    func hasNewEpisode(_ show: Show) -> Bool {
        let weekAgo = Date().addingTimeInterval(-7 * 86_400)
        return latestByShow[show.id]?.contains { episode in
            (episode.published ?? .distantPast) >= weekAgo && library.position(for: episode) == nil
        } ?? false
    }

    func position(for episode: Episode) -> PlaybackPosition? { library.position(for: episode) }

    /// Updates stored metadata (title, artwork, summary) for a subscribed show.
    func refreshSubscription(_ show: Show) {
        guard let index = library.subscriptions.firstIndex(where: { $0.id == show.id }),
              library.subscriptions[index] != show else { return }
        library.subscriptions[index] = show
        persist()
    }

    // MARK: Feeds

    /// Last known feed: from this session, or from the disk cache of an earlier one
    /// (Library shows only, loaded in the background at launch).
    func cachedFeed(for show: Show) -> Feed? { feedCache[show.id] }

    /// Reads Library shows' disk copies off the main thread, then fills in the New page.
    private func loadDiskFeeds(_ shows: [Show]) {
        let disk = feedDisk
        let urls = shows.map(\.feedURL)
        diskLoad = Task { [weak self] in
            let loaded = await Task.detached { urls.compactMap { disk.load($0) } }.value
            guard let self else { return }
            // A network fetch that finished first is newer; keep it.
            for feed in loaded where feedCache[feed.show.id] == nil { feedCache[feed.show.id] = feed }
            recomputeLatestFromCache()
        }
    }

    /// Fetches a feed from the network once per session (or again when forced),
    /// sharing in-flight requests. Successful fetches are saved to disk.
    /// `firstPageOnly` (the New page) skips the older pages of a paged feed and keeps
    /// the cached history under the fresh page; the show page then still fetches it all.
    func feed(for show: Show, force: Bool = false, firstPageOnly: Bool = false) async throws -> Feed {
        if !force, freshFeeds.contains(show.id), let cached = feedCache[show.id] { return cached }
        // A first-page fetch must not answer a caller that wants the whole history.
        let firstPageKey = show.id + "|first"
        if let running = feedTasks[show.id] ?? (firstPageOnly ? feedTasks[firstPageKey] : nil) { return try await running.value }
        let feeds = self.feeds
        let task = Task { try await feeds.fetch(show.feedURL, maxPages: firstPageOnly ? 1 : HTTPFeedService.maxPages) }
        let taskKey = firstPageOnly ? firstPageKey : show.id
        feedTasks[taskKey] = task
        defer { feedTasks[taskKey] = nil }
        var feed = try await task.value
        if firstPageOnly, feed.nextPageURL != nil {
            if let old = feedCache[show.id] {
                let ids = Set(feed.episodes.map(\.id))
                feed.episodes = Feed.sortedNewestFirst(feed.episodes + old.episodes.filter { !ids.contains($0.id) })
            }
        } else {
            freshFeeds.insert(show.id)
        }
        feedCache[show.id] = feed
        let disk = feedDisk
        Task.detached { [feed] in disk.save(feed) }
        return feed
    }

    // MARK: New page

    private static let latestWindow: TimeInterval = 30 * 86_400

    private func recomputeLatestFromCache() {
        let feeds = library.subscriptions.compactMap { cachedFeed(for: $0) }
        latest = LatestEpisodes.collect(from: feeds, since: Date().addingTimeInterval(-Self.latestWindow))
        latestByShow = Dictionary(grouping: latest) { FeedURL.key($0.showFeedURL) }
    }

    /// Shows cached episodes at once, then refreshes every Library feed (4 at a time).
    func refreshLatest(force: Bool = false) async {
        await diskLoad?.value
        recomputeLatestFromCache()
        let shows = library.subscriptions
        guard !shows.isEmpty else {
            latestPhase = .loaded
            return
        }
        if latest.isEmpty { latestPhase = .loading }
        var failures = 0
        var index = 0
        latestChecked = 0
        while index < shows.count {
            let batch = shows[index..<min(shows.count, index + 4)]
            index += batch.count
            // Unstructured child tasks inherit the main actor; the network
            // waits overlap, so a batch fetches concurrently.
            let tasks = batch.map { show in
                Task { (try? await self.feed(for: show, force: force, firstPageOnly: true)) != nil }
            }
            for task in tasks {
                if !(await task.value) { failures += 1 }
                latestChecked += 1
            }
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
            interests = []
            exploreBasis = basis
            explorePhase = .loaded
            return
        }
        if explore.isEmpty { explorePhase = .loading }
        do {
            let records = try await directory.lookup(ids: ids)
            let taste = Recommender.taste(from: records)
            interests = PodcastCategory.interests(
                taste: taste,
                keywords: Recommender.keywords(fromTitles: library.subscriptions.map(\.title))
            )
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
            if explore.isEmpty { explorePhase = .failed(SearchModel.message(for: error, fallback: "Something went wrong. Try again.")) }
        }
    }

    // MARK: Playback

    /// Tap on an episode row: load it paused at its saved spot and show Now Playing,
    /// where the listener presses Play. The loaded episode is left as it is.
    /// While something else plays, it only previews, so the audio isn't cut off.
    func open(_ episode: Episode) {
        preview = nil
        if player.episode?.id != episode.id {
            if player.isPlaying || player.isBuffering { preview = episode } else { load(episode, autoplay: false) }
        }
        presentPlayer()
    }

    /// The menu's Play: start or resume an episode. A different episode cancels Sleep.
    func play(_ episode: Episode) {
        if player.episode?.id == episode.id {
            if !player.isPlaying { player.play() }
        } else {
            load(episode, autoplay: true)
        }
        armSleepIfLate(for: episode)
        presentPlayer()
    }

    private func load(_ episode: Episode, autoplay: Bool) {
        preview = nil
        sleep.episodeWillChange(to: episode.id)
        clearDriftBack()
        let start = SeekMath.resumeTime(saved: library.position(for: episode), duration: episode.duration)
        player.load(episode, start: start, autoplay: autoplay)
        library.lastEpisode = episode
        persist()
        nightCheckedEpisodeID = nil
    }

    /// Night auto: between 22:00 and 04:59, the first play of an episode load turns
    /// Sleep on, wherever it starts. Runs after a different episode cancels Sleep (D07).
    private func armSleepIfLate(for episode: Episode) {
        guard nightCheckedEpisodeID != episode.id, Self.isLate(hour: currentHour()) else { return }
        nightCheckedEpisodeID = episode.id
        guard sleepStatus == .off, player.episode?.id == episode.id else { return }
        toggleSleep(announcing: false)
        guard case .waiting(let delay) = sleepStatus else { return }
        showNightNote(fadeDelay: delay)
    }

    static func isLate(hour: Int) -> Bool { hour >= 22 || hour < 5 }

    static let nightNoteCopy = "It’s late, so Sleep is on."

    private func showNightNote(fadeDelay: TimeInterval) {
        nightNote = Self.nightNoteCopy
        nightNoteTask?.cancel()
        nightNoteTask = Task { [weak self] in
            // One message for VoiceOver, after Now Playing has taken focus.
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            self?.announce("\(Self.nightNoteCopy) Fade begins in \(TimeFormat.sleepDelay(fadeDelay)).")
            try? await Task.sleep(for: .seconds(3.3))
            guard !Task.isCancelled else { return }
            self?.nightNote = nil
        }
    }

    /// Shows for an Explore category: the genre's top 50 in chart order, or a
    /// topic search. Cached for the session.
    func shows(in category: PodcastCategory, force: Bool = false) async throws -> [DirectoryResult] {
        if !force, let cached = categoryCache[category.id] { return cached }
        let results: [DirectoryResult]
        switch category.source {
        case .genre(let genreID):
            let ids = try await directory.topShowIDs(genreID: genreID, limit: 50)
            let records = try await directory.lookup(ids: ids)
            let byID = Dictionary(records.map { ($0.directoryID, $0) }, uniquingKeysWith: { first, _ in first })
            results = ids.compactMap { byID[$0] }
        case .search(let term):
            results = try await directory.search(term)
        }
        categoryCache[category.id] = results
        return results
    }

    private func presentPlayer() {
        isPlayerPresented = true
    }

    // MARK: Drift back

    /// Where to offer "Back to …" on Now Playing: the loaded episode's fade start,
    /// only once Sleep has paused it and while Sleep is off.
    var driftBackPosition: TimeInterval? {
        guard let marker = driftBack, sleepStatus == .off, marker.episodeID == player.episode?.id else { return nil }
        return marker.position
    }

    /// Seeks (paused stays paused) to where the fade began, then forgets the marker.
    func jumpToDriftBack() {
        guard let position = driftBackPosition else { return }
        player.seek(to: position)
        driftBack = nil
    }

    /// A different episode loaded: forget the drift-back marker and the wake-extend fade (D07).
    private func clearDriftBack() {
        fadeBegan = nil
        fadedOut = nil
        if driftBack != nil { driftBack = nil }
    }

    // MARK: Sleep

    /// Play again soon after Sleep faded the same episode out: Sleep comes back on, once.
    private func wakeExtendIfNeeded() {
        let playing = player.isPlaying
        defer { wasPlaying = playing }
        guard playing, !wasPlaying, let faded = fadedOut else { return }
        fadedOut = nil
        guard sleepStatus == .off,
              player.episode?.id == faded.episodeID,
              Date().timeIntervalSince(faded.at) <= wakeExtendWindow else { return }
        toggleSleep(backOn: true)
    }

    func toggleSleep(backOn: Bool = false, announcing: Bool = true) {
        guard let episode = player.episode else { return }
        if nightNote != nil {
            nightNoteTask?.cancel()
            nightNote = nil
        }
        let remaining = SeekMath.remaining(position: player.position, duration: player.duration)
        if let delay = sleep.toggle(
            player: player,
            episodeID: episode.id,
            remaining: remaining,
            position: player.position,
            durationIsProvisional: !player.isDurationMeasured
        ) {
            // The countdown bubble shows this; VoiceOver hears it.
            if announcing { announce(backOn ? SleepCopy.backOn(fadeDelay: delay) : SleepCopy.activated(fadeDelay: delay)) }
        } else {
            show(toast: SleepCopy.cancelled)
        }
        sleepStatus = sleep.status
        runSleepTicker()
    }

    /// Increments on each ±5 tap (drives a haptic tick).
    private(set) var sleepAdjustCount = 0

    /// The ±5 minute bubble above the Moon key.
    func adjustSleep(minutes: Int) {
        guard sleep.adjust(by: TimeInterval(minutes) * 60) else { return }
        sleepAdjustCount += 1
        sleepStatus = sleep.status
        if case .waiting(let t) = sleepStatus {
            announce("Fade begins in \(TimeFormat.sleepDelay(t))")
        }
        runSleepTicker()
    }

    // MARK: Lock Screen Sleep status

    /// The last Sleep line pushed to the Lock Screen; Sleep ticks only push when it changes.
    @ObservationIgnored private var lockStatusPushed: String?

    private func installLockStatus() {
        lockStatusPushed = nil
        nowPlaying?.artistLine = { [weak self] show in
            LockScreenSleepText.subtitle(show: show, status: self?.sleepStatus ?? .off)
        }
        nowPlaying?.update()
    }

    private func lockStatusLine() -> String {
        LockScreenSleepText.subtitle(show: "", status: sleepStatus)
    }

    /// Called on every Sleep change (4 Hz while counting down). Pushes only when the
    /// whole-minute text or the Sleep phase changed.
    private func refreshLockStatus() {
        let line = lockStatusLine()
        guard line != lockStatusPushed else { return }
        lockStatusPushed = line
        nowPlaying?.update()
    }

    private func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
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
        library.setPosition(PlaybackPosition(seconds: position, duration: duration, completed: finished), for: episode)
        persist()
    }

    private func persist() {
        do { try store.save(library) } catch { print("YawnCast: save failed: \(error)") }
    }

    #if DEBUG
    // MARK: Demo seeding (screenshots / UI tests only, via launch arguments)

    func seedForDemo(_ shows: [Show]) {
        for show in shows where !library.isSubscribed(show) { library.subscribe(show) }
        persist()
    }

    func loadForDemo(_ episode: Episode, position: TimeInterval) {
        clearDriftBack()
        player.load(episode, start: position, autoplay: false)
        library.lastEpisode = episode
        persist()
    }

    func activateSleepForDemo() {
        toggleSleep()
    }
    #endif
}

/// A playback position on one episode (drift back: where Sleep's fade began).
struct DriftBackMarker: Equatable {
    let episodeID: String
    let position: TimeInterval
}
