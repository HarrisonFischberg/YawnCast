import Foundation
import Testing
@testable import NightCastCore

extension SleepConfiguration {
    /// The original V1 spec (20% every 3 min). Mechanics tests pin to it so
    /// they keep checking the state machine independent of product tuning.
    static let v1 = SleepConfiguration(stepInterval: 180, levels: [0.8, 0.6, 0.4, 0.2, 0.0])
}

@Suite("Sleep — current spec: 10% every 40 s, 6 minutes")
struct TenPercentFadeTests {
    @Test func standardLevelsAreTenPercentSteps() {
        let config = SleepConfiguration.standard
        #expect(config.stepInterval == 40)
        #expect(config.levels.count == 10)
        #expect(zip(config.levels, [0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0]).allSatisfy { abs($0 - $1) < 1e-12 })
    }

    @Test("Each 40 s after the fade starts drops 10%", arguments: Array(0..<9))
    func eachMinute(step: Int) {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: nil)
        timer.advance(activeSeconds: 1800 + Double(step) * 40 + 2)
        #expect(abs(timer.gain - (0.9 - Double(step) / 10)) < 1e-9)
    }

    @Test func pausesSixMinutesTwoSecondsAfterFadeStarts() {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: nil)
        #expect(timer.timeUntilSilence == TimeInterval(1800 + 360 + 2))
        #expect(timer.advance(activeSeconds: 1800 + 360 + 1.9) == nil)
        #expect(timer.advance(activeSeconds: 0.1) == .reachedSilence)
        #expect(timer.gain == 1)
    }
}

@Suite("Sleep — ±5 minute adjustments")
struct SleepAdjustTests {
    @Test func plusAndMinusMoveTheFadeStart() {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: nil)
        timer.advance(activeSeconds: 100)
        do { let changed = timer.adjust(by: 300); #expect(changed) }
        #expect(timer.status == .waiting(untilFade: 2000))
        do { let changed = timer.adjust(by: -300); #expect(changed) }
        do { let changed = timer.adjust(by: -300); #expect(changed) }
        #expect(timer.status == .waiting(untilFade: 1400))
        #expect(timer.timeUntilSilence == TimeInterval(1400 + 362))
    }

    @Test func minusNeverGoesIntoThePast() {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: 400)  // fade after 200 s
        timer.advance(activeSeconds: 50)
        do { let changed = timer.adjust(by: -300); #expect(changed) }
        #expect(timer.status == .fading(level: 0.9), "fade starts now")
        #expect(timer.gain == 1, "and glides in from full volume")
        timer.advance(activeSeconds: 2)
        #expect(abs(timer.gain - 0.9) < 1e-9)
        do { let changed = timer.adjust(by: -300); #expect(!changed, "minus does nothing once fading") }
    }

    @Test func plusIsCappedAtFourHours() {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: nil)
        for _ in 0..<100 { timer.adjust(by: 300) }
        #expect(timer.status == .waiting(untilFade: 4 * 3600))
        do { let changed = timer.adjust(by: 300); #expect(!changed) }
    }

    @Test func plusWhileFadingGlidesBackUpAndWaitsAgain() {
        var timer = SleepTimer()
        timer.activate(baseline: 0.8, remaining: nil)
        timer.advance(activeSeconds: 1800 + 3 * 40 + 2) // at 60%
        #expect(abs(timer.gain - 0.8 * 0.6) < 1e-9)
        do { let changed = timer.adjust(by: 300); #expect(changed) }
        #expect(timer.status == .waiting(untilFade: 300))
        #expect(abs(timer.gain - 0.8 * 0.6) < 1e-9, "no jump")
        timer.advance(activeSeconds: 0.5)
        #expect(abs(timer.gain - 0.8 * 0.8) < 1e-9, "halfway back up")
        timer.advance(activeSeconds: 0.5)
        #expect(timer.gain == 0.8)
        timer.advance(activeSeconds: 299 + 2)
        #expect(abs(timer.gain - 0.8 * 0.9) < 1e-9, "fades again from the top")
    }

    @Test func adjustDoesNothingWhenOff() {
        var timer = SleepTimer()
        do { let changed = timer.adjust(by: 300); #expect(!changed) }
        #expect(timer.timeUntilSilence == nil)
    }

    @MainActor
    @Test func controllerAppliesAdjustToPlayer() {
        let clock = FakeClock()
        let player = FakePlayer()
        let controller = SleepController(clock: clock)
        controller.toggle(player: player, episodeID: "e1", remaining: 600) // fade after 300 s
        clock.advance(10)
        #expect(controller.adjust(by: 300))
        #expect(controller.status == .waiting(untilFade: 590))
        #expect(controller.adjust(by: -600))
        #expect(controller.status == .fading(level: 0.9))
    }
}
