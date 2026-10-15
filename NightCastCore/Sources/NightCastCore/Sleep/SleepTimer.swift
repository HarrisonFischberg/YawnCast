import Foundation

/// Tunables for the Sleep fade. `standard` is the V1 product spec.
public struct SleepConfiguration: Sendable, Equatable {
    /// Upper bound on the delay before fading starts.
    public var maxFadeDelay: TimeInterval
    /// Active playback seconds between fade steps.
    public var stepInterval: TimeInterval
    /// Gain multipliers of baseline, applied in order at each step.
    public var levels: [Double]
    /// Active playback seconds used to glide into each step.
    public var stepRamp: TimeInterval
    /// Active playback seconds used to glide back to baseline on cancel.
    public var cancelRamp: TimeInterval

    public init(
        maxFadeDelay: TimeInterval = 30 * 60,
        stepInterval: TimeInterval = 3 * 60,
        levels: [Double] = [0.8, 0.6, 0.4, 0.2, 0.0],
        stepRamp: TimeInterval = 2,
        cancelRamp: TimeInterval = 1
    ) {
        precondition(!levels.isEmpty, "Sleep needs at least one fade level")
        precondition(stepRamp >= 0 && stepRamp <= stepInterval, "Ramp must fit inside a step")
        self.maxFadeDelay = maxFadeDelay
        self.stepInterval = stepInterval
        self.levels = levels
        self.stepRamp = stepRamp
        self.cancelRamp = cancelRamp
    }

    public static let standard = SleepConfiguration()
}

/// What the UI shows for Sleep.
public enum SleepStatus: Equatable, Sendable {
    case off
    /// Sleep is on; fading begins after this many more active playback seconds.
    case waiting(untilFade: TimeInterval)
    /// Fading; `level` is the current step's target multiplier (0.8, 0.6, ...).
    case fading(level: Double)
}

/// Emitted by `advance` when the fade reaches zero. The caller must pause
/// playback and save the position *before* applying the restored gain.
public enum SleepEvent: Equatable, Sendable {
    case reachedSilence
}

/// Deterministic Sleep state machine. It knows nothing about clocks or
/// players: callers feed it *active* playback seconds (time spent actually
/// playing, never paused or buffering) and read back the gain to apply.
///
/// Timeline in active seconds, with F = fade delay and I = step interval:
/// gain is B until F, then glides to levels[0]·B, and at F + k·I glides to
/// levels[k]·B. When the final glide completes, `reachedSilence` fires and
/// the timer turns itself off with gain restored to B.
public struct SleepTimer: Sendable, Equatable {
    public let configuration: SleepConfiguration

    private enum Phase: Equatable, Sendable {
        case off
        case on(elapsed: TimeInterval)
        case restoring(from: Double, elapsed: TimeInterval)
    }

    private var phase: Phase = .off
    public private(set) var baseline: Double = 1
    /// Active playback seconds from activation until the first fade step.
    public private(set) var fadeDelay: TimeInterval = 0

    public init(configuration: SleepConfiguration = .standard) {
        self.configuration = configuration
    }

    /// The V1 rule: `min(maxFadeDelay, R / 2)` when R (playable seconds
    /// remaining) is known, otherwise `maxFadeDelay`.
    public static func fadeDelay(remaining: TimeInterval?, configuration: SleepConfiguration = .standard) -> TimeInterval {
        guard let remaining, remaining.isFinite else { return configuration.maxFadeDelay }
        return min(configuration.maxFadeDelay, max(0, remaining) / 2)
    }

    /// True while Sleep mode is on (waiting or fading). A cancel glide back
    /// to baseline is not "on".
    public var isActive: Bool {
        if case .on = phase { return true }
        return false
    }

    /// Active seconds since activation, while on.
    public var elapsed: TimeInterval? {
        if case .on(let elapsed) = phase { return elapsed }
        return nil
    }

