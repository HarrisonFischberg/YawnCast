import NightCastCore
import SwiftUI
import UIKit

/// Middle home page: subscribed shows. Large, small or list layout; press,
/// hold and drag a show to reorder.
struct LibraryView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Show being dragged to a new place (nil when not reordering).
    @State private var draggingID: String?
    /// Last time a drag moved over the grid; a drag dropped outside never reports its end.
    @State private var lastDragActivity = Date()

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
        @Bindable var model = model
        SearchablePage(page: .library) {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xxl) {
                header
                if !model.library.subscriptions.isEmpty {
                    // One bar for both: filters your shows and finds new ones.
                    SearchCapsule(placeholder: "Search your shows or find new ones", identifier: "librarySearch") {
                        model.openSearch()
                    }
                    .padding(.top, -Space.s)
                }
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
                    .onDrop(of: [.text], isTargeted: nil) { _ in draggingID = nil; return true }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.library.subscriptions.map(\.id))
                    .sensoryFeedback(.selection, trigger: model.library.subscriptions.map(\.id))
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: model.libraryLayout)
                }
            }
            .padding(.horizontal, Space.xl)
            .padding(.bottom, Space.xxxl)
        }
        .scrollIndicators(.hidden)
        .dockAware()
        }
        .task(id: draggingID) {
            // Watchdog: if the drag went quiet (e.g. dropped outside), restore the tile.
            while draggingID != nil {
                try? await Task.sleep(for: .seconds(1))
                if Date().timeIntervalSince(lastDragActivity) > 3 { draggingID = nil }
            }
        }
        .sheet(isPresented: $model.isThemesPresented) {
            ThemesSheet()
                // Opens tall; swipes inside always scroll the list. Resize from the grabber.
                .presentationDetents([.fraction(0.8), .large])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
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
        // The show being carried stays faintly in its new slot while you drag.
        .opacity(draggingID == show.id ? 0.35 : 1)
        // Press and hold to pick up; the grid rearranges live as you pass over other shows.
        .onDrag {
            draggingID = show.id
            lastDragActivity = Date()
            return NSItemProvider(object: show.id as NSString)
        } preview: {
            ArtworkView(url: show.artworkURL, cornerRadius: 12, title: show.title)
                .frame(width: 96, height: 96)
        }
        .onDrop(of: [.text], delegate: ReorderDropDelegate(target: show, draggingID: $draggingID, lastActivity: $lastDragActivity, model: model))
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
                IconKey(systemName: "circle.lefthalf.filled", label: "Themes") { model.isThemesPresented = true }
                    .accessibilityIdentifier("themesKey")
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

/// The floating player: always on screen once something is loaded (it never
/// hides or shrinks away). Compact by design — about 15% smaller than v0.9.
struct MiniPlayerDock: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    /// Cached once: the flag is read at init, not per render.
    private let showsMoonKey = Experiments.isOn(.miniMoon)
    /// Counts taps on the mini Moon key so its haptic fires only for taps here,
    /// never for Sleep changes made from Now Playing (which has its own haptic).
    @State private var moonTaps = 0

    var body: some View {
        let player = model.player
        let sleepOn = model.sleepStatus != .off
        HStack(spacing: 10) {
            Button { model.isPlayerPresented = true } label: {
                HStack(spacing: 10) {
                    ArtworkView(url: player.episode?.artworkURL, cornerRadius: 7, title: player.episode?.showTitle ?? "")
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(player.episode?.title ?? "")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(theme.text)
                            .lineLimit(1)
                        HStack(spacing: Space.xs) {
                            // With the Moon key present, the key itself shows Sleep state.
                            if sleepOn && !showsMoonKey {
                                Image(systemName: "moon.fill").foregroundStyle(theme.accent)
                            }
                            Text(player.episode?.showTitle ?? "").lineLimit(1)
                        }
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(theme.textMuted)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Now playing: \(player.episode?.title ?? "")")
            .accessibilityValue(model.sleepStatus == .off ? (player.episode?.showTitle ?? "") : "\(player.episode?.showTitle ?? ""), Sleep on")
            .accessibilityHint("Opens the player.")
            .accessibilityIdentifier("miniPlayer")

            if showsMoonKey {
                Button {
                    moonTaps += 1
                    model.toggleSleep()
                } label: {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(sleepOn ? theme.onAccent : theme.accent)
                }
                .buttonStyle(.roundKey(sleepOn ? .accent : .standard, depth: 3))
                .frame(width: 44, height: 44)
                .disabled(player.episode == nil)
                .accessibilityLabel("Sleep")
                .accessibilityValue(sleepOn ? "On" : "Off")
                .accessibilityAddTraits(sleepOn ? .isSelected : [])
                .accessibilityIdentifier("miniMoonKey")
                .accessibilityShowsLargeContentViewer {
                    Label("Sleep", systemImage: "moon.fill")
                }
                .sensoryFeedback(.impact(weight: .heavy, intensity: 0.8), trigger: moonTaps)
            }

            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 17, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.roundKey(.primary, depth: 3))
            .frame(width: 44, height: 44)
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            .accessibilityIdentifier("miniPlayPause")
            .accessibilityShowsLargeContentViewer {
                Label(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill")
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: player.isPlaying)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.raised)
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(theme.border, lineWidth: 1))
                .shadow(color: .black.opacity(theme.shadowOpacity), radius: 12, y: 6)
        }
    }
}

extension View {
    /// Leaves room at the bottom of a scroll view for the floating player.
    func dockAware() -> some View { modifier(DockInset()) }
}

private struct DockInset: ViewModifier {
    @Environment(AppModel.self) private var model
    func body(content: Content) -> some View {
        content.contentMargins(.bottom, model.player.episode == nil ? 0 : 82, for: .scrollContent)
    }
}

/// Live reordering: entering another show's slot moves the dragged show there at once.
struct ReorderDropDelegate: DropDelegate {
    let target: Show
    @Binding var draggingID: String?
    @Binding var lastActivity: Date
    let model: AppModel

    func dropEntered(info: DropInfo) {
        lastActivity = Date()
        guard let id = draggingID, id != target.id else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            model.moveSubscription(id: id, onto: target.id)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        lastActivity = Date()
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        return true
    }
}
