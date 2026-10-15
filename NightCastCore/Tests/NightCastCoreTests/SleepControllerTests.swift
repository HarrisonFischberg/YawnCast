import Foundation
import Testing
@testable import NightCastCore

final class FakeClock: PlaybackClock, @unchecked Sendable {
    private let lock = NSLock()
    private var t: TimeInterval = 1000
    func now() -> TimeInterval { lock.withLock { t } }
    func advance(_ dt: TimeInterval) { lock.withLock { t += dt } }
}

@MainActor
final class FakePlayer: SleepControllable {
    var gain: Double = 1
    var isPlaying = true
    var isBuffering = false
    var position: TimeInterval = 0
    var pauseCount = 0
    var playNextCount = 0 // must stay 0: nothing in Sleep may start another episode
    var isActivelyPlaying: Bool { isPlaying && !isBuffering }
    func pauseForSleep() {
        isPlaying = false
        pauseCount += 1
    }
}

@MainActor
@Suite("SleepController — virtual time")
struct SleepControllerTests {
    let clock = FakeClock()
    let player = FakePlayer()

    /// Advances virtual time in 0.25 s ticks, syncing like the app's driver.
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

    @Test("Activation message and gain stay at baseline")
    func activation() {
        let controller = SleepController(clock: clock, configuration: .v1)
        let delay = controller.toggle(player: player, episodeID: "e1", remaining: 3600)
        #expect(delay == 1800)
        #expect(SleepCopy.activated(fadeDelay: delay!) == "Sleep on · fade begins in 30 min")
        #expect(player.gain == 1)
    }

    @Test("Shorter interval is announced for short episodes")
    func shortMessage() {
        let controller = SleepController(clock: clock, configuration: .v1)
        let delay = controller.toggle(player: player, episodeID: "e1", remaining: 24 * 60)
        #expect(SleepCopy.activated(fadeDelay: delay!) == "Sleep on · fade begins in 12 min")
    }

    // M4.3
    @Test("Paused time does not consume the countdown")
    func pauseFreezes() {
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: nil)
        run(controller, seconds: 600)
        player.isPlaying = false
        controller.sync()
        run(controller, seconds: 5 * 3600)
        #expect(controller.status == .waiting(untilFade: 1200))
        player.isPlaying = true
        controller.sync()
        run(controller, seconds: 1200 + 2)
        #expect(abs(player.gain - 0.8) < 1e-9)
    }

    @Test("Buffering time does not consume the countdown")
    func bufferingFreezes() {
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: nil)
        run(controller, seconds: 100)
        player.isBuffering = true
        controller.sync()
        run(controller, seconds: 900)
        player.isBuffering = false
        controller.sync()
        #expect(controller.status == .waiting(untilFade: 1700))
    }

    @Test("Activating while paused does not count until playback resumes")
    func activateWhilePaused() {
        player.isPlaying = false
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: nil)
        run(controller, seconds: 3600)
        #expect(controller.status == .waiting(untilFade: 1800))
    }

    // M4.2 + M4.5 end to end
    @Test("Full fade pauses once, restores gain, never plays another episode")
    func fullFade() {
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: nil)
        var observed: [Double] = []
        for checkpoint in [1800.0 + 2, 180, 180, 180] {
            run(controller, seconds: checkpoint)
            observed.append((player.gain * 100).rounded() / 100)
        }
        #expect(observed == [0.8, 0.6, 0.4, 0.2])
        #expect(player.pauseCount == 0)
        run(controller, seconds: 180)
        #expect(player.pauseCount == 1)
        #expect(!player.isPlaying)
        #expect(!controller.isActive)
        #expect(player.gain == 1) // restored while paused
        run(controller, seconds: 3600)
        #expect(player.pauseCount == 1)
        #expect(player.playNextCount == 0)
    }

    // M4.4
    @Test("Second tap cancels and smoothly restores baseline")
    func secondTapCancels() {
        let controller = SleepController(clock: clock, configuration: .v1)
        player.gain = 0.9
        controller.toggle(player: player, episodeID: "e1", remaining: nil)
        run(controller, seconds: 1800 + 180 + 2) // 0.6 × 0.9
        #expect(abs(player.gain - 0.54) < 1e-9)
        #expect(controller.toggle(player: player, episodeID: "e1", remaining: nil) == nil)
        #expect(!controller.isActive)
        #expect(controller.needsTicks)
        run(controller, seconds: 1)
        #expect(abs(player.gain - 0.9) < 1e-9)
        #expect(!controller.needsTicks)
    }

    // M4.7
    @Test("Scrubbing does not reset the countdown")
    func seekDoesNotReset() {
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: 3 * 3600)
        run(controller, seconds: 900)
        player.position = 10 // user scrubs back
        controller.sync()
        #expect(controller.status == .waiting(untilFade: 900))
        player.position = 7000 // and forward
        run(controller, seconds: 900)
        #expect(controller.status == .fading(level: 0.8))
    }

    // M4.8
    @Test("Deliberately starting a different episode cancels Sleep")
    func differentEpisodeCancels() {
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: nil)
        run(controller, seconds: 1800 + 2)
        controller.episodeWillChange(to: "e1")
        #expect(controller.isActive)
        controller.episodeWillChange(to: "e2")
        #expect(!controller.isActive)
        #expect(player.gain == 1)
    }

    // M4.6
    @Test("Episode ending first stops Sleep and restores gain")
    func episodeEndsFirst() {
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: 120)
        run(controller, seconds: 62) // fade started at 60 s
        #expect(player.gain < 1)
        player.isPlaying = false
        controller.episodeDidEnd()
        #expect(!controller.isActive)
        #expect(player.gain == 1)
        #expect(player.playNextCount == 0)
    }

    @Test("Interruption pauses the countdown and resumes correctly")
    func interruption() {
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: nil)
        run(controller, seconds: 1000)
        player.isPlaying = false // phone call
        controller.sync()
        run(controller, seconds: 300)
        player.isPlaying = true // user or system resumes
        controller.sync()
        run(controller, seconds: 800)
        #expect(controller.status == .fading(level: 0.8))
    }

    // M4.9
    @Test("A fresh controller (relaunch) is never active")
    func relaunchNotActive() {
        let controller = SleepController(clock: clock, configuration: .v1)
        #expect(!controller.isActive)
        #expect(controller.status == .off)
        let snapshot = LibrarySnapshot()
        let json = String(decoding: try! JSONEncoder().encode(snapshot), as: UTF8.self)
        #expect(!json.lowercased().contains("sleep"))
    }
}

