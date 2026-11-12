import YawnCastCore
import SwiftUI

/// Only: the cover and title, scrubber, −15 / play-pause / +15, the Sleep bubble and Moon bar, and a way out.
struct NowPlayingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var skipTaps = 0
    @State private var showingAbout = false
    /// Where the title sits on screen, so the Scene's life keeps clear of the words.
    @State private var titleFrame = CGRect.null
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // The cover gives way first when the screen is short (a small phone, or the
        // "Back to" key showing); past that, at the largest text sizes, the page scrolls.
        ViewThatFits(in: .vertical) {
            if !typeSize.isAccessibilitySize {
                page(cover: 148)
                page(cover: 88)
                page(cover: 64)
            }
            page(cover: nil)
            ScrollView { page(cover: nil) }.scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { ScreenBackground(life: life, quiet: titleFrame) }
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

    /// How much of the Scene's life is out: all of it while an episode plays or Sleep
    /// waits, less with every fade step, none once the lights are out.
    private var life: Double {
        switch model.sleepStatus {
        case .fading(let level): level
        case .waiting: 1
        case .off: model.preview == nil && model.player.isPlaying ? 1 : 0
        }
    }

    /// The whole screen, with the cover at `cover` points or without one.
    private func page(cover: CGFloat?) -> some View {
        let player = model.player
        let preview = model.preview
        let episode = preview ?? player.episode
        return VStack(spacing: 0) {
            // Over the Scene: the way out, the show's cover in a paper mat, the title.
            VStack(spacing: 0) {
                HStack {
                    IconKey(systemName: "chevron.down", label: "Close player") { dismiss() }
                        .accessibilityIdentifier("closePlayer")
                    Spacer()
                }
                Spacer(minLength: Space.s)
                if let cover {
                    ArtworkView(url: episode?.artworkURL, cornerRadius: Radius.artwork, title: episode?.showTitle ?? "")
                        .frame(width: cover, height: cover)
                        .padding(Space.s)
                        .paper(seed: 1, fill: theme.raised)
                        .rotationEffect(.degrees(-2))
                }
                VStack(spacing: Space.xs) {
                    Text(episode?.title ?? "Nothing playing")
                        .font(typeSize.isAccessibilitySize ? Typo.showTitle : Typo.playerTitle)
                        .textCase(Typo.titleCase)
                        .foregroundStyle(theme.text)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityAction(named: "About this episode") { if episode?.summary?.isEmpty == false { showingAbout = true } }
                    Text(episode?.showTitle ?? "")
                        .font(Typo.caption)
                        .foregroundStyle(theme.textMuted)
                        .lineLimit(1)
                }
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { titleFrame = $0 }
                .frame(maxWidth: .infinity)
                .padding(.top, Space.l)
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
                    .background(theme.bg)
                    .environment(\.theme, theme)
                    .presentationDetents([.medium, .fraction(0.92)])
                    .presentationDragIndicator(.visible)
                }

                if preview == nil, case .failed(let message) = player.loadState {
                    HStack(spacing: Space.m) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(message).lineLimit(2)
                        Spacer()
                        Button("Retry") { player.retry() }
                            .font(Typo.headline)
                            .frame(minHeight: 44)
                    }
                    .font(Typo.caption)
                    .foregroundStyle(theme.danger)
                    .padding(.horizontal, Space.m)
                    .padding(.vertical, Space.xs)
                    .paper(seed: 1, fill: theme.surface)
                    .padding(.top, Space.m)
                }
                Spacer(minLength: Space.s)
            }
            .padding(.horizontal, Space.xxl)
            .padding(.top, Space.s)

            // On the cut-paper ground: everything you touch.
            VStack(spacing: Space.l) {
                if let preview {
                    Scrubber(position: model.position(for: preview)?.seconds ?? 0, duration: preview.duration) { _ in }
                        .disabled(true)
                } else {
                    Scrubber(position: player.position, duration: player.duration) { player.seek(to: $0) }
                }

                transport

                // "Back to …" on the left (only while Sleep is off), a toast on the right.
                // Stacked at accessibility sizes; the row is gone when both are.
                let note = model.sleepStatus != .off ? model.nightNote : model.toast
                let marker = preview == nil ? model.driftBackPosition : nil
                if marker != nil || note != nil {
                    sleepRowLayout {
                        if let marker {
                            DriftBackKey(position: marker) { model.jumpToDriftBack() }
                        }
                        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                        if let note { toastLabel(note) }
                    }
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 6)))
                }

                MoonKey(status: model.sleepStatus, action: { model.toggleSleep() }, onAdjust: { model.adjustSleep(minutes: $0) })
                    .disabled(player.episode == nil || preview != nil)
                    .sensoryFeedback(Haptic.moon, trigger: model.sleepStatus == .off)
                    .sensoryFeedback(.selection, trigger: model.sleepAdjustCount)
                    .overlay(alignment: .topLeading) {
                        if model.sleepStatus != .off {
                            // z's rise out of the moon and float up past the skip key, in every theme.
                            FloatingZs(isFading: { if case .fading = model.sleepStatus { return true }; return false }())
                                .frame(width: 90, height: 150)
                                .offset(x: 8, y: -140)
                                .transition(.opacity)
                        }
                    }
            }
            .animation(reduceMotion ? Motion.fade : Motion.move, value: model.sleepStatus == .off)
            .animation(Motion.fade, value: model.toast)
            .animation(Motion.fade, value: model.nightNote)
            .animation(reduceMotion ? Motion.fade : Motion.move, value: model.driftBackPosition)
            .padding(.horizontal, Space.xxl)
            .padding(.top, typeSize.isAccessibilitySize ? Space.l : Space.xxl)
            .padding(.bottom, Space.m)
            .background {
                ZStack {
                    GroundShape(lift: 14).fill(theme.raised)
                    GroundShape().fill(theme.bg)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    private func toastLabel(_ message: String) -> some View {
        Text(message)
            .font(Typo.caption)
            .foregroundStyle(theme.text)
            .padding(.horizontal, Space.l)
            .padding(.vertical, Space.s)
            .paper(seed: 1, fill: theme.surface)
            .transition(.opacity)
            .accessibilityHidden(true) // announced via UIAccessibility
    }

    /// Round keys, as in 1.0: the one place on Now Playing that is not cut paper.
    private var transport: some View {
        let player = model.player
        let preview = model.preview
        // Previewing: Play starts the previewed episode; the rest waits for it.
        let playing = preview == nil && player.isPlaying
        return HStack(spacing: Space.xl) {
            Button { player.skip(by: -15); skipTaps += 1 } label: {
                Image(systemName: "gobackward.15").font(.system(size: 24, weight: .semibold))
            }
            .buttonStyle(KeyStyle(shape: Circle()))
            .frame(width: 64, height: 64)
            .disabled(preview != nil)
            .accessibilityLabel("Back 15 seconds")

            Button {
                if let preview { model.play(preview) } else { player.togglePlayPause() }
            } label: {
                ZStack {
                    if preview == nil && player.isBuffering {
                        ProgressView().tint(theme.bg).controlSize(.large)
                    } else {
                        Image(systemName: playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 30, weight: .bold))
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
            .buttonStyle(KeyStyle(shape: Circle(), role: .primary))
            .frame(width: 88, height: 88)
            .disabled(player.episode == nil)
            .accessibilityLabel(playing ? "Pause" : "Play")
            .accessibilityValue(preview == nil && player.isBuffering ? "Loading" : "")
            .accessibilityIdentifier("playPause")
            .sensoryFeedback(Haptic.transport, trigger: playing)

            Button { player.skip(by: 15); skipTaps += 1 } label: {
                Image(systemName: "goforward.15").font(.system(size: 24, weight: .semibold))
            }
            .buttonStyle(KeyStyle(shape: Circle()))
            .frame(width: 64, height: 64)
            .disabled(preview != nil)
            .accessibilityLabel("Forward 15 seconds")
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(Haptic.skip, trigger: skipTaps)
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
        .buttonStyle(.capsuleKey(depth: 3))
        .fixedSize(horizontal: !typeSize.isAccessibilitySize, vertical: true)
        .sensoryFeedback(.selection, trigger: taps)
        .accessibilityLabel("Back to \(TimeFormat.spoken(position)), where the fade began")
        .accessibilityHint("Moves the episode there. It stays paused.")
        .accessibilityIdentifier("driftBackKey")
    }
}

/// The cut-paper ground the controls stand on; two layers (`lift` raises the back one)
/// with hand-cut top edges, in the theme's own dark tones.
private nonisolated struct GroundShape: Shape {
    var lift: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 26 - lift))
        p.addCurve(to: CGPoint(x: rect.maxX, y: 14 - lift),
                   control1: CGPoint(x: rect.maxX * 0.3, y: -14 - lift), control2: CGPoint(x: rect.maxX * 0.68, y: 34 - lift))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: rect.maxY))
        p.closeSubpath()
        return p
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
