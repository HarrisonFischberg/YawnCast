import NightCastCore
import SwiftUI

/// Middle home page: subscribed shows.
struct LibraryView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @State private var isAppearancePresented = false

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Two columns normally; one at accessibility text sizes so titles stay readable.
    private var columns: [GridItem] {
        let count = typeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: Space.xl, alignment: .top), count: count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xxl) {
                header
                if model.library.subscriptions.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: Space.xxl) {
                        ForEach(model.library.subscriptions) { show in
                            NavigationLink(value: Route.show(show)) {
                                ShowTile(show: show, hasNew: model.hasNewEpisode(show))
                            }
                            .buttonStyle(TileStyle())
                            .contextMenu {
                                Button(role: .destructive) { model.unsubscribe(show) } label: {
                                    Label("Unsubscribe", systemImage: "minus.circle")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Space.xl)
            .padding(.bottom, Space.xxxl)
        }
        .scrollIndicators(.hidden)
        .background(theme.bg)
        .sheet(isPresented: $isAppearancePresented) {
            AppearanceSheet()
                .presentationDetents([.height(320)])
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Library")
                .font(Typo.display)
                .foregroundStyle(theme.text)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            HStack(spacing: Space.m) {
                IconKey(systemName: "circle.lefthalf.filled", label: "Appearance") { isAppearancePresented = true }
                IconKey(systemName: "magnifyingglass", label: "Search podcasts") { model.openSearch() }
                    .accessibilityIdentifier("searchKey")
            }
        }
        .padding(.top, Space.s)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            Text("Nothing on the nightstand yet.")
                .font(Typo.playerTitle)
                .foregroundStyle(theme.text)
            Text("Find a show you like to fall asleep to. It will live here.")
                .font(Typo.body)
                .foregroundStyle(theme.textMuted)
            Button { model.openSearch() } label: {
                Label("Find a podcast", systemImage: "magnifyingglass")
                    .font(Typo.headline)
                    .padding(.vertical, Space.l)
            }
            .buttonStyle(.capsuleKey(.primary))
            .frame(minHeight: 60)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("findPodcastKey")
        }
        .padding(.top, Space.huge)
    }
}

struct ShowTile: View {
    let show: Show
    var hasNew = false
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            ArtworkView(url: show.artworkURL, title: show.title)
                .overlay(alignment: .topTrailing) {
                    if hasNew {
                        // A small "new episode" pip, outside the artwork's content.
                        Circle()
                            .fill(theme.accent)
                            .overlay(Circle().strokeBorder(theme.bg, lineWidth: 3))
                            .frame(width: 18, height: 18)
                            .offset(x: 5, y: -5)
                            .accessibilityHidden(true)
                    }
                }
            Text(show.title)
                .font(Typo.headline)
                .foregroundStyle(theme.text)
                .lineLimit(typeSize.isAccessibilitySize ? 4 : 2)
                .multilineTextAlignment(.leading)
            if let author = show.author {
                Text(author)
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(hasNew ? "New episode" : "")
    }
}

/// Tiles press down slightly; no chrome.
struct TileStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct MiniPlayer: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        let player = model.player
        HStack(spacing: Space.m) {
            Button { model.isPlayerPresented = true } label: {
                HStack(spacing: Space.m) {
                    ArtworkView(url: player.episode?.artworkURL, cornerRadius: 8, title: player.episode?.showTitle ?? "")
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.episode?.title ?? "")
                            .font(Typo.headline)
                            .foregroundStyle(theme.text)
                            .lineLimit(1)
                        HStack(spacing: Space.xs) {
                            if model.sleepStatus != .off {
                                Image(systemName: "moon.fill").foregroundStyle(theme.accent)
                            }
                            Text(player.episode?.showTitle ?? "")
                                .lineLimit(1)
                        }
                        .font(Typo.caption)
                        .foregroundStyle(theme.textMuted)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Now playing: \(player.episode?.title ?? "")")
            .accessibilityHint("Opens the player.")
            .accessibilityIdentifier("miniPlayer")

            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.roundKey(.primary, depth: 3))
            .frame(width: 52, height: 52)
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            .sensoryFeedback(.impact(weight: .medium), trigger: player.isPlaying)
        }
        .padding(Space.m)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(theme.raised)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(theme.border, lineWidth: 1))
                .shadow(color: .black.opacity(theme.shadowOpacity), radius: 16, y: 8)
        }
    }
}