@MainActor
@Suite("SleepController — provisional duration (D11)")
struct ProvisionalDurationTests {
    let clock = FakeClock()
    let player = FakePlayer()

    func run(_ controller: SleepController, seconds: TimeInterval) {
        var left = seconds
        while left > 1e-9 {
            let dt = min(0.25, left)
            clock.advance(dt)
            controller.sync()
            left -= dt
        }
    }

    @Test("Feed said 31:22, stream measures 37:04: delay corrected from 8:30 to 11:21 (681 s)")
    func correctsOnce() {
        let controller = SleepController(clock: clock, configuration: .v1)
        let position = 14 * 60 + 22.0
        let feed = 31 * 60 + 22.0
        let delay = controller.toggle(player: player, episodeID: "e1", remaining: feed - position, position: position, durationIsProvisional: true)
        #expect(delay == 510)
        run(controller, seconds: 60)
        controller.measuredDurationArrived(37 * 60 + 4, episodeID: "e1")
        // R = 2224 - 862 = 1362 → 681 s; 60 s already elapsed.
        #expect(controller.status == .waiting(untilFade: 621))
        // Only once.
        controller.measuredDurationArrived(50 * 60, episodeID: "e1")
        #expect(controller.status == .waiting(untilFade: 621))
    }

    @Test("Measured duration is ignored when R was not provisional")
    func ignoredWhenMeasured() {
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: 1000, position: 0, durationIsProvisional: false)
        controller.measuredDurationArrived(4000, episodeID: "e1")
        #expect(controller.status == .waiting(untilFade: 500))
    }

    @Test("Shorter real duration never starts the fade in the past")
    func neverInThePast() {
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: 3600, position: 0, durationIsProvisional: true)
        run(controller, seconds: 300)
        controller.measuredDurationArrived(200, episodeID: "e1") // R/2 = 100 < 300 elapsed
        #expect(controller.status == .fading(level: 0.8))
        #expect(player.gain == 1) // glide starts now, from baseline
        run(controller, seconds: 2)
        #expect(abs(player.gain - 0.8) < 1e-9)
    }

    @Test("No revision once fading, or for another episode")
    func noRevisionWhenFadingOrOtherEpisode() {
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: 120, position: 0, durationIsProvisional: true)
        controller.measuredDurationArrived(9000, episodeID: "e2")
        #expect(controller.status == .waiting(untilFade: 60))
        run(controller, seconds: 61)
        controller.measuredDurationArrived(9000, episodeID: "e1")
        #expect(controller.status == .fading(level: 0.8))
    }
}
