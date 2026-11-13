import AVFoundation
import Foundation
import YawnCastCore
import Observation

/// Streams one episode at a time with AVPlayer. Never advances to another
/// episode on its own. Gain is `AVPlayer.volume`: app-local, never system volume.
@Observable
final class PlaybackEngine: SleepControllable {
    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    private(set) var episode: Episode?
    private(set) var isPlaying = false
    private(set) var isBuffering = false
    private(set) var position: TimeInterval = 0
    private(set) var duration: TimeInterval?
    private(set) var loadState: LoadState = .idle
    /// True once the stream itself has reported a finite duration (vs. the feed's estimate).
    private(set) var isDurationMeasured = false
    /// Mirror of `AVPlayer.volume`, observable for UI tests and diagnostics.
    private(set) var appliedGain: Double = 1

    /// Called with (episode, position, duration, finished) whenever progress should be saved.
    @ObservationIgnored var onProgress: ((Episode, TimeInterval, TimeInterval?, Bool) -> Void)?
    /// Called on any transport state change (play/pause/buffer/end/seek).
    @ObservationIgnored var onStateChange: (() -> Void)?
    /// Called when the episode plays to its end.
    @ObservationIgnored var onEnded: (() -> Void)?
    /// Called once per item when the stream reports its real duration.
    @ObservationIgnored var onDurationMeasured: ((Episode, TimeInterval) -> Void)?

    /// Internal so tests can pause it the way the system does during an interruption.
    @ObservationIgnored let player = AVPlayer()
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var statusObservation: NSKeyValueObservation?
    @ObservationIgnored private var itemObservations: [NSKeyValueObservation] = []
    @ObservationIgnored private var notificationTasks: [Task<Void, Never>] = []
    @ObservationIgnored private var lastSavedAt: TimeInterval = 0
    @ObservationIgnored private var wasPlayingBeforeInterruption = false
    /// Whether the listener wants audio: set by play(), cleared by pause()/end. Unlike `isPlaying` it
    /// survives the system pausing the player, so an interruption can tell what to resume.
    @ObservationIgnored private var wantsToPlay = false

    init() {
        player.automaticallyWaitsToMinimizeStalling = true
        player.actionAtItemEnd = .pause
        observePlayer()
        observeSession()
    }

    // MARK: SleepControllable

    var gain: Double {
        get { Double(player.volume) }
        set {
            let clamped = min(1, max(0, newValue))
            player.volume = Float(clamped)
            if appliedGain != clamped { appliedGain = clamped }
        }
    }

    var isActivelyPlaying: Bool { isPlaying && !isBuffering }

    func pauseForSleep() {
        pause()
        saveProgress(force: true)
    }

    // MARK: Transport

