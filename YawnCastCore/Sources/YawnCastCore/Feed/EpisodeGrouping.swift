import Foundation

/// Episodes grouped under a year heading for the show page.
public struct YearGroup: Hashable, Identifiable, Sendable {
    /// nil for episodes without a publish date.
    public var year: Int?
    public var episodes: [Episode]

    public var id: String { year.map(String.init) ?? "undated" }
}

public enum EpisodeGrouping {
    /// Groups by calendar year in the chosen order (newest or oldest first).
    /// Undated episodes always come last.
    public static func byYear(_ episodes: [Episode], newestFirst: Bool, calendar: Calendar = .current) -> [YearGroup] {
        let sorted = Feed.sortedNewestFirst(episodes)
        let dated = sorted.filter { $0.published != nil }
        let undated = sorted.filter { $0.published == nil }
        let ordered = newestFirst ? dated : dated.reversed()
        var groups: [YearGroup] = []
        for episode in ordered {
            let year = calendar.component(.year, from: episode.published!)
            if groups.last?.year == year {
                groups[groups.count - 1].episodes.append(episode)
            } else {
                groups.append(YearGroup(year: year, episodes: [episode]))
            }
        }
        if !undated.isEmpty { groups.append(YearGroup(year: nil, episodes: undated)) }
        return groups
    }
}
