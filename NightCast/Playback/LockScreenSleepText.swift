import Foundation
import NightCastCore

/// The artist line on the Lock Screen and in Control Center when `exp_lock_status` is on.
/// Pure, so it can be tested without MediaPlayer. Whole minutes only: the Lock Screen
/// should not be rewritten at the 4 Hz Sleep tick rate.
nonisolated enum LockScreenSleepText {
    /// "Radiolab" when Sleep is off, otherwise "Radiolab · Sleep on, fades in 17 min"
    /// or "Radiolab · Sleep on, fading".
    static func subtitle(show: String, status: SleepStatus) -> String {
        switch status {
        case .off:
            return show
        case .waiting(let untilFade):
            return "\(show) · Sleep on, fades in \(minutes(untilFade)) min"
        case .fading:
            return "\(show) · Sleep on, fading"
        }
    }

    /// Whole minutes, rounded up, never below 1, so the text changes once a minute.
    static func minutes(_ seconds: TimeInterval) -> Int {
        max(1, Int((seconds / 60).rounded(.up)))
    }
}
