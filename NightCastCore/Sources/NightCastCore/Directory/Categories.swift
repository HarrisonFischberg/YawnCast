import Foundation

/// A browsable group of shows on Explore: an Apple Podcasts genre (top chart)
/// or a topic search for interests that have no genre (e.g. AI, sleep).
public struct PodcastCategory: Hashable, Identifiable, Codable, Sendable {
    public enum Source: Hashable, Codable, Sendable {
        case genre(String)
        case search(String)
    }

    public var id: String
    public var name: String
    /// SF Symbol name.
    public var symbol: String
    public var source: Source

    public init(id: String, name: String, symbol: String, source: Source) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.source = source
    }

    private static func genre(_ id: String, _ name: String, _ symbol: String) -> PodcastCategory {
        PodcastCategory(id: "genre-\(id)", name: name, symbol: symbol, source: .genre(id))
    }

    private static func topic(_ name: String, _ term: String, _ symbol: String) -> PodcastCategory {
        PodcastCategory(id: "topic-\(term.lowercased())", name: name, symbol: symbol, source: .search(term))
    }

    /// Explore's "Browse" cards. Genre ids verified against Apple's live charts (DECISIONS D35).
    public static let browse: [PodcastCategory] = [
        genre("1545", "Sports", "sportscourt"),
        genre("1527", "Politics", "building.columns"),
        genre("1489", "News", "newspaper"),
        genre("1318", "Technology", "cpu"),
        topic("AI", "artificial intelligence", "sparkles"),
        genre("1488", "True Crime", "magnifyingglass"),
        genre("1303", "Comedy", "face.smiling"),
        genre("1487", "History", "scroll"),
        genre("1533", "Science", "atom"),
        genre("1321", "Business", "chart.line.uptrend.xyaxis"),
        topic("Sleep", "sleep stories", "moon.zzz"),
        genre("1512", "Health & Fitness", "figure.run"),
        genre("1517", "Mental Health", "brain.head.profile"),
        genre("1483", "Fiction", "book"),
        genre("1324", "Society & Culture", "person.3"),
        genre("1309", "TV & Film", "film"),
        genre("1310", "Music", "music.note"),
        genre("1301", "Arts", "paintpalette"),
        genre("1505", "Hobbies", "puzzlepiece"),
        genre("1509", "Video Games", "gamecontroller"),
        genre("1508", "Home & Garden", "leaf"),
        genre("1503", "Automotive", "car"),
        genre("1522", "Pets & Animals", "pawprint"),
        genre("1305", "Kids & Family", "figure.and.child.holdinghands"),
        genre("1304", "Education", "graduationcap"),
        genre("1314", "Religion & Spirituality", "hands.sparkles"),
    ]

    /// The Browse card for a genre, or a plain card when the genre isn't in `browse`.
    public static func forGenre(_ genre: Genre) -> PodcastCategory {
        browse.first { $0.source == .genre(genre.id) }
            ?? PodcastCategory(id: "genre-\(genre.id)", name: genre.name, symbol: "square.grid.2x2", source: .genre(genre.id))
    }

    /// "Your interests" on Explore, strongest first: Library title keywords
    /// shared by several shows (e.g. "sleep"), then Library genres. No repeats.
    public static func interests(taste: [GenreWeight], keywords: [String: Double] = [:], limit: Int = 8) -> [PodcastCategory] {
        var result: [PodcastCategory] = []
        var seen = Set<String>()
        func add(_ category: PodcastCategory) {
            if seen.insert(category.id).inserted { result.append(category) }
        }
        for keyword in keywords.sorted(by: { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }).map(\.key) {
            if let match = browse.first(where: { if case .search(let term) = $0.source { return term.lowercased().contains(keyword) } else { return $0.name.lowercased() == keyword } }) {
                add(match)
            } else {
                add(PodcastCategory(id: "topic-\(keyword)", name: keyword.capitalized, symbol: "tag", source: .search(keyword)))
            }
        }
        for weight in taste { add(forGenre(weight.genre)) }
        return Array(result.prefix(limit))
    }
}

/// How the Library grid is drawn.
public enum LibraryLayout: String, Codable, CaseIterable, Sendable {
    case large, small, list

    public var next: LibraryLayout {
        let all = Self.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}
