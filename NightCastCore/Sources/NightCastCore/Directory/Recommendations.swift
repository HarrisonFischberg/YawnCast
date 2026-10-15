import Foundation

/// How much the listener likes a genre, from the shows in their Library.
public struct GenreWeight: Hashable, Sendable {
    public var genre: Genre
    public var weight: Double

    public init(genre: Genre, weight: Double) {
        self.genre = genre
        self.weight = weight
    }
}

/// A suggested show and why.
public struct Recommendation: Hashable, Identifiable, Sendable {
    public var result: DirectoryResult
    public var score: Double
    /// The Library genre that best explains the suggestion.
    public var reason: Genre?

    public var id: String { result.id }
}

/// A titled row on Explore, e.g. "Because you like Fiction".
public struct ExploreSection: Hashable, Identifiable, Sendable {
    public var genre: Genre
    public var shows: [Recommendation]

    public var id: String { genre.id }
}

/// Transparent, deterministic recommendations: shows that share genres with
/// the Library, drawn from public genre charts. No accounts, no AI, no tracking.
public enum Recommender {
    /// Primary genre counts 2, secondary genres 1, summed over Library shows.
    public static func taste(from library: [DirectoryResult]) -> [GenreWeight] {
        var weights: [String: GenreWeight] = [:]
        for show in library {
            for (index, genre) in show.genres.enumerated() where genre.id != Genre.umbrellaID {
                weights[genre.id, default: GenreWeight(genre: genre, weight: 0)].weight += index == 0 ? 2 : 1
            }
        }
        return weights.values.sorted { a, b in
            a.weight != b.weight ? a.weight > b.weight : a.genre.name < b.genre.name
        }
    }

    private static let stopwords: Set<String> = [
        "with", "from", "your", "that", "this", "show", "podcast", "podcasts", "radio", "the", "and",
        "for", "what", "when", "where", "about", "into", "more", "most", "best", "daily", "weekly",
        "help", "have", "just", "like", "official", "presents", "episode", "episodes", "news",
    ]

    /// Lowercased words of 4+ letters, minus filler words.
    public static func tokens(_ text: String) -> Set<String> {
        let words = text.lowercased().split { !$0.isLetter }
        return Set(words.map(String.init).filter { $0.count >= 4 && !stopwords.contains($0) })
    }

    /// Words that appear in the titles of at least two Library shows, weighted
    /// by how many shows share them (e.g. "sleep" across two sleep podcasts).
    public static func keywords(fromTitles titles: [String]) -> [String: Double] {
        var counts: [String: Int] = [:]
        for title in titles {
            for token in tokens(title) { counts[token, default: 0] += 1 }
        }
        return counts.filter { $0.value >= 2 }.mapValues(Double.init)
    }

    /// Scores candidates by genre overlap with `taste`, title-keyword overlap
    /// with `keywords` (each shared keyword adds 1.5 × its weight), plus a small
    /// bonus for chart position (`chartRank` 0 = top). Excludes Library shows.
    /// A candidate needs at least one shared genre or keyword.
    public static func rank(
        candidates: [(result: DirectoryResult, chartRank: Int)],
        taste: [GenreWeight],
        keywords: [String: Double] = [:],
        excluding library: [Show]
    ) -> [Recommendation] {
        let owned = Set(library.map(\.id))
        let ownedIDs = Set(library.compactMap(\.directoryID))
        let weights = Dictionary(uniqueKeysWithValues: taste.map { ($0.genre.id, $0.weight) })
        var best: [String: Recommendation] = [:]
        for candidate in candidates {
            let result = candidate.result
            guard !owned.contains(result.id), !ownedIDs.contains(result.directoryID) else { continue }
            let matches = result.genres.filter { weights[$0.id] != nil }
            let keywordScore = tokens(result.title).reduce(0) { $0 + (keywords[$1] ?? 0) * 1.5 }
            guard !matches.isEmpty || keywordScore > 0 else { continue }
            let overlap = matches.reduce(0) { $0 + (weights[$1.id] ?? 0) }
            let chartBonus = 1 / Double(candidate.chartRank + 2)
            let reason = matches.max { (weights[$0.id] ?? 0) < (weights[$1.id] ?? 0) }
            let recommendation = Recommendation(result: result, score: overlap + keywordScore + chartBonus, reason: reason)
            if let existing = best[result.id], existing.score >= recommendation.score { continue }
            best[result.id] = recommendation
        }
        return best.values.sorted { a, b in
            a.score != b.score ? a.score > b.score : a.result.title < b.result.title
        }
    }

    /// Id of the leading "Top picks" row (not a real directory genre).
    public static let topPicksID = "top-picks"

    /// A "Top picks" row of the best `perRow` overall, then one row per top
    /// genre. Every show appears once: in Top picks, or else under its
    /// strongest genre.
    public static func sections(_ ranked: [Recommendation], taste: [GenreWeight], maxRows: Int = 3, perRow: Int = 10) -> [ExploreSection] {
        var rows: [ExploreSection] = []
        let picks = Array(ranked.prefix(perRow))
        if !picks.isEmpty {
            rows.append(ExploreSection(genre: Genre(id: topPicksID, name: "Top picks"), shows: picks))
        }
        let picked = Set(picks.map(\.id))
        for weight in taste.prefix(maxRows) {
            let shows = ranked.filter { !picked.contains($0.id) && $0.reason?.id == weight.genre.id }.prefix(perRow)
            if !shows.isEmpty { rows.append(ExploreSection(genre: weight.genre, shows: Array(shows))) }
        }
        return rows
    }
}
