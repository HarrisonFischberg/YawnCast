import SwiftUI

/// Full-screen background for a screen: the look's still ground. (The animated
/// scenes of v0.5 to v0.16 were retired with their themes in v0.17.)
struct ScreenBackground: View {
    @Environment(\.theme) private var theme

    var body: some View {
        theme.bg.ignoresSafeArea()
    }
}
