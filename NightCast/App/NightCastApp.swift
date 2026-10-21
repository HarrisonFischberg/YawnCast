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
            RootView()
                .environment(model)
                .environment(\.theme, model.theme)
                .preferredColorScheme(model.theme.colorScheme)
                .tint(model.theme.accent)
        }
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
                // It sits in the home-indicator strip with a small gap, the same gap it keeps
                // above the keyboard (which still pushes it up: only the container inset is ignored).
                MiniPlayerDock()
                    .padding(.horizontal, 30)
                    .padding(.bottom, Space.xs)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.smooth(duration: 0.38), value: model.player.episode == nil)
        .fullScreenCover(isPresented: $model.isPlayerPresented) {
            NowPlayingView()
                .environment(\.theme, model.theme)
        }
    }
}
