import Foundation

/// Monotonic time source. Injected so tests can drive Sleep with virtual time.
public protocol PlaybackClock: Sendable {
    func now() -> TimeInterval
}

/// Monotonic uptime clock for production.
public struct SystemPlaybackClock: PlaybackClock {
    public init() {}
    public func now() -> TimeInterval { ProcessInfo.processInfo.systemUptime }
}

/// Converts clock samples into active playback seconds. Time between two
/// samples counts only if playback was active at the earlier sample, so
/// pausing or buffering freezes the count from the moment it is reported.
public struct ActivePlaybackMeter: Sendable, Equatable {
    private var lastSample: TimeInterval?
    private var wasActive = false

    public init() {}

    public mutating func sample(now: TimeInterval, isActive: Bool) -> TimeInterval {
        defer {
            lastSample = now
            wasActive = isActive
        }
        guard let lastSample, wasActive else { return 0 }
        return max(0, now - lastSample)
    }

    public mutating func reset() {
        lastSample = nil
        wasActive = false
    }
}

/// The parts of the player Sleep needs. The app's playback engine conforms.
@MainActor
public protocol SleepControllable: AnyObject {
    /// App-local output gain (never system volume).
    var gain: Double { get set }
    /// Playing and not buffering or stalled.
    var isActivelyPlaying: Bool { get }
    /// Pause and persist the current position.
    func pauseForSleep()
}

/// Owns the Sleep state machine for the currently loaded episode and applies
/// its gain to the player. Call `sync()` on every playback state change and
/// periodically (e.g. 4 Hz) while Sleep is on.
@MainActor
public final class SleepController {
    public private(set) var timer: SleepTimer
    public private(set) var episodeID: String?
    private var meter = ActivePlaybackMeter()
    /// Position when Sleep was turned on, and whether R then came from a
    /// provisional duration that may still be corrected once (DECISIONS D11).
    private var activationPosition: TimeInterval = 0
    private var durationIsProvisional = false
    private let clock: PlaybackClock
    private weak var player: SleepControllable?

    /// Called whenever `status` may have changed.
    public var onChange: (@MainActor () -> Void)?

    public init(clock: PlaybackClock = SystemPlaybackClock(), configuration: SleepConfiguration = .standard) {
        self.clock = clock
        self.timer = SleepTimer(configuration: configuration)
    }

    public var status: SleepStatus { timer.status }
    public var isActive: Bool { timer.isActive }
    /// True while Sleep is on or gliding back to baseline after a cancel;
    /// the driver must keep calling `sync()` while this is true.
    public var needsTicks: Bool { timer.isActive || timer.gain != timer.baseline }

    /// Moon tap. Turns Sleep on (returning the fade delay) or cancels it (returning nil).
    ///
    /// `position` is the playback position at the tap. Pass
    /// `durationIsProvisional: true` when `remaining` came from a duration the
    /// stream has not confirmed yet (see `measuredDurationArrived`).
    @discardableResult
    public func toggle(
        player: SleepControllable,
        episodeID: String,
        remaining: TimeInterval?,
        position: TimeInterval = 0,
        durationIsProvisional: Bool = false
    ) -> TimeInterval? {
        if timer.isActive {
            sync()
            timer.cancel(isPlaying: player.isActivelyPlaying)
            apply()
            onChange?()
            return nil
        }
        self.player = player
        self.episodeID = episodeID
        activationPosition = position
        self.durationIsProvisional = durationIsProvisional
        meter.reset()
        // If a cancel glide is still running, its current gain is not the
        // user's level; use the restore target instead.
        let baseline = timer.baseline != timer.gain ? timer.baseline : player.gain
        let delay = timer.activate(baseline: baseline, remaining: remaining)
        _ = meter.sample(now: clock.now(), isActive: player.isActivelyPlaying)
        apply()
        onChange?()
        return delay
    }

    /// Samples the clock and advances the state machine.
    public func sync() {
        guard let player else { return }
        let dt = meter.sample(now: clock.now(), isActive: player.isActivelyPlaying)
        let event = timer.advance(activeSeconds: dt)
        if event == .reachedSilence {
            // Pause at zero gain first, then restore gain silently.
            player.gain = 0
            player.pauseForSleep()
            apply()
            onChange?()
            return
        }
        apply()
        if dt > 0 || event != nil { onChange?() }
    }

    /// The user deliberately loaded an episode. A different episode cancels Sleep.
    public func episodeWillChange(to newEpisodeID: String) {
        guard newEpisodeID != episodeID else { return }
        endNow()
    }

    /// The ±5 minute bubble. See `SleepTimer.adjust(by:)`.
    @discardableResult
    public func adjust(by delta: TimeInterval) -> Bool {
        sync()
        guard timer.adjust(by: delta) else { return false }
        apply()
        onChange?()
        return true
    }

    /// Active seconds until Sleep pauses playback, while on.
    public var timeUntilSilence: TimeInterval? { timer.timeUntilSilence }

    /// The stream reported its real duration. If Sleep was activated with a
    /// provisional duration and is still waiting, recompute R from the
    /// activation position and correct the fade delay once.
    public func measuredDurationArrived(_ duration: TimeInterval, episodeID: String) {
        guard durationIsProvisional, episodeID == self.episodeID, timer.isActive,
              duration.isFinite, duration > 0 else { return }
        durationIsProvisional = false
        sync()
        if timer.reviseFadeDelay(remaining: max(0, duration - activationPosition)) {
            onChange?()
        }
    }

    /// The episode played to its end. Stop normally; Sleep ends; nothing else plays.
    public func episodeDidEnd() {
        endNow()
    }

    private func endNow() {
        guard timer.isActive || timer.gain != timer.baseline else { return }
        timer.end()
        apply()
        meter.reset()
        onChange?()
    }

    private func apply() {
        player?.gain = timer.gain
    }
}
