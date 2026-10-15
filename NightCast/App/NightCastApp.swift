import NightCastCore
import SwiftUI

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

    var body: some View {
        @Bindable var model = model
        LibraryView()
            .fullScreenCover(isPresented: $model.isPlayerPresented) {
                NowPlayingView()
                    .environment(\.theme, model.theme)
            }
    }
}
