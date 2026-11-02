import YawnCastCore
import SwiftUI

/// Only: title, scrubber, −15 / play-pause / +15, Moon, and a way out.
struct NowPlayingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var skipTaps = 0
    @State private var showingAbout = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let player = model.player
        let preview = model.preview
        let episode = preview ?? player.episode
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
                    Text(episode?.showTitle.uppercased() ?? "")
                        .font(Typo.eyebrow)
                        .tracking(1.2)
                        .foregroundStyle(theme.textMuted)
                        .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                    Text(episode?.title ?? "Nothing playing")
                        .font(typeSize.isAccessibilitySize ? Typo.showTitle : Typo.playerTitle)
                        .textCase(Typo.titleCase)
                        .foregroundStyle(theme.text)
                        .lineLimit(typeSize.isAccessibilitySize ? 3 : 4)
                        .minimumScaleFactor(0.75)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityAction(named: "About this episode") { if episode?.summary?.isEmpty == false { showingAbout = true } }
                }
                // Tap the title to read what the episode is about.
                .contentShape(Rectangle())
                .onTapGesture { if episode?.summary?.isEmpty == false { showingAbout = true } }
                .sheet(isPresented: $showingAbout) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Space.l) {
                            Text(episode?.title ?? "")
                                .font(Typo.title)
                                .textCase(Typo.titleCase)
                                .foregroundStyle(theme.text)
                                .accessibilityAddTraits(.isHeader)
                            Text(episode?.summary ?? "")
                                .font(Typo.body)
                                .foregroundStyle(theme.textMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Space.xxl)
                    }
                    .environment(\.theme, theme)
                    // Same frosted see-through at every height. The default iOS 26 glass
                    // turns opaque (and picks up a green cast) once the sheet is pulled tall.
                    .presentationBackground(.thinMaterial)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }

                if preview == nil, case .failed(let message) = player.loadState {
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

                if let preview {
                    Scrubber(position: model.position(for: preview)?.seconds ?? 0, duration: preview.duration) { _ in }
                        .disabled(true)
                } else {
                    Scrubber(position: player.position, duration: player.duration) { player.seek(to: $0) }
                }

                transport
                    .padding(.top, Space.xxl)

                Spacer(minLength: Space.xxl)

                VStack(alignment: .trailing, spacing: Space.l) {
                    // Above the Moon: "Back to …" on the left (only while Sleep is off),
                    // the Sleep chip or a toast on the right. Stacked at accessibility sizes.
                    sleepRowLayout {
                        if preview == nil, let marker = model.driftBackPosition {
                            DriftBackKey(position: marker) { model.jumpToDriftBack() }
                                .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 6)))
                        }
                        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                        ZStack {
                            if model.sleepStatus != .off, let note = model.nightNote {
                                toastLabel(note)
                            } else if model.sleepStatus != .off {
                                // −5 · 17 min · +5, for as long as Sleep is on.
                                SleepChip(status: model.sleepStatus) { model.adjustSleep(minutes: $0) }
                                    .transition(chipTransition)
                            } else if let toast = model.toast {
                                toastLabel(toast)
                            }
                        }
                        .frame(minHeight: 46, alignment: .bottomTrailing)
                        .padding(.trailing, Space.xl)
                    }

                    MoonKey(status: model.sleepStatus) { model.toggleSleep() }
                        .disabled(player.episode == nil || preview != nil)
                        .sensoryFeedback(.impact(weight: .heavy, intensity: 0.8), trigger: model.sleepStatus == .off)
                        .overlay(alignment: .topLeading) {
                            if model.sleepStatus != .off {
                                // Three lines of z's rise out of the Sleep icon, in every theme.
                                FloatingZs(isFading: { if case .fading = model.sleepStatus { return true }; return false }())
                                    // Tall, so they float well up the screen before fading out.
                                    .frame(width: 130, height: 360)
                                    .offset(x: 8, y: -336)
                                    .transition(.opacity)
                            }
                        }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.sleepStatus == .off)
                .animation(.easeOut(duration: 0.2), value: model.toast)
                .animation(.easeOut(duration: 0.2), value: model.nightNote)
                .sensoryFeedback(.selection, trigger: model.sleepAdjustCount)
                .padding(.bottom, Space.l)
            }
            .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.8), value: model.driftBackPosition)
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

    private func toastLabel(_ message: String) -> some View {
        Text(message)
            .font(Typo.caption)
            .foregroundStyle(theme.text)
            .padding(.horizontal, Space.l)
            .padding(.vertical, Space.s)
            .background(Capsule().fill(theme.surface).overlay(Capsule().strokeBorder(theme.border)))
            .transition(.opacity)
            .accessibilityHidden(true) // announced via UIAccessibility
    }

    private var chipTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.7, anchor: .bottomTrailing).combined(with: .opacity)
    }

    private var transport: some View {
        let player = model.player
        let preview = model.preview
        // Previewing: Play starts the previewed episode; the rest waits for it.
        let playing = preview == nil && player.isPlaying
        return HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button { player.skip(by: -15); skipTaps += 1 } label: {
                Image(systemName: "gobackward.15").font(.system(size: 26, weight: .semibold))
            }
            .buttonStyle(.roundKey())
            .frame(width: 76, height: 76)
            .disabled(preview != nil)
            .accessibilityLabel("Back 15 seconds")

            Spacer(minLength: Space.l)

            Button {
                if let preview { model.play(preview) } else { player.togglePlayPause() }
            } label: {
                ZStack {
                    if preview == nil && player.isBuffering {
                        ProgressView().tint(theme.bg).controlSize(.large)
                    } else {
                        Image(systemName: playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 40, weight: .bold))
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
            .buttonStyle(.roundKey(.primary, depth: 6))
            .frame(width: 112, height: 112)
            .disabled(player.episode == nil)
            .accessibilityLabel(playing ? "Pause" : "Play")
            .accessibilityValue(preview == nil && player.isBuffering ? "Loading" : "")
            .accessibilityIdentifier("playPause")
            .sensoryFeedback(.impact(weight: .medium), trigger: playing)

            Spacer(minLength: Space.l)

            Button { player.skip(by: 15); skipTaps += 1 } label: {
                Image(systemName: "goforward.15").font(.system(size: 26, weight: .semibold))
            }
            .buttonStyle(.roundKey())
            .frame(width: 76, height: 76)
            .disabled(preview != nil)
            .accessibilityLabel("Forward 15 seconds")
            Spacer(minLength: 0)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: skipTaps)
    }
}

