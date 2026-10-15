import NightCastCore
import SwiftUI

/// Only: title, scrubber, −15 / play-pause / +15, Moon, and a way out.
struct NowPlayingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var skipTaps = 0

    var body: some View {
        let player = model.player
        ZStack {
            theme.bg.ignoresSafeArea()

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
                        .lineLimit(1)
                    Text(player.episode?.title ?? "Nothing playing")
                        .font(typeSize.isAccessibilitySize ? .system(.title2, design: .serif, weight: .bold) : .system(size: 36, weight: .bold, design: .serif))
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

                ZStack(alignment: .top) {
                    MoonKey(status: model.sleepStatus) { model.toggleSleep() }
                        .disabled(player.episode == nil)
                        .sensoryFeedback(.impact(weight: .heavy, intensity: 0.8), trigger: model.sleepStatus == .off)
                    if let toast = model.toast {
                        Text(toast)
                            .font(Typo.caption)
                            .foregroundStyle(theme.text)
                            .padding(.horizontal, Space.l)
                            .padding(.vertical, Space.s)
                            .background(Capsule().fill(theme.surface).overlay(Capsule().strokeBorder(theme.border)))
                            .offset(y: -44)
                            .transition(.opacity.combined(with: .offset(y: 6)))
                            .accessibilityHidden(true) // announced via UIAccessibility
                    }
                }
                .animation(.easeOut(duration: 0.2), value: model.toast)
                .padding(.bottom, Space.l)
            }
            .padding(.horizontal, Space.xxl)
        }
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
