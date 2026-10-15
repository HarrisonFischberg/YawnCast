import NightCastCore
import SwiftUI

/// Middle home page: subscribed shows. Large, small or list layout; press,
/// hold and drag a show to reorder.
struct LibraryView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var isSettingsPresented = false
    /// Show currently under a dragged show (highlighted as the drop slot).
    @State private var dropTargetID: String?

    private var columns: [GridItem] {
        let count: Int
        switch model.libraryLayout {
        case .large: count = typeSize.isAccessibilitySize ? 1 : 2
        case .small: count = typeSize.isAccessibilitySize ? 2 : 3
        case .list: count = 1
        }
        let spacing = model.libraryLayout == .small ? Space.m : Space.xl
        return Array(repeating: GridItem(.flexible(), spacing: spacing, alignment: .top), count: count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xxl) {
                header
                if model.library.subscriptions.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(
                        columns: columns,
                        alignment: .leading,
                        spacing: model.libraryLayout == .list ? Space.s : (model.libraryLayout == .small ? Space.l : Space.xxl)
                    ) {
                        ForEach(model.library.subscriptions) { show in
                            item(show)
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.library.subscriptions.map(\.id))
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: model.libraryLayout)
                }
            }
            .padding(.horizontal, Space.xl)
            .padding(.bottom, Space.xxxl)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $isSettingsPresented) {
            SettingsSheet()
                .presentationDetents([.medium, .large])
        }
    }

    private func item(_ show: Show) -> some View {
        NavigationLink(value: Route.show(show)) {
            switch model.libraryLayout {
            case .large: ShowTile(show: show, hasNew: model.hasNewEpisode(show))
            case .small: ShowTile(show: show, hasNew: model.hasNewEpisode(show), compact: true)
            case .list: ShowListRow(show: show, hasNew: model.hasNewEpisode(show))
            }
        }
        .buttonStyle(TileStyle())
        .overlay {
            if dropTargetID == show.id {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(theme.accent, lineWidth: 3)
                    .padding(-4)
                    .allowsHitTesting(false)
            }
        }
        // Press, hold and drag onto another show to move it there.
        .draggable(show.id) {
            ArtworkView(url: show.artworkURL, cornerRadius: 12, title: show.title)
                .frame(width: 88, height: 88)
        }
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first else { return false }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { model.moveSubscription(id: id, onto: show.id) }
            dropTargetID = nil
            return true
        } isTargeted: { targeted in
            if targeted { dropTargetID = show.id } else if dropTargetID == show.id { dropTargetID = nil }
        }
        .contextMenu {
            Button { model.moveToTop(show) } label: { Label("Move to Top", systemImage: "arrow.up.to.line") }
            Button { model.moveToEnd(show) } label: { Label("Move to End", systemImage: "arrow.down.to.line") }
            Button(role: .destructive) { model.unsubscribe(show) } label: {
                Label("Unsubscribe", systemImage: "minus.circle")
            }
        }
        .accessibilityAction(named: "Move to Top") { model.moveToTop(show) }
        .accessibilityAction(named: "Move to End") { model.moveToEnd(show) }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Library")
                .font(Typo.display)
                .foregroundStyle(theme.text)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            HStack(spacing: Space.m) {
                if !model.library.subscriptions.isEmpty {
                    IconKey(systemName: model.libraryLayout.next.symbol, label: "Layout: \(model.libraryLayout.title). Switch to \(model.libraryLayout.next.title)") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { model.libraryLayout = model.libraryLayout.next }
                    }
                    .accessibilityIdentifier("layoutKey")
                    .sensoryFeedback(.selection, trigger: model.libraryLayout)
                }
                IconKey(systemName: "slider.horizontal.3", label: "Settings") { isSettingsPresented = true }
                    .accessibilityIdentifier("settingsKey")
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

extension LibraryLayout {
    var title: String {
        switch self {
        case .large: "Large"
        case .small: "Small"
        case .list: "List"
        }
    }

    var symbol: String {
        switch self {
        case .large: "square.grid.2x2"
        case .small: "square.grid.3x3"
        case .list: "list.bullet"
        }
    }
}

/// List layout row: artwork, title, author.
struct ShowListRow: View {
    let show: Show
    var hasNew = false
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: Space.m) {
            ArtworkView(url: show.artworkURL, cornerRadius: 10, title: show.title)
                .frame(width: 60, height: 60)
                .overlay(alignment: .topTrailing) { if hasNew { NewPip(size: 14) } }
            VStack(alignment: .leading, spacing: 2) {
                Text(show.title)
                    .font(Typo.headline)
                    .foregroundStyle(theme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let author = show.author {
                    Text(author).font(Typo.caption).foregroundStyle(theme.textMuted).lineLimit(1)
                }
            }
            Spacer(minLength: Space.s)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(theme.textMuted)
                .accessibilityHidden(true)
        }
        .padding(Space.s)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.surface.opacity(0.7)))
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(show.author.map { "\(show.title), \($0)" } ?? show.title)
        .accessibilityValue(hasNew ? "New episode" : "")
    }
}

/// Small accent dot: the show has an unplayed episode from the last week.
struct NewPip: View {
    var size: CGFloat = 18
    @Environment(\.theme) private var theme

    var body: some View {
        Circle()
            .fill(theme.accent)
            .overlay(Circle().strokeBorder(theme.edge, lineWidth: size / 6))
            .frame(width: size, height: size)
            .offset(x: size / 3.5, y: -size / 3.5)
            .accessibilityHidden(true)
    }
}

struct ShowTile: View {
    let show: Show
    var hasNew = false
    /// Small-card layout: tighter type, no author.
    var compact = false
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? Space.xs : Space.s) {
            ArtworkView(url: show.artworkURL, cornerRadius: compact ? 10 : 14, title: show.title)
                .overlay(alignment: .topTrailing) { if hasNew { NewPip(size: compact ? 14 : 18) } }
            Text(show.title)
                .font(compact ? Typo.caption : Typo.headline)
                .foregroundStyle(theme.text)
                .lineLimit(typeSize.isAccessibilitySize ? 4 : 2)
                .multilineTextAlignment(.leading)
            if !compact, let author = show.author {
                Text(author)
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .ignore)
        // Same label in every layout (compact cards hide the author visually).
        .accessibilityLabel(show.author.map { "\(show.title), \($0)" } ?? show.title)
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

    private func hide() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { model.isMiniPlayerHidden = true }
    }

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

            if !player.isPlaying {
                // Paused: one tap slides the player away until something plays again.
                Button { hide() } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(theme.textMuted)
                        .frame(width: 36, height: 52)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hide player")
                .accessibilityIdentifier("hideMiniPlayer")
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeOut(duration: 0.2), value: player.isPlaying)
        .gesture(
            DragGesture(minimumDistance: 20).onEnded { value in
                if value.translation.height > 40, !player.isPlaying { hide() }
            }
        )
        .padding(Space.m)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(theme.raised)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(theme.border, lineWidth: 1))
                .shadow(color: .black.opacity(theme.shadowOpacity), radius: 16, y: 8)
        }
    }
}
