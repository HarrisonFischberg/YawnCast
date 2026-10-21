import NightCastCore
import SwiftUI

/// The signature control. One tap turns Sleep on; another turns it off.
/// Every style shows the ten fade steps as a progress bar; the icon follows
/// the Scene (a wave underwater, a tree in the rainforest).
struct MoonKey: View {
    let status: SleepStatus
    let action: () -> Void

    var body: some View {
        LookMoonKey(status: status, action: action)
    }

    static func accessibilityValue(for status: SleepStatus) -> String {
        switch status {
        case .off: "Off"
        case .waiting(let t): "On. Fade begins in \(TimeFormat.spoken(t))"
        case .fading(let level): "On. Fading, volume \(Int((level * 100).rounded())) percent"
        }
    }
}

/// The heart after "Sweet dreams", filled with the look's accent. The key face
/// is already accent while Sleep is on, so an onAccent outline keeps it visible.
struct AccentHeart: View {
    @Environment(\.theme) private var theme
    @ScaledMetric(relativeTo: .title3) private var size: CGFloat = 17

    var body: some View {
        ZStack {
            Image(systemName: "heart.fill")
                .foregroundStyle(theme.accent)
            Image(systemName: "heart")
                .foregroundStyle(theme.onAccent)
        }
        .font(.system(size: size, weight: .semibold))
    }
}