    /// Absolute gain the player should use right now.
    public var gain: Double { baseline * multiplier }

    public var status: SleepStatus {
        guard case .on(let t) = phase else { return .off }
        if t < fadeDelay { return .waiting(untilFade: fadeDelay - t) }
        return .fading(level: configuration.levels[currentStep(at: t)])
    }

    /// Turns Sleep on. Returns the fade delay so the UI can announce it.
    @discardableResult
    public mutating func activate(baseline: Double, remaining: TimeInterval?) -> TimeInterval {
        self.baseline = baseline
        fadeDelay = Self.fadeDelay(remaining: remaining, configuration: configuration)
        phase = .on(elapsed: 0)
        return fadeDelay
    }

    /// Feeds active playback time. Returns `.reachedSilence` exactly once, on
    /// the advance that completes the final glide.
    @discardableResult
    public mutating func advance(activeSeconds dt: TimeInterval) -> SleepEvent? {
        guard dt > 0, dt.isFinite else { return nil }
        switch phase {
        case .off:
            return nil
        case .on(let elapsed):
            let next = elapsed + dt
            if next >= silenceTime {
                phase = .off
                return .reachedSilence
            }
            phase = .on(elapsed: next)
            return nil
        case .restoring(let from, let elapsed):
            let next = elapsed + dt
            phase = next >= configuration.cancelRamp ? .off : .restoring(from: from, elapsed: next)
            return nil
        }
    }

    /// Deliberate cancel (second Moon tap). While playing, glides back to
    /// baseline over `cancelRamp` active seconds; while paused, restores at once.
    public mutating func cancel(isPlaying: Bool) {
        guard case .on = phase else { return }
        let current = multiplier
        if isPlaying && current < 1 && configuration.cancelRamp > 0 {
            phase = .restoring(from: current, elapsed: 0)
        } else {
            phase = .off
        }
    }

    /// Ends Sleep immediately with gain back at baseline: the episode ended,
    /// or the user deliberately started a different episode.
    public mutating func end() {
        phase = .off
    }

    /// Corrects the fade delay when R was estimated from a provisional
    /// duration (e.g. the feed's) and the real duration arrives later.
    /// Applies only while still waiting; active time already elapsed is
    /// kept, and the fade never starts in the past (so the first step still
    /// glides in). Returns true when the delay changed.
    @discardableResult
    public mutating func reviseFadeDelay(remaining: TimeInterval?) -> Bool {
        guard case .on(let elapsed) = phase, elapsed < fadeDelay else { return false }
        let revised = max(elapsed, Self.fadeDelay(remaining: remaining, configuration: configuration))
        guard revised != fadeDelay else { return false }
        fadeDelay = revised
        return true
    }

    // MARK: - Timeline

    /// Active second at which the final glide completes.
    private var silenceTime: TimeInterval {
        fadeDelay + Double(configuration.levels.count - 1) * configuration.stepInterval + configuration.stepRamp
    }

    private func currentStep(at t: TimeInterval) -> Int {
        let k = Int(((t - fadeDelay) / configuration.stepInterval).rounded(.down))
        return min(max(k, 0), configuration.levels.count - 1)
    }

    private var multiplier: Double {
        switch phase {
        case .off:
            return 1
        case .restoring(let from, let elapsed):
            let u = configuration.cancelRamp > 0 ? min(1, elapsed / configuration.cancelRamp) : 1
            return from + (1 - from) * u
        case .on(let t):
            guard t >= fadeDelay else { return 1 }
            let k = currentStep(at: t)
            let stepStart = fadeDelay + Double(k) * configuration.stepInterval
            let previous = k == 0 ? 1 : configuration.levels[k - 1]
            let target = configuration.levels[k]
            let u = configuration.stepRamp > 0 ? min(1, (t - stepStart) / configuration.stepRamp) : 1
            return previous + (target - previous) * u
        }
    }
}
