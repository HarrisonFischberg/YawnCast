import Foundation
import NightCastCore
import Testing
@testable import NightCast

struct LockScreenSleepTextTests {
    @Test func offIsJustTheShow() {
        #expect(LockScreenSleepText.subtitle(show: "Radiolab", status: .off) == "Radiolab")
    }

    @Test func waitingShowsWholeMinutes() {
        #expect(LockScreenSleepText.subtitle(show: "Radiolab", status: .waiting(untilFade: 17 * 60))
            == "Radiolab · Sleep on, fades in 17 min")
        #expect(LockScreenSleepText.subtitle(show: "Radiolab", status: .waiting(untilFade: 16 * 60 + 1))
            == "Radiolab · Sleep on, fades in 17 min")
        #expect(LockScreenSleepText.subtitle(show: "Radiolab", status: .waiting(untilFade: 20))
            == "Radiolab · Sleep on, fades in 1 min")
    }

    @Test func fading() {
        #expect(LockScreenSleepText.subtitle(show: "Radiolab", status: .fading(level: 0.6))
            == "Radiolab · Sleep on, fading")
    }

    @Test func minuteValueChangesOnlyOncePerMinute() {
        let texts = Set(stride(from: 600.0, through: 481.0, by: -0.25).map {
            LockScreenSleepText.subtitle(show: "S", status: .waiting(untilFade: $0))
        })
        #expect(texts.count == 2) // 10 min then 9 min
    }

    @MainActor @Test func bridgeArtistLineFollowsProvider() {
        let episode = Episode(id: "e1", showFeedURL: URL(string: "https://example.com/feed")!, showTitle: "Radiolab", title: "Ep", audioURL: URL(string: "https://example.com/a.mp3")!)
        let bridge = NowPlayingBridge(engine: PlaybackEngine())
        #expect(bridge.artistText(for: episode) == episode.showTitle) // no provider: show title only
        bridge.artistLine = { LockScreenSleepText.subtitle(show: $0, status: .waiting(untilFade: 600)) }
        #expect(bridge.artistText(for: episode) == "\(episode.showTitle) · Sleep on, fades in 10 min")
    }
}
