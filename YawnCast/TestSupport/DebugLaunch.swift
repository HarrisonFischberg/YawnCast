#if DEBUG
import Foundation
import YawnCastCore

/// Debug-only launch handling. Excluded from Release builds (see DECISIONS D15/D20).
enum DebugLaunch {
    static func makeModel(arguments: [String]) -> AppModel {
        let launch = LaunchOptions(arguments: arguments)
        let store: LibraryStore
        let directory: DirectoryService
        let feeds: FeedService
        if launch.isUITest {
            store = JSONLibraryStore.uiTest(reset: launch.resetStore)
            directory = FixtureDirectory()
            feeds = FixtureFeedService()
        } else {
            store = (launch.isDemo || launch.isLiveTest) ? MemoryLibraryStore() : JSONLibraryStore.standard()
            directory = ITunesDirectory()
            feeds = HTTPFeedService()
        }
        let sleepConfiguration = launch.fastSleep
            ? SleepConfiguration(maxFadeDelay: 4, stepInterval: 3, stepRamp: 1, cancelRamp: 0.5)
            : .standard
        let model = AppModel(store: store, directory: directory, feeds: feeds, sleepConfiguration: sleepConfiguration)
        if let theme = launch.themeID {
            model.theme = Theme.migrated(from: theme)
        }
        if let look = launch.lookID.flatMap(ThemeStyle.init(rawValue:)) { model.look = look }
        // UI tests run at noon unless they ask for a time, so late-night Sleep can't arm by surprise.
        if let hour = launch.nightHour ?? (launch.isUITest ? 12 : nil) { model.currentHour = { hour } }
        // UI tests skip the first-run intro and first-show sheet unless they ask for them.
        if launch.isUITest {
            let firstRun = arguments.contains("-firstRun")
            UserDefaults.standard.set(!firstRun, forKey: "didOnboard")
            UserDefaults.standard.set(!firstRun, forKey: "celebratedFirstShow")
            if launch.resetStore { UserDefaults.standard.removeObject(forKey: "lastSearch") }
        }
        if launch.isDemo { DemoSeed.run(model: model, launch: launch) }
        return model
    }
}

struct LaunchOptions {
    var isDemo = false
    var themeID: String?
    /// `-look <style>`: the style, independent of `-theme` (the colour).
    var lookID: String?
    var openPlayer = false
    var sleepOn = false
    var fastSleep = false
    var autoplay = false
    var isUITest = false
    var resetStore = false
    /// Real network services with a throwaway in-memory library (live UI test).
    var isLiveTest = false
    var openShow = false
    var searchTerm: String?
    var page: HomePage?
    var layout: LibraryLayout?
    var categoryName: String?
    /// `-nightHour <0-23>`: fakes the local hour for late-night Sleep.
    var nightHour: Int?

    init(arguments: [String]) {
        isDemo = arguments.contains("-demo")
        openPlayer = arguments.contains("-openPlayer")
        sleepOn = arguments.contains("-sleepOn")
        fastSleep = arguments.contains("-fastSleep")
        autoplay = arguments.contains("-autoplay")
        isUITest = arguments.contains("-uitest")
        resetStore = arguments.contains("-resetStore")
        isLiveTest = arguments.contains("-liveTest")
        openShow = arguments.contains("-openShow")
        if let i = arguments.firstIndex(of: "-search"), i + 1 < arguments.count { searchTerm = arguments[i + 1] }
        if let i = arguments.firstIndex(of: "-layout"), i + 1 < arguments.count { layout = LibraryLayout(rawValue: arguments[i + 1]) }
        if let i = arguments.firstIndex(of: "-category"), i + 1 < arguments.count { categoryName = arguments[i + 1] }
        if let i = arguments.firstIndex(of: "-page"), i + 1 < arguments.count {
            page = HomePage.allCases.first { $0.title.lowercased() == arguments[i + 1].lowercased() }
        }
        if let i = arguments.firstIndex(of: "-nightHour"), i + 1 < arguments.count,
           let hour = Int(arguments[i + 1]), (0...23).contains(hour) { nightHour = hour }
        if let i = arguments.firstIndex(of: "-theme"), i + 1 < arguments.count { themeID = arguments[i + 1] }
        if let i = arguments.firstIndex(of: "-look"), i + 1 < arguments.count { lookID = arguments[i + 1] }
    }
}

