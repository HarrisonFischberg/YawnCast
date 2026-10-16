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
    @State private var keyboardVisible = false

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
        // Once something is loaded, the mini player stays on every screen.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Stays out of the way while the keyboard is up (it would cover search results).
            if model.player.episode != nil && !keyboardVisible {
                if model.showsMiniPlayer {
                    MiniPlayer()
                        .padding(.horizontal, Space.m)
                        .padding(.bottom, Space.xs)
                        .transition(.scale(scale: 0.4, anchor: .bottom).combined(with: .opacity))
                } else {
                    // Slid away: a small oval stays at the bottom; tap it to bring the player back.
                    MiniPlayerPill()
                        .padding(.bottom, Space.xs)
                        .transition(.scale(scale: 2.2, anchor: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: model.showsMiniPlayer)
        .animation(.easeOut(duration: 0.2), value: keyboardVisible)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in keyboardVisible = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardVisible = false }
        .fullScreenCover(isPresented: $model.isPlayerPresented) {
            NowPlayingView()
                .environment(\.theme, model.theme)
        }
    }
}
