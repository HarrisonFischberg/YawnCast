import YawnCastCore
import SwiftUI

extension SleepStatus {
    /// Fade steps still to come, of ten; none while Sleep is off.
    var litSteps: Int {
        switch self {
        case .off: 0
        case .waiting: 10
        case .fading(let level): Int((level * 10).rounded())
        }
    }
}

/// The ten fade steps as dots, for the mini player.
struct FadeDots: View {
    let status: SleepStatus
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { i in
                let lit = i >= 10 - status.litSteps
                Circle().fill(lit ? theme.fadeMark : .clear)
                    .overlay(Circle().strokeBorder(theme.text.opacity(lit ? 0 : 0.6), lineWidth: 1))
                    .frame(width: 7, height: 7)
            }
        }
        .animation(Motion.lightsOut, value: status.litSteps)
        .accessibilityHidden(true) // the Moon key beside it carries the value
    }
}
