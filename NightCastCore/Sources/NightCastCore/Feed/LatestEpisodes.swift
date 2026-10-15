import Foundation

/// Builds the "New" page: recent episodes across Library shows, newest first.
public enum LatestEpisodes {
    /// Dated episodes from `feeds`, published on or after `since`, newest first,
    /// ties broken by show title then episode title. Undated episodes are left out
    /// because they can't be placed on a calendar.
    public static func collect(from feeds: [Feed], since: Date, limit: Int = 100) -> [Episode] {
        let all = feeds.flatMap(\.episodes).filter { ($0.published ?? .distantPast) >= since }
        var seen = Set<String>()
        let unique = all.filter { seen.insert($0.showFeedURL.absoluteString + "|" + $0.id).inserted }
        return Array(unique.sorted { a, b in
            if a.published != b.published { return (a.published ?? .distantPast) > (b.published ?? .distantPast) }
            if a.showTitle != b.showTitle { return a.showTitle < b.showTitle }
            return a.title < b.title
        }.prefix(limit))
    }

    /// Groups already-sorted episodes by calendar day (in `calendar`'s time zone).
    public static func byDay(_ episodes: [Episode], calendar: Calendar = .current) -> [(day: Date, episodes: [Episode])] {
        var groups: [(day: Date, episodes: [Episode])] = []
        for episode in episodes {
            guard let published = episode.published else { continue }
            let day = calendar.startOfDay(for: published)
            if let last = groups.last, last.day == day {
                groups[groups.count - 1].episodes.append(episode)
            } else {
                groups.append((day, [episode]))
            }
        }
        return groups
    }
}
