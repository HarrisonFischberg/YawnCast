import MediaPlayer
import NightCastCore
import UIKit

/// Lock Screen / Control Center info and remote commands (play, pause, ±15, scrub).
/// Next/previous track are disabled: NightCast never changes episodes on its own.
final class NowPlayingBridge {
    private weak var engine: PlaybackEngine?
    private var artwork: MPMediaItemArtwork?
    private var artworkURL: URL?

    init(engine: PlaybackEngine) {
        self.engine = engine
        configureCommands()
    }

    private func configureCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.engine?.play() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.engine?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.engine?.togglePlayPause() }
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.engine?.skip(by: 15) }
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.engine?.skip(by: -15) }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let time = event.positionTime
            MainActor.assumeIsolated { self?.engine?.seek(to: time) }
            return .success
        }
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.changePlaybackRateCommand.isEnabled = false
    }

    /// Pushes current state to the Lock Screen. Cheap; call on every state change.
    func update() {
        guard let engine, let episode = engine.episode else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: episode.title,
            MPMediaItemPropertyArtist: episode.showTitle,
            MPMediaItemPropertyAlbumTitle: episode.showTitle,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: engine.position,
            MPNowPlayingInfoPropertyPlaybackRate: engine.isActivelyPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
        ]
        if let duration = engine.duration { info[MPMediaItemPropertyPlaybackDuration] = duration }
        if let artwork, artworkURL == episode.artworkURL { info[MPMediaItemPropertyArtwork] = artwork }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        loadArtworkIfNeeded(for: episode)
    }

    private func loadArtworkIfNeeded(for episode: Episode) {
        guard let url = episode.artworkURL, url != artworkURL else { return }
        artworkURL = url
        artwork = nil
        Task {
            guard let image = await ArtworkCache.shared.image(for: url), artworkURL == url else { return }
            artwork = MPMediaItemArtwork(boundsSize: image.size) { @Sendable _ in image }
            update()
        }
    }
}