/// Drift back: after Sleep fades an episode out and pauses it, one
/// standard key under the scrubber jumps back to where the fade began. Seeks only;
/// playback stays paused.
extension NowPlayingView {
    /// The row above the Moon key: side by side normally, stacked at accessibility sizes.
    fileprivate var sleepRowLayout: AnyLayout {
        typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .trailing, spacing: Space.m))
            : AnyLayout(HStackLayout(alignment: .bottom, spacing: Space.m))
    }
}

private struct DriftBackKey: View {
    let position: TimeInterval
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            action()
            UIAccessibility.post(notification: .announcement, argument: "At \(TimeFormat.spoken(position))")
        } label: {
            HStack(spacing: Space.m) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Back to \(TimeFormat.clock(position))")
                        .font(Typo.headline)
                        .monospacedDigit()
                    Text("where the fade began")
                        .font(Typo.caption)
                        .foregroundStyle(theme.textMuted)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, Space.l)
            .padding(.trailing, Space.xl)
            .padding(.vertical, Space.s)
            .frame(minHeight: 44)
        }
        .modifier(DriftBackKeyShape(largeType: typeSize.isAccessibilitySize))
        .fixedSize(horizontal: !typeSize.isAccessibilitySize, vertical: true)
        .sensoryFeedback(.selection, trigger: taps)
        .accessibilityLabel("Back to \(TimeFormat.spoken(position)), where the fade began")
        .accessibilityHint("Moves the episode there. It stays paused.")
        .accessibilityIdentifier("driftBackKey")
    }
}

/// A capsule key normally; a rounded plate when accessibility text wraps the lines.
private struct DriftBackKeyShape: ViewModifier {
    let largeType: Bool

    func body(content: Content) -> some View {
        if largeType {
            content.buttonStyle(KeyStyle(shape: RoundedRectangle(cornerRadius: 18, style: .continuous), depth: 3))
        } else {
            content.buttonStyle(.capsuleKey(depth: 3))
        }
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
