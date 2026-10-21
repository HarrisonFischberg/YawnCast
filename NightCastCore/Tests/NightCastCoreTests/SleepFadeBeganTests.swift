import Foundation
import Testing
@testable import NightCastCore

/// `onFadeBegan` / `onFadedToSilence`: the hooks the app uses to offer
/// "Back to where the fade began" after Sleep pauses an episode.
@MainActor
@Suite("SleepController — fade began")
struct SleepFadeBeganTests {
    let clock = FakeClock()
    let player = FakePlayer()

    func run(_ controller: SleepController, seconds: TimeInterval, tick: TimeInterval = 0.25) {
        var left = seconds
        while left > 1e-9 {
            let dt = min(tick, left)
            clock.advance(dt)
            if player.isPlaying && !player.isBuffering { player.position += dt }
            controller.sync()
            left -= dt
        }
    }

    @Test("Fires once when the countdown runs out, with the position recoverable")
    func firesOnceAtFadeStart() {
        let controller = SleepController(clock: clock, configuration: .v1)
        var began: [(String, TimeInterval)] = []
        var silenced: [String] = []
        controller.onFadeBegan = { id, ago in began.append((id, self.player.position - ago)) }
        controller.onFadedToSilence = { silenced.append($0) }
        player.position = 600
        controller.toggle(player: player, episodeID: "e1", remaining: nil, position: 600)
        run(controller, seconds: 1799)
        #expect(began.isEmpty)
        run(controller, seconds: 2, tick: 0.3)
        #expect(began.count == 1)
        #expect(began.first?.0 == "e1")
        #expect(abs((began.first?.1 ?? 0) - (600 + 1800)) < 1e-6)
        run(controller, seconds: 4 * 180 + 10)
        #expect(began.count == 1)
        #expect(silenced == ["e1"])
        #expect(player.pauseCount == 1)
    }

    @Test("Cancel during the fade does not report silence")
    func cancelNoSilence() {
        let controller = SleepController(clock: clock, configuration: .v1)
        var began = 0
        var silenced = 0
        controller.onFadeBegan = { _, _ in began += 1 }
        controller.onFadedToSilence = { _ in silenced += 1 }
        controller.toggle(player: player, episodeID: "e1", remaining: nil)
        run(controller, seconds: 1900)
        controller.toggle(player: player, episodeID: "e1", remaining: nil)
        run(controller, seconds: 3600)
        #expect(began == 1)
        #expect(silenced == 0)
    }

    @Test("+5 min during a fade starts a new fade later, which reports again")
    func adjustRefires() {
        let controller = SleepController(clock: clock, configuration: .v1)
        var began = 0
        controller.onFadeBegan = { _, _ in began += 1 }
        controller.toggle(player: player, episodeID: "e1", remaining: nil)
        run(controller, seconds: 1850)
        #expect(began == 1)
        controller.adjust(by: 300)
        run(controller, seconds: 301)
        #expect(began == 2)
    }

    @Test("−5 min with under 5 min left starts the fade now, and still reports it")
    func minusFiveClampedToNow() {
        let controller = SleepController(clock: clock, configuration: .v1)
        var began: [(String, TimeInterval)] = []
        var silenced: [String] = []
        controller.onFadeBegan = { id, ago in began.append((id, self.player.position - ago)) }
        controller.onFadedToSilence = { silenced.append($0) }
        player.position = 100
        controller.toggle(player: player, episodeID: "e1", remaining: nil, position: 100)
        run(controller, seconds: 1700)
        #expect(began.isEmpty)
        #expect(controller.adjust(by: -300))
        #expect(began.count == 1)
        #expect(abs((began.first?.1 ?? 0) - (100 + 1700)) < 1e-6)
        run(controller, seconds: 4 * 180 + 10)
        #expect(began.count == 1)
        #expect(silenced == ["e1"])
    }

    @Test("Paused time never starts the fade")
    func pausedNoFade() {
        let controller = SleepController(clock: clock, configuration: .v1)
        var began = 0
        controller.onFadeBegan = { _, _ in began += 1 }
        controller.toggle(player: player, episodeID: "e1", remaining: nil)
        player.isPlaying = false
        controller.sync()
        run(controller, seconds: 4000)
        #expect(began == 0)
    }
}
