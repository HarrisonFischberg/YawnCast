import YawnCastCore
import SwiftUI
import UIKit

@main
struct YawnCastApp: App {
    @State private var model: AppModel

    init() {
        #if DEBUG
        // Launch arguments for screenshots and UI tests (TestSupport/, Debug builds only).
        _model = State(initialValue: DebugLaunch.makeModel(arguments: ProcessInfo.processInfo.arguments))
        #else
        _model = State(initialValue: AppModel(store: JSONLibraryStore.standard(), directory: ITunesDirectory(), feeds: HTTPFeedService()))
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ThemedRoot()
                .environment(model)
                // A look with a day page follows the phone; classic themes force their own scheme.
                .preferredColorScheme(model.theme.followsSystem ? nil : model.theme.colorScheme)
        }
    }
}

/// Resolves the theme for the phone's current appearance and hands it down.
struct ThemedRoot: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let theme = model.theme.resolved(for: scheme).styled(model.look)
        RootView()
            .environment(\.theme, theme)
            .tint(theme.accent)
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.path) {
            HomeView()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .show(let show):
                        ShowView(show: show, app: model)
                    case .category(let category):
                        CategoryView(category: category)
                    }
                }
        }
        .tint(theme.text)
        // Once something is loaded, the player floats over every screen and stays there.
        .overlay(alignment: .bottom) {
            VStack(spacing: Space.s) {
                // Above the mini player, in reach of a thumb, and clear of the back button.
                if let undo = model.unsubscribed {
                    UndoToast(message: "Unsubscribed from \(undo.show.title)") { model.undoUnsubscribe() }
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 8)))
                }
                if model.player.episode != nil {
                    // It floats a little above the bottom edge (v0.17, owner request), the same gap
                    // it keeps above the keyboard (which still pushes it up: only the container
                    // inset is ignored).
                    MiniPlayerDock()
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, Space.xl)
            // Clears the home indicator with room to spare.
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .animation(.smooth(duration: 0.38), value: model.player.episode == nil)
        .animation(Motion.fade, value: model.unsubscribed?.show.id)
        // One success tap whenever a show lands in the Library (any + or Subscribe, or an Undo).
        .sensoryFeedback(trigger: model.library.subscriptions.count) { old, new in new > old ? .success : nil }
        .overlay(alignment: .top) {
            if let note = model.addedNote {
                Text(note)
                    .font(Typo.caption)
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, Space.l)
                    .padding(.vertical, Space.s)
                    .paper(seed: 1, fill: theme.surface)
                    .padding(.top, Space.s)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: -8)))
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("addedToast")
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.addedNote)
        .fullScreenCover(isPresented: $model.isPlayerPresented) {
            NowPlayingView()
                .environment(\.theme, theme)
        }
    }
}

/// What just happened, with a way back: shown for a few seconds after a removal.
struct UndoToast: View {
    let message: String
    let undo: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: Space.m) {
            Text(message)
                .font(Typo.caption)
                .foregroundStyle(theme.text)
                .lineLimit(2)
            Spacer(minLength: 0)
            Button("Undo", action: undo)
                .font(Typo.headline)
                .foregroundStyle(theme.text)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityIdentifier("undoKey")
        }
        .padding(.leading, Space.l)
        .padding(.trailing, Space.m)
        .background { PaperShape(seed: 2).fill(theme.raised).shadow(color: .black.opacity(theme.shadowOpacity), radius: 10, y: 4) }
    }
}