    /// Loads an episode at `start`. Plays only when `autoplay` is true (a deliberate tap).
    func load(_ episode: Episode, start: TimeInterval, autoplay: Bool) {
        saveProgress(force: true)
        self.episode = episode
        position = start
        duration = episode.duration
        isDurationMeasured = false
        loadState = .loading
        isBuffering = autoplay
        wantsToPlay = false

        let item = AVPlayerItem(url: episode.audioURL.httpsUpgraded)
        item.preferredForwardBufferDuration = 60
        observe(item)
        // AVPlayer keeps its rate across items, so a paused load must stop the old one.
        if !autoplay { player.pause() }
        player.replaceCurrentItem(with: item)
        if start > 0 {
            player.seek(to: CMTime(seconds: start, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        }
        if autoplay { play() }
        onStateChange?()
    }

    func play() {
        guard episode != nil else { return }
        // A failed item never recovers by itself: Play reloads it, from every Play path.
        if case .failed = loadState { retry(); return }
        wantsToPlay = true
        activateSession()
        // Play at the very end starts the episode over.
        if let duration, duration > 0, position >= duration - 1 { seek(to: 0) }
        player.play()
    }

    func pause() {
        wantsToPlay = false
        player.pause()
        saveProgress(force: true)
    }

    func togglePlayPause() {
        player.timeControlStatus == .paused ? play() : pause()
    }

    func skip(by delta: TimeInterval) {
        seek(to: SeekMath.skip(from: position, by: delta, duration: duration))
    }

    func seek(to time: TimeInterval) {
        let target = SeekMath.clamp(time, duration: duration)
        position = target
        let cmTime = CMTime(seconds: target, preferredTimescale: 600)
        // AVPlayer raises an exception for a seek with a completion handler while the item isn't ready.
        if player.currentItem?.status == .readyToPlay {
            player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                Task { @MainActor in self?.saveProgress(force: true) }
            }
        } else {
            player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
            saveProgress(force: true)
        }
        onStateChange?()
    }

    func retry() {
        guard let episode else { return }
        load(episode, start: position, autoplay: true)
    }

    // MARK: Observation

    private func observePlayer() {
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self else { return }
                let seconds = time.seconds
                if seconds.isFinite { self.position = seconds }
                self.saveProgress(force: false)
            }
        }
        statusObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            let status = player.timeControlStatus
            Task { @MainActor in self?.apply(status) }
        }
    }

    private func apply(_ status: AVPlayer.TimeControlStatus) {
        let playing = status != .paused
        let buffering = status == .waitingToPlayAtSpecifiedRate
        guard playing != isPlaying || buffering != isBuffering else { return }
        isPlaying = playing
        isBuffering = buffering
        onStateChange?()
    }

    private func observe(_ item: AVPlayerItem) {
        itemObservations = [
            item.observe(\.status, options: [.new]) { [weak self] item, _ in
                let status = item.status
                let message = item.error?.localizedDescription
                Task { @MainActor in self?.itemStatusChanged(status, message: message) }
            },
            item.observe(\.duration, options: [.new]) { [weak self] item, _ in
                let seconds = item.duration.seconds
                Task { @MainActor in self?.durationChanged(seconds, item: item) }
            },
        ]
    }

    private func durationChanged(_ seconds: Double, item: AVPlayerItem) {
        guard item === player.currentItem, seconds.isFinite, seconds > 0 else { return }
        duration = seconds
        guard !isDurationMeasured, let episode else { return }
        isDurationMeasured = true
        onDurationMeasured?(episode, seconds)
        onStateChange?()
    }

    private func itemStatusChanged(_ status: AVPlayerItem.Status, message: String?) {
        switch status {
        case .readyToPlay:
            loadState = .ready
        case .failed:
            loadState = .failed(message ?? "This episode can’t be played right now.")
            isPlaying = false
            isBuffering = false
            onStateChange?()
        default:
            break
        }
    }

    private func observeSession() {
        let center = NotificationCenter.default
        notificationTasks = [
            Task { [weak self] in
                for await note in center.notifications(named: AVPlayerItem.didPlayToEndTimeNotification) {
                    guard let self, (note.object as? AVPlayerItem) === self.player.currentItem else { continue }
                    self.handleEnd()
                }
            },
            Task { [weak self] in
                for await note in center.notifications(named: AVAudioSession.interruptionNotification) {
                    self?.handleInterruption(note.userInfo ?? [:])
                }
            },
            Task { [weak self] in
                for await note in center.notifications(named: AVAudioSession.routeChangeNotification) {
                    self?.handleRouteChange(note.userInfo ?? [:])
                }
            },
            Task { [weak self] in
                for await note in center.notifications(named: AVPlayerItem.failedToPlayToEndTimeNotification) {
                    let error = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                    self?.loadState = .failed(error?.localizedDescription ?? "Playback stopped unexpectedly.")
                    self?.onStateChange?()
                }
            },
        ]
    }

    /// Episode finished: stop, mark complete. Never starts another episode.
    private func handleEnd() {
        wantsToPlay = false
        player.pause()
        if let d = duration { position = d }
        saveProgress(force: true, finished: true)
        onEnded?()
        onStateChange?()
    }

    private func handleInterruption(_ info: [AnyHashable: Any]) {
        guard let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        switch type {
        case .began:
            // Not isPlaying: the system's pause may already have cleared it.
            wasPlayingBeforeInterruption = wantsToPlay
            saveProgress(force: true)
        case .ended:
            let optionsRaw = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            if wasPlayingBeforeInterruption, AVAudioSession.InterruptionOptions(rawValue: optionsRaw).contains(.shouldResume) {
                play()
            }
            wasPlayingBeforeInterruption = false
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ info: [AnyHashable: Any]) {
        guard let raw = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else { return }
        // Headphones unplugged / Bluetooth gone: stay paused; never resume by itself.
        if reason == .oldDeviceUnavailable {
            pause()
        }
    }

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio)
            try session.setActive(true)
        } catch {
            loadState = .failed("Audio is unavailable: \(error.localizedDescription)")
        }
    }

    private func saveProgress(force: Bool, finished: Bool = false) {
        guard let episode else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard force || now - lastSavedAt >= 5 else { return }
        lastSavedAt = now
        let done = finished || SeekMath.isFinished(position: position, duration: duration)
        onProgress?(episode, position, duration, done)
    }
}
