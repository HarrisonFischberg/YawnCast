import CryptoKit
import YawnCastCore
import SwiftUI
import UIKit

/// Memory + disk cache for publisher artwork. Images are stored and shown
/// exactly as published (decoded and downsampled, never recolored).
actor ArtworkCache {
    static let shared = ArtworkCache()

    private let memory = NSCache<NSURL, UIImage>()
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]
    private let directory: URL
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
        directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "Artwork")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        memory.countLimit = 200
    }

    func image(for url: URL) async -> UIImage? {
        if let hit = memory.object(forKey: url as NSURL) { return hit }
        if let task = inFlight[url] { return await task.value }
        let file = directory.appending(path: Self.fileName(for: url))
        let session = self.session
        let task = Task<UIImage?, Never> {
            if let data = try? Data(contentsOf: file), let image = Self.decode(data) { return image }
            guard let (data, response) = try? await session.data(from: url.httpsUpgraded),
                  (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true,
                  let image = Self.decode(data) else { return nil }
            try? data.write(to: file, options: .atomic)
            return image
        }
        inFlight[url] = task
        let image = await task.value
        inFlight[url] = nil
        if let image { memory.setObject(image, forKey: url as NSURL) }
        return image
    }

    private static func fileName(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Decodes and downsamples to at most 600 px for memory efficiency.
    private static func decode(_ data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        let maxSide: CGFloat = 600
        let longest = max(image.size.width, image.size.height) * image.scale
        guard longest > maxSide else { return image.preparingForDisplay() ?? image }
        let target = CGSize(width: image.size.width * image.scale * maxSide / longest,
                            height: image.size.height * image.scale * maxSide / longest)
        return image.preparingThumbnail(of: target) ?? image
    }
}

/// Square artwork tile with a placeholder while loading or when unavailable.
struct ArtworkView: View {
    let url: URL?
    var cornerRadius: CGFloat = 14
    var title: String = ""

    @Environment(\.theme) private var theme
    @State private var image: UIImage?

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(theme.surface)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                } else {
                    Text(String(title.prefix(1)))
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundStyle(theme.textMuted)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(theme.border.opacity(0.9), lineWidth: 1)
            }
            .aspectRatio(1, contentMode: .fit)
            .task(id: url) {
                guard let url else { image = nil; return }
                let loaded = await ArtworkCache.shared.image(for: url)
                withAnimation(.easeOut(duration: 0.2)) { image = loaded }
            }
            .accessibilityHidden(true)
    }
}
