import SwiftUI

// Reusable flow pieces: a stepped intro, a success sheet, and honest staged progress.

/// One page of `OnboardingFlow`.
struct OnboardingPage {
    let systemImage: String
    let title: String
    let message: String
    let buttonTitle: String
}

/// A short intro with "Step N of M". `stepsDone` counts steps already behind the
/// user (installing the app), so the first page already reads as progress.
struct OnboardingFlow: View {
    let pages: [OnboardingPage]
    var stepsDone = 1
    /// Steps that follow the intro (e.g. picking shows), counted in the total.
    var stepsAfter = 0
    /// `true` when the last page's button was pressed, `false` on Skip.
    let onFinish: (Bool) -> Void

    @State private var index = 0
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let page = pages[index]
        let total = pages.count + stepsDone + stepsAfter
        let step = index + stepsDone + 1
        VStack(alignment: .leading, spacing: Space.xl) {
            HStack {
                Text("Step \(step) of \(total)")
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
                Spacer()
                Button("Skip") { onFinish(false) }
                    .font(Typo.headline)
                    .foregroundStyle(theme.textMuted)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("skipOnboarding")
            }
            ProgressView(value: Double(step), total: Double(total))
                .tint(theme.text)
                .accessibilityHidden(true) // "Step N of M" says it

            Spacer()

            VStack(alignment: .leading, spacing: Space.l) {
                Image(systemName: page.systemImage)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(theme.text)
                    .accessibilityHidden(true)
                Text(page.title)
                    .font(Typo.playerTitle)
                    .foregroundStyle(theme.text)
                    .accessibilityAddTraits(.isHeader)
                Text(page.message)
                    .font(Typo.body)
                    .foregroundStyle(theme.textMuted)
            }
            .id(index)
            .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))

            Spacer()

            Button {
                if index + 1 < pages.count {
                    withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .smooth(duration: 0.35)) { index += 1 }
                } else {
                    onFinish(true)
                }
            } label: {
                Text(page.buttonTitle)
                    .font(Typo.headline)
                    .padding(.vertical, Space.l)
            }
            .buttonStyle(.capsuleKey(.primary))
            .fixedSize(horizontal: false, vertical: true)
            .sensoryFeedback(.selection, trigger: index)
            .accessibilityIdentifier("onboardingNext")
        }
        .padding(.horizontal, Space.xxl)
        .padding(.vertical, Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background { ScreenBackground() }
    }
}

/// A win moment: one symbol, a confirmation, and the next step. Plays the
/// success haptic once; the symbol bounces unless Reduce Motion is on.
struct SuccessView: View {
    let systemImage: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    @State private var appeared = false
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Space.l) {
            Image(systemName: systemImage)
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(theme.accent)
                .symbolEffect(.bounce, value: reduceMotion ? false : appeared)
                .accessibilityHidden(true)
            Text(title)
                .font(Typo.playerTitle)
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(Typo.body)
                .foregroundStyle(theme.textMuted)
                .multilineTextAlignment(.center)
            Button(action: action) {
                Text(actionTitle)
                    .font(Typo.headline)
                    .padding(.vertical, Space.l)
            }
            .buttonStyle(.capsuleKey(.primary))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, Space.s)
            .accessibilityIdentifier("successAction")
        }
        .padding(Space.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { ScreenBackground() }
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear { appeared = true }
    }
}

/// Progress for real, counted work ("Checking your shows · 2 of 5"), ending on a
/// check. It only reports work as it happens; it never adds a delay.
struct StagedProgress: View {
    let title: String
    let done: Int
    let total: Int
    var doneTitle = "Done"

    @Environment(\.theme) private var theme

    var body: some View {
        let finished = total > 0 && done >= total
        VStack(alignment: .leading, spacing: Space.s) {
            HStack(spacing: Space.m) {
                if finished {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.text)
                } else {
                    ProgressView().tint(theme.text)
                }
                Text(finished ? doneTitle : total > 0 ? "\(title) · \(done) of \(total)" : title)
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
                    .contentTransition(.numericText())
            }
            if total > 1 {
                ProgressView(value: Double(min(done, total)), total: Double(total))
                    .tint(theme.text)
                    .animation(.easeOut(duration: 0.25), value: done)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(finished ? doneTitle : title)
        .accessibilityValue(total > 0 ? "\(done) of \(total)" : "")
    }
}
