import Foundation
import Testing
@testable import YawnCastCore

private func result(_ id: Int, _ title: String, genres: [(String, String)]) -> DirectoryResult {
    DirectoryResult(
        directoryID: id, title: title, author: nil, artworkURL: nil,
        feedURL: URL(string: "https://feeds.example.com/\(id)")!,
        genres: genres.map { Genre(id: $0.0, name: $0.1) }
    )
}

@Suite("Directory genres and charts")
struct DirectoryGenreTests {
    @Test func lookupDecodesGenresWithoutUmbrella() throws {
        let json = """
        {"resultCount":1,"results":[{"collectionId":7,"collectionName":"Moths","feedUrl":"https://m.example/rss",
        "genreIds":["1483","26","1512"],"genres":["Fiction","Podcasts","Health & Fitness"]}]}
        """
        let results = try ITunesDirectory.decode(Data(json.utf8))
        #expect(results.first?.genres == [Genre(id: "1483", name: "Fiction"), Genre(id: "1512", name: "Health & Fitness")])
    }

    @Test func chartDecodesArrayInOrderAndDedupes() throws {
        let json = """
        {"feed":{"entry":[{"id":{"attributes":{"im:id":"30"}}},{"id":{"attributes":{"im:id":"10"}}},{"id":{"attributes":{"im:id":"30"}}},{"id":{}}]}}
        """
        #expect(try ITunesDirectory.decodeChart(Data(json.utf8)) == [30, 10])
    }

    @Test func chartDecodesSingleObjectAndEmpty() throws {
        #expect(try ITunesDirectory.decodeChart(Data(#"{"feed":{"entry":{"id":{"attributes":{"im:id":"5"}}}}}"#.utf8)) == [5])
        #expect(try ITunesDirectory.decodeChart(Data(#"{"feed":{}}"#.utf8)) == [])
        #expect(throws: DirectoryError.badResponse) { try ITunesDirectory.decodeChart(Data("nope".utf8)) }
    }

    @Test func chartURLSanitizesGenre() {
        #expect(ITunesDirectory.chartURL(country: "US", genreID: "1483", limit: 500)?.absoluteString
                == "https://itunes.apple.com/us/rss/toppodcasts/limit=100/genre=1483/json")
        #expect(ITunesDirectory.chartURL(country: "US", genreID: "../x", limit: 5) == nil)
    }
}

@Suite("Recommender")
struct RecommenderTests {
    let fiction = Genre(id: "1483", name: "Fiction")
    let health = Genre(id: "1512", name: "Health & Fitness")
    let science = Genre(id: "1533", name: "Science")

    var library: [DirectoryResult] {
        [
            result(1, "Nothing Much", genres: [("1512", "Health & Fitness"), ("1483", "Fiction")]),
            result(2, "Story Hour", genres: [("1483", "Fiction")]),
            result(3, "Radio Science", genres: [("1533", "Science")]),
        ]
    }

    @Test func tasteWeightsPrimaryDouble() {
        let taste = Recommender.taste(from: library)
        #expect(taste.map(\.genre.name) == ["Fiction", "Health & Fitness", "Science"])
        #expect(taste.map(\.weight) == [3, 2, 2])
    }

    @Test func rankExcludesLibraryAndOrdersByOverlapThenChart() {
        let taste = Recommender.taste(from: library)
        let candidates: [(result: DirectoryResult, chartRank: Int)] = [
            (result(1, "Nothing Much (owned)", genres: [("1483", "Fiction")]), 0),
            (result(10, "Sci Pod", genres: [("1533", "Science")]), 0),
            (result(11, "Fiction + Health", genres: [("1483", "Fiction"), ("1512", "Health & Fitness")]), 9),
            (result(12, "Fiction Only", genres: [("1483", "Fiction")]), 1),
            (result(13, "Comedy", genres: [("1303", "Comedy")]), 0),
        ]
        let owned = library.map(\.show)
        let ranked = Recommender.rank(candidates: candidates, taste: taste, excluding: owned)
        #expect(ranked.map(\.result.directoryID) == [11, 12, 10])
        #expect(ranked.first?.reason == fiction)
        #expect(!ranked.contains { $0.result.directoryID == 13 }, "no shared genre → not suggested")
    }

    @Test func sameShowFromTwoChartsKeepsBestScore() {
        let taste = Recommender.taste(from: library)
        let dup = result(20, "Twice", genres: [("1483", "Fiction")])
        let ranked = Recommender.rank(candidates: [(dup, 40), (dup, 0)], taste: taste, excluding: [])
        #expect(ranked.count == 1)
        #expect(ranked[0].score == 3 + 0.5)
    }

    @Test func keywordsNeedTwoShows() {
        let words = Recommender.keywords(fromTitles: ["Nothing much happens: bedtime stories to help you sleep", "Sleep With Me", "Radiolab"])
        #expect(words == ["sleep": 2])
        #expect(Recommender.tokens("The Daily Podcast") == [])
    }

    @Test func keywordOverlapLiftsAndAdmitsCandidates() {
        let taste = [GenreWeight(genre: Genre(id: "1512", name: "Health & Fitness"), weight: 4)]
        let candidates: [(result: DirectoryResult, chartRank: Int)] = [
            (result(40, "Mindset Coaching", genres: [("1512", "Health & Fitness")]), 0),
            (result(41, "Sleep Stories", genres: [("1512", "Health & Fitness")]), 20),
            (result(42, "Deep Sleep Sounds", genres: [("1310", "Music")]), 5),
        ]
        let ranked = Recommender.rank(candidates: candidates, taste: taste, keywords: ["sleep": 2], excluding: [])
        #expect(ranked.map(\.result.directoryID) == [41, 40, 42])
        #expect(ranked.last?.reason == nil, "keyword-only match has no genre reason")
    }