/// Seeds a throwaway in-memory library with real directory shows, loads a
/// real episode from a real feed, for screenshots. Only runs with `-demo`.
enum DemoSeed {
    static let shows: [Show] = [
        Show(feedURL: URL(string: "https://feeds.megaphone.fm/SSM2868305742")!, directoryID: 1378040733, title: "Nothing much happens: bedtime stories to help you sleep", author: "Wellness Loud", artworkURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts221/v4/87/f2/26/87f226c9-77ac-d4fe-6b98-4da2345de5c0/mza_5833691041544808336.jpg/600x600bb.jpg")),
        Show(feedURL: URL(string: "https://feeds.simplecast.com/EmVW7VGp")!, directoryID: 152249110, title: "Radiolab", author: "WNYC Studios", artworkURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts211/v4/2b/b2/4d/2bb24d28-f3bb-916f-6bf3-9e125ba5219b/mza_4476298389845914795.jpg/600x600bb.jpg")),
        Show(feedURL: URL(string: "https://feeds.simplecast.com/BqbsxVfO")!, directoryID: 394775318, title: "99% Invisible", author: "Roman Mars", artworkURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts211/v4/79/d0/35/79d035ea-9043-b43e-7380-33cd47bd968b/mza_2606971010425550919.jpg/600x600bb.jpg")),
        Show(feedURL: URL(string: "https://rss.pdrl.fm/5d8327/feed.sleepwithmepodcast.com/")!, directoryID: 740675898, title: "Sleep With Me", author: "Silver Sleeper Productions LLC", artworkURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts112/v4/a6/2d/96/a62d9642-5efe-e042-3673-e242aa1346fd/mza_13039729790115515983.jpg/600x600bb.jpg")),
        Show(feedURL: URL(string: "http://feeds.feedburner.com/themothpodcast")!, directoryID: 275699983, title: "The Moth", author: "The Moth", artworkURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts221/v4/16/39/63/1639632d-7ad2-d87b-d4f7-d0ec95eff386/mza_8915289722686017414.jpg/600x600bb.jpg")),
        Show(feedURL: URL(string: "https://feeds.feedburner.com/dancarlin/history?format=xml")!, directoryID: 173001861, title: "Dan Carlin's Hardcore History", author: "Dan Carlin", artworkURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts115/v4/49/b7/eb/49b7eb32-8f08-6fac-aadb-2f002131fe5f/mza_15196161972010256532.jpg/600x600bb.jpg")),
    ]

    static func run(model: AppModel, launch: LaunchOptions, arguments: [String] = ProcessInfo.processInfo.arguments) {
        model.seedForDemo(shows)
        if launch.openShow { model.path = [.show(shows[0])] }
        if let page = launch.page { model.homePage = page }
        if let layout = launch.layout { model.libraryLayout = layout }
        if arguments.contains("-themes") { model.isThemesPresented = true }
        if let name = launch.categoryName, let category = PodcastCategory.browse.first(where: { $0.name == name }) {
            model.path = [.category(category)]
        }
        if let term = launch.searchTerm {
            model.openSearch()
            model.search.query = term
        }
        Task {
            do {
                let feed = try await model.feeds.fetch(shows[1].feedURL)
                guard let episode = feed.episodes.first else { return }
                if launch.autoplay {
                    model.play(episode)
                } else {
                    model.loadForDemo(episode, position: 14 * 60 + 22)
                }
                if launch.openPlayer { model.isPlayerPresented = true }
                if launch.sleepOn {
                    try? await Task.sleep(for: .seconds(1))
                    model.activateSleepForDemo()
                }
            } catch {
                print("YawnCast demo: feed failed: \(error)")
            }
        }
    }
}
#endif
