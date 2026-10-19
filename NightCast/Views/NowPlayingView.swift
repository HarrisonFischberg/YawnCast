import NightCastCore
import SwiftUI

/// Only: title, scrubber, −15 / play-pause / +15, Moon, and a way out.
struct NowPlayingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var skipTaps = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The ±5 bubble opens with Sleep, then tucks into a small pill after a
    /// few quiet seconds (or a tap on its center); tapping the pill reopens it.
    @State private var bubbleExpanded = true
    @State private var collapseTask: Task<Void, Never>?

    var body: some View {
        let player = model.player
        ZStack {
            ScreenBackground()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    IconKey(systemName: "chevron.down", label: "Close player") { dismiss() }
                        .accessibilityIdentifier("closePlayer")
                    Spacer()
                }
                .padding(.top, Space.s)

                Spacer(minLength: Space.xxl)

                VStack(alignment: .leading, spacing: Space.m) {
                    Text(player.episode?.showTitle.uppercased() ?? "")
                        .font(Typo.eyebrow)
                        .tracking(1.2)
                        .foregroundStyle(theme.textMuted)
                        .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                    Text(player.episode?.title ?? "Nothing playing")
                        .font(typeSize.isAccessibilitySize ? Typo.showTitle : Typo.playerTitle)
                        .textCase(Typo.titleCase)
                        .foregroundStyle(theme.text)
                        .lineLimit(typeSize.isAccessibilitySize ? 3 : 4)
                        .minimumScaleFactor(0.75)
                        .accessibilityAddTraits(.isHeader)
                }

                if case .failed(let message) = player.loadState {
                    HStack(spacing: Space.m) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(message).lineLimit(2)
                        Spacer()
                        Button("Retry") { player.retry() }
                            .font(Typo.headline)
                    }
                    .font(Typo.caption)
                    .foregroundStyle(theme.danger)
                    .padding(.top, Space.l)
                }

                Spacer(minLength: Space.xxl)

                Scrubber(position: player.position, duration: player.duration) { player.seek(to: $0) }

                transport
                    .padding(.top, Space.xxl)

                Spacer(minLength: Space.xxl)

                VStack(alignment: .trailing, spacing: Space.l) {
                    ZStack {
                        if model.sleepStatus != .off {
                            if bubbleExpanded {
                                SleepAdjustBubble(status: model.sleepStatus, onAdjust: { minutes in
                                    model.adjustSleep(minutes: minutes)
                                    scheduleCollapse()
                                }, onCollapse: { setExpanded(false) })
                                .transition(bubbleTransition)
                            } else {
                                CollapsedSleepPill(status: model.sleepStatus) { setExpanded(true) }
                                    .transition(bubbleTransition)
                            }
                        } else if let toast = model.toast {
                            Text(toast)
                                .font(Typo.caption)
                                .foregroundStyle(theme.text)
                                .padding(.horizontal, Space.l)
                                .padding(.vertical, Space.s)
                                .background(Capsule().fill(theme.surface).overlay(Capsule().strokeBorder(theme.border)))
                                .transition(.opacity)
                                .accessibilityHidden(true) // announced via UIAccessibility
                        }
                    }
                    .frame(minHeight: 46, alignment: .bottomTrailing)
                    .padding(.trailing, Space.xl)

                    MoonKey(status: model.sleepStatus) { model.toggleSleep() }
                        .disabled(player.episode == nil)
                        .sensoryFeedback(.impact(weight: .heavy, intensity: 0.8), trigger: model.sleepStatus == .off)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.sleepStatus == .off)
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: bubbleExpanded)
                .onChange(of: model.sleepStatus == .off) { _, isOff in
                    if !isOff { setExpanded(true) }
                }
                .onAppear { if model.sleepStatus != .off { setExpanded(false) } }
                .animation(.easeOut(duration: 0.2), value: model.toast)
                .sensoryFeedback(.selection, trigger: model.sleepAdjustCount)
                .padding(.bottom, Space.l)
            }
            .padding(.horizontal, Space.xxl)
        }
        // Swipe down anywhere (not just the chevron) to drop back into the mini player.
        .modifier(PullDownToDismiss { dismiss() })
        // VoiceOver can't use the swipe; the two-finger scrub (escape) closes it too.
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape) { dismiss() }
        .presentationBackground(.clear)
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            if ProcessInfo.processInfo.arguments.contains("-uitest") {
                // Test-only readout of the live AVPlayer.volume.
                Text(String(format: "%.2f", model.player.appliedGain))
                    .font(.caption2)
                    .foregroundStyle(.clear)
                    .accessibilityIdentifier("debugGain")
            }
        }
        #endif
    }

    private var bubbleTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.6, anchor: .bottomTrailing).combined(with: .opacity)
    }

    private func setExpanded(_ expanded: Bool) {
        bubbleExpanded = expanded
        if expanded { scheduleCollapse() } else { collapseTask?.cancel() }
    }

    private func scheduleCollapse() {
        collapseTask?.cancel()
        collapseTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            bubbleExpanded = false
        }
    }

    private var transport: some View {
        let player = model.player
        return HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button { player.skip(by: -15); skipTaps += 1 } label: {
                Image(systemName: "gobackward.15").font(.system(size: 26, weight: .semibold))
            }
            .buttonStyle(.roundKey())
            .frame(width: 76, height: 76)
            .accessibilityLabel("Back 15 seconds")

            Spacer(minLength: Space.l)

            Button { player.togglePlayPause() } label: {
                ZStack {
                    if player.isBuffering {
                        ProgressView().tint(theme.bg).controlSize(.large)
                    } else {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40, weight: .bold))
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
            .buttonStyle(.roundKey(.primary, depth: 6))
            .frame(width: 112, height: 112)
            .disabled(player.episode == nil)
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            .accessibilityValue(player.isBuffering ? "Loading" : "")
            .accessibilityIdentifier("playPause")
            .sensoryFeedback(.impact(weight: .medium), trigger: player.isPlaying)

            Spacer(minLength: Space.l)

            Button { player.skip(by: 15); skipTaps += 1 } label: {
                Image(systemName: "goforward.15").font(.system(size: 26, weight: .semibold))
            }
            .buttonStyle(.roundKey())
            .frame(width: 76, height: 76)
            .accessibilityLabel("Forward 15 seconds")
            Spacer(minLength: 0)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: skipTaps)
    }
}