    @Test func sectionsLeadWithTopPicksThenGenresWithoutRepeats() {
        let taste = Recommender.taste(from: library)
        let candidates: [(result: DirectoryResult, chartRank: Int)] = (0..<8).map { i in
            (result(100 + i, "F\(i)", genres: [("1483", "Fiction")]), i)
        } + [(result(200, "S1", genres: [("1533", "Science")]), 0)]
        let sections = Recommender.sections(Recommender.rank(candidates: candidates, taste: taste, excluding: []), taste: taste, perRow: 3)
        #expect(sections.first?.genre.id == Recommender.topPicksID)
        #expect(sections.first?.shows.count == 3)
        let all = sections.flatMap { $0.shows.map(\.result.directoryID) }
        #expect(Set(all).count == all.count)
        #expect(sections.map(\.genre.name).contains("Science"))
    }

    @Test func sectionsOneRowPerTopGenreNoRepeats() {
        let taste = Recommender.taste(from: library)
        let candidates: [(result: DirectoryResult, chartRank: Int)] = [
            (result(30, "F1", genres: [("1483", "Fiction")]), 0),
            (result(31, "H1", genres: [("1512", "Health & Fitness")]), 0),
            (result(32, "S1", genres: [("1533", "Science")]), 0),
            (result(33, "F+H", genres: [("1512", "Health & Fitness"), ("1483", "Fiction")]), 0),
        ]
        let sections = Recommender.sections(Recommender.rank(candidates: candidates, taste: taste, excluding: []), taste: taste, perRow: 1)
        #expect(sections.map(\.genre.name) == ["Top picks", "Fiction", "Health & Fitness", "Science"])
        let all = sections.flatMap { $0.shows.map(\.result.directoryID) }
        #expect(Set(all).count == all.count)
        #expect(sections[0].shows.map(\.result.directoryID) == [33], "F+H scores highest")
    }

    @Test func emptyLibraryMeansNoSuggestions() {
        #expect(Recommender.taste(from: []).isEmpty)
        #expect(Recommender.rank(candidates: [(result(1, "X", genres: [("1483", "Fiction")]), 0)], taste: [], excluding: []).isEmpty)
    }
}

@Suite("Latest episodes (New page)")
struct LatestEpisodesTests {
    func episode(_ id: String, show: String, day: Int?, hour: Int = 12) -> Episode {
        let date = day.map { Date(timeIntervalSince1970: 1_759_968_000 + Double($0) * 86_400 + Double(hour) * 3600) }
        return Episode(id: id, showFeedURL: URL(string: "https://f.example/\(show)")!, showTitle: show, title: id, published: date, audioURL: URL(string: "https://a.example/\(id).mp3")!)
    }

    @Test func newestFirstAcrossShowsWithinWindow() {
        let a = Feed(show: Show(feedURL: URL(string: "https://f.example/A")!, title: "A"), episodes: [episode("a3", show: "A", day: 3), episode("a1", show: "A", day: 1), episode("a0", show: "A", day: nil)])
        let b = Feed(show: Show(feedURL: URL(string: "https://f.example/B")!, title: "B"), episodes: [episode("b2", show: "B", day: 2), episode("old", show: "B", day: -40)])
        let since = Date(timeIntervalSince1970: 1_760_000_000 - 30 * 86_400)
        let latest = LatestEpisodes.collect(from: [a, b], since: since)
        #expect(latest.map(\.id) == ["a3", "b2", "a1"])
        #expect(LatestEpisodes.collect(from: [a, b], since: since, limit: 2).count == 2)
    }

    @Test func groupsByCalendarDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let eps = [episode("x", show: "A", day: 2, hour: 20), episode("y", show: "B", day: 2, hour: 1), episode("z", show: "A", day: 1)]
        let groups = LatestEpisodes.byDay(eps, calendar: calendar)
        #expect(groups.map { $0.episodes.map(\.id) } == [["x", "y"], ["z"]])
    }

    @Test func feedRoundTripsThroughJSON() throws {
        let feed = Feed(show: Show(feedURL: URL(string: "https://f.example/A")!, title: "A"), episodes: [episode("a1", show: "A", day: 1)])
        let data = try JSONEncoder().encode(feed)
        #expect(try JSONDecoder().decode(Feed.self, from: data) == feed)
    }
}

@Suite("Episodes by year (show page)")
struct EpisodeGroupingTests {
    func ep(_ id: String, _ year: Int?) -> Episode {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let date = year.flatMap { calendar.date(from: DateComponents(year: $0, month: 6, day: 1)) }
        return Episode(id: id, showFeedURL: URL(string: "https://f.example/a")!, showTitle: "A", title: id, published: date, audioURL: URL(string: "https://a.example/\(id).mp3")!)
    }

    var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    @Test func newestFirstGroupsByYearUndatedLast() {
        let groups = EpisodeGrouping.byYear([ep("a", 2019), ep("x", nil), ep("b", 2024), ep("c", 2024)], newestFirst: true, calendar: utc)
        #expect(groups.map(\.year) == [2024, 2019, nil])
        #expect(groups[0].episodes.count == 2)
    }

    @Test func oldestFirstRunsStartToFinish() {
        let groups = EpisodeGrouping.byYear([ep("a", 2019), ep("b", 2024), ep("c", 2021)], newestFirst: false, calendar: utc)
        #expect(groups.map(\.year) == [2019, 2021, 2024])
        #expect(groups.flatMap(\.episodes).map(\.id) == ["a", "c", "b"])
    }
}
