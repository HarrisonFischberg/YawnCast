import YawnCastCore
import SwiftUI

/// The signature control. One tap turns Sleep on; another turns it off.
/// The crescent follows the scene; the ±5 row lives inside the panel while on.
struct MoonKey: View {
    let status: SleepStatus
    var paused = false
    var activatedAt: Date?
    var onAdjust: ((Int) -> Void)?
    let action: () -> Void

    var body: some View {
        LookMoonKey(status: status, paused: paused, activatedAt: activatedAt, onAdjust: onAdjust, action: action)
    }

    static func accessibilityValue(for status: SleepStatus) -> String {
        switch status {
        case .off: "Off"
        case .waiting(let t): "On. Fade begins in \(TimeFormat.spoken(t))"
        case .fading(let level): "On. Fading, volume \(Int((level * 100).rounded())) percent"
        }
    }
}