/// Swipe-down-to-close for Now Playing. Its own modifier so a drag frame only
/// updates the offset here, not the whole Now Playing body.
private struct PullDownToDismiss: ViewModifier {
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How far the screen has been pulled down.
    @State private var pullDown: CGFloat = 0
    /// True only while a finger is down. Resets even when the system cancels the
    /// drag (onEnded never fires then), so the page can't stay stuck part-way down.
    @GestureState private var isDragging = false
    @State private var isClosing = false

    func body(content: Content) -> some View {
        content
            // Mask, not clipShape: clipShape trims at the safe area, which cut the
            // background off above the home indicator and let the page behind show.
            .mask {
                RoundedRectangle(cornerRadius: pullDown > 0 ? 38 : 0, style: .continuous)
                    .ignoresSafeArea()
            }
            .scaleEffect(reduceMotion ? 1 : 1 - min(pullDown, 400) / 4000, anchor: .top)
            .offset(y: pullDown)
            .gesture(
                // Global space: measured in the moving view's own space, the
                // translation shifts as the view does and the drag stutters.
                DragGesture(minimumDistance: 12, coordinateSpace: .global)
                    .updating($isDragging) { _, state, _ in state = true }
                    .onChanged { value in
                        let dy = value.translation.height
                        guard abs(dy) > abs(value.translation.width) else { return }
                        var t = Transaction()
                        t.disablesAnimations = true
                        withTransaction(t) { pullDown = max(0, dy) }
                    }
                    .onEnded { value in
                        if value.translation.height > 140 || value.predictedEndTranslation.height > 420 {
                            isClosing = true
                            onDismiss()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { pullDown = 0 }
                        }
                    }
            )
            .onChange(of: isDragging) { _, dragging in
                guard !dragging, !isClosing, pullDown != 0 else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { pullDown = 0 }
            }
            .onAppear { pullDown = 0; isClosing = false }
    }
}
