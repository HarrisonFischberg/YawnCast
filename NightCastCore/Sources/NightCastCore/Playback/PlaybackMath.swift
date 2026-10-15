import Foundation

public enum SeekMath {
    public static let skipInterval: TimeInterval = 15

    /// Clamps a target time into `0...duration` (upper bound only when duration is known).
    public static func clamp(_ time: TimeInterval, duration: TimeInterval?) -> TimeInterval {
        guard time.isFinite else { return 0 }
        var t = max(0, time)
        if let duration, duration.isFinite, duration > 0 { t = min(t, duration) }
        return t
    }

    public static func skip(from time: TimeInterval, by delta: TimeInterval, duration: TimeInterval?) -> TimeInterval {
        clamp(time + delta, duration: duration)
    }

    /// Where to start an episode: the saved position, or the beginning when
    /// it was finished or within the last 15 seconds.
    public static func resumeTime(saved: PlaybackPosition?, duration: TimeInterval?) -> TimeInterval {
        guard let saved, !saved.completed else { return 0 }
        let total = duration ?? saved.duration
        if let total, total.isFinite, total > 0, saved.seconds >= total - 15 { return 0 }
        return clamp(saved.seconds, duration: total)
    }

    /// Playable seconds remaining, or nil when the duration is unknown.
    public static func remaining(position: TimeInterval, duration: TimeInterval?) -> TimeInterval? {
        guard let duration, duration.isFinite, duration > 0 else { return nil }
        return max(0, duration - clamp(position, duration: duration))
    }

    /// Positions within the last 15 seconds count as finished.
    public static func isFinished(position: TimeInterval, duration: TimeInterval?) -> Bool {
        guard let duration, duration.isFinite, duration > 0 else { return false }
        return position >= duration - 15
    }
}

public enum TimeFormat {
    /// `12:03`, `1:02:03`.
    public static func clock(_ seconds: TimeInterval) -> String {
        let s = Int((seconds.isFinite ? max(0, seconds) : 0).rounded(.down))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
    }

    /// `-12:03`.
    public static func remaining(_ seconds: TimeInterval) -> String {
        "-" + clock(seconds.rounded(.up))
    }

    /// `1 hr 5 min`, `42 min`, `45 sec`.
    public static func duration(_ seconds: TimeInterval) -> String {
        let s = Int(max(0, seconds).rounded())
        if s < 60 { return "\(s) sec" }
        let h = s / 3600, m = (s % 3600 + 30) / 60
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }

    /// VoiceOver-friendly: "12 minutes, 3 seconds".
    public static func spoken(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute, .second]
        return formatter.string(from: max(0, seconds.rounded())) ?? clock(seconds)
    }

    /// Fade-delay phrase for Sleep feedback: "30 min", "4 min", "40 sec".
    public static func sleepDelay(_ seconds: TimeInterval) -> String {
        if seconds < 60 { return "\(Int(seconds.rounded(.up))) sec" }
        return "\(Int((seconds / 60).rounded())) min"
    }
}

public enum SleepCopy {
    /// "Sleep on · fade begins in 30 min".
    public static func activated(fadeDelay: TimeInterval) -> String {
        "Sleep on · fade begins in \(TimeFormat.sleepDelay(fadeDelay))"
    }

    public static let cancelled = "Sleep off"

    /// Short status for the Moon key.
    public static func status(_ status: SleepStatus) -> String {
        switch status {
        case .off: return "Sleep"
        case .waiting(let t): return "Fade in \(TimeFormat.sleepDelay(t))"
        case .fading(let level): return "Fading · \(Int((level * 100).rounded()))%"
        }
    }
}
