import NightCastCore
import SwiftUI
import UIKit

@main
struct NightCastApp: App {
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
        let theme = model.theme.resolved(for: scheme)
        RootView()
            .environment(\.theme, theme)
            .tint(theme.accent)
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

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
            if model.player.episode != nil {
                // It floats a little above the bottom edge (v0.17, owner request), the same gap
                // it keeps above the keyboard (which still pushes it up: only the container
                // inset is ignored).
                MiniPlayerDock()
                    .padding(.horizontal, 30)
                    // Clears the home indicator with room to spare.
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.smooth(duration: 0.38), value: model.player.episode == nil)
        .fullScreenCover(isPresented: $model.isPlayerPresented) {
            NowPlayingView()
                .environment(\.theme, theme)
        }
    }
}
