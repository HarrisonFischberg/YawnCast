import Foundation

/// Everything YawnCast persists. Sleep state is deliberately absent: Sleep
/// must never resume after a relaunch.
public struct LibrarySnapshot: Codable, Equatable, Sendable {
    public var subscriptions: [Show]
    /// Keyed by `Episode.id`.
    public var positions: [String: PlaybackPosition]
    /// Last episode loaded into the player, for the mini-player after relaunch.
    public var lastEpisode: Episode?
    /// The colour: a Scene or one of the four flat colours.
    public var themeID: String?
    /// The text style (v0.17): "picturebook" or "signoff". Nil means Picture Book.
    public var lookID: String?
    public var libraryLayout: LibraryLayout?
    /// Bumped when a release changes appearance defaults, so they apply once.
    public var appearanceVersion: Int?

    public init(subscriptions: [Show] = [], positions: [String: PlaybackPosition] = [:], lastEpisode: Episode? = nil, themeID: String? = nil, lookID: String? = nil, libraryLayout: LibraryLayout? = nil, appearanceVersion: Int? = nil) {
        self.subscriptions = subscriptions
        self.positions = positions
        self.lastEpisode = lastEpisode
        self.themeID = themeID
        self.lookID = lookID
        self.libraryLayout = libraryLayout
        self.appearanceVersion = appearanceVersion
    }

    public static let empty = LibrarySnapshot()

    public func isSubscribed(_ show: Show) -> Bool {
        subscriptions.contains { $0.id == show.id }
    }

    public mutating func subscribe(_ show: Show) {
        if let index = subscriptions.firstIndex(where: { $0.id == show.id }) {
            subscriptions[index] = show
        } else {
            subscriptions.append(show)
        }
    }

    public mutating func unsubscribe(_ show: Show) {
        subscriptions.removeAll { $0.id == show.id }
    }

    /// Drag-to-reorder: moves the show with `id` into the slot of `targetID`
    /// (before it when moving up, after it when moving down). Returns true if moved.
    @discardableResult
    public mutating func moveSubscription(id: String, onto targetID: String) -> Bool {
        guard id != targetID,
              let from = subscriptions.firstIndex(where: { $0.id == id }),
              let to = subscriptions.firstIndex(where: { $0.id == targetID }) else { return false }
        let show = subscriptions.remove(at: from)
        subscriptions.insert(show, at: to)
        return true
    }
}

public protocol LibraryStore: Sendable {
    func load() -> LibrarySnapshot
    func save(_ snapshot: LibrarySnapshot) throws
}

/// Stores the snapshot as one JSON file, written atomically.
public struct JSONLibraryStore: LibraryStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// `Application Support/NightCast/library.json`. The folder keeps the app's old name so
    /// libraries saved before the YawnCast rename still load.
    public static func standard() -> JSONLibraryStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return JSONLibraryStore(fileURL: base.appending(path: "NightCast/library.json"))
    }

    /// Missing file → empty library. Unreadable file → moved aside to
    /// `library.corrupt.json` so it is not overwritten, then empty library.
    public func load() -> LibrarySnapshot {
        guard let data = try? Data(contentsOf: fileURL) else { return .empty }
        do {
            return try JSONDecoder.library.decode(LibrarySnapshot.self, from: data)
        } catch {
            let aside = fileURL.deletingPathExtension().appendingPathExtension("corrupt.json")
            try? FileManager.default.removeItem(at: aside)
            try? FileManager.default.moveItem(at: fileURL, to: aside)
            return .empty
        }
    }

    public func save(_ snapshot: LibrarySnapshot) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder.library.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }
}

/// In-memory store for previews and UI tests.
public final class MemoryLibraryStore: LibraryStore, @unchecked Sendable {
    private let lock = NSLock()
    private var snapshot: LibrarySnapshot

    public init(_ snapshot: LibrarySnapshot = .empty) {
        self.snapshot = snapshot
    }

    public func load() -> LibrarySnapshot {
        lock.withLock { snapshot }
    }

    public func save(_ snapshot: LibrarySnapshot) throws {
        lock.withLock { self.snapshot = snapshot }
    }
}

extension JSONEncoder {
    static var library: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var library: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
