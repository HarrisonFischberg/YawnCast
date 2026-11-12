import SwiftUI

/// A "−5" / "+5" key on the Moon bar, 44 pt to tap.
struct StepKey: View {
    let minutes: Int
    let ink: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(minutes > 0 ? "+5" : "−5")
                .font(.system(.subheadline, weight: .semibold).monospacedDigit())
                .foregroundStyle(ink)
                .frame(width: 44, height: 44)
                .paper(seed: minutes > 0 ? 2 : 1, fill: .black.opacity(0.16))
                .contentShape(Rectangle())
        }
        .buttonStyle(PressDim())
        .accessibilityLabel(minutes > 0 ? "Add 5 minutes" : "Remove 5 minutes")
        .accessibilityIdentifier(minutes > 0 ? "sleepPlus5" : "sleepMinus5")
    }
}
