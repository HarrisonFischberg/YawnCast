import Foundation

public enum FeedError: Error, Equatable, Sendable {
    /// The document is not well-formed XML, or is not an RSS channel.
    case malformed(String)
    /// Valid feed with no playable episodes.
    case noEpisodes
    case http(status: Int)
}

/// Parses podcast RSS 2.0 (with the iTunes namespace) into a `Feed`.
/// Items without an audio enclosure are skipped rather than failing the feed.
public enum RSSParser {
    public static func parse(_ data: Data, feedURL: URL) throws -> Feed {
        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = false
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate
        let ok = parser.parse()
        guard ok, delegate.sawChannel else {
            let reason = parser.parserError.map { "\($0.localizedDescription)" } ?? "Not an RSS channel"
            throw FeedError.malformed(reason)
        }

        let channel = delegate.channel
        let title = channel.title.trimmed.nilIfEmpty ?? feedURL.host() ?? "Untitled"
        let showArtwork = (channel.itunesImage ?? channel.imageURL).flatMap(URL.init(string:))
        let show = Show(
            feedURL: feedURL,
            title: title,
            author: channel.author.trimmed.nilIfEmpty,
            summary: HTMLText.plain(channel.summary.nilIfEmpty ?? channel.description).nilIfEmpty,
            artworkURL: showArtwork
        )

        let episodes: [Episode] = delegate.items.compactMap { item in
            guard let raw = item.enclosureURL?.trimmed, let audioURL = URL(string: raw),
                  audioURL.scheme == "https" || audioURL.scheme == "http" else { return nil }
            if let type = item.enclosureType?.lowercased(), !type.isEmpty,
               !(type.hasPrefix("audio/") || type == "application/octet-stream" || type.hasPrefix("video/")) {
                return nil
            }
            return Episode(
                id: item.guid.trimmed.nilIfEmpty ?? audioURL.absoluteString,
                showFeedURL: feedURL,
                showTitle: title,
                title: item.title.trimmed.nilIfEmpty ?? "Untitled episode",
                published: RSSDate.parse(item.pubDate),
                duration: RSSDuration.parse(item.duration),
                audioURL: audioURL,
                summary: HTMLText.plain(item.summary.nilIfEmpty ?? item.description).nilIfEmpty,
                artworkURL: item.itunesImage.flatMap(URL.init(string:)) ?? showArtwork
            )
        }

        // Stable de-dup by episode id, newest first.
        var seen = Set<String>()
        let unique = episodes.filter { seen.insert($0.id).inserted }
        let sorted = Feed.sortedNewestFirst(unique)
        let next = delegate.channel.nextPage.flatMap { URL(string: $0, relativeTo: feedURL)?.absoluteURL }
        return Feed(show: show, episodes: sorted, nextPageURL: next)
    }

    private struct ChannelFields {
        var title = ""
        var author = ""
        var description = ""
        var summary = ""
        var imageURL: String?
        var itunesImage: String?
        var nextPage: String?
    }

    private struct ItemFields {
        var title = ""
        var guid = ""
        var pubDate = ""
        var description = ""
        var summary = ""
        var duration = ""
        var enclosureURL: String?
        var enclosureType: String?
        var itunesImage: String?
    }

    private final class Delegate: NSObject, XMLParserDelegate {
        var channel = ChannelFields()
        var items: [ItemFields] = []
        var sawChannel = false

        private var current: ItemFields?
        private var stack: [String] = []
        private var text = ""

        func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                    qualifiedName qName: String?, attributes: [String: String] = [:]) {
            stack.append(name)
            text = ""
            switch name {
            case "channel":
                sawChannel = true
            case "item":
                current = ItemFields()
            case "enclosure":
                if current != nil, current?.enclosureURL == nil {
                    current?.enclosureURL = attributes["url"]
                    current?.enclosureType = attributes["type"]
                }
            case "atom:link", "link":
                if current == nil, attributes["rel"] == "next", let href = attributes["href"], !href.isEmpty {
                    channel.nextPage = href
                }
            case "itunes:image":
                if let href = attributes["href"] {
                    if current != nil { current?.itunesImage = href } else { channel.itunesImage = href }
                }
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            text += string
        }

        func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            text += String(decoding: CDATABlock, as: UTF8.self)
        }

        func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName qName: String?) {
            defer {
                stack.removeLast()
                text = ""
            }
            let parent = stack.dropLast().last
            if var item = current {
                switch name {
                case "title" where parent == "item": item.title = text
                case "guid": item.guid = text
                case "pubDate": item.pubDate = text
                case "description": item.description = text
                case "itunes:summary", "content:encoded": if item.summary.isEmpty { item.summary = text }
                case "itunes:duration": item.duration = text
                case "item":
                    items.append(item)
                    current = nil
                    return
                default: break
                }
                current = item
                return
            }
            switch (name, parent) {
            case ("title", "channel"): channel.title = text
            case ("itunes:author", "channel"): channel.author = text
            case ("description", "channel"): channel.description = text
            case ("itunes:summary", "channel"): channel.summary = text
            case ("url", "image"): channel.imageURL = text.trimmed
            default: break
            }
        }
    }
}

enum RSSDuration {
    /// Accepts `HH:MM:SS`, `MM:SS`, plain seconds, and decimal seconds.
    static func parse(_ raw: String) -> TimeInterval? {
        let s = raw.trimmed
        guard !s.isEmpty else { return nil }
        let parts = s.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count <= 3 else { return nil }
        var total: Double = 0
        for part in parts {
            guard let value = Double(part.trimmingCharacters(in: .whitespaces)), value >= 0, value.isFinite else { return nil }
            total = total * 60 + value
        }
        return total > 0 ? total : nil
    }
}

enum RSSDate {
    private static let formats = [
        "EEE, dd MMM yyyy HH:mm:ss Z",
        "EEE, dd MMM yyyy HH:mm:ss zzz",
        "EEE, d MMM yyyy HH:mm:ss Z",
        "EEE, d MMM yyyy HH:mm:ss zzz",
        "dd MMM yyyy HH:mm:ss Z",
        "EEE, dd MMM yyyy HH:mm Z",
        "EEE, dd MMM yy HH:mm:ss Z",
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd",
    ]

    /// Built once: a formatter per episode made big feeds slow to parse. DateFormatter
    /// is thread-safe for parsing, so sharing them across fetches is fine.
    nonisolated(unsafe) private static let formatters: [DateFormatter] = formats.map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = format
        return formatter
    }

    static func parse(_ raw: String) -> Date? {
        let s = raw.trimmed
        guard !s.isEmpty else { return nil }
        for formatter in formatters {
            if let date = formatter.date(from: s) { return date }
        }
        return nil
    }
}

public enum HTMLText {
    /// Strips tags and decodes common entities. Good enough for short
    /// descriptions; not a general HTML renderer.
    public static func plain(_ html: String) -> String {
        var s = html.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: [.regularExpression, .caseInsensitive])
        s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let entities = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&apos;": "'", "&nbsp;": " ", "&#8217;": "\u{2019}", "&#8220;": "\u{201C}", "&#8221;": "\u{201D}", "&#8211;": "\u{2013}", "&#8212;": "\u{2014}"]
        for (entity, value) in entities { s = s.replacingOccurrences(of: entity, with: value) }
        s = s.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\n\\s*\\n+", with: "\n\n", options: .regularExpression)
        return s.trimmed
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
